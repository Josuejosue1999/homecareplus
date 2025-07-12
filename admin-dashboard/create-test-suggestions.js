const { adminUtils } = require('./config/firebase-admin');

// Données de test pour les suggestions
const testSuggestions = [
  {
    hospitalName: 'Centre Hospitalier de Kigali',
    hospitalAddress: 'Boulevard du 1er Juillet, Kigali',
    description: 'Excellent hôpital avec des services complets et un personnel qualifié. Recommandé pour les soins spécialisés.',
    suggestionType: 'hospital_recommendation',
    status: 'pending',
    priority: 'high',
    userEmail: 'patient1@example.com',
    userName: 'Marie Uwimana',
    category: 'suggestion',
    tags: ['cardiologie', 'urgences', 'pédiatrie'],
    placeId: 'ChIJtest123456789',
    latitude: -1.9441,
    longitude: 30.0619,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    hospitalName: 'King Faisal Hospital',
    hospitalAddress: 'KG 544 St, Kigali',
    description: 'Hôpital moderne avec équipements de pointe. Très bon service en obstétrique.',
    suggestionType: 'hospital_recommendation',
    status: 'reviewed',
    priority: 'medium',
    userEmail: 'patient2@example.com',
    userName: 'Jean Baptiste Ntirenganya',
    category: 'suggestion',
    tags: ['obstétrique', 'chirurgie', 'radiologie'],
    adminNotes: 'Suggestion vérifiée et approuvée',
    reviewedBy: 'admin@homecare.com',
    reviewedAt: new Date().toISOString(),
    createdAt: new Date(Date.now() - 86400000).toISOString(), // 1 jour avant
    updatedAt: new Date().toISOString()
  },
  {
    hospitalName: 'Clinique Medica',
    hospitalAddress: 'Remera, Kigali',
    description: 'Clinique privée avec des spécialistes en dermatologie et ophtalmologie.',
    suggestionType: 'hospital_recommendation',
    status: 'implemented',
    priority: 'low',
    userEmail: 'patient3@example.com',
    userName: 'Claudine Mukamana',
    category: 'suggestion',
    tags: ['dermatologie', 'ophtalmologie'],
    adminNotes: 'Ajouté à la liste des cliniques recommandées',
    reviewedBy: 'admin@homecare.com',
    reviewedAt: new Date(Date.now() - 43200000).toISOString(), // 12 heures avant
    createdAt: new Date(Date.now() - 172800000).toISOString(), // 2 jours avant
    updatedAt: new Date().toISOString()
  },
  {
    hospitalName: 'Centre de Santé Nyamirambo',
    hospitalAddress: 'Nyamirambo, Kigali',
    description: 'Centre de santé communautaire avec des services de base très accessibles.',
    suggestionType: 'hospital_recommendation',
    status: 'pending',
    priority: 'medium',
    userEmail: 'patient4@example.com',
    userName: 'Eric Habimana',
    category: 'suggestion',
    tags: ['soins primaires', 'vaccination'],
    createdAt: new Date(Date.now() - 3600000).toISOString(), // 1 heure avant
    updatedAt: new Date(Date.now() - 3600000).toISOString()
  },
  {
    hospitalName: 'Polyclinique du Centre',
    hospitalAddress: 'Centre-ville, Kigali',
    description: 'Polyclinique avec plusieurs spécialités médicales et services de laboratoire.',
    suggestionType: 'hospital_recommendation',
    status: 'pending',
    priority: 'high',
    userEmail: 'patient5@example.com',
    userName: 'Ange Uwimana',
    category: 'suggestion',
    tags: ['laboratoire', 'analyses', 'consultations'],
    createdAt: new Date(Date.now() - 7200000).toISOString(), // 2 heures avant
    updatedAt: new Date(Date.now() - 7200000).toISOString()
  }
];

async function createTestSuggestions() {
  try {
    console.log('🔄 Création des suggestions de test...');
    
    for (const suggestion of testSuggestions) {
      console.log(`➕ Ajout de la suggestion: ${suggestion.hospitalName}`);
      
      // Utiliser l'API REST pour créer la suggestion
      const url = `https://firestore.googleapis.com/v1/projects/homecare-9f4d0/databases/(default)/documents/suggestions`;
      
      // Convertir les données au format Firestore
      const firestoreData = {
        fields: {}
      };
      
      Object.keys(suggestion).forEach(key => {
        const value = suggestion[key];
        if (typeof value === 'string') {
          firestoreData.fields[key] = { stringValue: value };
        } else if (typeof value === 'number') {
          firestoreData.fields[key] = { doubleValue: value };
        } else if (typeof value === 'boolean') {
          firestoreData.fields[key] = { booleanValue: value };
        } else if (Array.isArray(value)) {
          firestoreData.fields[key] = {
            arrayValue: {
              values: value.map(item => ({ stringValue: item }))
            }
          };
        }
      });
      
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(firestoreData)
      });
      
      if (!response.ok) {
        const error = await response.text();
        throw new Error(`Erreur API Firebase: ${response.status} - ${error}`);
      }
      
      const result = await response.json();
      console.log(`✅ Suggestion créée avec ID: ${result.name.split('/').pop()}`);
    }
    
    console.log('🎉 Toutes les suggestions de test ont été créées avec succès!');
    console.log('📊 Résumé:');
    console.log(`   - Total: ${testSuggestions.length} suggestions`);
    console.log(`   - Pending: ${testSuggestions.filter(s => s.status === 'pending').length}`);
    console.log(`   - Reviewed: ${testSuggestions.filter(s => s.status === 'reviewed').length}`);
    console.log(`   - Implemented: ${testSuggestions.filter(s => s.status === 'implemented').length}`);
    
  } catch (error) {
    console.error('❌ Erreur lors de la création des suggestions de test:', error);
  }
}

// Exécuter le script
createTestSuggestions(); 