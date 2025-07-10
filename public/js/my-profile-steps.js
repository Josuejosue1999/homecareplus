// My Profile Steps Management
class ProfileSteps {
    constructor() {
        this.currentStep = 1;
        this.totalSteps = 3;
        this.init();
    }

    init() {
        this.setupStepNavigation();
        this.setupGoogleMaps();
        this.setupFormValidation();
        // Initialize custom services and scheduling functionality
        setTimeout(() => {
            this.initializeCustomServices();
            this.initializeScheduling();
            // Populate email from Firebase immediately on load
            this.populateEmailFromFirebase();
        }, 1000);
    }

    // Setup step navigation
    setupStepNavigation() {
        const stepItems = document.querySelectorAll('.step-item');
        stepItems.forEach(item => {
            item.addEventListener('click', (e) => {
                const stepNumber = parseInt(item.dataset.step);
                if (stepNumber <= this.currentStep) {
                    this.goToStep(stepNumber);
                }
            });
        });
    }

    // Navigate to specific step
    goToStep(stepNumber) {
        if (stepNumber < 1 || stepNumber > this.totalSteps) return;
        
        // Hide all step content
        document.querySelectorAll('.step-content').forEach(content => {
            content.classList.remove('active');
        });
        
        // Show current step content
        const currentContent = document.getElementById(`step-${stepNumber}`);
        if (currentContent) {
            currentContent.classList.add('active');
        }
        
        // Update step indicators
        document.querySelectorAll('.step-item').forEach((item, index) => {
            item.classList.remove('active', 'completed');
            if (index + 1 === stepNumber) {
                item.classList.add('active');
            } else if (index + 1 < stepNumber) {
                item.classList.add('completed');
            }
        });
        
        this.currentStep = stepNumber;
        this.updateNavigationButtons();
        
        // Step-specific actions
        if (stepNumber === 1) {
            // Initialize map if needed
            setTimeout(() => {
                this.setupGoogleMaps();
            }, 100);
        } else if (stepNumber === 2) {
            // Auto-fill profile information if available
            this.applyAutoFillData();
            // Focus on first form field
            setTimeout(() => {
                document.getElementById('clinicNameProfile')?.focus();
            }, 100);
        } else if (stepNumber === 3) {
            // Initialize photo upload
            this.initializePhotoUpload();
        }
    }

    // Apply auto-fill data to profile form
    applyAutoFillData() {
        if (this.autoFillData) {
            // Fill basic information
            if (this.autoFillData.clinicName) {
                const clinicNameField = document.getElementById('clinicNameProfile');
                if (clinicNameField) clinicNameField.value = this.autoFillData.clinicName;
            }
            if (this.autoFillData.clinicPhone) {
                const clinicPhoneField = document.getElementById('clinicPhone');
                if (clinicPhoneField) clinicPhoneField.value = this.autoFillData.clinicPhone;
            }
            if (this.autoFillData.clinicWebsite) {
                const clinicWebsiteField = document.getElementById('clinicWebsite');
                if (clinicWebsiteField) clinicWebsiteField.value = this.autoFillData.clinicWebsite;
            }
            if (this.autoFillData.clinicAddress) {
                const clinicAddressField = document.getElementById('clinicAddress');
                if (clinicAddressField) clinicAddressField.value = this.autoFillData.clinicAddress;
            }
            
            // Generate description based on Google data
            if (this.autoFillData.clinicName && this.autoFillData.clinicAddress) {
                const description = `${this.autoFillData.clinicName} is a healthcare facility located at ${this.autoFillData.clinicAddress}. ${this.autoFillData.clinicRating ? `Rated ${this.autoFillData.clinicRating} stars by patients.` : 'Providing quality healthcare services to the community.'}`;
                const descriptionField = document.getElementById('clinicDescription');
                if (descriptionField) descriptionField.value = description;
            }
        }
        
        // Always populate email from Firebase user data
        this.populateEmailFromFirebase();
    }

    // Display profile photo from Firebase
    populateEmailFromFirebase() {
        // Display profile photo if available
        this.displayProfilePhoto();
    }

    // Display profile photo from Firebase
    displayProfilePhoto() {
        // Get profile image from window.clinicData or localStorage
        const clinicData = window.clinicData || JSON.parse(localStorage.getItem('clinicData') || '{}');
        const profileImageUrl = clinicData.profileImageUrl || clinicData.profileImage;
        
        if (profileImageUrl) {
            const profileImagePreview = document.getElementById('profileImagePreview');
            const profilePlaceholder = document.getElementById('profilePlaceholder');
            
            if (profileImagePreview && profilePlaceholder) {
                profileImagePreview.src = profileImageUrl;
                profileImagePreview.style.display = 'block';
                profilePlaceholder.style.display = 'none';
            }
        }
    }

    // Go to next step
    nextStep() {
        if (this.validateCurrentStep()) {
            this.goToStep(this.currentStep + 1);
        }
    }

    // Go to previous step
    previousStep() {
        if (this.currentStep > 1) {
            this.goToStep(this.currentStep - 1);
        }
    }

    // Update navigation buttons
    updateNavigationButtons() {
        const prevBtn = document.getElementById('prevBtn');
        const nextBtn = document.getElementById('nextBtn');
        const saveBtn = document.getElementById('saveBtn');
        
        if (prevBtn) {
            prevBtn.disabled = this.currentStep === 1;
        }
        
        if (nextBtn) {
            nextBtn.style.display = this.currentStep === this.totalSteps ? 'none' : 'inline-block';
        }
        
        if (saveBtn) {
            saveBtn.style.display = this.currentStep === this.totalSteps ? 'inline-block' : 'none';
        }
    }

    // Validate current step
    validateCurrentStep() {
        switch (this.currentStep) {
            case 1:
                return this.validateStep1();
            case 2:
                return this.validateStep2();
            case 3:
                return true; // Step 3 is optional
            default:
                return true;
        }
    }

    // Validate step 1 (Hospital Location)
    validateStep1() {
        const selectedHospital = document.getElementById('selectedHospital');
        if (!selectedHospital || selectedHospital.style.display === 'none') {
            Swal.fire({
                icon: 'warning',
                title: 'Hospital Location Required',
                text: 'Please search and select your hospital location before proceeding.',
                confirmButtonColor: '#007bff'
            });
            return false;
        }
        return true;
    }

    // Validate step 2 (Profile Information)
    validateStep2() {
        const clinicName = document.getElementById('clinicNameProfile');
        const clinicDescription = document.getElementById('clinicDescription');
        
        if (!clinicName || !clinicName.value.trim()) {
            Swal.fire({
                icon: 'warning',
                title: 'Clinic Name Required',
                text: 'Please enter your clinic name before proceeding.',
                confirmButtonColor: '#007bff'
            });
            clinicName?.focus();
            return false;
        }
        
        if (!clinicDescription || clinicDescription.value.trim().length < 20) {
            Swal.fire({
                icon: 'warning',
                title: 'Clinic Description Required',
                text: 'Please provide a detailed description of your clinic (at least 20 characters).',
                confirmButtonColor: '#007bff'
            });
            clinicDescription?.focus();
            return false;
        }
        
        return true;
    }

    // Setup Google Maps
    setupGoogleMaps() {
        // Initialize map when My Profile section is shown
        if (typeof google !== 'undefined' && google.maps) {
            this.initializeMap();
        } else {
            // Load Google Maps API
            this.loadGoogleMapsAPI();
        }
    }

    // Load Google Maps API
    loadGoogleMapsAPI() {
        const script = document.createElement('script');
        script.src = 'https://maps.googleapis.com/maps/api/js?key=AIzaSyA1g-UDJcfQS_33U3Sysxe9g4zlAOnpS3g&libraries=places&callback=profileSteps.initializeMap';
        script.async = true;
        document.head.appendChild(script);
    }

    // Initialize Google Maps
    initializeMap() {
        const mapElement = document.getElementById('map');
        if (!mapElement) return;

        // Default location (Kigali, Rwanda)
        const defaultLocation = { lat: -1.9441, lng: 30.0619 };
        
        this.map = new google.maps.Map(mapElement, {
            zoom: 12,
            center: defaultLocation,
            styles: [
                {
                    featureType: "poi",
                    elementType: "labels",
                    stylers: [{ visibility: "off" }]
                }
            ]
        });

        // Initialize Places service
        this.placesService = new google.maps.places.PlacesService(this.map);
        
        // Setup search functionality
        this.setupHospitalSearch();
    }

    // Setup hospital search with real-time autocomplete
    setupHospitalSearch() {
        const searchInput = document.getElementById('hospitalSearch');
        const searchBtn = document.getElementById('searchBtn');
        
        if (searchInput && searchBtn) {
            // Setup Google Places Autocomplete for real-time suggestions
            this.setupAutocomplete(searchInput);
            
            // Search button functionality
            searchBtn.addEventListener('click', () => {
                this.searchHospitals(searchInput.value);
            });
            
            // Enter key functionality
            searchInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    this.searchHospitals(searchInput.value);
                }
            });
            
            // Real-time search as user types (debounced)
            let searchTimeout;
            searchInput.addEventListener('input', (e) => {
                clearTimeout(searchTimeout);
                const query = e.target.value.trim();
                
                if (query.length >= 3) {
                    searchTimeout = setTimeout(() => {
                        this.performRealTimeSearch(query);
                    }, 500); // 500ms debounce
                } else {
                    // Clear results if query too short
                    document.getElementById('searchResults').innerHTML = '';
                }
            });
        }
    }

    // Setup Google Places Autocomplete
    setupAutocomplete(input) {
        if (typeof google !== 'undefined' && google.maps && google.maps.places) {
            // Focus on Rwanda for better local results
            const autocomplete = new google.maps.places.Autocomplete(input, {
                types: ['hospital', 'health'],
                componentRestrictions: { country: 'rw' }, // Rwanda
                fields: ['place_id', 'name', 'formatted_address', 'geometry', 'photos', 'formatted_phone_number', 'website', 'rating']
            });

            autocomplete.addListener('place_changed', () => {
                const place = autocomplete.getPlace();
                if (place.place_id) {
                    this.handleAutocompleteSelection(place);
                }
            });
        }
    }

    // Handle autocomplete selection
    handleAutocompleteSelection(place) {
        // Auto-select the hospital
        this.selectHospital(
            place.place_id,
            place.name,
            place.formatted_address,
            place.geometry.location.lat(),
            place.geometry.location.lng(),
            place
        );
        
        // Store additional details for auto-fill
        this.selectedHospitalDetails = place;
    }

    // Real-time search for hospitals in Rwanda
    performRealTimeSearch(query) {
        const request = {
            query: `${query} hospital Rwanda`,
            fields: ['place_id', 'name', 'formatted_address', 'geometry', 'photos', 'rating'],
            locationBias: {
                center: { lat: -1.9441, lng: 30.0619 }, // Kigali center
                radius: 50000 // 50km radius
            }
        };

        this.placesService.textSearch(request, (results, status) => {
            if (status === google.maps.places.PlacesServiceStatus.OK && results.length > 0) {
                this.displayRealTimeResults(results.slice(0, 5)); // Show top 5 results
            }
        });
    }

    // Display real-time search results
    displayRealTimeResults(results) {
        const resultsContainer = document.getElementById('searchResults');
        if (!resultsContainer) return;

        resultsContainer.innerHTML = '';
        
        results.forEach(place => {
            const resultItem = document.createElement('div');
            resultItem.className = 'search-result-item real-time';
            resultItem.innerHTML = `
                <div class="result-info">
                    <div class="hospital-name">
                        <i class="fas fa-hospital text-primary me-2"></i>
                        <h6>${place.name}</h6>
                    </div>
                    <p class="text-muted">${place.formatted_address}</p>
                    <div class="hospital-meta">
                        ${place.rating ? `<span class="rating"><i class="fas fa-star text-warning"></i> ${place.rating}</span>` : ''}
                        <span class="location-badge"><i class="fas fa-map-marker-alt"></i> Rwanda</span>
                    </div>
                </div>
                <button class="btn btn-sm btn-primary select-btn" onclick="profileSteps.selectHospitalFromRealTime('${place.place_id}', \`${place.name}\`, \`${place.formatted_address}\`, ${place.geometry.location.lat()}, ${place.geometry.location.lng()})">
                    <i class="fas fa-check me-1"></i>Select
                </button>
            `;
            resultsContainer.appendChild(resultItem);
        });
    }

    // Select hospital from real-time results
    selectHospitalFromRealTime(placeId, name, address, lat, lng) {
        // Get detailed information for auto-fill
        this.getPlaceDetails(placeId).then(details => {
            this.selectHospital(placeId, name, address, lat, lng, details);
            this.selectedHospitalDetails = details;
        });
    }

    // Search for hospitals
    searchHospitals(query) {
        if (!query.trim()) {
            Swal.fire({
                icon: 'warning',
                title: 'Search Query Required',
                text: 'Please enter a hospital name or address to search.',
                confirmButtonColor: '#007bff'
            });
            return;
        }

        const request = {
            query: query + ' hospital',
            fields: ['name', 'formatted_address', 'geometry', 'place_id']
        };

        this.placesService.textSearch(request, (results, status) => {
            if (status === google.maps.places.PlacesServiceStatus.OK) {
                this.displaySearchResults(results);
            } else {
                Swal.fire({
                    icon: 'error',
                    title: 'Search Failed',
                    text: 'Unable to find hospitals with that search term. Please try a different query.',
                    confirmButtonColor: '#007bff'
                });
            }
        });
    }

    // Display search results
    displaySearchResults(results) {
        const resultsContainer = document.getElementById('searchResults');
        if (!resultsContainer) return;

        resultsContainer.innerHTML = '';
        
        if (results.length === 0) {
            resultsContainer.innerHTML = '<p class="text-muted">No hospitals found. Try a different search term.</p>';
            return;
        }

        results.forEach(place => {
            const resultItem = document.createElement('div');
            resultItem.className = 'search-result-item';
            resultItem.innerHTML = `
                <div class="result-info">
                    <h6>${place.name}</h6>
                    <p class="text-muted">${place.formatted_address}</p>
                </div>
                <button class="btn btn-sm btn-outline-primary" onclick="profileSteps.selectHospital('${place.place_id}', '${place.name}', '${place.formatted_address}', ${place.geometry.location.lat()}, ${place.geometry.location.lng()})">
                    Select
                </button>
            `;
            resultsContainer.appendChild(resultItem);
        });
    }

    // Select hospital with enhanced details
    selectHospital(placeId, name, address, lat, lng, placeDetails = null) {
        // Update selected hospital display
        document.getElementById('selectedHospitalName').textContent = name;
        document.getElementById('selectedHospitalAddress').textContent = address;
        document.getElementById('selectedLat').value = lat;
        document.getElementById('selectedLng').value = lng;
        document.getElementById('selectedHospital').style.display = 'block';
        
        // Store place details for auto-fill and saving
        this.selectedHospitalPlaceId = placeId;
        this.selectedHospitalDetails = placeDetails;
        
        // Center map on selected hospital
        const location = new google.maps.LatLng(lat, lng);
        this.map.setCenter(location);
        this.map.setZoom(15);
        
        // Add marker
        if (this.selectedMarker) {
            this.selectedMarker.setMap(null);
        }
        
        this.selectedMarker = new google.maps.Marker({
            position: location,
            map: this.map,
            title: name,
            icon: {
                url: 'https://maps.google.com/mapfiles/ms/icons/hospital.png',
                scaledSize: new google.maps.Size(40, 40)
            }
        });
        
        // Clear search results
        document.getElementById('searchResults').innerHTML = '';
        document.getElementById('hospitalSearch').value = '';
        
        // Auto-fill profile information if details available
        if (placeDetails) {
            this.autoFillProfileInfo(placeDetails);
        }
        
        // Show success message with auto-fill info
        Swal.fire({
            icon: 'success',
            title: 'Hospital Selected',
            text: `${name} has been selected. ${placeDetails ? 'Profile information will be auto-filled on the next step.' : ''}`,
            timer: 3000,
            showConfirmButton: false
        });
    }

    // Auto-fill profile information from Google Places data
    autoFillProfileInfo(placeDetails) {
        // Store for use when moving to step 2
        this.autoFillData = {
            clinicName: placeDetails.name,
            clinicPhone: placeDetails.formatted_phone_number || '',
            clinicWebsite: placeDetails.website || '',
            clinicAddress: placeDetails.formatted_address,
            clinicRating: placeDetails.rating || '',
            // Extract photo URL if available
            clinicPhoto: placeDetails.photos && placeDetails.photos.length > 0 
                ? placeDetails.photos[0].getUrl({ maxWidth: 400 }) 
                : null
        };
    }

    // Enhanced getPlaceDetails method
    async getPlaceDetails(placeId) {
        return new Promise((resolve, reject) => {
            const request = {
                placeId: placeId,
                fields: ['name', 'formatted_address', 'formatted_phone_number', 'website', 'photos', 'rating', 'reviews', 'opening_hours']
            };

            this.placesService.getDetails(request, (place, status) => {
                if (status === google.maps.places.PlacesServiceStatus.OK) {
                    resolve(place);
                } else {
                    reject(status);
                }
            });
        });
    }

    // Setup form validation
    setupFormValidation() {
        // Real-time validation for clinic name
        const clinicNameInput = document.getElementById('clinicNameProfile');
        if (clinicNameInput) {
            clinicNameInput.addEventListener('input', (e) => {
                const value = e.target.value.trim();
                if (value.length < 3) {
                    e.target.classList.add('is-invalid');
                } else {
                    e.target.classList.remove('is-invalid');
                    e.target.classList.add('is-valid');
                }
            });
        }

        // Real-time validation for description
        const descriptionInput = document.getElementById('clinicDescription');
        if (descriptionInput) {
            descriptionInput.addEventListener('input', (e) => {
                const value = e.target.value.trim();
                if (value.length < 20) {
                    e.target.classList.add('is-invalid');
                } else {
                    e.target.classList.remove('is-invalid');
                    e.target.classList.add('is-valid');
                }
            });
        }
    }

    // Save profile
    async saveProfile() {
        if (!this.validateCurrentStep()) {
            return;
        }

        // Collect all form data
        const servicesData = this.getCustomServicesData();
        const schedulingData = this.getSchedulingData();
        
        const profileData = {
            // Step 1: Hospital Location (Google Places)
            hospitalName: document.getElementById('selectedHospitalName')?.textContent,
            hospitalAddress: document.getElementById('selectedHospitalAddress')?.textContent,
            latitude: document.getElementById('selectedLat')?.value,
            longitude: document.getElementById('selectedLng')?.value,
            placeId: this.selectedHospitalPlaceId || null,
            placeDetails: this.selectedHospitalDetails || null,
            
            // Step 2: Profile Information
            clinicName: document.getElementById('clinicNameProfile')?.value,
            clinicDescription: document.getElementById('clinicDescription')?.value,
            clinicPhone: document.getElementById('clinicPhone')?.value,
            
            // Services (standard + custom)
            services: servicesData.standard,
            customServices: servicesData.custom,
            
            // Scheduling Data
            appointmentDuration: schedulingData.appointmentDuration,
            bufferTime: schedulingData.bufferTime,
            weeklySchedule: schedulingData.weeklySchedule,
            
            // Step 3: Photos (placeholders - will be enhanced later)
            profileImage: null,
            certificateImage: null,
            clinicPhotos: []
        };

        console.log('💾 Saving profile data:', profileData);

        // Show loading
        Swal.fire({
            title: 'Saving Profile...',
            text: 'Please wait while we save your profile information to Firebase.',
            allowOutsideClick: false,
            didOpen: () => {
                Swal.showLoading();
            }
        });

        try {
            // Send to server
            const response = await fetch('/api/save-hospital-profile', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(profileData)
            });

            const result = await response.json();

            if (result.success) {
                console.log('✅ Profile saved successfully:', result);
                
                Swal.fire({
                    icon: 'success',
                    title: 'Profile Saved!',
                    text: 'Your clinic profile has been successfully saved to Firebase.',
                    confirmButtonColor: '#28a745'
                }).then(() => {
                    // Update profile completion
                    this.updateProfileCompletion();
                    
                    // Navigate back to dashboard
                    if (typeof dashboardNavigation !== 'undefined') {
                        dashboardNavigation.showSection('dashboard');
                    }
                });
            } else {
                console.error('❌ Error saving profile:', result.error);
                
                Swal.fire({
                    icon: 'error',
                    title: 'Save Failed',
                    text: result.error || 'Failed to save profile. Please try again.',
                    confirmButtonColor: '#dc3545'
                });
            }
        } catch (error) {
            console.error('❌ Network error saving profile:', error);
            
            Swal.fire({
                icon: 'error',
                title: 'Network Error',
                text: 'Could not connect to server. Please check your internet connection and try again.',
                confirmButtonColor: '#dc3545'
            });
        }
    }

    // Initialize photo upload
    initializePhotoUpload() {
        // Photo upload functionality placeholder
        console.log('Photo upload initialized');
    }

    // Initialize custom services functionality
    initializeCustomServices() {
        console.log('🔧 Initializing custom services...');
        
        const addBtn = document.getElementById('addCustomService');
        const input = document.getElementById('customServiceInput');
        const servicesList = document.getElementById('customServicesList');
        
        if (!addBtn) {
            console.error('❌ Add custom service button not found');
            return;
        }
        
        if (!input) {
            console.error('❌ Custom service input not found');
            return;
        }
        
        if (!servicesList) {
            console.error('❌ Custom services list not found');
            return;
        }
        
        console.log('✅ All custom service elements found');
        
        // Remove existing event listeners to prevent duplicates
        const newAddBtn = addBtn.cloneNode(true);
        addBtn.parentNode.replaceChild(newAddBtn, addBtn);
        
        const newInput = input.cloneNode(true);
        input.parentNode.replaceChild(newInput, input);
        
        // Add event listeners
        newAddBtn.addEventListener('click', () => {
            console.log('🔧 Add custom service button clicked');
            this.addCustomService();
        });
        
        newInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                console.log('🔧 Enter key pressed on custom service input');
                this.addCustomService();
            }
        });
        
        console.log('✅ Custom services initialized successfully');
    }

    // Add custom service
    addCustomService() {
        console.log('🔧 Adding custom service...');
        
        const input = document.getElementById('customServiceInput');
        const servicesList = document.getElementById('customServicesList');
        
        console.log('Input element:', input);
        console.log('Services list element:', servicesList);
        
        if (!input) {
            console.error('❌ Custom service input not found');
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: 'Input field not found. Please refresh the page.',
                timer: 2000,
                showConfirmButton: false
            });
            return;
        }
        
        if (!servicesList) {
            console.error('❌ Custom services list not found');
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: 'Services list not found. Please refresh the page.',
                timer: 2000,
                showConfirmButton: false
            });
            return;
        }
        
        const serviceName = input.value.trim();
        console.log('Service name:', serviceName);
        
        if (!serviceName) {
            console.log('❌ Service name is empty');
            Swal.fire({
                icon: 'warning',
                title: 'Service Name Required',
                text: 'Please enter a service name.',
                timer: 2000,
                showConfirmButton: false
            });
            return;
        }
        
        // Check if service already exists
        const existingServices = servicesList.querySelectorAll('.custom-service-item');
        for (let service of existingServices) {
            if (service.textContent.toLowerCase().includes(serviceName.toLowerCase())) {
                console.log('❌ Service already exists');
                Swal.fire({
                    icon: 'warning',
                    title: 'Service Already Exists',
                    text: 'This service is already added.',
                    timer: 2000,
                    showConfirmButton: false
                });
                return;
            }
        }
        
        // Create custom service item
        const serviceItem = document.createElement('div');
        serviceItem.className = 'custom-service-item';
        serviceItem.innerHTML = `
            <span class="service-name">${serviceName}</span>
            <button class="btn btn-sm btn-outline-danger remove-custom-service">
                <i class="fas fa-times"></i>
            </button>
        `;
        
        // Add remove functionality
        serviceItem.querySelector('.remove-custom-service').addEventListener('click', () => {
            serviceItem.remove();
            console.log('✅ Custom service removed:', serviceName);
        });
        
        servicesList.appendChild(serviceItem);
        input.value = '';
        
        console.log('✅ Custom service added successfully:', serviceName);
        
        // Show success message
        Swal.fire({
            icon: 'success',
            title: 'Service Added',
            text: `${serviceName} has been added to your services.`,
            timer: 1500,
            showConfirmButton: false
        });
    }

    // Initialize scheduling functionality
    initializeScheduling() {
        // Add event listeners for day toggles
        document.querySelectorAll('.day-checkbox').forEach(checkbox => {
            checkbox.addEventListener('change', (e) => {
                const scheduleDay = e.target.closest('.schedule-day');
                const timeSlots = scheduleDay.querySelector('.time-slots');
                const addSlotBtn = scheduleDay.querySelector('.add-slot');
                
                if (e.target.checked) {
                    timeSlots.style.display = 'block';
                    addSlotBtn.style.display = 'inline-block';
                } else {
                    timeSlots.style.display = 'none';
                    addSlotBtn.style.display = 'none';
                }
            });
        });
        
        // Add event listeners for add slot buttons
        document.querySelectorAll('.add-slot').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const scheduleDay = e.target.closest('.schedule-day');
                this.addTimeSlot(scheduleDay);
            });
        });
        
        // Add event listeners for remove slot buttons
        document.querySelectorAll('.remove-slot').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const timeSlot = e.target.closest('.time-slot');
                this.removeTimeSlot(timeSlot);
            });
        });
        
        // Initial state setup
        document.querySelectorAll('.day-checkbox').forEach(checkbox => {
            const scheduleDay = checkbox.closest('.schedule-day');
            const timeSlots = scheduleDay.querySelector('.time-slots');
            const addSlotBtn = scheduleDay.querySelector('.add-slot');
            
            if (!checkbox.checked) {
                timeSlots.style.display = 'none';
                addSlotBtn.style.display = 'none';
            }
        });
    }

    // Add time slot to a day
    addTimeSlot(scheduleDay) {
        const timeSlotsContainer = scheduleDay.querySelector('.time-slots');
        
        const timeSlot = document.createElement('div');
        timeSlot.className = 'time-slot';
        timeSlot.innerHTML = `
            <input type="time" class="form-control form-control-sm" value="09:00">
            <span class="time-separator">to</span>
            <input type="time" class="form-control form-control-sm" value="17:00">
            <button class="btn btn-sm btn-outline-danger remove-slot">
                <i class="fas fa-times"></i>
            </button>
        `;
        
        // Add remove functionality
        timeSlot.querySelector('.remove-slot').addEventListener('click', () => {
            this.removeTimeSlot(timeSlot);
        });
        
        timeSlotsContainer.appendChild(timeSlot);
    }

    // Remove time slot
    removeTimeSlot(timeSlot) {
        const timeSlotsContainer = timeSlot.parentElement;
        
        // Don't allow removing the last time slot
        if (timeSlotsContainer.querySelectorAll('.time-slot').length <= 1) {
            Swal.fire({
                icon: 'warning',
                title: 'Cannot Remove',
                text: 'Each active day must have at least one time slot.',
                timer: 2000,
                showConfirmButton: false
            });
            return;
        }
        
        timeSlot.remove();
    }

    // Get scheduling data
    getSchedulingData() {
        const scheduleData = {
            appointmentDuration: document.getElementById('appointmentDuration')?.value || 30,
            bufferTime: document.getElementById('bufferTime')?.value || 10,
            weeklySchedule: {}
        };
        
        document.querySelectorAll('.schedule-day').forEach(dayElement => {
            const day = dayElement.getAttribute('data-day');
            const checkbox = dayElement.querySelector('.day-checkbox');
            const timeSlots = dayElement.querySelectorAll('.time-slot');
            
            if (checkbox.checked) {
                scheduleData.weeklySchedule[day] = {
                    active: true,
                    slots: []
                };
                
                timeSlots.forEach(slot => {
                    const startTime = slot.querySelector('input[type="time"]').value;
                    const endTime = slot.querySelectorAll('input[type="time"]')[1].value;
                    
                    if (startTime && endTime) {
                        scheduleData.weeklySchedule[day].slots.push({
                            start: startTime,
                            end: endTime
                        });
                    }
                });
            } else {
                scheduleData.weeklySchedule[day] = {
                    active: false,
                    slots: []
                };
            }
        });
        
        return scheduleData;
    }

    // Get custom services data
    getCustomServicesData() {
        console.log('🔧 Getting custom services data...');
        
        const customServices = [];
        const standardServices = [];
        
        // Get standard services
        const standardCheckboxes = document.querySelectorAll('#servicesGrid input[type="checkbox"]:checked');
        console.log('Standard checkboxes found:', standardCheckboxes.length);
        
        standardCheckboxes.forEach(checkbox => {
            standardServices.push(checkbox.value);
            console.log('Standard service:', checkbox.value);
        });
        
        // Get custom services
        const customServiceItems = document.querySelectorAll('#customServicesList .custom-service-item');
        console.log('Custom service items found:', customServiceItems.length);
        
        customServiceItems.forEach(item => {
            const serviceName = item.querySelector('.service-name').textContent.trim();
            if (serviceName) {
                customServices.push(serviceName);
                console.log('Custom service:', serviceName);
            }
        });
        
        const result = {
            standard: standardServices,
            custom: customServices
        };
        
        console.log('✅ Services data collected:', result);
        
        return result;
    }

    // Update profile completion percentage
    updateProfileCompletion() {
        const completionText = document.querySelector('.completion-text');
        const progressCircle = document.querySelector('.progress-ring-circle-fill');
        
        if (completionText && progressCircle) {
            completionText.textContent = '85%';
            
            // Animate progress circle
            const circumference = 2 * Math.PI * 25; // radius = 25
            const offset = circumference - (0.85 * circumference);
            progressCircle.style.strokeDasharray = circumference;
            progressCircle.style.strokeDashoffset = offset;
        }
    }
}

// Initialize profile steps when DOM is loaded
let profileSteps;
document.addEventListener('DOMContentLoaded', function() {
    profileSteps = new ProfileSteps();
}); 