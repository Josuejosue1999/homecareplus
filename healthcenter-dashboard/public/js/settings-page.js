/**
 * Settings Page Manager - Handles all settings functionality
 * Including profile editing, contact info, services, and file uploads
 */

const settingsPage = {
    currentData: {},

    /**
     * Initialize the settings page
     */
    init() {
        console.log('🚀 Initializing Settings Page...');
        this.bindEvents();
        this.loadInitialData();
        this.setupTabs();
        console.log('✅ Settings Page initialized');
    },

    /**
     * Setup tab functionality
     */
    setupTabs() {
        document.querySelectorAll('[data-settings-tab]').forEach(button => {
            button.addEventListener('click', (e) => {
            e.preventDefault();
                const tabName = e.target.getAttribute('data-settings-tab');
                this.switchTab(tabName);
                
                // Update button states
                document.querySelectorAll('[data-settings-tab]').forEach(btn => 
                    btn.classList.remove('active'));
                e.target.classList.add('active');
            });
        });
    },

    /**
     * Switch between tabs
     */
    switchTab(tabName) {
        // Hide all tabs
        document.querySelectorAll('.settings-tab').forEach(tab => {
            tab.classList.remove('active');
        });
        
        // Show selected tab
        const targetTab = document.getElementById(`${tabName}-tab`);
        if (targetTab) {
            targetTab.classList.add('active');
        }
    },

    /**
     * Bind all event listeners
     */
    bindEvents() {
        // Form submissions with SweetAlert integration
        const profileForm = document.getElementById('profileForm');
        if (profileForm) {
            profileForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.saveProfile();
            });
        }

        const contactForm = document.getElementById('contactForm');
        if (contactForm) {
            contactForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.saveContact();
            });
        }

        const servicesForm = document.getElementById('servicesForm');
        if (servicesForm) {
            servicesForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.saveServices();
            });
        }

        const scheduleForm = document.getElementById('scheduleForm');
        if (scheduleForm) {
            scheduleForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.saveSchedule();
            });
        }

        // File upload events with automatic save
        const profileImageInput = document.getElementById('profileImageInput');
        if (profileImageInput) {
            profileImageInput.addEventListener('change', (e) => {
                this.handleProfileImageChange(e);
            });
        }

        const certificateInput = document.getElementById('certificateInput');
        if (certificateInput) {
            certificateInput.addEventListener('change', (e) => {
                this.handleCertificateUpload(e);
            });
        }

        // Profile image click to trigger file upload
        const profileImageContainer = document.querySelector('.profile-image-container');
        if (profileImageContainer) {
            profileImageContainer.addEventListener('click', () => {
                document.getElementById('profileImageInput')?.click();
            });
        }
    },

    /**
     * Load initial data from backend
     */
    async loadInitialData() {
        try {
            console.log('📥 Loading profile data...');
            
            const response = await fetch('/api/profile/clinic-data');
            const data = await response.json();
            
            if (response.ok && data.clinic) {
                this.currentData = data.clinic;
                this.populateAllForms(data.clinic);
                console.log('✅ Profile data loaded successfully');
            } else {
                console.warn('⚠️ No profile data found');
            }
        } catch (error) {
            console.error('❌ Error loading profile data:', error);
            Swal.fire({
                icon: 'warning',
                title: 'Data Loading Issue',
                text: 'Some profile data may not load correctly.',
                timer: 3000
            });
        }
    },

    /**
     * Populate all forms with data
     */
    populateAllForms(data) {
        // Profile form
        this.safeSetValue('clinicName', data.name || data.clinicName);
        this.safeSetValue('clinicEmail', data.email);
        this.safeSetValue('clinicAbout', data.about);
        this.safeSetValue('meetingDuration', data.meetingDuration || '30');

        // Contact form
        this.safeSetValue('clinicPhone', data.phone);
        this.safeSetValue('clinicAddress', data.address);
        this.safeSetValue('clinicSector', data.sector);
        this.safeSetValue('clinicLatitude', data.latitude);
        this.safeSetValue('clinicLongitude', data.longitude);

        // Services - handle both facilities and services fields
        const services = data.facilities || data.services || [];
        if (Array.isArray(services)) {
            document.querySelectorAll('.services-grid input[type="checkbox"]').forEach(checkbox => {
                checkbox.checked = services.includes(checkbox.value);
            });
        }

        // Profile image
        const imageUrl = data.profileImageUrl || data.imageUrl;
        if (imageUrl) {
            const profileImage = document.getElementById('profileImage');
            if (profileImage) {
                profileImage.src = imageUrl;
            }
        }

        // Update statistics
        this.updateStatistics();
    },

    /**
     * Safe value setter
     */
    safeSetValue(elementId, value) {
        const element = document.getElementById(elementId);
        if (element && value !== null && value !== undefined) {
            element.value = value;
        }
    },

    /**
     * Save profile section with SweetAlert feedback
     */
    async saveProfile() {
        try {
            const clinicName = document.getElementById('clinicName')?.value?.trim();
            const about = document.getElementById('clinicAbout')?.value?.trim();
            const meetingDuration = document.getElementById('meetingDuration')?.value;
            
            // Validation
            if (!clinicName) {
                Swal.fire({
                    icon: 'error',
                    title: 'Validation Error',
                    text: 'Clinic name is required'
                });
                return;
            }

            if (!about) {
                Swal.fire({
                    icon: 'error',
                    title: 'Validation Error',
                    text: 'Please provide information about your clinic'
                });
                return;
            }

            // Show loading
            Swal.fire({
                title: 'Saving Profile...',
                text: 'Please wait while we update your profile information.',
                allowOutsideClick: false,
                didOpen: () => {
                    Swal.showLoading();
                }
            });

            const response = await fetch('/api/profile/update', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    section: 'profile',
                    name: clinicName,
                    about: about,
                    meetingDuration: parseInt(meetingDuration) || 30
                })
            });

            const result = await response.json();
            
            if (result.success) {
                // Update current data
                this.currentData = { ...this.currentData, name: clinicName, about: about, meetingDuration: meetingDuration };
                
                // Update header clinic name if it exists
                const headerClinicName = document.querySelector('.clinic-name');
                if (headerClinicName) {
                    headerClinicName.textContent = clinicName;
                }

                Swal.fire({
                    icon: 'success',
                    title: 'Profile Updated!',
                    text: 'Your profile information has been saved successfully.',
                    timer: 2000,
                    showConfirmButton: false
                });
            } else {
                Swal.fire({
                    icon: 'error',
                    title: 'Update Failed',
                    text: result.message || 'Failed to update profile information'
                });
            }
        } catch (error) {
            console.error('Profile save error:', error);
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: 'An error occurred while saving your profile. Please try again.'
            });
        }
    },

    /**
     * Save contact information with SweetAlert feedback
     */
    async saveContact() {
        try {
            const phone = document.getElementById('clinicPhone')?.value?.trim();
            const address = document.getElementById('clinicAddress')?.value?.trim();
            const sector = document.getElementById('clinicSector')?.value;
            const latitude = document.getElementById('clinicLatitude')?.value;
            const longitude = document.getElementById('clinicLongitude')?.value;

            // Validation
            if (!phone) {
                Swal.fire({
                    icon: 'error',
                    title: 'Validation Error',
                    text: 'Phone number is required'
                });
                return;
            }

            if (!address) {
                Swal.fire({
                    icon: 'error',
                    title: 'Validation Error',
                    text: 'Address is required'
                });
                return;
            }

            // Show loading
            Swal.fire({
                title: 'Saving Contact Info...',
                text: 'Please wait while we update your contact information.',
                allowOutsideClick: false,
                didOpen: () => {
                    Swal.showLoading();
                }
            });

            const response = await fetch('/api/profile/update', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    section: 'contact',
                    phone: phone,
                    address: address,
                    sector: sector,
                    latitude: parseFloat(latitude) || null,
                    longitude: parseFloat(longitude) || null
                })
            });

            const result = await response.json();
            
            if (result.success) {
                this.currentData = { ...this.currentData, phone, address, sector, latitude, longitude };
                
                Swal.fire({
                    icon: 'success',
                    title: 'Contact Updated!',
                    text: 'Your contact information has been saved successfully.',
                    timer: 2000,
                    showConfirmButton: false
                });
            } else {
                Swal.fire({
                    icon: 'error',
                    title: 'Update Failed',
                    text: result.message || 'Failed to update contact information'
                });
            }
        } catch (error) {
            console.error('Contact save error:', error);
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: 'An error occurred while saving your contact information. Please try again.'
            });
        }
    },

    /**
     * Save services with SweetAlert feedback
     */
    async saveServices() {
        try {
            const checkedServices = [];
            document.querySelectorAll('.services-grid input[type="checkbox"]:checked').forEach(checkbox => {
                checkedServices.push(checkbox.value);
            });

            if (checkedServices.length === 0) {
                Swal.fire({
                    icon: 'warning',
                    title: 'No Services Selected',
                    text: 'Please select at least one service that your clinic provides.'
                });
                return;
            }

            // Show loading
            Swal.fire({
                title: 'Saving Services...',
                text: 'Please wait while we update your services.',
                allowOutsideClick: false,
                didOpen: () => {
                    Swal.showLoading();
                }
            });

            const response = await fetch('/api/profile/update', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    section: 'services',
                    services: checkedServices,
                    facilities: checkedServices  // For compatibility with Flutter app
                })
            });

            const result = await response.json();
            
            if (result.success) {
                this.currentData.services = checkedServices;
                this.currentData.facilities = checkedServices;
                
                Swal.fire({
                    icon: 'success',
                    title: 'Services Updated!',
                    text: `${checkedServices.length} services have been saved successfully.`,
                    timer: 2000,
                    showConfirmButton: false
                });

                this.updateStatistics();
            } else {
                Swal.fire({
                    icon: 'error',
                    title: 'Update Failed',
                    text: result.message || 'Failed to update services'
                });
            }
        } catch (error) {
            console.error('Services save error:', error);
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: 'An error occurred while saving your services. Please try again.'
            });
        }
    },

    /**
     * Handle profile image change with automatic upload
     */
    async handleProfileImageChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        // Validate file
        const maxSize = 5 * 1024 * 1024; // 5MB
        const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];

        if (!allowedTypes.includes(file.type)) {
            Swal.fire({
                icon: 'error',
                title: 'Invalid File Type',
                text: 'Please select a JPG or PNG image file.'
            });
            return;
        }

        if (file.size > maxSize) {
            Swal.fire({
                icon: 'error',
                title: 'File Too Large',
                text: 'Image file size must be less than 5MB.'
            });
            return;
        }

        // Show preview immediately
        const reader = new FileReader();
        reader.onload = (e) => {
            const profileImage = document.getElementById('profileImage');
            if (profileImage) {
                profileImage.src = e.target.result;
            }
        };
        reader.readAsDataURL(file);

        // Upload file
        this.uploadProfileImage(file);
    },

    /**
     * Upload profile image to server
     */
    async uploadProfileImage(file) {
        try {
            // Show loading
            Swal.fire({
                title: 'Uploading Image...',
                text: 'Please wait while we upload your profile image.',
                allowOutsideClick: false,
                didOpen: () => {
                    Swal.showLoading();
                }
            });

            const formData = new FormData();
            formData.append('profileImage', file);

            const response = await fetch('/api/profile/upload-image', {
                method: 'POST',
                body: formData,
                credentials: 'include'
            });

            const result = await response.json();
            
            if (result.success) {
                // Update header avatar if it exists
                const headerAvatar = document.getElementById('headerUserAvatar');
                if (headerAvatar && result.imageUrl) {
                    headerAvatar.src = result.imageUrl;
                }

                Swal.fire({
                    icon: 'success',
                    title: 'Image Uploaded!',
                    text: 'Your profile image has been updated successfully.',
                    timer: 2000,
                    showConfirmButton: false
                });
            } else {
                Swal.fire({
                    icon: 'error',
                    title: 'Upload Failed',
                    text: result.message || 'Failed to upload image'
                });
            }
        } catch (error) {
            console.error('Image upload error:', error);
            Swal.fire({
                icon: 'error',
                title: 'Upload Error',
                text: 'An error occurred while uploading your image. Please try again.'
            });
        }
    },

    /**
     * Get current location for address
     */
    getCurrentLocation() {
        if (!navigator.geolocation) {
            Swal.fire({
                icon: 'error',
                title: 'Geolocation Not Supported',
                text: 'Your browser does not support geolocation.'
            });
            return;
        }

        Swal.fire({
            title: 'Getting Location...',
            text: 'Please wait while we get your current location.',
            allowOutsideClick: false,
            didOpen: () => {
                Swal.showLoading();
            }
        });

        navigator.geolocation.getCurrentPosition(
            (position) => {
                const latitude = position.coords.latitude.toFixed(6);
                const longitude = position.coords.longitude.toFixed(6);
                
                document.getElementById('clinicLatitude').value = latitude;
                document.getElementById('clinicLongitude').value = longitude;
                
                Swal.fire({
                    icon: 'success',
                    title: 'Location Found!',
                    text: `Coordinates: ${latitude}, ${longitude}`,
                    timer: 2000,
                    showConfirmButton: false
                });
            },
            (error) => {
                console.error('Geolocation error:', error);
                Swal.fire({
                    icon: 'error',
                    title: 'Location Error',
                    text: 'Unable to get your location. Please enter coordinates manually.'
                });
            }
        );
    },

    /**
     * Update statistics display
     */
    updateStatistics() {
        // Update active services count
        const checkedServices = document.querySelectorAll('.services-grid input[type="checkbox"]:checked');
        const activeServicesElement = document.getElementById('activeServices');
        if (activeServicesElement) {
            activeServicesElement.textContent = checkedServices.length;
        }

        // Calculate profile completion
        let completedFields = 0;
        let totalFields = 8;

        if (document.getElementById('clinicName')?.value?.trim()) completedFields++;
        if (document.getElementById('clinicEmail')?.value?.trim()) completedFields++;
        if (document.getElementById('clinicAbout')?.value?.trim()) completedFields++;
        if (document.getElementById('clinicPhone')?.value?.trim()) completedFields++;
        if (document.getElementById('clinicAddress')?.value?.trim()) completedFields++;
        if (document.getElementById('clinicSector')?.value) completedFields++;
        if (checkedServices.length > 0) completedFields++;
        if (document.getElementById('profileImage')?.src && !document.getElementById('profileImage')?.src.includes('hospital.PNG')) completedFields++;

        const completionPercentage = Math.round((completedFields / totalFields) * 100);
        const profileCompletionElement = document.getElementById('profileCompletion');
        if (profileCompletionElement) {
            profileCompletionElement.textContent = `${completionPercentage}%`;
        }
    },

    /**
     * Save all settings at once
     */
    async saveAllSettings() {
        try {
            Swal.fire({
                title: 'Saving All Settings...',
                text: 'Please wait while we save all your settings.',
                allowOutsideClick: false,
                didOpen: () => {
                    Swal.showLoading();
                }
            });

            // Save all sections
            await Promise.all([
                this.saveProfile(),
                this.saveContact(),
                this.saveServices()
            ]);

            Swal.fire({
                icon: 'success',
                title: 'All Settings Saved!',
                text: 'All your settings have been saved successfully.',
                confirmButtonColor: '#159BBD'
            });
        } catch (error) {
            console.error('Error saving all settings:', error);
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: 'Failed to save some settings. Please check and try again.',
                confirmButtonColor: '#159BBD'
            });
        }
    },

    /**
     * Reset profile form
     */
    resetProfileForm() {
        Swal.fire({
            title: 'Reset Profile Form?',
            text: 'This will restore the form to the last saved values.',
            icon: 'question',
            showCancelButton: true,
            confirmButtonColor: '#159BBD',
            cancelButtonColor: '#6c757d',
            confirmButtonText: 'Yes, reset it!'
        }).then((result) => {
            if (result.isConfirmed) {
                this.populateAllForms(this.currentData);
                Swal.fire({
                    icon: 'info',
                    title: 'Form Reset',
                    text: 'Profile form has been reset to saved values.',
                    timer: 2000,
                    showConfirmButton: false
                });
            }
        });
    },

    /**
     * Change profile image trigger
     */
    changeProfileImage() {
        document.getElementById('profileImageInput')?.click();
    }
};

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
        settingsPage.init();
}); 

// Make it globally available
window.settingsPage = settingsPage; 