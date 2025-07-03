/**
 * Profile Editor - Handles all profile editing functionality
 * Including form submission, file uploads, validation, and user feedback
 */

class ProfileEditor {
    constructor() {
        this.currentProfileData = {};
        this.uploadedFiles = {
            profileImage: null,
            certificate: null
        };
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.setupDragAndDrop();
        this.initializeAvailability();
        this.loadProfileData();
        this.updateServicesCount();
        console.log('🚀 ProfileEditor initialized with tabbed interface');
    }

    setupEventListeners() {
        // Tab-specific form handlers
        const generalInfoForm = document.getElementById('generalInfoForm');
        const contactInfoForm = document.getElementById('contactInfoForm');
        const servicesForm = document.getElementById('servicesForm');
        
        if (generalInfoForm) {
            generalInfoForm.addEventListener('submit', (e) => this.handleGeneralInfoSubmit(e));
        }
        
        if (contactInfoForm) {
            contactInfoForm.addEventListener('submit', (e) => this.handleContactInfoSubmit(e));
        }
        
        if (servicesForm) {
            servicesForm.addEventListener('submit', (e) => this.handleServicesSubmit(e));
        }

        // File upload handlers with automatic upload
        const profileImageInput = document.getElementById('profileImageInput');
        const certificateInput = document.getElementById('certificateInput');
        
        if (profileImageInput) {
            profileImageInput.addEventListener('change', (e) => this.handleProfileImageChange(e));
        }
        
        if (certificateInput) {
            certificateInput.addEventListener('change', (e) => this.handleCertificateChange(e));
        }

        // Services checkboxes
        const serviceCheckboxes = document.querySelectorAll('input[name="services"]');
        serviceCheckboxes.forEach(checkbox => {
            checkbox.addEventListener('change', () => this.updateServicesCount());
        });

        // Tab switching handlers
        const tabLinks = document.querySelectorAll('[data-bs-toggle="tab"]');
        tabLinks.forEach(tab => {
            tab.addEventListener('shown.bs.tab', (e) => this.handleTabSwitch(e));
        });
    }

    handleTabSwitch(event) {
        const targetTab = event.target.getAttribute('data-bs-target');
        console.log('📋 Switched to tab:', targetTab);
        
        // Update URL hash for better navigation
        if (targetTab) {
            window.location.hash = targetTab.replace('#', '');
        }
    }

    async handleGeneralInfoSubmit(event) {
        event.preventDefault();
        console.log('💾 Saving general info...');

        const formData = new FormData(event.target);
        const data = Object.fromEntries(formData.entries());

        // Map form fields to expected API fields
        const mappedData = {
            name: data.profileClinicName,
            email: data.profileClinicEmail,
            type: data.profileClinicType,
            establishedYear: data.profileEstablishedYear,
            about: data.profileClinicAbout
        };

        try {
            const response = await fetch('/api/profile/update', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ section: 'general', ...mappedData })
            });

            const result = await response.json();
            
            if (response.ok) {
                this.showSuccessMessage('General information updated successfully!');
                this.currentProfileData = { ...this.currentProfileData, ...mappedData };
            } else {
                this.showErrorMessage(result.message || 'Error updating general information');
            }
        } catch (error) {
            console.error('General info update error:', error);
            this.showErrorMessage('Error updating general information');
        }
    }

    async handleContactInfoSubmit(event) {
        event.preventDefault();
        console.log('📞 Saving contact info...');

        const formData = new FormData(event.target);
        const data = Object.fromEntries(formData.entries());

        // Map form fields to expected API fields
        const mappedData = {
            phone: data.profileClinicPhone,
            website: data.profileClinicWebsite,
            address: data.profileClinicAddress,
            sector: data.profileClinicSector,
            city: data.profileClinicCity,
            state: data.profileClinicState,
            country: data.profileClinicCountry
        };

        // Validate required fields
        const requiredFields = ['phone', 'address', 'city', 'country'];
        const missingFields = requiredFields.filter(field => !mappedData[field]);
        
        if (missingFields.length > 0) {
            this.showErrorMessage(`Please fill in required fields: ${missingFields.join(', ')}`);
            return;
        }

        try {
            const response = await fetch('/api/profile/update', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ section: 'contact', ...mappedData })
            });

            const result = await response.json();
            
            if (response.ok) {
                this.showSuccessMessage('Contact information updated successfully!');
                this.currentProfileData = { ...this.currentProfileData, ...mappedData };
            } else {
                this.showErrorMessage(result.message || 'Error updating contact information');
            }
        } catch (error) {
            console.error('Contact info update error:', error);
            this.showErrorMessage('Error updating contact information');
        }
    }

    async handleServicesSubmit(event) {
        event.preventDefault();
        console.log('🏥 Saving services...');

        const formData = new FormData(event.target);
        const services = formData.getAll('services');

        try {
            const response = await fetch('/api/profile/update', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ section: 'services', services })
            });

            const result = await response.json();
            
            if (response.ok) {
                this.showSuccessMessage(`Services updated successfully! (${services.length} services selected)`);
                this.currentProfileData.services = services;
                this.updateServicesCount();
            } else {
                this.showErrorMessage(result.message || 'Error updating services');
            }
        } catch (error) {
            console.error('Services update error:', error);
            this.showErrorMessage('Error updating services');
        }
    }

    async handleProfileImageChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        if (!this.validateImageFile(file)) return;

        // Show preview immediately
        this.showImagePreview(file);
        
        // Upload automatically
        this.uploadProfileImageFile(file);
    }

    async uploadProfileImageFile(file) {
        const formData = new FormData();
        formData.append('profileImage', file);

        // Show loading
        this.showLoadingMessage('Uploading profile image...');

        try {
            const response = await fetch('/api/profile/upload-image', {
                method: 'POST',
                body: formData,
                credentials: 'include'
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.message || `Server error: ${response.status}`);
            }

            const result = await response.json();
            console.log('✅ Upload successful:', result);
            
            this.showSuccessMessage('Profile image uploaded successfully!');
            
            // Update the display image
            const displayImage = document.getElementById('profileDisplayImage');
            if (displayImage && result.imageUrl) {
                displayImage.src = result.imageUrl;
            }

            // Update header avatar if it exists
            const headerAvatar = document.getElementById('headerUserAvatar');
            if (headerAvatar && result.imageUrl) {
                headerAvatar.src = result.imageUrl;
            }
            
        } catch (error) {
            console.error('❌ Photo upload error:', error);
            this.showErrorMessage(error.message || 'Failed to upload image');
        }
    }

    validateImageFile(file) {
        const maxSize = 5 * 1024 * 1024; // 5MB
        const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];

        if (!allowedTypes.includes(file.type)) {
            this.showErrorMessage('Please select a valid image file (JPG, PNG)');
            return false;
        }

        if (file.size > maxSize) {
            this.showErrorMessage('Image file size must be less than 5MB');
            return false;
        }

        return true;
    }

    showImagePreview(file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            const previewImage = document.getElementById('profileDisplayImage');
            if (previewImage) {
                previewImage.src = e.target.result;
            }
        };
        reader.readAsDataURL(file);
    }

    handleCertificateChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        if (!this.validateCertificateFile(file)) return;

        console.log('📄 Certificate file selected:', file.name);
        this.uploadedFiles.certificate = file;
        
        // Upload automatically
        this.uploadCertificateFile(file);
    }

    async uploadCertificateFile(file) {
        const formData = new FormData();
        formData.append('certificate', file);

        // Show loading
        this.showLoadingMessage('Uploading certificate...');

        try {
            const response = await fetch('/api/profile/upload-certificate', {
                method: 'POST',
                body: formData,
                credentials: 'include'
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.message || `Server error: ${response.status}`);
            }

            const result = await response.json();
            console.log('✅ Certificate upload successful:', result);
            
            this.showSuccessMessage('Certificate uploaded successfully!');
            
            // Show current certificate section
            const currentCertDiv = document.getElementById('currentCertificate');
            const certLink = document.getElementById('currentCertLink');
            
            if (currentCertDiv && certLink && result.certificateUrl) {
                certLink.href = result.certificateUrl;
                currentCertDiv.style.display = 'block';
            }
            
        } catch (error) {
            console.error('❌ Certificate upload error:', error);
            this.showErrorMessage(error.message || 'Failed to upload certificate');
        }
    }

    validateCertificateFile(file) {
        const maxSize = 10 * 1024 * 1024; // 10MB
        const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg'];

        if (!allowedTypes.includes(file.type)) {
            this.showErrorMessage('Please select a valid file (PDF, JPG, PNG)');
            return false;
        }

        if (file.size > maxSize) {
            this.showErrorMessage('File size must be less than 10MB');
            return false;
        }

        return true;
    }

    async loadProfileData() {
        try {
            const response = await fetch('/api/profile/clinic-data');
            const data = await response.json();
            
            if (response.ok && data.clinic) {
                this.currentProfileData = data.clinic;
                this.populateForm(data.clinic);
                console.log('✅ Profile data loaded successfully');
            }
        } catch (error) {
            console.error('❌ Error loading profile data:', error);
        }
    }

    populateForm(profile) {
        // General Info
        this.safeSetValue('profileClinicName', profile.name);
        this.safeSetValue('profileClinicEmail', profile.email);
        this.safeSetValue('profileClinicType', profile.type);
        this.safeSetValue('profileEstablishedYear', profile.establishedYear);
        this.safeSetValue('profileClinicAbout', profile.about);

        // Contact Info
        this.safeSetValue('profileClinicPhone', profile.phone);
        this.safeSetValue('profileClinicWebsite', profile.website);
        this.safeSetValue('profileClinicAddress', profile.address);
        this.safeSetValue('profileClinicSector', profile.sector);
        this.safeSetValue('profileClinicCity', profile.city);
        this.safeSetValue('profileClinicState', profile.state);
        this.safeSetValue('profileClinicCountry', profile.country);

        // Services
        if (profile.services && Array.isArray(profile.services)) {
            profile.services.forEach(service => {
                const checkbox = document.querySelector(`input[name="services"][value="${service}"]`);
                if (checkbox) {
                    checkbox.checked = true;
                }
            });
        }

        // Availability
        if (profile.availability) {
            const { workingDays, startTime, endTime, appointmentDuration } = profile.availability;
            
            // Set working days
            if (workingDays && Array.isArray(workingDays)) {
                workingDays.forEach(day => {
                    const checkbox = document.querySelector(`input[name="workingDays"][value="${day}"]`);
                    if (checkbox) {
                        checkbox.checked = true;
                    }
                });
            }
            
            // Set times
            this.safeSetValue('startTime', startTime || '08:00');
            this.safeSetValue('endTime', endTime || '17:00');
            this.safeSetValue('appointmentDuration', appointmentDuration || 30);
            
            this.updateAvailabilitySummary();
        }

        // Profile Image - multiple possible field names
        const imageUrl = profile.profileImageUrl || profile.imageUrl || profile.image || profile.profileImage;
        if (imageUrl) {
            const imageElement = document.getElementById('profileDisplayImage');
            if (imageElement) {
                imageElement.src = imageUrl;
            }
        }

        this.updateServicesCount();
    }

    updateServicesCount() {
        const checkedServices = document.querySelectorAll('input[name="services"]:checked');
        const countElement = document.getElementById('selectedServicesCount');
        
        if (countElement) {
            countElement.textContent = checkedServices.length;
        }
        
        console.log(`📊 Selected services: ${checkedServices.length}`);
    }

    showMessage(message, type) {
        // Use SweetAlert2 for better user experience
        if (typeof Swal !== 'undefined') {
            let icon, title;
            
            switch (type) {
                case 'success':
                    icon = 'success';
                    title = 'Success!';
                    break;
                case 'error':
                    icon = 'error';
                    title = 'Error!';
                    break;
                case 'info':
                    icon = 'info';
                    title = 'Processing...';
                    break;
                default:
                    icon = 'info';
                    title = 'Notice';
            }
            
            if (type === 'info') {
                // Show a loading toast for info messages
                Swal.fire({
                    title: message,
                    allowOutsideClick: false,
                    allowEscapeKey: false,
                    showConfirmButton: false,
                    timer: 2000,
                    timerProgressBar: true,
                    toast: true,
                    position: 'top-end'
                });
            } else {
                Swal.fire({
                    icon: icon,
                    title: title,
                    text: message,
                    timer: type === 'success' ? 3000 : 5000,
                    timerProgressBar: true,
                    showConfirmButton: type === 'error'
                });
            }
        } else {
            // Fallback to basic alert if SweetAlert is not available
            const messageDiv = document.getElementById('profileMessage');
            if (messageDiv) {
                messageDiv.className = `alert alert-${type === 'success' ? 'success' : 'danger'}`;
                messageDiv.textContent = message;
                messageDiv.style.display = 'block';
                
                setTimeout(() => {
                    messageDiv.style.display = 'none';
                }, 5000);
            } else {
                alert(message);
            }
        }
    }

    safeSetValue(elementId, value) {
        const element = document.getElementById(elementId);
        if (element && value !== null && value !== undefined) {
            element.value = value;
        }
    }

    setupDragAndDrop() {
        const dropzone = document.querySelector('.upload-dropzone');
        if (!dropzone) return;

        dropzone.addEventListener('dragover', (e) => {
            e.preventDefault();
            dropzone.style.borderColor = '#007bff';
            dropzone.style.backgroundColor = '#f0f8ff';
        });

        dropzone.addEventListener('dragleave', (e) => {
            e.preventDefault();
            dropzone.style.borderColor = '#dee2e6';
            dropzone.style.backgroundColor = '#fafafa';
        });

        dropzone.addEventListener('drop', (e) => {
            e.preventDefault();
            dropzone.style.borderColor = '#dee2e6';
            dropzone.style.backgroundColor = '#fafafa';
            
            const files = e.dataTransfer.files;
            if (files.length > 0) {
                const certificateInput = document.getElementById('certificateInput');
                if (certificateInput) {
                    certificateInput.files = files;
                    this.handleCertificateChange({ target: { files } });
                }
            }
        });
    }

    initializeAvailability() {
        console.log('⏰ Initializing availability functionality...');
        
        // Initialize availability form
        const availabilityForm = document.getElementById('availabilityForm');
        if (availabilityForm) {
            availabilityForm.addEventListener('submit', (e) => this.handleAvailabilitySubmit(e));
        }

        // Add event listeners for real-time updates
        const startTimeInput = document.getElementById('startTime');
        const endTimeInput = document.getElementById('endTime');
        const durationSelect = document.getElementById('appointmentDuration');
        const workingDaysCheckboxes = document.querySelectorAll('input[name="workingDays"]');

        // Set up event listeners for real-time updates
        if (startTimeInput) {
            startTimeInput.addEventListener('change', () => {
                this.updateTimePreview();
                this.updateDailyCapacity();
                this.updateAvailabilitySummary();
            });
        }

        if (endTimeInput) {
            endTimeInput.addEventListener('change', () => {
                this.updateTimePreview();
                this.updateDailyCapacity();
                this.updateAvailabilitySummary();
            });
        }

        if (durationSelect) {
            durationSelect.addEventListener('change', () => {
                this.updateDailyCapacity();
                this.updateAvailabilitySummary();
            });
        }

        workingDaysCheckboxes.forEach(checkbox => {
            checkbox.addEventListener('change', () => {
                this.updateAvailabilitySummary();
            });
        });

        // Initialize displays
        this.updateTimePreview();
        this.updateDailyCapacity();
        this.updateAvailabilitySummary();
    }

    updateTimePreview() {
        const startTime = document.getElementById('startTime')?.value || '08:00';
        const endTime = document.getElementById('endTime')?.value || '17:00';
        const previewElement = document.getElementById('timePreview');
        
        if (previewElement) {
            const start = new Date(`1970-01-01T${startTime}:00`);
            const end = new Date(`1970-01-01T${endTime}:00`);
            const diffMs = end - start;
            const hours = Math.floor(diffMs / (1000 * 60 * 60));
            const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
            
            let duration = `${hours} hours`;
            if (minutes > 0) {
                duration += ` ${minutes} minutes`;
            }
            
            previewElement.textContent = `Working hours: ${startTime} - ${endTime} (${duration})`;
        }
    }

    updateDailyCapacity() {
        const startTime = document.getElementById('startTime')?.value || '08:00';
        const endTime = document.getElementById('endTime')?.value || '17:00';
        const duration = parseInt(document.getElementById('appointmentDuration')?.value || '30');
        const capacityElement = document.getElementById('dailyCapacity');
        
        if (capacityElement) {
            const start = new Date(`1970-01-01T${startTime}:00`);
            const end = new Date(`1970-01-01T${endTime}:00`);
            const totalMinutes = (end - start) / (1000 * 60);
            const appointments = Math.floor(totalMinutes / duration);
            
            capacityElement.textContent = `Approximately ${appointments} appointments per day`;
        }
    }

    updateAvailabilitySummary() {
        const workingDaysCheckboxes = document.querySelectorAll('input[name="workingDays"]:checked');
        const startTime = document.getElementById('startTime')?.value || '08:00';
        const endTime = document.getElementById('endTime')?.value || '17:00';
        const duration = document.getElementById('appointmentDuration')?.value || '30';
        
        const summaryDays = document.getElementById('summaryDays');
        const summaryHours = document.getElementById('summaryHours');
        const summaryDuration = document.getElementById('summaryDuration');
        
        if (summaryDays) {
            if (workingDaysCheckboxes.length > 0) {
                const days = Array.from(workingDaysCheckboxes).map(cb => 
                    cb.value.charAt(0).toUpperCase() + cb.value.slice(1)
                );
                summaryDays.textContent = days.join(', ');
            } else {
                summaryDays.textContent = 'Not configured';
            }
        }
        
        if (summaryHours) {
            summaryHours.textContent = `${startTime} - ${endTime}`;
        }
        
        if (summaryDuration) {
            const durationText = duration === '60' ? '1 hour' : 
                                duration === '90' ? '1.5 hours' :
                                duration === '120' ? '2 hours' : 
                                `${duration} minutes`;
            summaryDuration.textContent = durationText;
        }
    }

    async handleAvailabilitySubmit(event) {
        event.preventDefault();
        console.log('⏰ Saving availability settings...');
        
        const workingDaysCheckboxes = document.querySelectorAll('input[name="workingDays"]:checked');
        const workingDays = Array.from(workingDaysCheckboxes).map(cb => cb.value);
        
        const availabilityData = {
            workingDays: workingDays,
            startTime: document.getElementById('startTime')?.value || '08:00',
            endTime: document.getElementById('endTime')?.value || '17:00',
            appointmentDuration: parseInt(document.getElementById('appointmentDuration')?.value) || 30
        };

        // Validate that at least one day is selected
        if (workingDays.length === 0) {
            this.showErrorMessage('Please select at least one working day');
            return;
        }

        try {
            const response = await fetch('/api/profile/update', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    section: 'availability',
                    ...availabilityData
                })
            });

            const result = await response.json();
            
            if (response.ok) {
                this.showSuccessMessage('Availability settings saved successfully!');
                this.currentProfileData.availability = availabilityData;
                this.updateAvailabilitySummary();
            } else {
                this.showErrorMessage(result.message || 'Failed to save availability settings');
            }
        } catch (error) {
            console.error('Availability update error:', error);
            this.showErrorMessage('Connection error - Unable to save availability settings');
        }
    }

    showSuccessMessage(message) {
        this.showMessage(message, 'success');
    }

    showErrorMessage(message) {
        this.showMessage(message, 'error');
    }

    showLoadingMessage(message) {
        this.showMessage(message, 'info');
    }
}

// Global functions for button handlers (Updated with SweetAlert integration)
async function uploadProfilePhoto() {
    console.log('🚀 Manual profile photo upload triggered...');
    
    const fileInput = document.getElementById('profileImageInput');
    const file = fileInput?.files[0];
    
    if (!file) {
        if (typeof Swal !== 'undefined') {
            Swal.fire({
                icon: 'warning',
                title: 'No File Selected',
                text: 'Please select an image file first',
                confirmButtonText: 'OK'
            });
        } else {
            alert('Please select an image file first');
        }
        return;
    }

    // Use the ProfileEditor instance if available
    if (window.profileEditor) {
        window.profileEditor.uploadProfileImageFile(file);
    } else {
        // Fallback to direct upload
        await directImageUpload(file);
    }
}

async function directImageUpload(file) {
    console.log('📄 Direct upload for file:', {
        name: file.name,
        size: file.size,
        type: file.type
    });

    // Validate file
    const maxSize = 5 * 1024 * 1024; // 5MB
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png'];
    
    if (!allowedTypes.includes(file.type)) {
        if (typeof Swal !== 'undefined') {
            Swal.fire({
                icon: 'error',
                title: 'Invalid File Type',
                text: 'Please select a JPG, JPEG, or PNG image file',
                confirmButtonText: 'OK'
            });
        } else {
            alert('Invalid file type. Please use JPG, JPEG, or PNG');
        }
        return;
    }

    if (file.size > maxSize) {
        if (typeof Swal !== 'undefined') {
            Swal.fire({
                icon: 'error',
                title: 'File Too Large',
                text: 'Image file size must be less than 5MB',
                confirmButtonText: 'OK'
            });
        } else {
            alert('File too large. Maximum size is 5MB');
        }
        return;
    }

    const formData = new FormData();
    formData.append('profileImage', file);

    // Show loading
    let loadingAlert;
    if (typeof Swal !== 'undefined') {
        loadingAlert = Swal.fire({
            title: 'Uploading Image...',
            text: 'Please wait while we upload your profile image',
            allowOutsideClick: false,
            allowEscapeKey: false,
            showConfirmButton: false,
            didOpen: () => {
                Swal.showLoading();
            }
        });
    }

    try {
        const response = await fetch('/api/profile/upload-image', {
            method: 'POST',
            body: formData,
            credentials: 'include'
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || `Server error: ${response.status}`);
        }

        const result = await response.json();
        console.log('✅ Upload successful:', result);
        
        // Update the display image
        const displayImage = document.getElementById('profileDisplayImage');
        if (displayImage && result.imageUrl) {
            displayImage.src = result.imageUrl;
        }

        // Update header avatar if it exists
        const headerAvatar = document.getElementById('headerUserAvatar');
        if (headerAvatar && result.imageUrl) {
            headerAvatar.src = result.imageUrl;
        }

        if (typeof Swal !== 'undefined') {
            if (loadingAlert) {
                Swal.close();
            }
            Swal.fire({
                icon: 'success',
                title: 'Success!',
                text: 'Profile image uploaded successfully!',
                timer: 3000,
                timerProgressBar: true
            });
        } else {
            alert('Profile image uploaded successfully!');
        }
        
    } catch (error) {
        console.error('❌ Photo upload error:', error);
        
        if (typeof Swal !== 'undefined') {
            if (loadingAlert) {
                Swal.close();
            }
            Swal.fire({
                icon: 'error',
                title: 'Upload Failed',
                text: error.message || 'Failed to upload image',
                confirmButtonText: 'OK'
            });
        } else {
            alert(error.message || 'Failed to upload image');
        }
    }
}

async function uploadCertificate() {
    console.log('🚀 Manual certificate upload triggered...');
    
    const fileInput = document.getElementById('certificateInput');
    const file = fileInput?.files[0];
    
    if (!file) {
        if (typeof Swal !== 'undefined') {
            Swal.fire({
                icon: 'warning',
                title: 'No File Selected',
                text: 'Please select a certificate file first',
                confirmButtonText: 'OK'
            });
        } else {
            alert('Please select a certificate file first');
        }
        return;
    }

    // Use the ProfileEditor instance if available
    if (window.profileEditor) {
        window.profileEditor.uploadCertificateFile(file);
    } else {
        // Fallback message
        if (typeof Swal !== 'undefined') {
            Swal.fire({
                icon: 'info',
                title: 'Upload Started',
                text: 'Certificate upload will be processed automatically',
                timer: 2000
            });
        } else {
            alert('Certificate upload started');
        }
    }
}

function removeProfilePhoto() {
    if (confirm('Are you sure you want to remove the current profile photo?')) {
        const displayImage = document.getElementById('profileDisplayImage');
        if (displayImage) {
            displayImage.src = '/assets/hospital.PNG';
        }
        
        const profileEditor = window.profileEditor;
        if (profileEditor) {
            profileEditor.showMessage('Profile photo removed. Upload a new one to replace it.', 'success');
        }
    }
}

function removeCertificate() {
    if (confirm('Are you sure you want to remove the current certificate?')) {
        const currentCertDiv = document.getElementById('currentCertificate');
        if (currentCertDiv) {
            currentCertDiv.style.display = 'none';
        }
        
        const profileEditor = window.profileEditor;
        if (profileEditor) {
            profileEditor.showMessage('Certificate removed. Upload a new one to replace it.', 'success');
        }
    }
}

function resetGeneralInfo() {
    if (confirm('Reset general information to original values?')) {
        const form = document.getElementById('generalInfoForm');
        if (form && window.profileEditor) {
            window.profileEditor.populateForm(window.profileEditor.currentProfileData);
            window.profileEditor.showMessage('General information reset to original values', 'success');
        }
    }
}

function resetContactInfo() {
    if (confirm('Reset contact information to original values?')) {
        const form = document.getElementById('contactInfoForm');
        if (form && window.profileEditor) {
            window.profileEditor.populateForm(window.profileEditor.currentProfileData);
            window.profileEditor.showMessage('Contact information reset to original values', 'success');
        }
    }
}

function resetServices() {
    if (confirm('Reset services to original selection?')) {
        const checkboxes = document.querySelectorAll('input[name="services"]');
        checkboxes.forEach(checkbox => checkbox.checked = false);
        
        if (window.profileEditor && window.profileEditor.currentProfileData.services) {
            window.profileEditor.currentProfileData.services.forEach(service => {
                const checkbox = document.querySelector(`input[name="services"][value="${service}"]`);
                if (checkbox) {
                    checkbox.checked = true;
                }
            });
        }
        
        if (window.profileEditor) {
            window.profileEditor.updateServicesCount();
            window.profileEditor.showMessage('Services reset to original selection', 'success');
        }
    }
}

function resetAvailability() {
    if (confirm('Reset availability settings to default values?')) {
        // Reset to default values
        const startTimeInput = document.getElementById('startTime');
        const endTimeInput = document.getElementById('endTime');
        const durationSelect = document.getElementById('appointmentDuration');
        const workingDaysCheckboxes = document.querySelectorAll('input[name="workingDays"]');
        
        if (startTimeInput) startTimeInput.value = '08:00';
        if (endTimeInput) endTimeInput.value = '17:00';
        if (durationSelect) durationSelect.value = '30';
        
        // Uncheck all working days
        workingDaysCheckboxes.forEach(checkbox => {
            checkbox.checked = false;
        });
        
        // Update displays
        if (window.profileEditor) {
            window.profileEditor.updateTimePreview();
            window.profileEditor.updateDailyCapacity();
            window.profileEditor.updateAvailabilitySummary();
            window.profileEditor.showMessage('Availability settings reset to default values', 'success');
        }
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Only initialize if we're on the profile page
    const profileTabs = document.getElementById('profileTabs');
    if (profileTabs) {
        window.profileEditor = new ProfileEditor();
        console.log('✅ Profile Editor initialized for tabbed interface');
    }
});
