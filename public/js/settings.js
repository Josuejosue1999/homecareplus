// Settings Management
class SettingsManager {
  constructor() {
    this.apiBase = '/api/settings';
    this.googleMapsApiKey = 'AIzaSyA1g-UDJcfQS_33U3Sysxe9g4zlAOnpS3g';
    this.isGoogleMapsReady = false;
    this.geocoder = null;
    this.setupEventListeners();
    this.initializeForms();
    this.loadExistingData();
    this.setupContactPreview();
    this.setupLocationDetection();
    this.initializeGoogleMaps();
  }

  // Initialize Google Maps API
  async initializeGoogleMaps() {
    try {
      console.log('🗺️ Initializing Google Maps API...');
      
      // Load Google Maps API dynamically
      if (!window.google) {
        await this.loadGoogleMapsScript();
      }
      
      // Wait for Google Maps to be ready
      await this.waitForGoogleMaps();
      
      // Initialize geocoder
      this.geocoder = new google.maps.Geocoder();
      this.isGoogleMapsReady = true;
      
      console.log('✅ Google Maps API initialized successfully');
    } catch (error) {
      console.error('❌ Failed to initialize Google Maps API:', error);
      this.isGoogleMapsReady = false;
    }
  }

  // Load Google Maps script
  loadGoogleMapsScript() {
    return new Promise((resolve, reject) => {
      if (document.getElementById('google-maps-script')) {
        resolve();
        return;
      }

      const script = document.createElement('script');
      script.id = 'google-maps-script';
      script.src = `https://maps.googleapis.com/maps/api/js?key=${this.googleMapsApiKey}&libraries=places`;
      script.async = true;
      script.defer = true;
      
      script.onload = () => {
        console.log('✅ Google Maps script loaded');
        resolve();
      };
      
      script.onerror = (error) => {
        console.error('❌ Failed to load Google Maps script:', error);
        reject(error);
      };
      
      document.head.appendChild(script);
    });
  }

  // Wait for Google Maps to be ready
  waitForGoogleMaps() {
    return new Promise((resolve) => {
      const checkGoogle = () => {
        if (window.google && window.google.maps && window.google.maps.Geocoder) {
          resolve();
        } else {
          setTimeout(checkGoogle, 100);
        }
      };
      checkGoogle();
    });
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
      this.detectLocationHandler = () => this.detectLocationWithGoogleMaps();
      detectBtn.addEventListener('click', this.detectLocationHandler);
      detectBtn.setAttribute('data-listener-added', 'true');
    }

    // Add manual address input button
    this.setupManualAddressInput();

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

  // Nouvelle méthode pour la saisie manuelle d'adresse
  setupManualAddressInput() {
    const detectBtn = document.getElementById('detectLocationBtn');
    if (detectBtn && detectBtn.parentNode) {
      const manualBtn = document.createElement('button');
      manualBtn.type = 'button';
      manualBtn.className = 'btn btn-outline-secondary btn-sm ms-2';
      manualBtn.id = 'manualAddressBtn';
      manualBtn.innerHTML = '<i class="fas fa-edit me-1"></i>Manual Input';
      manualBtn.addEventListener('click', () => this.showManualAddressModal());
      
      detectBtn.parentNode.insertBefore(manualBtn, detectBtn.nextSibling);
    }
  }

  // Afficher la modal de saisie manuelle
  showManualAddressModal() {
    const modal = document.createElement('div');
    modal.className = 'modal fade';
    modal.id = 'manualAddressModal';
    modal.innerHTML = `
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              <i class="fas fa-map-marker-alt text-primary me-2"></i>
              Manual Address Input
            </h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <div class="mb-3">
              <label for="manualAddressInput" class="form-label">Enter your hospital address:</label>
              <input type="text" class="form-control" id="manualAddressInput" 
                     placeholder="e.g., Kacyiru, Gasabo, Kigali, Rwanda">
              <small class="text-muted">Enter as complete an address as possible for better accuracy</small>
            </div>
            <div id="manualAddressStatus" class="alert d-none"></div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-primary" id="geocodeAddressBtn">
              <i class="fas fa-search me-1"></i>Find Location
            </button>
          </div>
        </div>
      </div>
    `;
    
    document.body.appendChild(modal);
    const bootstrapModal = new bootstrap.Modal(modal);
    
    // Add event listener for geocoding
    document.getElementById('geocodeAddressBtn').addEventListener('click', () => {
      this.geocodeManualAddress();
    });
    
    bootstrapModal.show();
    
    // Clean up modal when closed
    modal.addEventListener('hidden.bs.modal', () => {
      document.body.removeChild(modal);
    });
  }

  // Afficher le statut de la recherche manuelle
  showManualAddressStatus(message, type) {
    const statusDiv = document.getElementById('manualAddressStatus');
    statusDiv.className = `alert alert-${type}`;
    statusDiv.innerHTML = `<i class="fas fa-info-circle me-2"></i>${message}`;
    statusDiv.classList.remove('d-none');
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

  // Professional location detection with Google Maps
  async detectLocationWithGoogleMaps() {
    const detectBtn = document.getElementById('detectLocationBtn');
    const originalBtnText = detectBtn.innerHTML;

    try {
      // Initialize button state
      detectBtn.disabled = true;
      detectBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Initializing...';
      this.showLocationStatus('🔄 Initializing location detection system...', 'info');

      // Ensure Google Maps is ready
      if (!this.isGoogleMapsReady) {
        await this.initializeGoogleMaps();
      }

      if (!this.isGoogleMapsReady) {
        throw new Error('Google Maps API not available');
      }

      // Check geolocation support
      if (!navigator.geolocation) {
        throw new Error('Geolocation is not supported by this browser');
      }

      // Start location detection
      detectBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Detecting location...';
      this.showLocationStatus('📍 Detecting your precise location...', 'info');

      console.log('🎯 Starting enhanced location detection...');

      // Get current position with high accuracy
      const position = await this.getCurrentPositionEnhanced();
      
      const { latitude, longitude } = position.coords;
      console.log('📍 Location detected:', { latitude, longitude, accuracy: position.coords.accuracy });

      // Update coordinate fields immediately
      document.getElementById('latitude').value = latitude.toFixed(6);
      document.getElementById('longitude').value = longitude.toFixed(6);

      // Update button to show coordinates
      detectBtn.innerHTML = `<i class="fas fa-crosshairs me-2"></i>Coordinates: ${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;

      // Perform reverse geocoding with Google Maps
      detectBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Finding address...';
      this.showLocationStatus('🔍 Finding your address using Google Maps...', 'info');

      const addressData = await this.reverseGeocodeEnhanced(latitude, longitude);
      
      if (addressData.success) {
        // Update all address fields
        this.updateAddressFields(addressData);
        
        // Show success
        this.showLocationStatus('✅ Location and address detected successfully!', 'success');
        detectBtn.innerHTML = '<i class="fas fa-check-circle me-2"></i>Location Detected Successfully';
        detectBtn.classList.add('btn-success');
        detectBtn.classList.remove('btn-outline-primary');

        // Auto-save the location
        await this.saveLocationData();
        
        console.log('✅ Location detection completed successfully');
      } else {
        // Partial success - coordinates only
        this.showLocationStatus('📍 Coordinates detected. Please complete the address manually.', 'warning');
        detectBtn.innerHTML = '<i class="fas fa-exclamation-triangle me-2"></i>Complete Address Manually';
        detectBtn.classList.add('btn-warning');
        detectBtn.classList.remove('btn-outline-primary');
      }

    } catch (error) {
      console.error('❌ Location detection failed:', error);
      
      // Handle specific error types
      let errorMessage = 'Unable to detect location. ';
      let showManualInput = false;

      if (error.code) {
        switch (error.code) {
          case 1: // PERMISSION_DENIED
            errorMessage = '🚫 Location permission denied. Please enable location access in your browser.';
            showManualInput = true;
            break;
          case 2: // POSITION_UNAVAILABLE
            errorMessage = '📍 Location unavailable. Please check your GPS settings.';
            showManualInput = true;
            break;
          case 3: // TIMEOUT
            errorMessage = '⏱️ Location detection timed out. Please try again.';
            break;
          default:
            errorMessage = '❌ Location detection failed. Please try again or enter manually.';
            showManualInput = true;
        }
      } else if (error.message.includes('Google Maps')) {
        errorMessage = '🗺️ Google Maps service unavailable. Please try again later.';
        showManualInput = true;
      } else {
        errorMessage = '❌ Location detection failed. Please enter your address manually.';
        showManualInput = true;
      }

      this.showLocationStatus(errorMessage, 'danger');
      detectBtn.innerHTML = '<i class="fas fa-exclamation-circle me-2"></i>Detection Failed';
      detectBtn.classList.add('btn-danger');
      detectBtn.classList.remove('btn-outline-primary');

      if (showManualInput) {
        this.showManualLocationInput();
      }
    } finally {
      // Reset button state after 5 seconds
      setTimeout(() => {
        detectBtn.disabled = false;
        detectBtn.innerHTML = originalBtnText;
        detectBtn.className = 'btn btn-outline-primary';
      }, 5000);
    }
  }

  // Enhanced geolocation with retry mechanism
  getCurrentPositionEnhanced() {
    return new Promise((resolve, reject) => {
      const options = {
        enableHighAccuracy: true,
        timeout: 15000,
        maximumAge: 60000
      };

      let attempts = 0;
      const maxAttempts = 3;

      const tryGeolocation = () => {
        attempts++;
        console.log(`🔄 Geolocation attempt ${attempts}/${maxAttempts}`);

        navigator.geolocation.getCurrentPosition(
          (position) => {
            console.log(`✅ Geolocation success on attempt ${attempts}`);
            console.log(`📍 Accuracy: ${position.coords.accuracy}m`);
            resolve(position);
          },
          (error) => {
            console.log(`❌ Geolocation attempt ${attempts} failed:`, error);
            
            if (attempts < maxAttempts && error.code === 3) { // TIMEOUT
              console.log('🔄 Retrying with relaxed settings...');
              setTimeout(tryGeolocation, 2000);
            } else {
              reject(error);
            }
          },
          {
            ...options,
            enableHighAccuracy: attempts === 1,
            timeout: attempts * 10000, // Increase timeout on retry
          }
        );
      };

      tryGeolocation();
    });
  }

  // Enhanced reverse geocoding with Google Maps
  async reverseGeocodeEnhanced(latitude, longitude) {
    try {
      console.log('🔍 Starting enhanced reverse geocoding...');
      
      if (!this.geocoder) {
        throw new Error('Google Maps Geocoder not available');
      }

      const latlng = new google.maps.LatLng(latitude, longitude);
      
      return new Promise((resolve) => {
        this.geocoder.geocode({ location: latlng }, (results, status) => {
          if (status === 'OK' && results && results.length > 0) {
            console.log('✅ Geocoding successful:', results[0]);
            
            const addressData = this.parseGoogleMapsResult(results[0]);
            resolve({ success: true, ...addressData });
          } else {
            console.log('⚠️ Geocoding failed:', status);
            resolve({ success: false });
          }
        });
      });
    } catch (error) {
      console.error('❌ Reverse geocoding error:', error);
      return { success: false };
    }
  }

  // Parse Google Maps geocoding result
  parseGoogleMapsResult(result) {
    console.log('📝 Parsing Google Maps result...');
    
    const components = result.address_components;
    const formattedAddress = result.formatted_address;
    
    let street = '';
    let sector = '';
    let country = 'Rwanda';
    
    // Extract address components
    for (const component of components) {
      const types = component.types;
      
      if (types.includes('street_number')) {
        street = component.long_name + ' ' + street;
      } else if (types.includes('route')) {
        street = street + component.long_name;
      } else if (types.includes('sublocality_level_1') || types.includes('sublocality')) {
        sector = component.long_name;
      } else if (types.includes('locality') && !sector) {
        sector = component.long_name;
      } else if (types.includes('administrative_area_level_1') && !sector) {
        sector = component.long_name;
      } else if (types.includes('country')) {
        country = component.long_name;
      }
    }
    
    // Fallback to formatted address if no street found
    if (!street && formattedAddress) {
      const parts = formattedAddress.split(',');
      street = parts[0].trim();
    }
    
    // Fallback for sector
    if (!sector && formattedAddress) {
      const parts = formattedAddress.split(',');
      if (parts.length > 1) {
        sector = parts[1].trim();
      }
    }
    
    // Clean up values
    street = street.trim() || 'Detected Location';
    sector = sector.trim() || 'Detected Area';
    
    console.log('📍 Parsed address:', { street, sector, country });
    
    return {
      street: street,
      sector: sector,
      country: country,
      fullAddress: formattedAddress
    };
  }

  // Update address fields with parsed data
  updateAddressFields(addressData) {
    const streetField = document.getElementById('street');
    const sectorField = document.getElementById('sector');
    const countryField = document.getElementById('country');
    
    if (streetField && addressData.street) {
      streetField.value = addressData.street;
      streetField.classList.add('is-valid');
      streetField.classList.remove('is-invalid');
    }
    
    if (sectorField && addressData.sector) {
      sectorField.value = addressData.sector;
      sectorField.classList.add('is-valid');
      sectorField.classList.remove('is-invalid');
    }
    
    if (countryField && addressData.country) {
      countryField.value = addressData.country;
      countryField.classList.add('is-valid');
      countryField.classList.remove('is-invalid');
    }
    
    // Update derived fields
    this.updateAddressField();
    this.updateContactPreview();
  }

  // Save location data to backend
  async saveLocationData() {
    try {
      console.log('💾 Saving location data...');
      
      const locationData = {
        street: document.getElementById('street')?.value || '',
        sector: document.getElementById('sector')?.value || '',
        country: document.getElementById('country')?.value || 'Rwanda',
        latitude: document.getElementById('latitude')?.value || '',
        longitude: document.getElementById('longitude')?.value || '',
        phone: document.getElementById('phone')?.value || '',
        website: document.getElementById('website')?.value || ''
      };
      
      const response = await fetch('/api/settings/contact', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(locationData)
      });

      const result = await response.json();
      
      if (response.ok && result.success) {
        console.log('✅ Location data saved successfully');
        this.showNotification('📍 Location saved successfully!', 'success');
        return true;
      } else {
        console.error('❌ Failed to save location data:', result.message);
        return false;
      }
    } catch (error) {
      console.error('❌ Error saving location data:', error);
      return false;
    }
  }

  showLocationStatus(message, type) {
    const statusDiv = document.getElementById('locationStatus');
    const statusText = document.getElementById('locationStatusText');
    
    if (statusDiv && statusText) {
      statusDiv.className = `alert alert-${type}`;
      statusText.textContent = message;
      statusDiv.classList.remove('d-none');
      
      // Auto-hide success messages after 5 seconds
      if (type === 'success') {
        setTimeout(() => {
          statusDiv.classList.add('d-none');
        }, 5000);
      }
    }
  }

  resetContactForm() {
    const contactForm = document.getElementById('contactForm');
    if (contactForm) {
      contactForm.reset();
      
      // Clear validation states
      const fields = contactForm.querySelectorAll('.form-control');
      fields.forEach(field => {
        field.classList.remove('is-valid', 'is-invalid');
      });
      
      // Clear error messages
      const errorMessages = contactForm.querySelectorAll('.invalid-feedback');
      errorMessages.forEach(msg => msg.remove());
      
      // Reset location status
      const locationStatus = document.getElementById('locationStatus');
      if (locationStatus) {
        locationStatus.classList.add('d-none');
      }
      
      // Reset detect button
      const detectBtn = document.getElementById('detectLocationBtn');
      if (detectBtn) {
        detectBtn.disabled = false;
        detectBtn.innerHTML = '<i class="fas fa-location-arrow me-2"></i>Auto-Detect Location';
      }
      
      // Update preview
      this.updateContactPreview();
    }
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