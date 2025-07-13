/**
 * Settings Page Management Module
 * Handles all settings page functionality with modern UI and professional interactions
 */
const settingsPage = {
    currentTab: 'profile',
    formData: {},
    uploadedFiles: {},

    /**
     * Initialize the settings page
     */
    async init() {
        console.log('🚀 Initializing Settings Page...');
        this.bindEvents();
        
        // Charger les données de manière asynchrone
        try {
            await this.loadSettingsData();
            await this.loadExistingDocuments();
            console.log('✅ Settings data loaded successfully');
        } catch (error) {
            console.error('❌ Error loading settings data:', error);
        }
        
        this.updateStatistics();
        this.setupTabNavigation();
        console.log('✅ Settings Page initialized');
    },

    /**
     * Bind all event listeners
     */
    bindEvents() {
        // Tab navigation
        document.querySelectorAll('[data-settings-tab]').forEach(button => {
            button.addEventListener('click', (e) => {
                this.switchTab(e.target.dataset.settingsTab);
            });
        });

        // Form submissions
        document.getElementById('profileForm')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.saveProfile();
        });

        document.getElementById('contactForm')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.saveContact();
        });

        document.getElementById('passwordForm')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.changePassword();
        });

        // File upload events
        document.getElementById('profileImageInput')?.addEventListener('change', (e) => {
            this.handleProfileImageChange(e);
        });

        document.getElementById('certificateInput')?.addEventListener('change', (e) => {
            this.handleCertificateUpload(e);
        });

        document.getElementById('idInput')?.addEventListener('change', (e) => {
            this.handleIdUpload(e);
        });

        document.getElementById('additionalInput')?.addEventListener('change', (e) => {
            this.handleAdditionalUpload(e);
        });

        // Drag and drop events
        this.setupDragAndDrop();
    },

    /**
     * Setup tab navigation
     */
    setupTabNavigation() {
        const tabButtons = document.querySelectorAll('[data-settings-tab]');
        tabButtons.forEach(button => {
            button.addEventListener('click', (e) => {
                // Remove active class from all buttons
                tabButtons.forEach(btn => btn.classList.remove('active'));
                // Add active class to clicked button
                e.target.classList.add('active');
                
                // Hide all tabs
                document.querySelectorAll('.settings-tab').forEach(tab => {
                    tab.classList.remove('active');
                });
                
                // Show selected tab
                const tabId = e.target.dataset.settingsTab;
                document.getElementById(`${tabId}-tab`)?.classList.add('active');
                
                this.currentTab = tabId;
            });
        });
    },

    /**
     * Switch to a specific tab
     */
    switchTab(tabName) {
        // Update button states
        document.querySelectorAll('[data-settings-tab]').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-settings-tab="${tabName}"]`)?.classList.add('active');

        // Update tab visibility
        document.querySelectorAll('.settings-tab').forEach(tab => {
            tab.classList.remove('active');
        });
        document.getElementById(`${tabName}-tab`)?.classList.add('active');

        this.currentTab = tabName;
    },

    /**
     * Load settings data from server
     */
    async loadSettingsData() {
        try {
            console.log('🔄 Loading settings data from server...');
            
            const response = await fetch('/api/settings/clinic-data', {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                }
            });

            console.log('📡 Response status:', response.status);

            if (response.ok) {
                const result = await response.json();
                console.log('📦 Response data:', result);
                
                if (result.success && result.clinicData) {
                    console.log('✅ Clinic data found, populating settings...');
                    this.populateSettings(result.clinicData);
                } else {
                    console.error('❌ No clinic data found in response');
                    // Essayer de charger les données depuis les champs existants
                    this.loadFromExistingFields();
                }
            } else {
                console.error('❌ Failed to load settings data, status:', response.status);
                // Essayer de charger les données depuis les champs existants
                this.loadFromExistingFields();
            }
        } catch (error) {
            console.error('❌ Error loading settings:', error);
            // Essayer de charger les données depuis les champs existants
            this.loadFromExistingFields();
        }
    },

    /**
     * Load data from existing form fields (fallback)
     */
    loadFromExistingFields() {
        console.log('🔄 Loading data from existing form fields...');
        
        // Récupérer les valeurs des champs existants
        const clinicNameField = document.getElementById('clinicName');
        const clinicAboutField = document.getElementById('clinicAbout');
        
        if (clinicNameField && clinicNameField.value) {
            console.log('📝 Found existing clinic name:', clinicNameField.value);
        }
        
        if (clinicAboutField && clinicAboutField.value) {
            console.log('📝 Found existing clinic about:', clinicAboutField.value);
        }
        
        // Mettre à jour les statistiques avec les données existantes
        this.updateStatistics();
    },

    /**
     * Populate settings forms with data
     */
    populateSettings(data) {
        console.log('🔄 Populating settings with data:', data);
        
        if (!data) {
            console.warn('⚠️ No data provided to populateSettings');
            return;
        }
        
        // Profile data - gérer les différents noms de champs possibles
        const clinicName = data.clinicName || data.name || data.hospitalName || '';
        const about = data.about || data.description || '';
        const meetingDuration = data.meetingDuration || '30';
        
        console.log('📝 Setting clinic name to:', clinicName);
        console.log('📝 Setting about to:', about);
        
        // S'assurer que les éléments existent avant de les modifier
        const clinicNameField = document.getElementById('clinicName');
        const clinicAboutField = document.getElementById('clinicAbout');
        const meetingDurationField = document.getElementById('meetingDuration');
        
        if (clinicNameField) {
            clinicNameField.value = clinicName;
            console.log('✅ Clinic name field updated');
        } else {
            console.error('❌ Clinic name field not found');
        }
        
        if (clinicAboutField) {
            clinicAboutField.value = about;
            console.log('✅ Clinic about field updated');
        } else {
            console.error('❌ Clinic about field not found');
        }
        
        if (meetingDurationField) {
            meetingDurationField.value = meetingDuration;
            console.log('✅ Meeting duration field updated');
        } else {
            console.error('❌ Meeting duration field not found');
        }
        
        // Profile image
        const profileImageField = document.getElementById('profileImage');
        if (profileImageField) {
            if (data.profileImageUrl) {
                profileImageField.src = data.profileImageUrl;
                console.log('🖼️ Setting profile image to:', data.profileImageUrl);
            } else {
                profileImageField.src = '/assets/hospital.PNG';
                console.log('🖼️ Using default profile image');
            }
        } else {
            console.error('❌ Profile image field not found');
        }
        
        // Contact data
        const contactFields = {
            'clinicPhone': data.phone || '',
            'clinicAddress': data.address || '',
            'clinicSector': data.sector || '',
            'clinicLatitude': data.latitude || '',
            'clinicLongitude': data.longitude || ''
        };
        
        Object.entries(contactFields).forEach(([fieldId, value]) => {
            const field = document.getElementById(fieldId);
            if (field) {
                field.value = value;
                console.log(`✅ ${fieldId} field updated with: ${value}`);
            } else {
                console.error(`❌ ${fieldId} field not found`);
            }
        });
        
        console.log('📞 Contact data set:', contactFields);
        
        // Services data
        if (Array.isArray(data.facilities)) {
            document.querySelectorAll('.services-grid input[type="checkbox"]').forEach(cb => {
                cb.checked = data.facilities.includes(cb.value);
            });
            console.log('🏥 Services set:', data.facilities);
        }
        
        // Schedule data
        if (data.availableSchedule) {
            Object.keys(data.availableSchedule).forEach(day => {
                const startInput = document.getElementById(`${day.toLowerCase()}Start`);
                const endInput = document.getElementById(`${day.toLowerCase()}End`);
                const sched = data.availableSchedule[day];
                if (startInput && sched.startTime) startInput.value = sched.startTime || sched.start || '';
                if (endInput && sched.endTime) endInput.value = sched.endTime || sched.end || '';
            });
            console.log('📅 Schedule set:', data.availableSchedule);
        }
        
        // Mettre à jour les statistiques
        this.updateStatistics();
        
        console.log('✅ Settings populated successfully');
    },

    /**
     * Update statistics display
     */
    updateStatistics() {
        // Calculate profile completion
        const profileFields = ['clinicName', 'clinicAbout', 'clinicPhone', 'clinicAddress'];
        const filledFields = profileFields.filter(field => {
            const element = document.getElementById(field);
            return element && element.value.trim() !== '';
        }).length;
        const completion = Math.round((filledFields / profileFields.length) * 100);
        
        document.getElementById('profileCompletion').textContent = `${completion}%`;

        // Count active services
        const activeServices = document.querySelectorAll('input[type="checkbox"]:checked').length;
        document.getElementById('activeServices').textContent = activeServices;

        // Count working days
        const workingDays = document.querySelectorAll('input[type="time"]').length;
        document.getElementById('workingDays').textContent = workingDays;

        // Security level (placeholder)
        document.getElementById('securityLevel').textContent = 'High';
    },

    /**
     * Save profile section
     */
    async saveProfile() {
        try {
            const clinicName = document.getElementById('clinicName').value;
            const about = document.getElementById('clinicAbout').value;
            const meetingDuration = document.getElementById('meetingDuration').value;
            
            // Vérifier si l'image de profil a été modifiée
            const profileImage = document.getElementById('profileImage');
            const currentImageSrc = profileImage.src;
            
            const res = await fetch('/api/settings/profile', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ clinicName, about, meetingDuration })
            });
            const result = await res.json();
            
            if (result.success) {
                // Si l'image a été modifiée (pas l'image par défaut), la sauvegarder aussi
                if (currentImageSrc && 
                    !currentImageSrc.includes('/assets/hospital.PNG') && 
                    !currentImageSrc.includes('via.placeholder.com')) {
                    await this.saveProfileImage(currentImageSrc);
                }
                
                Swal.fire('Saved!', 'Profile updated successfully.', 'success');
            } else {
                Swal.fire('Error', result.message || 'Failed to update profile', 'error');
            }
        } catch (e) {
            Swal.fire('Error', 'Failed to update profile', 'error');
        }
    },

    /**
     * Save contact section
     */
    async saveContact() {
        try {
            const phone = document.getElementById('clinicPhone').value;
            const address = document.getElementById('clinicAddress').value;
            const sector = document.getElementById('clinicSector').value;
            const latitude = document.getElementById('clinicLatitude').value;
            const longitude = document.getElementById('clinicLongitude').value;
            const res = await fetch('/api/settings/contact', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ phone, address, sector, latitude, longitude })
            });
            const result = await res.json();
            if (result.success) {
                Swal.fire('Saved!', 'Contact info updated successfully.', 'success');
            } else {
                Swal.fire('Error', result.message || 'Failed to update contact info', 'error');
            }
        } catch (e) {
            Swal.fire('Error', 'Failed to update contact info', 'error');
        }
    },

    /**
     * Save services section
     */
    async saveServices() {
        try {
            const facilities = Array.from(document.querySelectorAll('.services-grid input[type="checkbox"]:checked')).map(cb => cb.value);
            const res = await fetch('/api/settings/services', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ facilities })
            });
            const result = await res.json();
            if (result.success) {
                Swal.fire('Saved!', 'Services updated successfully.', 'success');
            } else {
                Swal.fire('Error', result.message || 'Failed to update services', 'error');
            }
        } catch (e) {
            Swal.fire('Error', 'Failed to update services', 'error');
        }
    },

    /**
     * Save schedule section
     */
    async saveSchedule() {
        try {
            const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
            const availableSchedule = {};
            days.forEach(day => {
                const start = document.getElementById(`${day.toLowerCase()}Start`)?.value || '';
                const end = document.getElementById(`${day.toLowerCase()}End`)?.value || '';
                availableSchedule[day] = { startTime: start, endTime: end };
            });
            const res = await fetch('/api/settings/schedule', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ availableSchedule })
            });
            const result = await res.json();
            if (result.success) {
                Swal.fire('Saved!', 'Schedule updated successfully.', 'success');
            } else {
                Swal.fire('Error', result.message || 'Failed to update schedule', 'error');
            }
        } catch (e) {
            Swal.fire('Error', 'Failed to update schedule', 'error');
        }
    },

    /**
     * Save documents
     */
    async saveDocuments() {
        try {
            const documentsToUpload = [];
            
            // Check which documents need to be uploaded
            if (this.uploadedFiles.certificate) {
                documentsToUpload.push({ type: 'certificate', file: this.uploadedFiles.certificate });
            }
            if (this.uploadedFiles.id) {
                documentsToUpload.push({ type: 'id', file: this.uploadedFiles.id });
            }
            if (this.uploadedFiles.additional) {
                documentsToUpload.push({ type: 'additional', file: this.uploadedFiles.additional });
            }

            if (documentsToUpload.length === 0) {
                Swal.fire({
                    icon: 'warning',
                    title: 'No Documents Selected',
                    text: 'Please select at least one document to upload.',
                    confirmButtonColor: '#159BBD'
                });
                return;
            }

            console.log(`📄 Uploading ${documentsToUpload.length} documents`);

            // Show progress dialog
            Swal.fire({
                title: 'Uploading Documents',
                html: 'Please wait while we upload your documents...<br><br><div class="progress-info">Starting upload...</div>',
                allowOutsideClick: false,
                showConfirmButton: false,
                didOpen: () => {
                    Swal.showLoading();
                }
            });

            const results = [];
            const errors = [];

            // Upload documents one by one for better error handling
            for (let i = 0; i < documentsToUpload.length; i++) {
                const { type, file } = documentsToUpload[i];
                
                try {
                    // Update progress
                    const progressInfo = document.querySelector('.progress-info');
                    if (progressInfo) {
                        progressInfo.innerHTML = `Uploading ${type} document (${i + 1}/${documentsToUpload.length})...<br>File: ${file.name} (${this.formatFileSize(file.size)})`;
                    }
                    
                    const result = await this.uploadSingleDocument(type, file);
                    results.push({ type, result });
                    
                } catch (error) {
                    console.error(`❌ Failed to upload ${type}:`, error);
                    errors.push({ type, error: error.message });
                }
            }

            // Close progress dialog
            Swal.close();

            // Show results
            if (errors.length === 0) {
                console.log(`✅ All documents uploaded successfully`);
                
                Swal.fire({
                    icon: 'success',
                    title: 'Documents Uploaded Successfully!',
                    html: `
                        <div class="success-details">
                            <p>All ${results.length} documents have been uploaded.</p>
                            <ul style="text-align: left; margin-top: 10px;">
                                ${results.map(r => `<li><strong>${r.type}</strong>: ${r.result.method === 'firebase-storage' ? 'Cloud Storage' : 'Database'}</li>`).join('')}
                            </ul>
                        </div>
                    `,
                    confirmButtonColor: '#159BBD',
                    timer: 5000,
                    timerProgressBar: true
                });
                
                // Reset form
                this.resetForm();
                
                // Reload documents
                this.loadExistingDocuments();
                
            } else if (results.length > 0) {
                console.log(`⚠️  Partial upload success: ${results.length} successful, ${errors.length} failed`);
                
                Swal.fire({
                    icon: 'warning',
                    title: 'Partial Upload Success',
                    html: `
                        <div class="partial-success">
                            <p><strong>Successful uploads:</strong> ${results.length}</p>
                            <p><strong>Failed uploads:</strong> ${errors.length}</p>
                            <div style="margin-top: 15px;">
                                <strong>Errors:</strong>
                                <ul style="text-align: left; margin-top: 5px;">
                                    ${errors.map(e => `<li><strong>${e.type}</strong>: ${e.error}</li>`).join('')}
                                </ul>
                            </div>
                        </div>
                    `,
                    confirmButtonColor: '#159BBD'
                });
                
                // Reload documents to show successful uploads
                this.loadExistingDocuments();
                
            } else {
                console.log(`❌ All uploads failed`);
                
                Swal.fire({
                    icon: 'error',
                    title: 'Upload Failed',
                    html: `
                        <div class="error-details">
                            <p>All document uploads failed:</p>
                            <ul style="text-align: left; margin-top: 10px;">
                                ${errors.map(e => `<li><strong>${e.type}</strong>: ${e.error}</li>`).join('')}
                            </ul>
                            <div style="margin-top: 15px; font-size: 14px; color: #666;">
                                <strong>Tips:</strong>
                                <ul style="text-align: left; margin-top: 5px;">
                                    <li>Ensure files are under 800KB</li>
                                    <li>Use JPG, PNG, or PDF format</li>
                                    <li>Check your internet connection</li>
                                </ul>
                            </div>
                        </div>
                    `,
                    confirmButtonColor: '#159BBD'
                });
            }

        } catch (error) {
            console.error('❌ Document upload error:', error);
            
            Swal.fire({
                icon: 'error',
                title: 'Upload Error',
                text: `An unexpected error occurred: ${error.message}`,
                confirmButtonColor: '#159BBD'
            });
        }
    },

    /**
     * Upload a single document with improved error handling
     */
    async uploadSingleDocument(documentType, file) {
        return new Promise((resolve, reject) => {
            console.log(`📄 Starting upload for ${documentType}`);
            console.log(`📄 File: ${file.name}, Size: ${this.formatFileSize(file.size)}`);
            
            // Validate file first
            const validation = this.validateFile(file);
            if (!validation.valid) {
                console.log(`❌ File validation failed: ${validation.message}`);
                reject(new Error(validation.message));
                return;
            }
            
            const reader = new FileReader();
            reader.onload = async (e) => {
                try {
                    const documentData = {
                        fileName: file.name,
                        fileType: file.type,
                        fileSize: file.size,
                        fileData: e.target.result,
                        uploadedAt: new Date().toISOString()
                    };

                    console.log(`📤 Sending upload request for ${documentType}`);
                    
                    const response = await fetch('/api/settings/upload-document', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            documentType: documentType,
                            documentData: documentData
                        })
                    });

                    console.log(`📥 Upload response status: ${response.status}`);
                    const result = await response.json();
                    console.log(`📥 Upload response:`, result);

                    if (result.success) {
                        console.log(`✅ ${documentType} uploaded successfully`);
                        console.log(`📄 Upload method: ${result.method}`);
                        resolve(result);
                    } else {
                        console.error(`❌ Upload failed: ${result.message}`);
                        reject(new Error(result.message));
                    }
                } catch (error) {
                    console.error(`❌ Upload error for ${documentType}:`, error);
                    reject(new Error(`Failed to upload ${documentType}: ${error.message}`));
                }
            };
            
            reader.onerror = (error) => {
                console.error(`❌ FileReader error:`, error);
                reject(new Error('Failed to read file'));
            };
            
            reader.readAsDataURL(file);
        });
    },

    /**
     * Change password
     */
    async changePassword() {
        try {
            const currentPassword = document.getElementById('currentPassword').value;
            const newPassword = document.getElementById('newPassword').value;
            const confirmPassword = document.getElementById('confirmPassword').value;

            if (newPassword !== confirmPassword) {
                Swal.fire({
                    icon: 'error',
                    title: 'Password Mismatch',
                    text: 'New password and confirm password do not match.',
                    confirmButtonColor: '#159BBD'
                });
                return;
            }

            const response = await fetch('/api/clinic/password', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    currentPassword,
                    newPassword
                })
            });

            if (response.ok) {
                Swal.fire({
                    icon: 'success',
                    title: 'Password Changed!',
                    text: 'Your password has been changed successfully.',
                    confirmButtonColor: '#159BBD'
                });
                this.resetPasswordForm();
            } else {
                throw new Error('Failed to change password');
            }
        } catch (error) {
            console.error('Error changing password:', error);
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: 'Failed to change password. Please try again.',
                confirmButtonColor: '#159BBD'
            });
        }
    },

    /**
     * Save security settings
     */
    async saveSecuritySettings() {
        try {
            const settings = {
                twoFactorAuth: document.getElementById('twoFactorAuth').checked,
                emailNotifications: document.getElementById('emailNotifications').checked,
                smsNotifications: document.getElementById('smsNotifications').checked
            };

            const response = await fetch('/api/clinic/security', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(settings)
            });

            if (response.ok) {
                Swal.fire({
                    icon: 'success',
                    title: 'Security Updated!',
                    text: 'Your security settings have been saved successfully.',
                    confirmButtonColor: '#159BBD'
                });
            } else {
                throw new Error('Failed to save security settings');
            }
        } catch (error) {
            console.error('Error saving security settings:', error);
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: 'Failed to save security settings. Please try again.',
                confirmButtonColor: '#159BBD'
            });
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

            // Save all forms
            await Promise.all([
                this.saveProfile(),
                this.saveContact(),
                this.saveServices(),
                this.saveSchedule(),
                this.saveSecuritySettings()
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
     * Get current location
     */
    getCurrentLocation() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    document.getElementById('clinicLatitude').value = position.coords.latitude.toFixed(6);
                    document.getElementById('clinicLongitude').value = position.coords.longitude.toFixed(6);
                    
                    Swal.fire({
                        icon: 'success',
                        title: 'Location Updated!',
                        text: 'Your current location has been set.',
                        confirmButtonColor: '#159BBD'
                    });
                },
                (error) => {
                    console.error('Error getting location:', error);
                    Swal.fire({
                        icon: 'error',
                        title: 'Location Error',
                        text: 'Unable to get your current location. Please enter manually.',
                        confirmButtonColor: '#159BBD'
                    });
                }
            );
        } else {
            Swal.fire({
                icon: 'error',
                title: 'Not Supported',
                text: 'Geolocation is not supported by this browser.',
                confirmButtonColor: '#159BBD'
            });
        }
    },

    /**
     * Change profile image
     */
    changeProfileImage() {
        document.getElementById('profileImageInput').click();
    },

    /**
     * Handle profile image change
     */
    handleProfileImageChange(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (e) => {
                const imageData = e.target.result;
                document.getElementById('profileImage').src = imageData;
                // Sauvegarder automatiquement l'image dans Firebase
                this.saveProfileImage(imageData);
            };
            reader.readAsDataURL(file);
        }
    },

    /**
     * Save profile image to Firebase
     */
    async saveProfileImage(imageData) {
        try {
            console.log('🖼️ Saving profile image...');
            console.log('Image data length:', imageData.length);
            
            // Vérifier la taille de l'image (limiter à 5MB)
            if (imageData.length > 5 * 1024 * 1024) {
                Swal.fire({
                    icon: 'error',
                    title: 'Image trop grande',
                    text: 'L\'image doit faire moins de 5MB. Veuillez choisir une image plus petite.',
                    confirmButtonColor: '#159BBD'
                });
                return;
            }

            const response = await fetch('/api/settings/profile-image', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ profileImageUrl: imageData })
            });

            console.log('Response status:', response.status);
            console.log('Response ok:', response.ok);

            if (!response.ok) {
                const errorText = await response.text();
                console.error('Server error response:', errorText);
                throw new Error(`Server error: ${response.status} ${response.statusText}`);
            }

            const result = await response.json();
            console.log('Response result:', result);

            if (result.success) {
                console.log('✅ Profile image saved successfully');
                // Mettre à jour aussi l'image dans l'en-tête si elle existe
                const headerImage = document.getElementById('headerUserAvatar');
                if (headerImage) {
                    headerImage.src = imageData;
                }
                
                // Afficher un message de succès
                Swal.fire({
                    icon: 'success',
                    title: 'Image sauvegardée !',
                    text: 'Votre image de profil a été mise à jour avec succès.',
                    confirmButtonColor: '#159BBD',
                    timer: 2000,
                    showConfirmButton: false
                });
            } else {
                console.error('Failed to save profile image:', result.message);
                Swal.fire({
                    icon: 'error',
                    title: 'Erreur',
                    text: result.message || 'Échec de la sauvegarde de l\'image de profil. Veuillez réessayer.',
                    confirmButtonColor: '#159BBD'
                });
            }
        } catch (error) {
            console.error('❌ Error saving profile image:', error);
            Swal.fire({
                icon: 'error',
                title: 'Erreur de connexion',
                text: 'Impossible de sauvegarder l\'image. Vérifiez votre connexion et réessayez.',
                confirmButtonColor: '#159BBD'
            });
        }
    },

    /**
     * Validate file before upload
     */
    validateFile(file) {
        const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'application/pdf'];
        const maxSize = 800 * 1024; // 800KB limit
        
        console.log(`📄 Validating file: ${file.name}`);
        console.log(`📄 File type: ${file.type}`);
        console.log(`📄 File size: ${file.size} bytes`);
        
        if (!allowedTypes.includes(file.type)) {
            console.log(`❌ Invalid file type: ${file.type}`);
            return {
                valid: false,
                message: 'Invalid file type. Only PDF, JPG, JPEG, and PNG files are allowed.'
            };
        }
        
        if (file.size > maxSize) {
            console.log(`❌ File too large: ${file.size} bytes > ${maxSize} bytes`);
            return {
                valid: false,
                message: `File size exceeds 800KB limit. Current size: ${this.formatFileSize(file.size)}. Please reduce the file size.`
            };
        }
        
        console.log(`✅ File validation passed`);
        return {
            valid: true,
            message: 'File is valid'
        };
    },

    /**
     * Format file size for display
     */
    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    },

    /**
     * Upload certificate
     */
    uploadCertificate() {
        document.getElementById('certificateInput').click();
    },

    /**
     * Handle certificate upload
     */
    handleCertificateUpload(event) {
        const file = event.target.files[0];
        if (file && this.validateFile(file).valid) {
            this.uploadedFiles.certificate = file;
            document.getElementById('certificateFileName').textContent = file.name;
            document.getElementById('certificateFileInfo').style.display = 'block';
            document.getElementById('certificateStatus').textContent = 'Uploaded';
            document.getElementById('certificateStatus').className = 'badge bg-success';
        }
    },

    /**
     * Remove certificate
     */
    removeCertificate() {
        delete this.uploadedFiles.certificate;
        document.getElementById('certificateFileInfo').style.display = 'none';
        document.getElementById('certificateStatus').textContent = 'Pending';
        document.getElementById('certificateStatus').className = 'badge bg-warning';
        document.getElementById('certificateInput').value = '';
    },

    /**
     * Upload ID
     */
    uploadId() {
        document.getElementById('idInput').click();
    },

    /**
     * Handle ID upload
     */
    handleIdUpload(event) {
        const file = event.target.files[0];
        if (file && this.validateFile(file).valid) {
            this.uploadedFiles.id = file;
            document.getElementById('idFileName').textContent = file.name;
            document.getElementById('idFileInfo').style.display = 'block';
            document.getElementById('idStatus').textContent = 'Uploaded';
            document.getElementById('idStatus').className = 'badge bg-success';
        }
    },

    /**
     * Remove ID
     */
    removeId() {
        delete this.uploadedFiles.id;
        document.getElementById('idFileInfo').style.display = 'none';
        document.getElementById('idStatus').textContent = 'Pending';
        document.getElementById('idStatus').className = 'badge bg-warning';
        document.getElementById('idInput').value = '';
    },

    /**
     * Upload additional document
     */
    uploadAdditional() {
        document.getElementById('additionalInput').click();
    },

    /**
     * Handle additional document upload
     */
    handleAdditionalUpload(event) {
        const file = event.target.files[0];
        if (file && this.validateFile(file).valid) {
            this.uploadedFiles.additional = file;
            document.getElementById('additionalFileName').textContent = file.name;
            document.getElementById('additionalFileInfo').style.display = 'block';
            document.getElementById('additionalStatus').textContent = 'Uploaded';
            document.getElementById('additionalStatus').className = 'badge bg-success';
        }
    },

    /**
     * Remove additional document
     */
    removeAdditional() {
        delete this.uploadedFiles.additional;
        document.getElementById('additionalFileInfo').style.display = 'none';
        document.getElementById('additionalStatus').textContent = 'Pending';
        document.getElementById('additionalStatus').className = 'badge bg-warning';
        document.getElementById('additionalInput').value = '';
    },

    /**
     * Preview a specific document
     */
    async previewDocument(documentType) {
        const documents = await this.getExistingDocuments();
        const document = documents[documentType];
        
        if (!document) {
        Swal.fire({
                icon: 'warning',
                title: 'No Document Found',
                text: 'This document has not been uploaded yet.',
                confirmButtonColor: '#159BBD'
            });
            return;
        }
        
        this.showDocumentPreviewModal(document, documentType);
    },

    /**
     * Preview all documents
     */
    async previewAllDocuments() {
        const documents = await this.getExistingDocuments();
        const documentTypes = ['certificate', 'id', 'additional'];
        const availableDocuments = documentTypes.filter(type => documents[type]);
        
        if (availableDocuments.length === 0) {
            Swal.fire({
            icon: 'info',
                title: 'No Documents',
                text: 'No documents have been uploaded yet.',
                confirmButtonColor: '#159BBD'
            });
            return;
        }
        
        let htmlContent = '<div class="text-start">';
        availableDocuments.forEach(type => {
            const doc = documents[type];
            const typeName = type === 'certificate' ? 'Hospital Certificate' : 
                           type === 'id' ? 'ID/Passport' : 'Additional Document';
            htmlContent += `
                <div class="mb-3 p-3 border rounded">
                    <h6><i class="fas fa-file me-2"></i>${typeName}</h6>
                    <p class="mb-1"><strong>File:</strong> ${doc.fileName}</p>
                    <p class="mb-1"><strong>Size:</strong> ${this.formatFileSize(doc.fileSize)}</p>
                    <p class="mb-1"><strong>Type:</strong> ${doc.fileType}</p>
                    <button class="btn btn-sm btn-outline-primary" onclick="settingsPage.previewDocument('${type}')">
                        <i class="fas fa-eye me-1"></i>Preview
                    </button>
                </div>
            `;
        });
        htmlContent += '</div>';
        
        Swal.fire({
            title: 'Document Overview',
            html: htmlContent,
            width: '600px',
            confirmButtonColor: '#159BBD'
        });
    },

    /**
     * Show document preview modal
     */
    showDocumentPreviewModal(document, documentType) {
        const modal = document.getElementById('documentPreviewModal');
        const modalTitle = modal.querySelector('#documentPreviewModalLabel');
        const fileName = modal.querySelector('#previewFileName');
        const fileType = modal.querySelector('#previewFileType');
        const fileSize = modal.querySelector('#previewFileSize');
        const iframe = modal.querySelector('#documentPreviewIframe');
        const imageDiv = modal.querySelector('#documentPreviewImage');
        const image = modal.querySelector('#documentPreviewImg');
        const downloadBtn = modal.querySelector('#downloadDocumentBtn');
        const loader = modal.querySelector('#documentPreviewLoader');
        const content = modal.querySelector('#documentPreviewContent');
        
        // Set document info
        const typeName = documentType === 'certificate' ? 'Hospital Certificate' : 
                        documentType === 'id' ? 'ID/Passport' : 'Additional Document';
        modalTitle.textContent = `${typeName} Preview`;
        fileName.textContent = document.fileName;
        fileType.textContent = document.fileType;
        fileSize.textContent = this.formatFileSize(document.fileSize);
        
        // Show loader
        loader.style.display = 'block';
        content.style.display = 'none';
        
        // Set download button
        downloadBtn.onclick = () => {
            const link = document.createElement('a');
            link.href = document.downloadURL;
            link.download = document.fileName;
            link.click();
        };
        
        // Load document
        if (document.fileType === 'application/pdf') {
            iframe.src = document.downloadURL;
            iframe.style.display = 'block';
            imageDiv.style.display = 'none';
        } else {
            image.src = document.downloadURL;
            iframe.style.display = 'none';
            imageDiv.style.display = 'block';
        }
        
        // Hide loader and show content
        setTimeout(() => {
            loader.style.display = 'none';
            content.style.display = 'block';
        }, 1000);
        
        // Show modal
        const bootstrapModal = new bootstrap.Modal(modal);
        bootstrapModal.show();
    },

    /**
     * Format file size for display
     */
    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    },

    /**
     * Get existing documents from server
     */
    async getExistingDocuments() {
        try {
            const response = await fetch('/api/settings/get-documents');
            if (response.ok) {
                const result = await response.json();
                return result.documents || {};
            }
        } catch (error) {
            console.error('Error getting documents:', error);
        }
        return {};
    },

    /**
     * Load existing documents and populate UI
     */
    async loadExistingDocuments() {
        try {
            const documents = await this.getExistingDocuments();
            
            // Update UI for each document type
            Object.keys(documents).forEach(documentType => {
                const doc = documents[documentType];
                if (doc && doc.fileName) {
                    this.populateDocumentUI(documentType, doc);
                }
            });
        } catch (error) {
            console.error('Error loading existing documents:', error);
        }
    },

    /**
     * Populate document UI with existing document info
     */
    populateDocumentUI(documentType, docData) {
        const fileNameElement = document.getElementById(`${documentType}FileName`);
        const fileInfoElement = document.getElementById(`${documentType}FileInfo`);
        const statusElement = document.getElementById(`${documentType}Status`);
        
        if (fileNameElement && fileInfoElement && statusElement) {
            fileNameElement.textContent = docData.fileName;
            fileInfoElement.style.display = 'block';
            statusElement.textContent = 'Uploaded';
            statusElement.className = 'badge bg-success';
        }
    },

    /**
     * Logout all devices
     */
    logoutAllDevices() {
        Swal.fire({
            title: 'Logout All Devices?',
            text: 'This will log you out from all devices. You will need to log in again.',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d33',
            cancelButtonColor: '#3085d6',
            confirmButtonText: 'Yes, logout all devices'
        }).then((result) => {
            if (result.isConfirmed) {
                // Implement logout all devices functionality
                Swal.fire({
                    icon: 'success',
                    title: 'Logged Out!',
                    text: 'You have been logged out from all devices.',
                    confirmButtonColor: '#159BBD'
                }).then(() => {
                    window.location.href = '/logout';
                });
            }
        });
    },

    /**
     * Setup drag and drop functionality
     */
    setupDragAndDrop() {
        const uploadAreas = ['certificateUploadArea', 'idUploadArea', 'additionalUploadArea'];
        
        uploadAreas.forEach(areaId => {
            const area = document.getElementById(areaId);
            if (area) {
                area.addEventListener('dragover', (e) => {
                    e.preventDefault();
                    area.classList.add('drag-over');
                });

                area.addEventListener('dragleave', (e) => {
                    e.preventDefault();
                    area.classList.remove('drag-over');
                });

                area.addEventListener('drop', (e) => {
                    e.preventDefault();
                    area.classList.remove('drag-over');
                    
                    const files = e.dataTransfer.files;
                    if (files.length > 0) {
                        const file = files[0];
                        if (areaId === 'certificateUploadArea') {
                            this.handleCertificateUpload({ target: { files: [file] } });
                        } else if (areaId === 'idUploadArea') {
                            this.handleIdUpload({ target: { files: [file] } });
                        } else if (areaId === 'additionalUploadArea') {
                            this.handleAdditionalUpload({ target: { files: [file] } });
                        }
                    }
                });
            }
        });
    },

    /**
     * Reset profile form
     */
    resetProfileForm() {
        // Sauvegarder l'image de profil actuelle
        const profileImage = document.getElementById('profileImage');
        const currentImageSrc = profileImage.src;
        
        // Réinitialiser le formulaire
        document.getElementById('profileForm').reset();
        
        // Restaurer l'image de profil
        if (currentImageSrc) {
            profileImage.src = currentImageSrc;
        }
        
        Swal.fire({
            icon: 'info',
            title: 'Form Reset',
            text: 'Profile form has been reset to default values.',
            confirmButtonColor: '#159BBD'
        });
    },

    /**
     * Reset contact form
     */
    resetContactForm() {
        document.getElementById('contactForm').reset();
        Swal.fire({
            icon: 'info',
            title: 'Form Reset',
            text: 'Contact form has been reset to default values.',
            confirmButtonColor: '#159BBD'
        });
    },

    /**
     * Reset services
     */
    resetServices() {
        document.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
            checkbox.checked = false;
        });
        Swal.fire({
            icon: 'info',
            title: 'Services Reset',
            text: 'All services have been unchecked.',
            confirmButtonColor: '#159BBD'
        });
    },

    /**
     * Reset schedule
     */
    resetSchedule() {
        // Reset all time inputs to default values
        const defaultTimes = {
            monday: { start: '08:00', end: '17:00' },
            tuesday: { start: '08:00', end: '17:00' },
            wednesday: { start: '08:00', end: '17:00' },
            thursday: { start: '08:00', end: '17:00' },
            friday: { start: '08:00', end: '17:00' },
            saturday: { start: '09:00', end: '15:00' }
        };

        Object.keys(defaultTimes).forEach(day => {
            const startInput = document.getElementById(`${day}Start`);
            const endInput = document.getElementById(`${day}End`);
            if (startInput) startInput.value = defaultTimes[day].start;
            if (endInput) endInput.value = defaultTimes[day].end;
        });

        // Reset other schedule inputs
        document.getElementById('breakStart').value = '12:00';
        document.getElementById('breakEnd').value = '13:00';
        document.getElementById('appointmentInterval').value = '30';
        document.getElementById('maxAppointments').value = '20';

        Swal.fire({
            icon: 'info',
            title: 'Schedule Reset',
            text: 'Schedule has been reset to default values.',
            confirmButtonColor: '#159BBD'
        });
    },

    /**
     * Reset password form
     */
    resetPasswordForm() {
        document.getElementById('passwordForm').reset();
        Swal.fire({
            icon: 'info',
            title: 'Form Reset',
            text: 'Password form has been reset.',
            confirmButtonColor: '#159BBD'
        });
    },

    /**
     * Refresh settings data
     */
    refresh() {
        this.loadSettingsData();
        this.updateStatistics();
        Swal.fire({
            icon: 'success',
            title: 'Settings Refreshed!',
            text: 'Settings data has been refreshed successfully.',
            confirmButtonColor: '#159BBD'
        });
    }
};

// Initialize settings page when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    if (document.getElementById('settings-content')) {
        settingsPage.init();
    }
}); 