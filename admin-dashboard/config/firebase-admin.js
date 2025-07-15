const admin = require('firebase-admin');

// Configuration Firebase using environment variables
const firebaseConfig = {
  type: "service_account",
  project_id: process.env.FIREBASE_PROJECT_ID || "homecare-9f4d0",
  private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
  private_key: process.env.FIREBASE_PRIVATE_KEY ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n') : undefined,
  client_email: process.env.FIREBASE_CLIENT_EMAIL,
  client_id: process.env.FIREBASE_CLIENT_ID,
  auth_uri: "https://accounts.google.com/o/oauth2/auth",
  token_uri: "https://oauth2.googleapis.com/token",
  auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
  client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL
};

console.log('🔥 Connexion au projet Firebase: homecare-9f4d0');
console.log('📡 Utilisation de l\'API REST Firestore pour éviter les problèmes de credentials');

// Google Places API Key
const GOOGLE_PLACES_API_KEY = process.env.GOOGLE_PLACES_API_KEY || 'AIzaSyA1g-UDJcfQS_33U3Sysxe9g4zlAOnpS3g';

// Fonction pour enrichir les données avec l'API Google Places
const enrichWithGooglePlaces = async (clinic) => {
  try {
    if (!clinic.placeId || !GOOGLE_PLACES_API_KEY) {
      return clinic;
    }

    console.log(`🔍 Enrichissement Google Places pour: ${clinic.name || clinic.clinicName}`);
    
    // Appel à l'API Google Places Details
    const detailsUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${clinic.placeId}&fields=formatted_address,formatted_phone_number,website,rating,user_ratings_total,price_level,opening_hours,photos,reviews,types&key=${GOOGLE_PLACES_API_KEY}`;
    
    const response = await fetch(detailsUrl);
    const data = await response.json();
    
    if (data.status === 'OK' && data.result) {
      const result = data.result;
      
      // Enrichir avec les photos Google Places
      const googlePhotos = [];
      if (result.photos && result.photos.length > 0) {
        result.photos.forEach(photo => {
          const photoUrl = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${photo.photo_reference}&key=${GOOGLE_PLACES_API_KEY}`;
          googlePhotos.push({
            photo_reference: photo.photo_reference,
            url: photoUrl,
            width: photo.width,
            height: photo.height,
            html_attributions: photo.html_attributions || []
          });
        });
      }
      
      // Enrichir avec les avis Google
      const googleReviews = [];
      if (result.reviews && result.reviews.length > 0) {
        result.reviews.forEach(review => {
          googleReviews.push({
            author_name: review.author_name,
            rating: review.rating,
            text: review.text,
            time: review.time,
            author_url: review.author_url,
            profile_photo_url: review.profile_photo_url,
            relative_time_description: review.relative_time_description
          });
        });
      }
      
      // Enrichir les données de la clinique
      clinic.googleAddress = result.formatted_address || clinic.address;
      clinic.googlePhoneNumber = result.formatted_phone_number || clinic.phone;
      clinic.googleWebsite = result.website || null;
      clinic.googleRating = result.rating || null;
      clinic.googleUserRatingsTotal = result.user_ratings_total || null;
      clinic.googlePriceLevel = result.price_level || null;
      clinic.googleTypes = result.types || [];
      clinic.googlePhotos = googlePhotos;
      clinic.googleReviews = googleReviews.slice(0, 5); // Limite à 5 avis
      
      // Heures d'ouverture
      if (result.opening_hours) {
        clinic.googleOpeningHours = {
          open_now: result.opening_hours.open_now,
          periods: result.opening_hours.periods || [],
          weekday_text: result.opening_hours.weekday_text || []
        };
      }
      
      console.log(`✅ Clinique ${clinic.name || clinic.clinicName} enrichie avec ${googlePhotos.length} photos et ${googleReviews.length} avis`);
    }
    
    return clinic;
  } catch (error) {
    console.error(`❌ Erreur lors de l'enrichissement Google Places pour ${clinic.name || clinic.clinicName}:`, error);
    return clinic;
  }
};

// Fonction pour faire des requêtes HTTP à l'API REST Firestore
const makeFirestoreRequest = async (path, method = 'GET', data = null) => {
  try {
    const baseUrl = 'https://firestore.googleapis.com/v1/projects/homecare-9f4d0/databases/(default)/documents';
    const url = `${baseUrl}${path}`;
    
    const options = {
      method: method,
      headers: {
        'Content-Type': 'application/json',
      }
    };
    
    if (data && (method === 'POST' || method === 'PATCH')) {
      options.body = JSON.stringify(data);
    }
    
    const response = await fetch(url, options);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Erreur lors de la requête Firestore:', error);
    throw error;
  }
};

// Fonction pour convertir les données Firestore en format simple
const convertFirestoreData = (doc) => {
  const data = {};
  if (doc.fields) {
    for (const [key, value] of Object.entries(doc.fields)) {
      if (value.stringValue !== undefined) {
        data[key] = value.stringValue;
      } else if (value.booleanValue !== undefined) {
        data[key] = value.booleanValue;
      } else if (value.timestampValue !== undefined) {
        data[key] = value.timestampValue;
      } else if (value.arrayValue !== undefined) {
        data[key] = value.arrayValue.values ? value.arrayValue.values.map(v => v.stringValue || v) : [];
      } else if (value.mapValue !== undefined) {
        data[key] = convertFirestoreData(value.mapValue);
      } else if (value.integerValue !== undefined) {
        data[key] = parseInt(value.integerValue);
      } else if (value.doubleValue !== undefined) {
        data[key] = parseFloat(value.doubleValue);
      } else if (value.nullValue !== undefined) {
        data[key] = null;
      } else {
        data[key] = value;
      }
    }
  }
  return data;
};

// Fonction pour convertir les données simples en format Firestore
const convertToFirestoreFormat = (data) => {
  const fields = {};
  for (const [key, value] of Object.entries(data)) {
    if (value === null || value === undefined) {
      fields[key] = { nullValue: null };
    } else if (typeof value === 'string') {
      fields[key] = { stringValue: value };
    } else if (typeof value === 'boolean') {
      fields[key] = { booleanValue: value };
    } else if (typeof value === 'number') {
      if (Number.isInteger(value)) {
        fields[key] = { integerValue: value.toString() };
      } else {
        fields[key] = { doubleValue: value };
      }
    } else if (Array.isArray(value)) {
      fields[key] = {
        arrayValue: {
          values: value.map(v => {
            if (typeof v === 'string') return { stringValue: v };
            if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: v.toString() } : { doubleValue: v };
            if (typeof v === 'boolean') return { booleanValue: v };
            return { stringValue: v.toString() };
          })
        }
      };
    } else if (value instanceof Date) {
      fields[key] = { timestampValue: value.toISOString() };
    } else if (typeof value === 'object') {
      fields[key] = { mapValue: convertToFirestoreFormat(value) };
    } else {
      fields[key] = { stringValue: value.toString() };
    }
  }
  return { fields };
};

// Utilitaires d'administration
const adminUtils = {
  // Récupérer toutes les cliniques avec pagination
  getAllClinics: async (limit = 100, pageToken = null) => {
    try {
      console.log('🏥 ===== RÉCUPÉRATION DES CLINIQUES DEPUIS FIREBASE =====');
      
      let url = '/clinics';
      const params = new URLSearchParams();
      
      if (limit) params.append('pageSize', limit.toString());
      if (pageToken) params.append('pageToken', pageToken);
      
      if (params.toString()) {
        url += '?' + params.toString();
      }
      
      const response = await makeFirestoreRequest(url);
      
      const clinics = [];
      if (response.documents) {
        for (const doc of response.documents) {
          const id = doc.name.split('/').pop();
          const data = convertFirestoreData(doc);
          
          // Enrichir avec Google Places si disponible
          let enrichedData = data;
          if (data.isFromGooglePlaces && data.placeId) {
            enrichedData = await enrichWithGooglePlaces(data);
          }
          
          clinics.push({ id, ...enrichedData });
        }
      }
      
      // Si on a plus de cliniques, récupérer de manière récursive
      if (response.nextPageToken) {
        const nextResults = await adminUtils.getAllClinics(limit, response.nextPageToken);
        if (nextResults.success) {
          clinics.push(...nextResults.clinics);
        }
      }
      
      console.log(`📋 API: Processing ${clinics.length} clinics...`);
      console.log(`✅ API: Found ${clinics.length} clinics in Firebase`);
      console.log(`📤 API: Sending response with ${clinics.length} clinics`);
      
      return { success: true, clinics };
    } catch (error) {
      console.error('❌ Erreur lors de la récupération des cliniques:', error);
      return { success: false, error: error.message };
    }
  },

  // Obtenir une clinique par son ID avec enrichissement Google Places
  getClinic: async (clinicId) => {
    try {
      console.log(`🔍 Récupération de la clinique: ${clinicId}`);
      
      const response = await makeFirestoreRequest(`/clinics/${clinicId}`);
      
      if (!response.fields) {
        throw new Error(`Clinique ${clinicId} non trouvée`);
      }
      
      let data = convertFirestoreData(response);
      
      // Enrichir avec Google Places si disponible
      if (data.isFromGooglePlaces && data.placeId) {
        console.log(`🔍 Enrichissement Google Places pour clinique ${clinicId}`);
        data = await enrichWithGooglePlaces(data);
      }
      
      console.log(`✅ Clinique ${data.name || data.clinicName} récupérée avec succès`);
      return { success: true, clinic: { id: clinicId, ...data } };
    } catch (error) {
      console.error('❌ Erreur lors de la récupération de la clinique:', error);
      return { success: false, error: error.message };
    }
  },

  // Approuver une clinique
  approveClinic: async (clinicId) => {
    try {
      console.log(`🔄 Approbation de la clinique: ${clinicId}`);
      
      // D'abord récupérer la clinique existante
      const existingResponse = await makeFirestoreRequest(`/clinics/${clinicId}`);
      if (!existingResponse.fields) {
        throw new Error(`Clinique ${clinicId} non trouvée`);
      }
      
      const existingData = convertFirestoreData(existingResponse);
      
      // Mettre à jour seulement les champs d'approbation
      const updateData = {
        ...existingData,
        verified: true,
        isVerified: true,
        approved: true,
        status: 'verified',
        verifiedAt: new Date().toISOString(),
        approvedAt: new Date().toISOString(),
        existsInFirebase: true,
        profileSetupComplete: true
      };
      
      // Supprimer les champs de rejet s'ils existent
      delete updateData.rejectedAt;
      delete updateData.rejectionReason;
      delete updateData.unapprovedAt;
      
      const firestoreData = convertToFirestoreFormat(updateData);
      
      await makeFirestoreRequest(`/clinics/${clinicId}`, 'PATCH', firestoreData);
      
      console.log(`✅ Clinique ${existingData.name || existingData.clinicName} approuvée avec succès`);
      return { success: true, clinic: updateData };
    } catch (error) {
      console.error('❌ Erreur lors de l\'approbation:', error);
      return { success: false, error: error.message };
    }
  },

  // Retirer l'approbation d'une clinique
  unapproveClinic: async (clinicId) => {
    try {
      console.log(`🔄 Retrait d'approbation de la clinique: ${clinicId}`);
      
      // D'abord récupérer la clinique existante
      const existingResponse = await makeFirestoreRequest(`/clinics/${clinicId}`);
      if (!existingResponse.fields) {
        throw new Error(`Clinique ${clinicId} non trouvée`);
      }
      
      const existingData = convertFirestoreData(existingResponse);
      
      // Mettre à jour seulement les champs d'approbation
      const updateData = {
        ...existingData,
        verified: false,
        isVerified: false,
        approved: false,
        status: 'pending',
        verifiedAt: null,
        approvedAt: null,
        unapprovedAt: new Date().toISOString(),
        existsInFirebase: true,
        profileSetupComplete: true
      };
      
      // Supprimer les champs de rejet s'ils existent
      delete updateData.rejectedAt;
      delete updateData.rejectionReason;
      
      const firestoreData = convertToFirestoreFormat(updateData);
      
      await makeFirestoreRequest(`/clinics/${clinicId}`, 'PATCH', firestoreData);
      
      console.log(`✅ Approbation retirée pour ${existingData.name || existingData.clinicName}`);
      return { success: true, clinic: updateData };
    } catch (error) {
      console.error('❌ Erreur lors du retrait d\'approbation:', error);
      return { success: false, error: error.message };
    }
  },

  // Obtenir les statistiques du dashboard
  getDashboardStats: async () => {
    try {
      console.log('📊 Récupération des statistiques du dashboard depuis Firebase');
      
      const result = await adminUtils.getAllClinics();
      
      if (!result.success) {
        throw new Error('Impossible de récupérer les cliniques');
      }
      
      const clinics = result.clinics;
      const stats = {
        totalClinics: clinics.length,
        verifiedClinics: clinics.filter(c => c.verified || c.isVerified).length,
        pendingClinics: clinics.filter(c => c.status === 'pending').length,
        rejectedClinics: clinics.filter(c => c.status === 'rejected').length,
        approvedClinics: clinics.filter(c => c.approved).length,
        googlePlacesClinics: clinics.filter(c => c.isFromGooglePlaces).length,
        lastUpdated: new Date().toISOString()
      };
      
      console.log('📊 Statistiques calculées:', stats);
      return { success: true, stats };
    } catch (error) {
      console.error('❌ Erreur lors de la récupération des statistiques:', error);
      return { success: false, error: error.message };
    }
  },

  // Obtenir toutes les cliniques depuis Firebase
  getAllClinics: async () => {
    try {
      console.log('🔍 Fetching all clinics from Firebase...');
      
      // Utiliser l'API REST Firestore pour récupérer toutes les cliniques
      const url = `https://firestore.googleapis.com/v1/projects/homecare-9f4d0/databases/(default)/documents/clinics`;
      
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) {
        throw new Error(`Firebase API error: ${response.status} ${response.statusText}`);
      }
      
      const data = await response.json();
      console.log('📡 Firebase API response received');
      
      if (!data.documents) {
        console.log('📋 No clinics found in Firebase');
        return { success: true, clinics: [] };
      }
      
      // Traiter les cliniques
      const clinics = data.documents.map(doc => {
        const docId = doc.name.split('/').pop();
        const fields = doc.fields || {};
        
        return {
          id: docId,
          name: fields.name?.stringValue || fields.clinicName?.stringValue || '',
          clinicName: fields.clinicName?.stringValue || fields.name?.stringValue || '',
          email: fields.email?.stringValue || '',
          address: fields.address?.stringValue || '',
          phone: fields.phone?.stringValue || '',
          about: fields.about?.stringValue || '',
          status: fields.status?.stringValue || 'pending',
          verified: fields.verified?.booleanValue || false,
          isVerified: fields.isVerified?.booleanValue || false,
          approved: fields.approved?.booleanValue || false,
          createdAt: fields.createdAt?.timestampValue || new Date().toISOString(),
          updatedAt: fields.updatedAt?.timestampValue || new Date().toISOString(),
          verifiedAt: fields.verifiedAt?.timestampValue || null,
          approvedAt: fields.approvedAt?.timestampValue || null,
          isFromGooglePlaces: fields.isFromGooglePlaces?.booleanValue || false,
          placeId: fields.placeId?.stringValue || null,
          latitude: fields.latitude?.doubleValue || null,
          longitude: fields.longitude?.doubleValue || null,
          profileSetupComplete: fields.profileSetupComplete?.booleanValue || false,
          existsInFirebase: true
        };
      });
      
      console.log(`✅ Successfully processed ${clinics.length} clinics from Firebase`);
      return { success: true, clinics };
    } catch (error) {
      console.error('❌ Error fetching clinics:', error);
      return { success: false, error: error.message };
    }
  },

  // Obtenir une clinique individuelle avec tous ses détails
  getClinic: async (clinicId) => {
    try {
      console.log('🔍 Récupération de la clinique:', clinicId);
      
      // Utiliser l'API REST Firestore pour récupérer la clinique
      const url = `https://firestore.googleapis.com/v1/projects/homecare-9f4d0/databases/(default)/documents/clinics/${clinicId}`;
      
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) {
        if (response.status === 404) {
          console.log('❌ Clinique non trouvée:', clinicId);
          return { success: false, error: 'Clinique non trouvée' };
        }
        throw new Error(`Firebase API error: ${response.status} ${response.statusText}`);
      }
      
      const data = await response.json();
      console.log('📡 Firebase API response received for clinic');
      
      if (!data.fields) {
        console.log('❌ Aucune donnée trouvée pour la clinique:', clinicId);
        return { success: false, error: 'Aucune donnée trouvée' };
      }
      
      const fields = data.fields;
      
      // Traiter les documents
      let documents = {};
      if (fields.documents && fields.documents.mapValue && fields.documents.mapValue.fields) {
        const docFields = fields.documents.mapValue.fields;
        
        // Certificat
        if (docFields.certificate && docFields.certificate.mapValue) {
          const certFields = docFields.certificate.mapValue.fields;
          documents.certificate = {
            fileName: certFields.fileName?.stringValue || null,
            fileType: certFields.fileType?.stringValue || null,
            fileSize: certFields.fileSize?.integerValue ? parseInt(certFields.fileSize.integerValue) : null,
            fileData: certFields.fileData?.stringValue || null,
            fileUrl: certFields.fileUrl?.stringValue || null,
            uploadedAt: certFields.uploadedAt?.timestampValue || certFields.uploadedAt?.stringValue || null,
            storageMethod: certFields.storageMethod?.stringValue || 'firestore'
          };
        }
        
        // Document d'identité
        if (docFields.id && docFields.id.mapValue) {
          const idFields = docFields.id.mapValue.fields;
          documents.id = {
            fileName: idFields.fileName?.stringValue || null,
            fileType: idFields.fileType?.stringValue || null,
            fileSize: idFields.fileSize?.integerValue ? parseInt(idFields.fileSize.integerValue) : null,
            fileData: idFields.fileData?.stringValue || null,
            fileUrl: idFields.fileUrl?.stringValue || null,
            uploadedAt: idFields.uploadedAt?.timestampValue || idFields.uploadedAt?.stringValue || null,
            storageMethod: idFields.storageMethod?.stringValue || 'firestore'
          };
        }
        
        // Document supplémentaire
        if (docFields.additional && docFields.additional.mapValue) {
          const addFields = docFields.additional.mapValue.fields;
          documents.additional = {
            fileName: addFields.fileName?.stringValue || null,
            fileType: addFields.fileType?.stringValue || null,
            fileSize: addFields.fileSize?.integerValue ? parseInt(addFields.fileSize.integerValue) : null,
            fileData: addFields.fileData?.stringValue || null,
            fileUrl: addFields.fileUrl?.stringValue || null,
            uploadedAt: addFields.uploadedAt?.timestampValue || addFields.uploadedAt?.stringValue || null,
            storageMethod: addFields.storageMethod?.stringValue || 'firestore'
          };
        }
      }
      
      // Traiter les détails Google Places
      let googlePlaceDetails = null;
      if (fields.googlePlaceDetails && fields.googlePlaceDetails.mapValue) {
        const placeFields = fields.googlePlaceDetails.mapValue.fields;
        googlePlaceDetails = {
          name: placeFields.name?.stringValue || null,
          formatted_address: placeFields.formatted_address?.stringValue || null,
          formatted_phone_number: placeFields.formatted_phone_number?.stringValue || null,
          rating: placeFields.rating?.doubleValue || null,
          website: placeFields.website?.stringValue || null,
          photos: placeFields.photos?.arrayValue?.values?.map(photo => {
            if (photo.mapValue && photo.mapValue.fields) {
              return {
                photo_reference: photo.mapValue.fields.photo_reference?.stringValue || null,
                width: photo.mapValue.fields.width?.integerValue || null,
                height: photo.mapValue.fields.height?.integerValue || null
              };
            }
            return null;
          }).filter(photo => photo !== null) || []
        };
      }
      
      // Construire l'objet clinique
      const clinic = {
        id: clinicId,
        name: fields.name?.stringValue || fields.clinicName?.stringValue || '',
        clinicName: fields.clinicName?.stringValue || fields.name?.stringValue || '',
        email: fields.email?.stringValue || '',
        address: fields.address?.stringValue || fields.location?.stringValue || '',
        location: fields.location?.stringValue || fields.address?.stringValue || '',
        phone: fields.phone?.stringValue || fields.googlePhoneNumber?.stringValue || '',
        googlePhoneNumber: fields.googlePhoneNumber?.stringValue || fields.phone?.stringValue || '',
        about: fields.about?.stringValue || '',
        status: fields.status?.stringValue || 'pending',
        verified: fields.verified?.booleanValue || false,
        isVerified: fields.isVerified?.booleanValue || false,
        approved: fields.approved?.booleanValue || false,
        createdAt: fields.createdAt?.timestampValue || new Date().toISOString(),
        updatedAt: fields.updatedAt?.timestampValue || new Date().toISOString(),
        lastUpdated: fields.lastUpdated?.timestampValue || fields.updatedAt?.timestampValue || new Date().toISOString(),
        verifiedAt: fields.verifiedAt?.timestampValue || null,
        approvedAt: fields.approvedAt?.timestampValue || null,
        isFromGooglePlaces: fields.isFromGooglePlaces?.booleanValue || false,
        placeId: fields.placeId?.stringValue || null,
        latitude: fields.latitude?.doubleValue || null,
        longitude: fields.longitude?.doubleValue || null,
        profileSetupComplete: fields.profileSetupComplete?.booleanValue || false,
        profileImageUrl: fields.profileImageUrl?.stringValue || null,
        profileImage: fields.profileImage?.stringValue || null,
        certificateUrl: fields.certificateUrl?.stringValue || null,
        rating: fields.rating?.doubleValue || null,
        googleWebsite: fields.googleWebsite?.stringValue || null,
        appointmentDuration: fields.appointmentDuration?.integerValue || null,
        bufferTime: fields.bufferTime?.integerValue || null,
        facilities: fields.facilities?.arrayValue?.values?.map(f => f.stringValue) || [],
        services: fields.services?.arrayValue?.values?.map(s => s.stringValue) || [],
        documents: documents,
        googlePlaceDetails: googlePlaceDetails,
        existsInFirebase: true
      };
      
      // Enrichir avec Google Places si nécessaire
      if (clinic.isFromGooglePlaces && clinic.placeId) {
        console.log('🔍 Enrichissement Google Places pour clinique', clinicId);
        const enrichedClinic = await enrichWithGooglePlaces(clinic);
        console.log('✅ Clinique', enrichedClinic.name, 'enrichie avec', enrichedClinic.googlePhotos?.length || 0, 'photos et', enrichedClinic.googleReviews?.length || 0, 'avis');
        
        console.log('✅ Clinique', enrichedClinic.name, 'récupérée avec succès');
        return { success: true, clinic: enrichedClinic };
      }
      
      console.log('✅ Clinique', clinic.name, 'récupérée avec succès');
      return { success: true, clinic };
    } catch (error) {
      console.error('❌ Erreur lors de la récupération de la clinique:', error);
      return { success: false, error: error.message };
    }
  },

  // Obtenir toutes les suggestions depuis Firebase
  getAllSuggestions: async () => {
    try {
      console.log('🔍 Fetching all suggestions from Firebase...');
      
      // Utiliser l'API REST Firestore pour récupérer toutes les suggestions
      const url = `https://firestore.googleapis.com/v1/projects/homecare-9f4d0/databases/(default)/documents/suggestions`;
      
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) {
        throw new Error(`Firebase API error: ${response.status} ${response.statusText}`);
      }
      
      const data = await response.json();
      console.log('📡 Firebase API response received');
      
      if (!data.documents) {
        console.log('📋 No suggestions found in Firebase');
        return { success: true, suggestions: [] };
      }
      
      // Traiter les suggestions
      const suggestions = data.documents.map(doc => {
        const docId = doc.name.split('/').pop();
        const fields = doc.fields || {};
        
        return {
          id: docId,
          hospitalName: fields.hospitalName?.stringValue || '',
          hospitalAddress: fields.hospitalAddress?.stringValue || '',
          description: fields.description?.stringValue || '',
          suggestionType: fields.suggestionType?.stringValue || 'general',
          status: fields.status?.stringValue || 'pending',
          priority: fields.priority?.stringValue || 'medium',
          userEmail: fields.userEmail?.stringValue || '',
          userName: fields.userName?.stringValue || '',
          createdAt: fields.createdAt?.timestampValue || new Date().toISOString(),
          updatedAt: fields.updatedAt?.timestampValue || new Date().toISOString(),
          adminNotes: fields.adminNotes?.stringValue || '',
          reviewed: fields.reviewed?.booleanValue || false,
          reviewedBy: fields.reviewedBy?.stringValue || '',
          reviewedAt: fields.reviewedAt?.timestampValue || null,
          placeId: fields.placeId?.stringValue || null,
          latitude: fields.latitude?.doubleValue || null,
          longitude: fields.longitude?.doubleValue || null,
          category: fields.category?.stringValue || 'suggestion',
          tags: fields.tags?.arrayValue?.values?.map(tag => tag.stringValue) || [],
          attachments: fields.attachments?.arrayValue?.values?.map(att => att.stringValue) || []
        };
      });
      
      console.log(`✅ Successfully processed ${suggestions.length} suggestions from Firebase`);
      return { success: true, suggestions };
    } catch (error) {
      console.error('❌ Error fetching suggestions:', error);
      return { success: false, error: error.message };
    }
  }
};

// Initialisation
try {
  console.log('✅ Firebase Admin initialisé avec succès');
} catch (error) {
  console.error('❌ Erreur lors de l\'initialisation de Firebase Admin:', error);
}

module.exports = {
  admin: null,
  db: null,
  adminUtils,
  useRestAPI: true,
  useMockData: false
}; 