// Settings Management
class SettingsManager {
  constructor() {
    this.apiBase = '/api/settings';
    this.setupEventListeners();
    this.initializeForms();
    this.loadExistingData();
    this.setupContactPreview();
    this.setupLocationDetection();
  }

  setupEventListeners() {
    // Remove existing listeners to prevent duplicates
    this.removeExistingListeners();
    
    // Profile form
    const profileForm = document.getElementById('profileForm');
    if (profileForm && !profileForm.hasAttribute('data-listener-added')) {
      this.profileUpdateHandler = (e) => this.handleProfileUpdate(e);
      profileForm.addEventListener('submit', this.profileUpdateHandler);
      profileForm.setAttribute('data-listener-added', 'true');
    }

    // Contact form
    const contactForm = document.getElementById('contactForm');
    if (contactForm && !contactForm.hasAttribute('data-listener-added')) {
      this.contactUpdateHandler = (e) => this.handleContactUpdate(e);
      contactForm.addEventListener('submit', this.contactUpdateHandler);
      contactForm.setAttribute('data-listener-added', 'true');
    }

    // Services form
    const servicesForm = document.getElementById('servicesForm');
    if (servicesForm && !servicesForm.hasAttribute('data-listener-added')) {
      this.servicesUpdateHandler = (e) => this.handleServicesUpdate(e);
      servicesForm.addEventListener('submit', this.servicesUpdateHandler);
      servicesForm.setAttribute('data-listener-added', 'true');
    }

    // Schedule form
    const scheduleForm = document.getElementById('scheduleForm');
    if (scheduleForm && !scheduleForm.hasAttribute('data-listener-added')) {
      this.scheduleUpdateHandler = (e) => this.handleScheduleUpdate(e);
      scheduleForm.addEventListener('submit', this.scheduleUpdateHandler);
      scheduleForm.setAttribute('data-listener-added', 'true');
    }

    // Security form
    const securityForm = document.getElementById('securityForm');
    if (securityForm && !securityForm.hasAttribute('data-listener-added')) {
      this.passwordChangeHandler = (e) => this.handlePasswordChange(e);
      securityForm.addEventListener('submit', this.passwordChangeHandler);
      securityForm.setAttribute('data-listener-added', 'true');
    }

    // Profile image upload
    const profileImageInput = document.getElementById('profileImage');
    if (profileImageInput && !profileImageInput.hasAttribute('data-listener-added')) {
      this.profileImageChangeHandler = (e) => this.handleProfileImageChange(e);
      profileImageInput.addEventListener('change', this.profileImageChangeHandler);
      profileImageInput.setAttribute('data-listener-added', 'true');
    }

    // Handle closed checkboxes for schedule
    this.setupScheduleCheckboxes();
  }

  removeExistingListeners() {
    // Remove existing event listeners to prevent duplicates
    const forms = ['profileForm', 'contactForm', 'servicesForm', 'scheduleForm', 'securityForm'];
    forms.forEach(formId => {
      const form = document.getElementById(formId);
      if (form && form.hasAttribute('data-listener-added')) {
        // Clone the node to remove all event listeners
        const newForm = form.cloneNode(true);
        form.parentNode.replaceChild(newForm, form);
      }
    });

    const profileImageInput = document.getElementById('profileImage');
    if (profileImageInput && profileImageInput.hasAttribute('data-listener-added')) {
      const newInput = profileImageInput.cloneNode(true);
      profileImageInput.parentNode.replaceChild(newInput, profileImageInput);
    }
  }

  initializeForms() {
    // Initialize tooltips
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Initialize form validation
    this.setupFormValidation();
  }

  // New method for contact preview functionality
  setupContactPreview() {
    const previewFields = ['phone', 'street', 'sector', 'country', 'website'];
    
    previewFields.forEach(fieldId => {
      const field = document.getElementById(fieldId);
      if (field) {
        field.addEventListener('input', () => this.updateContactPreview());
      }
    });
  }

  // New method for enhanced location detection
  setupLocationDetection() {
    const detectBtn = document.getElementById('detectLocationBtn');
    if (detectBtn && !detectBtn.hasAttribute('data-listener-added')) {
      this.detectLocationHandler = () => this.detectLocation();
      detectBtn.addEventListener('click', this.detectLocationHandler);
      detectBtn.setAttribute('data-listener-added', 'true');
    }

    // Auto-update address when components change
    const addressComponents = ['street', 'sector', 'country'];
    addressComponents.forEach(fieldId => {
      const field = document.getElementById(fieldId);
      if (field && !field.hasAttribute('data-address-listener-added')) {
        this.updateAddressHandler = () => this.updateAddressField();
        field.addEventListener('input', this.updateAddressHandler);
        field.setAttribute('data-address-listener-added', 'true');
      }
    });
  }

  // New method to update contact preview in real-time
  updateContactPreview() {
    const phoneField = document.getElementById('phone');
    const streetField = document.getElementById('street');
    const sectorField = document.getElementById('sector');
    const countryField = document.getElementById('country');
    const websiteField = document.getElementById('website');
    
    // Update preview elements
    const previewPhone = document.getElementById('preview-phone');
    const previewAddress = document.getElementById('preview-address');
    const previewWebsite = document.getElementById('preview-website');

    if (previewPhone && phoneField) {
      previewPhone.textContent = phoneField.value || 'Phone number will appear here';
    }

    if (previewAddress && streetField && sectorField && countryField) {
      const addressParts = [
        streetField.value,
        sectorField.value,
        countryField.value
      ].filter(part => part.trim() !== '');
      
      previewAddress.textContent = addressParts.length > 0 
        ? addressParts.join(', ') 
        : 'Address will appear here';
    }

    if (previewWebsite && websiteField) {
      previewWebsite.textContent = websiteField.value || 'Website will appear here';
    }
  }

  // New method to auto-update address field
  updateAddressField() {
    const streetField = document.getElementById('street');
    const sectorField = document.getElementById('sector');
    const countryField = document.getElementById('country');
    const addressField = document.getElementById('address');

    if (addressField && streetField && sectorField && countryField) {
      const addressParts = [
        streetField.value,
        sectorField.value,
        countryField.value
      ].filter(part => part.trim() !== '');
      
      addressField.value = addressParts.join(', ');
    }
  }

  // Enhanced location detection
  async detectLocation() {
    const detectBtn = document.getElementById('detectLocationBtn');
    const statusDiv = document.getElementById('locationStatus');
    const statusText = document.getElementById('locationStatusText');

    if (!navigator.geolocation) {
      this.showLocationStatus('Geolocation is not supported by this browser.', 'danger');
      return;
    }

    // Show loading state
    detectBtn.disabled = true;
    detectBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Detecting...';
    this.showLocationStatus('Detecting your location...', 'info');

    try {
      const position = await new Promise((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject, {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 300000
        });
      });

      const { latitude, longitude } = position.coords;
      
      // Update coordinate fields
      document.getElementById('latitude').value = latitude.toFixed(6);
      document.getElementById('longitude').value = longitude.toFixed(6);

      // Update button text to show coordinates
      detectBtn.innerHTML = `<i class="fas fa-map-marker-alt me-2"></i>Lat: ${latitude.toFixed(4)}, Lng: ${longitude.toFixed(4)}`;

      // Try to get address from coordinates
      const addressFound = await this.reverseGeocode(latitude, longitude);
      
      if (addressFound) {
        this.showLocationStatus('📍 Localisation et adresse détectées avec succès!', 'success');
      } else {
        this.showLocationStatus('📍 Coordonnées détectées. Veuillez saisir l\'adresse manuellement.', 'warning');
      }
      
    } catch (error) {
      console.error('Geolocation error:', error);
      let message = 'Unable to detect location. ';
      
      switch(error.code) {
        case error.PERMISSION_DENIED:
          message += 'Please allow location access.';
          break;
        case error.POSITION_UNAVAILABLE:
          message += 'Location information unavailable.';
          break;
        case error.TIMEOUT:
          message += 'Location request timed out.';
          break;
        default:
          message += 'Unknown error occurred.';
          break;
      }
      
      this.showLocationStatus(message, 'danger');
    } finally {
      // Reset button state but keep coordinates if detected
      detectBtn.disabled = false;
      if (!detectBtn.innerHTML.includes('Lat:')) {
        detectBtn.innerHTML = '<i class="fas fa-location-arrow me-2"></i>Auto-Detect Location';
      }
    }
  }

  // Enhanced method for reverse geocoding with precise street address detection
  async reverseGeocode(lat, lng) {
    console.log(`🌍 Détection d'adresse pour les coordonnées au Rwanda: ${lat}, ${lng}`);
    
    try {
      // Service principal: Nominatim avec paramètres optimisés pour le Rwanda
      const response = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1&countrycodes=rw&accept-language=en,fr`, {
        headers: {
          'User-Agent': 'HealthCenter-Dashboard-Rwanda/1.0'
        }
      });
      
      const data = await response.json();
      console.log('📍 Données Nominatim Rwanda reçues:', data);
      
      if (data && data.address) {
        const address = data.address;
        const streetField = document.getElementById('street');
        const sectorField = document.getElementById('sector');
        
        // Construction intelligente de l'adresse de rue pour le Rwanda
        let streetValue = '';
        let addressComponents = [];
        
        // Au Rwanda, les adresses suivent souvent le format: Secteur, Cellule, Village
        // Essayer d'abord les composants standards
        if (address.house_number) {
          addressComponents.push(address.house_number);
          console.log(`🏠 Numéro de maison trouvé: ${address.house_number}`);
        }
        
        // Nom de la rue (plusieurs variantes possibles au Rwanda)
        const roadName = address.road || address.street || address.pedestrian || 
                         address.footway || address.path || address.track || 
                         address.residential || address.hamlet || address.neighbourhood;
        if (roadName) {
          addressComponents.push(roadName);
          console.log(`🛣️ Nom de rue/quartier trouvé: ${roadName}`);
        }
        
        // Si pas de rue spécifique, utiliser des éléments géographiques rwandais
        if (addressComponents.length === 0) {
          // Utiliser la cellule, le village ou le secteur comme adresse
          const localArea = address.suburb || address.village || address.hamlet || 
                           address.neighbourhood || address.quarter || address.residential;
          if (localArea) {
            addressComponents.push(localArea);
            console.log(`🏘️ Zone locale rwandaise trouvée: ${localArea}`);
          }
        }
        
        // Fallback: utiliser des points d'intérêt ou bâtiments
        if (addressComponents.length === 0 && (address.building || address.amenity || address.shop || address.office)) {
          const landmark = address.building || address.amenity || address.shop || address.office;
          addressComponents.push(`Près de ${landmark}`);
          console.log(`🏢 Point de repère trouvé: ${landmark}`);
        }
        
        // Assembler l'adresse
        if (addressComponents.length > 0) {
          streetValue = addressComponents.join(' ');
        }
        
        // Remplir le champ street address
        if (streetField) {
          if (streetValue.trim()) {
            streetField.value = streetValue.trim();
            streetField.classList.add('is-valid');
            console.log(`✅ Adresse rwandaise définie: ${streetValue.trim()}`);
            
            // Notification spécifique pour le Rwanda
            this.showNotification(`📍 Adresse détectée au Rwanda: ${streetValue.trim()}`, 'success');
          } else {
            console.log('⚠️ Aucune adresse spécifique trouvée au Rwanda');
            // Utiliser les coordonnées comme référence
            streetField.value = `Coordonnées: ${lat.toFixed(6)}, ${lng.toFixed(6)}`;
            streetField.classList.add('is-warning');
            this.showNotification('📍 Localisation détectée. Au Rwanda, utilisez les coordonnées GPS ou décrivez l\'emplacement (ex: "Près de l\'école primaire de Kimisagara").', 'warning');
          }
        }
        
        // Remplir le champ sector avec les divisions administratives rwandaises
        if (sectorField) {
          // Au Rwanda: Province > District > Secteur > Cellule > Village
          const sectorValue = address.state_district || address.county || // District
                             address.suburb || address.neighbourhood || // Secteur/Cellule
                             address.city || address.town || address.village || // Ville/Village
                             address.state || // Province
                             'Kigali'; // Fallback par défaut
          
          if (sectorValue) {
            sectorField.value = sectorValue;
            sectorField.classList.add('is-valid');
            console.log(`🏘️ Division administrative rwandaise définie: ${sectorValue}`);
          }
        }
        
        this.updateAddressField();
        this.updateContactPreview();
        return true; // Succès
      }
    } catch (error) {
      console.warn('❌ Service Nominatim échoué:', error);
    }
    
    // Service de fallback: BigDataCloud
    try {
      console.log('🔄 Tentative avec le service de fallback pour le Rwanda...');
      const fallbackResponse = await fetch(`https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lng}&localityLanguage=en`);
      const fallbackData = await fallbackResponse.json();
      console.log('📍 Données BigDataCloud Rwanda reçues:', fallbackData);
      
      if (fallbackData) {
        const streetField = document.getElementById('street');
        const sectorField = document.getElementById('sector');
        
        // Construire une adresse pour le Rwanda
        let streetValue = '';
        
        if (fallbackData.streetNumber && fallbackData.streetName) {
          streetValue = `${fallbackData.streetNumber} ${fallbackData.streetName}`;
          console.log(`🏠 Adresse complète BigDataCloud Rwanda: ${streetValue}`);
        } else if (fallbackData.locality || fallbackData.localityInfo) {
          streetValue = fallbackData.locality || fallbackData.localityInfo.administrative[0]?.name || 'Zone détectée';
          console.log(`📍 Localité Rwanda BigDataCloud: ${streetValue}`);
        } else {
          // Fallback pour le Rwanda - utiliser les coordonnées
          streetValue = `Coordonnées Rwanda: ${lat.toFixed(6)}, ${lng.toFixed(6)}`;
          console.log(`📍 Utilisation des coordonnées GPS pour le Rwanda: ${streetValue}`);
        }
        
        if (streetField && streetValue) {
          streetField.value = streetValue;
          streetField.classList.add('is-valid');
          this.showNotification(`📍 Localisation Rwanda détectée: ${streetValue}`, 'success');
        }
        
        if (sectorField) {
          const sectorValue = fallbackData.principalSubdivision || 
                             fallbackData.countryName || 
                             'Rwanda';
          sectorField.value = sectorValue;
          sectorField.classList.add('is-valid');
        }
        
        this.updateAddressField();
        this.updateContactPreview();
        return true; // Succès partiel
      }
    } catch (fallbackError) {
      console.warn('❌ Service BigDataCloud échoué aussi:', fallbackError);
    }
    
    // Service spécifique pour le Rwanda - utiliser les coordonnées
    try {
      console.log('🔄 Utilisation des coordonnées GPS pour le Rwanda...');
      const streetField = document.getElementById('street');
      const sectorField = document.getElementById('sector');
      
      if (streetField) {
        // Au Rwanda, les coordonnées GPS sont souvent utilisées comme référence
        streetField.value = `GPS: ${lat.toFixed(6)}, ${lng.toFixed(6)}`;
        streetField.classList.add('is-valid');
        
        // Déterminer approximativement la zone basée sur les coordonnées
        let zone = 'Rwanda';
        if (lat >= -1.9 && lat <= -1.8 && lng >= 30.0 && lng <= 30.2) {
          zone = 'Kigali Centre';
        } else if (lat >= -2.0 && lat <= -1.7 && lng >= 29.9 && lng <= 30.3) {
          zone = 'Région de Kigali';
        }
        
        if (sectorField) {
          sectorField.value = zone;
          sectorField.classList.add('is-valid');
        }
        
        this.showNotification(`📍 Coordonnées GPS Rwanda enregistrées. Vous pouvez ajouter une description de l'emplacement (ex: "Près du marché de Kimisagara").`, 'info');
        this.updateAddressField();
        this.updateContactPreview();
        return true;
      }
    } catch (coordError) {
      console.warn('❌ Erreur lors de l\'utilisation des coordonnées:', coordError);
    }
    
    // Si tout échoue
    console.log('⚠️ Tous les services de géocodage ont échoué pour le Rwanda');
    this.showNotification('📍 Coordonnées GPS détectées au Rwanda. Veuillez ajouter manuellement une description de l\'emplacement (ex: "Secteur Kimisagara, près de l\'école").', 'warning');
    return false;
  }

  // New method to show location status
  showLocationStatus(message, type) {
    const statusDiv = document.getElementById('locationStatus');
    const statusText = document.getElementById('locationStatusText');
    
    if (statusDiv && statusText) {
      statusDiv.className = `alert alert-${type} d-block`;
      statusText.textContent = message;
      
      // Auto-hide success messages
      if (type === 'success') {
        setTimeout(() => {
          statusDiv.classList.add('d-none');
        }, 3000);
      }
    }
  }

  // New method to reset contact form
  resetContactForm() {
    const contactForm = document.getElementById('contactForm');
    if (!contactForm) return;

    Swal.fire({
      title: 'Reset Contact Form?',
      text: 'This will clear all contact information fields. Are you sure?',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#159BBD',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Yes, reset it!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        // Reset form fields
        const fields = ['phone', 'website', 'street', 'sector', 'country', 'address', 'latitude', 'longitude'];
        fields.forEach(fieldId => {
          const field = document.getElementById(fieldId);
          if (field) {
            field.value = '';
            field.classList.remove('is-invalid', 'is-valid');
          }
        });

        // Reset preview
        this.updateContactPreview();
        
        // Hide location status
        const statusDiv = document.getElementById('locationStatus');
        if (statusDiv) {
          statusDiv.classList.add('d-none');
        }

        Swal.fire({
          title: 'Reset Complete!',
          text: 'Contact form has been cleared.',
          icon: 'success',
          timer: 2000,
          showConfirmButton: false
        });
      }
    });
  }

  async loadExistingData() {
    try {
      console.log('Loading existing clinic data...');
      
      const response = await fetch(`${this.apiBase}/clinic-data`);
      const result = await response.json();
      
      if (result.success && result.clinicData) {
        console.log('Clinic data loaded:', result.clinicData);
        this.populateFormFields(result.clinicData);
        // Update preview after loading data
        this.updateContactPreview();
      } else {
        console.log('No existing clinic data found');
      }
    } catch (error) {
      console.error('Error loading clinic data:', error);
    }
  }

  populateFormFields(data) {
    // Contact fields (only fields that exist in the form)
    const contactFields = [
      'phone', 'website', 'street', 'sector', 
      'address', 'latitude', 'longitude'
    ];
    
    contactFields.forEach(field => {
      const element = document.getElementById(field);
      if (element && data[field] !== undefined) {
        element.value = data[field] || '';
      }
    });

    // Profile fields
    const profileFields = ['clinicName', 'email', 'description'];
    profileFields.forEach(field => {
      const element = document.getElementById(field);
      if (element && data[field] !== undefined) {
        element.value = data[field] || '';
      }
    });

    // Services/Facilities
    if (data.facilities && Array.isArray(data.facilities)) {
      data.facilities.forEach(facility => {
        const checkbox = document.querySelector(`input[name="facilities"][value="${facility}"]`);
        if (checkbox) {
          checkbox.checked = true;
        }
      });
    }

    // Schedule
    if (data.availableSchedule) {
      Object.keys(data.availableSchedule).forEach(day => {
        const dayLower = day.toLowerCase();
        const schedule = data.availableSchedule[day];
        
        if (schedule.start === 'Closed' || schedule.end === 'Closed') {
          const closedCheckbox = document.getElementById(`${dayLower}_closed`);
          if (closedCheckbox) {
            closedCheckbox.checked = true;
          }
        } else {
          const startInput = document.getElementById(`${dayLower}_start`);
          const endInput = document.getElementById(`${dayLower}_end`);
          
          if (startInput) startInput.value = schedule.start || '08:00';
          if (endInput) endInput.value = schedule.end || '17:00';
        }
      });
    }

    console.log('Form fields populated with existing data');
  }

  setupScheduleCheckboxes() {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    days.forEach(day => {
      const closedCheckbox = document.getElementById(`${day}_closed`);
      const startInput = document.querySelector(`input[name="${day}_start"]`);
      const endInput = document.querySelector(`input[name="${day}_end"]`);
      
      if (closedCheckbox && startInput && endInput) {
        closedCheckbox.addEventListener('change', (e) => {
          if (e.target.checked) {
            startInput.value = 'Closed';
            endInput.value = 'Closed';
            startInput.disabled = true;
            endInput.disabled = true;
          } else {
            startInput.value = '08:00';
            endInput.value = '17:00';
            startInput.disabled = false;
            endInput.disabled = false;
          }
        });
      }
    });
  }

  setupFormValidation() {
    // Add custom validation for required fields
    const requiredFields = document.querySelectorAll('[required]');
    requiredFields.forEach(field => {
      field.addEventListener('blur', () => {
        this.validateField(field);
      });
      
      // Add real-time validation for contact fields
      field.addEventListener('input', () => {
        if (field.classList.contains('is-invalid')) {
          this.validateField(field);
        }
      });
    });

    // Phone number validation
    const phoneField = document.getElementById('phone');
    if (phoneField) {
      phoneField.addEventListener('input', () => this.validatePhone(phoneField));
    }

    // Website URL validation
    const websiteField = document.getElementById('website');
    if (websiteField) {
      websiteField.addEventListener('blur', () => this.validateWebsite(websiteField));
    }
  }

  validatePhone(field) {
    const value = field.value.trim();
    const phoneRegex = /^[\+]?[0-9\s\-\(\)]{10,}$/;
    
    if (value && !phoneRegex.test(value)) {
      field.classList.add('is-invalid');
      this.showFieldError(field, 'Please enter a valid phone number');
      return false;
    } else {
      field.classList.remove('is-invalid');
      if (value) field.classList.add('is-valid');
      this.removeFieldError(field);
      return true;
    }
  }

  validateWebsite(field) {
    const value = field.value.trim();
    const urlRegex = /^https?:\/\/.+\..+/;
    
    if (value && !urlRegex.test(value)) {
      field.classList.add('is-invalid');
      this.showFieldError(field, 'Please enter a valid website URL (starting with http:// or https://)');
      return false;
    } else {
      field.classList.remove('is-invalid');
      if (value) field.classList.add('is-valid');
      this.removeFieldError(field);
      return true;
    }
  }

  validateField(field) {
    const value = field.value.trim();
    const isValid = value.length > 0;
    
    if (!isValid) {
      field.classList.add('is-invalid');
      this.showFieldError(field, 'Ce champ est obligatoire');
    } else {
      field.classList.remove('is-invalid');
      field.classList.add('is-valid');
      this.removeFieldError(field);
    }
    
    return isValid;
  }

  showFieldError(field, message) {
    let errorDiv = field.closest('.col-md-6, .col-md-8, .col-md-4')?.querySelector('.invalid-feedback');
    if (!errorDiv) {
      errorDiv = document.createElement('div');
      errorDiv.className = 'invalid-feedback';
      field.closest('.input-group')?.parentNode.appendChild(errorDiv) || field.parentNode.appendChild(errorDiv);
    }
    errorDiv.textContent = message;
  }

  removeFieldError(field) {
    const errorDiv = field.closest('.col-md-6, .col-md-8, .col-md-4')?.querySelector('.invalid-feedback');
    if (errorDiv) {
      errorDiv.remove();
    }
  }

  async handleProfileUpdate(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const data = {
      clinicName: formData.get('clinicName'),
      about: formData.get('about')
    };

    try {
      this.showLoading(e.target);
      
      const response = await fetch(`${this.apiBase}/profile`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      const result = await response.json();
      
      if (result.success) {
        this.showSuccess('Profile updated successfully!');
        // Update the header clinic name if it exists
        const headerClinicName = document.querySelector('.clinic-name');
        if (headerClinicName) {
          headerClinicName.textContent = data.clinicName;
        }
      } else {
        this.showError(result.message || 'Failed to update profile');
      }
    } catch (error) {
      console.error('Profile update error:', error);
      this.showError('An error occurred while updating profile');
    } finally {
      this.hideLoading(e.target);
    }
  }

  async handleContactUpdate(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const data = {
      phone: formData.get('phone'),
      website: formData.get('website'),
      street: formData.get('street'),
      sector: formData.get('sector'),
      country: formData.get('country'),
      address: formData.get('address'),
      latitude: formData.get('latitude') || null,
      longitude: formData.get('longitude') || null
    };

    console.log('📝 Form data being sent:', data);
    console.log('📝 Required fields check:');
    
    // Client-side validation for required fields - enhanced logging
    const requiredFields = [
      { field: 'phone', label: 'Téléphone' },
      { field: 'street', label: 'Rue' },
      { field: 'sector', label: 'Secteur' },
      { field: 'country', label: 'Pays' }
    ];

    const missingFields = [];
    for (const { field, label } of requiredFields) {
      const value = data[field];
      const trimmedValue = value ? value.trim() : '';
      const isEmpty = !trimmedValue;
      
      console.log(`   ${field}: "${value}" -> trimmed: "${trimmedValue}" -> isEmpty: ${isEmpty}`);
      
      if (isEmpty) {
        missingFields.push(label);
        // Add visual indication to the field
        const fieldElement = document.getElementById(field);
        if (fieldElement) {
          fieldElement.classList.add('is-invalid');
          console.log(`   ❌ Added is-invalid class to ${field}`);
        }
      } else {
        // Remove visual indication if field is filled
        const fieldElement = document.getElementById(field);
        if (fieldElement) {
          fieldElement.classList.remove('is-invalid');
          fieldElement.classList.add('is-valid');
          console.log(`   ✅ Field ${field} is valid`);
        }
      }
    }

    if (missingFields.length > 0) {
      await Swal.fire({
        icon: 'error',
        title: 'Champs Requis Manquants',
        text: `Veuillez remplir les champs suivants : ${missingFields.join(', ')}`,
        confirmButtonColor: '#159BBD'
      });
      return;
    }

    // Validate phone number format (basic validation)
    const phoneRegex = /^[\+]?[0-9\s\-\(\)]{7,15}$/;
    if (!phoneRegex.test(data.phone.trim())) {
      await Swal.fire({
        icon: 'error',
        title: 'Numéro de Téléphone Invalide',
        text: 'Veuillez entrer un numéro de téléphone valide (7-15 chiffres)',
        confirmButtonColor: '#159BBD'
      });
      document.getElementById('phone').classList.add('is-invalid');
      return;
    }

    // Validate website URL if provided
    if (data.website && data.website.trim()) {
      try {
        new URL(data.website);
      } catch {
        await Swal.fire({
          icon: 'error',
          title: 'URL du Site Web Invalide',
          text: 'Veuillez entrer une URL valide (ex: https://example.com)',
          confirmButtonColor: '#159BBD'
        });
        document.getElementById('website').classList.add('is-invalid');
        return;
      }
    }

    try {
      this.showLoading(e.target);
      
      const response = await fetch(`${this.apiBase}/contact`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      const result = await response.json();
      
      if (result.success) {
        await Swal.fire({
          icon: 'success',
          title: 'Informations Sauvegardées!',
          text: 'Vos informations de contact ont été mises à jour avec succès.',
          timer: 2000,
          showConfirmButton: false,
          confirmButtonColor: '#159BBD'
        });
        
        // Update the displayed fields with the new data
        if (result.data) {
          this.updateDisplayedFields(result.data);
          // Update preview as well
          this.updateContactPreview();
        }
        
        // Remove any validation error classes and add success classes
        const form = e.target;
        const inputs = form.querySelectorAll('.is-invalid');
        inputs.forEach(input => {
          input.classList.remove('is-invalid');
          input.classList.add('is-valid');
        });
        
        console.log('✅ Contact information updated successfully!');
        
      } else {
        await Swal.fire({
          icon: 'error',
          title: 'Échec de la Sauvegarde',
          text: result.message || 'Impossible de mettre à jour les informations de contact. Veuillez réessayer.',
          confirmButtonColor: '#159BBD'
        });
      }
    } catch (error) {
      console.error('Contact update error:', error);
      await Swal.fire({
        icon: 'error',
        title: 'Erreur de Connexion',
        text: 'Une erreur est survenue lors de la mise à jour. Veuillez vérifier votre connexion internet et réessayer.',
        confirmButtonColor: '#159BBD'
      });
    } finally {
      this.hideLoading(e.target);
    }
  }

  // Nouvelle méthode pour mettre à jour les champs affichés
  updateDisplayedFields(data) {
    const fields = ['phone', 'website', 'street', 'city', 'sector', 'country', 'address', 'latitude', 'longitude'];
    
    fields.forEach(field => {
      const element = document.getElementById(field);
      if (element && data[field] !== undefined) {
        element.value = data[field] || '';
      }
    });
  }

  async handleServicesUpdate(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const selectedFacilities = formData.getAll('facilities');
    const customFacilities = formData.get('customFacilities');
    
    // Add custom facilities if provided
    let facilities = [...selectedFacilities];
    if (customFacilities && customFacilities.trim()) {
      const customList = customFacilities.split(',').map(f => f.trim()).filter(f => f);
      facilities = [...facilities, ...customList];
    }

    const data = { facilities };

    try {
      this.showLoading(e.target);
      
      const response = await fetch(`${this.apiBase}/services`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      const result = await response.json();
      
      if (result.success) {
        this.showSuccess('Services updated successfully!');
      } else {
        this.showError(result.message || 'Failed to update services');
      }
    } catch (error) {
      console.error('Services update error:', error);
      this.showError('An error occurred while updating services');
    } finally {
      this.hideLoading(e.target);
    }
  }

  async handleScheduleUpdate(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    const schedule = {};

    days.forEach(day => {
      const isClosed = formData.get(`${day}_closed`) === 'on';
      if (isClosed) {
        schedule[day.charAt(0).toUpperCase() + day.slice(1)] = {
          start: 'Closed',
          end: 'Closed'
        };
      } else {
        schedule[day.charAt(0).toUpperCase() + day.slice(1)] = {
          start: formData.get(`${day}_start`) || '08:00',
          end: formData.get(`${day}_end`) || '17:00'
        };
      }
    });

    const data = { availableSchedule: schedule };

    try {
      this.showLoading(e.target);
      
      const response = await fetch(`${this.apiBase}/schedule`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      const result = await response.json();
      
      if (result.success) {
        this.showSuccess('Working hours updated successfully!');
      } else {
        this.showError(result.message || 'Failed to update working hours');
      }
    } catch (error) {
      console.error('Schedule update error:', error);
      this.showError('An error occurred while updating working hours');
    } finally {
      this.hideLoading(e.target);
    }
  }

  async handlePasswordChange(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const currentPassword = formData.get('currentPassword');
    const newPassword = formData.get('newPassword');
    const confirmPassword = formData.get('confirmPassword');

    // Validate passwords
    if (!currentPassword || !newPassword || !confirmPassword) {
      this.showError('All password fields are required');
      return;
    }

    if (newPassword !== confirmPassword) {
      this.showError('New passwords do not match');
      return;
    }

    if (newPassword.length < 6) {
      this.showError('New password must be at least 6 characters long');
      return;
    }

    const data = {
      currentPassword,
      newPassword
    };

    try {
      this.showLoading(e.target);
      
      const response = await fetch(`${this.apiBase}/password`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      const result = await response.json();
      
      if (result.success) {
        this.showSuccess('Password changed successfully!');
        e.target.reset();
      } else {
        this.showError(result.message || 'Failed to change password');
      }
    } catch (error) {
      console.error('Password change error:', error);
      this.showError('An error occurred while changing password');
    } finally {
      this.hideLoading(e.target);
    }
  }

  showLoading(form) {
    const submitBtn = form.querySelector('button[type="submit"]');
    if (submitBtn) {
      submitBtn.disabled = true;
      submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Saving...';
    }
  }

  hideLoading(form) {
    const submitBtn = form.querySelector('button[type="submit"]');
    if (submitBtn) {
      submitBtn.disabled = false;
      const originalText = submitBtn.getAttribute('data-original-text') || 'Save';
      submitBtn.innerHTML = originalText;
    }
  }

  async showSuccess(message) {
    await Swal.fire({
      icon: 'success',
      title: 'Success!',
      text: message,
      timer: 2000,
      showConfirmButton: false,
      confirmButtonColor: '#159BBD'
    });
  }

  async showError(message) {
    await Swal.fire({
      icon: 'error',
      title: 'Error',
      text: message,
      confirmButtonColor: '#159BBD'
    });
  }

  showNotification(message, type) {
    // Create and show a notification
    const alertClass = type === 'success' ? 'alert-success' : 'alert-danger';
    const iconClass = type === 'success' ? 'fa-check-circle' : 'fa-exclamation-triangle';
    
    const notification = document.createElement('div');
    notification.className = `alert ${alertClass} alert-dismissible fade show position-fixed`;
    notification.style.cssText = 'top: 20px; right: 20px; z-index: 1050; min-width: 300px;';
    notification.innerHTML = `
      <i class="fas ${iconClass} me-2"></i>
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;

    document.body.appendChild(notification);

    // Auto-remove after 5 seconds
    setTimeout(() => {
      if (notification.parentNode) {
        notification.remove();
      }
    }, 5000);
  }

  // Profile image upload functionality
  async handleProfileImageChange(event) {
    const file = event.target.files[0];
    if (!file) return;

    console.log('📷 Selected file:', file.name, 'Size:', file.size, 'Type:', file.type);

    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (!allowedTypes.includes(file.type)) {
      await Swal.fire({
        icon: 'error',
        title: 'Type de fichier invalide',
        text: 'Veuillez sélectionner un fichier JPG, PNG ou WebP.',
        confirmButtonColor: '#159BBD'
      });
      return;
    }

    // Validate file size (3MB max for better performance)
    const maxSize = 3 * 1024 * 1024; // 3MB
    if (file.size > maxSize) {
      await Swal.fire({
        icon: 'error',
        title: 'Fichier trop volumineux',
        text: 'La taille du fichier doit être inférieure à 3MB. Veuillez compresser votre image.',
        confirmButtonColor: '#159BBD'
      });
      return;
    }

    // Convert and compress image
    await this.processAndUploadImage(file);
  }

  async processAndUploadImage(file) {
    try {
      console.log('🔄 Processing image...');
      
      // Create canvas for image compression
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      const img = new Image();
      
      return new Promise((resolve, reject) => {
        img.onload = async () => {
          try {
            // Calculate new dimensions (max 800x800 for profile images)
            const maxSize = 800;
            let { width, height } = img;
            
            if (width > height) {
              if (width > maxSize) {
                height = (height * maxSize) / width;
                width = maxSize;
              }
            } else {
              if (height > maxSize) {
                width = (width * maxSize) / height;
                height = maxSize;
              }
            }
            
            // Set canvas size
            canvas.width = width;
            canvas.height = height;
            
            // Draw and compress image
            ctx.drawImage(img, 0, 0, width, height);
            
            // Convert to base64 with compression
            const quality = file.size > 1024 * 1024 ? 0.7 : 0.85; // Lower quality for larger files
            const compressedImageData = canvas.toDataURL('image/jpeg', quality);
            
            console.log('📦 Original size:', file.size, 'Compressed size:', compressedImageData.length);
            
            // Upload the compressed image
            await this.uploadProfileImage(compressedImageData);
            resolve();
          } catch (error) {
            console.error('❌ Error processing image:', error);
            reject(error);
          }
        };
        
        img.onerror = () => {
          console.error('❌ Error loading image');
          reject(new Error('Failed to load image'));
        };
        
        // Convert file to data URL
        const reader = new FileReader();
        reader.onload = (e) => {
          img.src = e.target.result;
        };
        reader.onerror = () => {
          console.error('❌ Error reading file');
          reject(new Error('Failed to read file'));
        };
        reader.readAsDataURL(file);
      });
      
    } catch (error) {
      console.error('❌ Error in processAndUploadImage:', error);
      await Swal.fire({
        icon: 'error',
        title: 'Erreur de traitement',
        text: 'Impossible de traiter l\'image. Veuillez essayer avec une autre image.',
        confirmButtonColor: '#159BBD'
      });
    }
  }

  async uploadProfileImage(imageData) {
    try {
      console.log('🖼️ Uploading profile image...');
      console.log('Image data length:', imageData.length);

      // Show loading with progress
      let progressInterval;
      Swal.fire({
        title: 'Téléchargement en cours...',
        html: `
          <div class="upload-progress">
            <p>Veuillez patienter pendant que nous téléchargeons votre image de profil.</p>
            <div class="progress mt-3">
              <div class="progress-bar progress-bar-striped progress-bar-animated" 
                   role="progressbar" style="width: 0%" id="uploadProgress"></div>
            </div>
          </div>
        `,
        allowOutsideClick: false,
        allowEscapeKey: false,
        showConfirmButton: false,
        didOpen: () => {
          // Simulate progress
          let progress = 0;
          progressInterval = setInterval(() => {
            progress += Math.random() * 15;
            if (progress > 90) progress = 90;
            document.getElementById('uploadProgress').style.width = progress + '%';
          }, 200);
        }
      });

      // Prepare request with timeout
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 30000); // 30 second timeout

      const response = await fetch('/api/settings/profile-image', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ profileImageUrl: imageData }),
        signal: controller.signal
      });

      clearTimeout(timeoutId);
      clearInterval(progressInterval);

      console.log('Response status:', response.status);
      console.log('Response ok:', response.ok);

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Server error response:', errorText);
        
        let errorMessage = 'Erreur du serveur';
        if (response.status === 413) {
          errorMessage = 'Image trop volumineuse. Veuillez réduire la taille de votre image.';
        } else if (response.status === 400) {
          errorMessage = 'Format d\'image invalide. Veuillez utiliser JPG ou PNG.';
        } else if (response.status >= 500) {
          errorMessage = 'Erreur du serveur. Veuillez réessayer dans quelques instants.';
        }
        
        throw new Error(errorMessage);
      }

      const result = await response.json();
      console.log('Response result:', result);

      if (result.success) {
        console.log('✅ Profile image uploaded successfully');
        
        // Update any profile images on the page
        const profileImages = document.querySelectorAll('img[src*="hospital"], img[alt*="profile"], .profile-image');
        profileImages.forEach(img => {
          img.src = imageData;
        });
        
        // Update the current profile image preview
        const currentProfileImage = document.getElementById('currentProfileImage');
        if (currentProfileImage) {
          currentProfileImage.src = imageData;
        }
        
        // Update header avatar if it exists
        const headerImage = document.getElementById('headerUserAvatar');
        if (headerImage) {
          headerImage.src = imageData;
        }
        
        // Show success message
        await Swal.fire({
          icon: 'success',
          title: 'Image téléchargée !',
          text: 'Votre image de profil a été mise à jour avec succès.',
          confirmButtonColor: '#159BBD',
          timer: 3000,
          timerProgressBar: true
        });
      } else {
        console.error('Failed to upload profile image:', result.message);
        await Swal.fire({
          icon: 'error',
          title: 'Erreur',
          text: result.message || 'Échec du téléchargement de l\'image de profil. Veuillez réessayer.',
          confirmButtonColor: '#159BBD'
        });
      }
    } catch (error) {
      clearInterval(progressInterval);
      console.error('❌ Error uploading profile image:', error);
      
      let errorMessage = 'Impossible de sauvegarder l\'image. Vérifiez votre connexion et réessayez.';
      
      if (error.name === 'AbortError') {
        errorMessage = 'Le téléchargement a pris trop de temps. Veuillez réessayer avec une image plus petite.';
      } else if (error.message.includes('Failed to fetch')) {
        errorMessage = 'Problème de connexion. Vérifiez votre connexion internet et réessayez.';
      } else if (error.message) {
        errorMessage = error.message;
      }
      
      await Swal.fire({
        icon: 'error',
        title: 'Erreur de connexion',
        text: errorMessage,
        confirmButtonColor: '#159BBD'
      });
    }
  }
}

// Initialize settings manager when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  window.settingsManager = new SettingsManager();
  
  // Make resetContactForm available globally for HTML onclick
  window.resetContactForm = () => {
    window.settingsManager.resetContactForm();
  };
}); 