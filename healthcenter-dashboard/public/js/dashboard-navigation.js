// Dashboard Navigation and General Functions
class DashboardNavigation {
    constructor() {
        this.init();
    }

    init() {
        this.setupNavigation();
        this.setupLogout();
        this.setupCharts();
    }

    // Setup navigation between dashboard sections
    setupNavigation() {
        const settingsLink = document.getElementById('settings-link');
        const profileLink = document.getElementById('profile-link');
        const dashboardLink = document.querySelector('a[href="#dashboard"]');
        const appointmentsLink = document.querySelector('a[href="#appointments"]');
        const messagesLink = document.querySelector('a[href="#messages"]');
        
        const dashboardContent = document.querySelector('.dashboard-content');
        const settingsContent = document.getElementById('settings-content');
        const profileContent = document.getElementById('profile-content');
        const appointmentsContent = document.getElementById('appointments-content');
        const messagesContent = document.getElementById('messages-content');

        // Settings navigation
        if (settingsLink) {
            settingsLink.addEventListener('click', (e) => {
                e.preventDefault();
                this.showSection('settings', dashboardContent, settingsContent, profileContent, appointmentsContent, messagesContent);
                this.updateHeaderTitle('Settings');
                // Initialize settings page if not already done
                if (typeof settingsPage !== 'undefined' && settingsPage.init) {
                    setTimeout(() => settingsPage.init(), 100);
                }
            });
        }

        // Profile navigation
        if (profileLink) {
            profileLink.addEventListener('click', (e) => {
                e.preventDefault();
                this.showSection('profile', dashboardContent, settingsContent, profileContent, appointmentsContent, messagesContent);
                this.updateHeaderTitle('Profile');
                this.loadClinicDataIntoProfile();
            });
        }

        // Dashboard navigation
        if (dashboardLink) {
            dashboardLink.addEventListener('click', (e) => {
                e.preventDefault();
                this.showSection('dashboard', dashboardContent, settingsContent, profileContent, appointmentsContent, messagesContent);
                this.updateHeaderTitle('Dashboard');
            });
        }

        // Appointments navigation
        if (appointmentsLink) {
            appointmentsLink.addEventListener('click', (e) => {
                e.preventDefault();
                this.showSection('appointments', dashboardContent, settingsContent, profileContent, appointmentsContent, messagesContent);
                this.updateHeaderTitle('Appointments');
                // Initialize appointments page if not already done
                if (typeof appointmentsPage !== 'undefined' && appointmentsPage.init) {
                    setTimeout(() => appointmentsPage.init(), 100);
                }
            });
        }

        // Messages navigation
        if (messagesLink) {
            messagesLink.addEventListener('click', (e) => {
                e.preventDefault();
                this.showSection('messages', dashboardContent, settingsContent, profileContent, appointmentsContent, messagesContent);
                this.updateHeaderTitle('Messages');
                // Initialize messages page if not already done
                if (typeof messagesPage !== 'undefined' && messagesPage.init) {
                    setTimeout(() => messagesPage.init(), 100);
                }
            });
        }
    }

    // Show specific section
    showSection(section, dashboardContent, settingsContent, profileContent, appointmentsContent, messagesContent) {
        // Hide all sections
        if (dashboardContent) dashboardContent.style.display = 'none';
        if (settingsContent) settingsContent.style.display = 'none';
        if (profileContent) profileContent.style.display = 'none';
        if (appointmentsContent) appointmentsContent.style.display = 'none';
        if (messagesContent) messagesContent.style.display = 'none';

        // Show selected section
        switch (section) {
            case 'dashboard':
                if (dashboardContent) dashboardContent.style.display = 'block';
                break;
            case 'settings':
                if (settingsContent) settingsContent.style.display = 'block';
                break;
            case 'profile':
                if (profileContent) profileContent.style.display = 'block';
                break;
            case 'appointments':
                if (appointmentsContent) appointmentsContent.style.display = 'block';
                break;
            case 'messages':
                if (messagesContent) messagesContent.style.display = 'block';
                break;
        }

        // Update active nav item
        this.setActiveNavItem(section);
    }

    // Update header title
    updateHeaderTitle(title) {
        const headerTitle = document.querySelector('.header-title h1');
        if (headerTitle) {
            const icons = {
                'Dashboard': 'fas fa-tachometer-alt',
                'Settings': 'fas fa-cog',
                'Profile': 'fas fa-user-circle',
                'Appointments': 'fas fa-calendar-check',
                'Messages': 'fas fa-comments'
            };
            const icon = icons[title] || 'fas fa-home';
            headerTitle.innerHTML = `<i class="${icon} me-2"></i>${title}`;
        }
    }

    // Setup logout functionality
    setupLogout() {
        const logoutLink = document.querySelector('a[href="/logout"]');
        if (logoutLink) {
            logoutLink.addEventListener('click', (e) => {
                e.preventDefault();
                this.performLogout();
            });
        }
    }

    // Perform logout
    performLogout() {
        fetch('/api/auth/logout', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                window.location.href = '/login';
            } else {
                console.error('Logout failed:', data.message);
                window.location.href = '/login';
            }
        })
        .catch(error => {
            console.error('Logout error:', error);
            window.location.href = '/login';
        });
    }

    // Setup performance chart
    setupCharts() {
        const ctx = document.getElementById('performanceChart');
        if (ctx) {
            new Chart(ctx.getContext('2d'), {
                type: 'line',
                data: {
                    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                    datasets: [{
                        label: 'Appointments Completed',
                        data: [12, 19, 14, 17, 22, 20, 24],
                        backgroundColor: 'rgba(21, 155, 189, 0.2)',
                        borderColor: 'rgba(21, 155, 189, 1)',
                        borderWidth: 3,
                        tension: 0.4,
                        fill: true,
                        pointBackgroundColor: 'rgba(21, 155, 189, 1)'
                    }]
                },
                options: {
                    plugins: { legend: { display: false } },
                    scales: {
                        y: { beginAtZero: true, ticks: { color: '#2C3E50' } },
                        x: { ticks: { color: '#2C3E50' } }
                    }
                }
            });
        }
    }

    // Load clinic data into settings form
    loadClinicDataIntoSettings() {
        fetch('/api/settings/clinic-data')
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    this.populateSettingsForm(data.clinicData);
                } else {
                    console.error('Failed to load clinic data for settings:', data.message);
                }
            })
            .catch(error => {
                console.error('Error loading clinic data for settings:', error);
            });
    }

    // Populate settings form
    populateSettingsForm(clinicData) {
        // Profile form
        document.getElementById('clinicName').value = clinicData.name || clinicData.clinicName || '';
        document.getElementById('clinicEmail').value = clinicData.email || '';
        document.getElementById('clinicAbout').value = clinicData.about || '';
        document.getElementById('meetingDuration').value = clinicData.meetingDuration || '30';

        // Contact form
        document.getElementById('clinicPhone').value = clinicData.phone || '';
        document.getElementById('clinicAddress').value = clinicData.address || '';
        document.getElementById('clinicSector').value = clinicData.sector || '';
        document.getElementById('clinicLatitude').value = clinicData.latitude || '';
        document.getElementById('clinicLongitude').value = clinicData.longitude || '';

        // Services
        if (clinicData.facilities && Array.isArray(clinicData.facilities)) {
            document.querySelectorAll('.services-grid input[type="checkbox"]').forEach(checkbox => {
                checkbox.checked = false;
            });
            
            clinicData.facilities.forEach(service => {
                const checkbox = document.querySelector(`input[value="${service}"]`);
                if (checkbox) {
                    checkbox.checked = true;
                }
            });
        }

        // Schedule
        if (clinicData.availableSchedule) {
            const schedule = clinicData.availableSchedule;
            Object.keys(schedule).forEach(day => {
                const startInput = document.getElementById(`${day.toLowerCase()}Start`);
                const endInput = document.getElementById(`${day.toLowerCase()}End`);
                if (startInput && endInput) {
                    startInput.value = schedule[day].start || schedule[day].startTime || '';
                    endInput.value = schedule[day].end || schedule[day].endTime || '';
                }
            });
        }

        // Profile image
        if (clinicData.profileImageUrl) {
            document.getElementById('profileImage').src = clinicData.profileImageUrl;
            // Mettre à jour aussi l'image dans l'en-tête
            const headerImage = document.getElementById('headerUserAvatar');
            if (headerImage) {
                headerImage.src = clinicData.profileImageUrl;
            }
        } else {
            document.getElementById('profileImage').src = '/assets/hospital.PNG';
            // Mettre à jour aussi l'image dans l'en-tête avec l'image par défaut
            const headerImage = document.getElementById('headerUserAvatar');
            if (headerImage) {
                headerImage.src = '/assets/hospital.PNG';
            }
        }
    }

    // Load clinic data into profile display (fallback for client-side loading)
    loadClinicDataIntoProfile() {
        console.log('🔍 Loading comprehensive clinic data into profile...');
        
        // Check if profile data is already loaded server-side
        const profileName = document.getElementById('profileClinicName');
        if (profileName && profileName.textContent && !profileName.textContent.includes('Loading...')) {
            console.log('✅ Profile data already loaded server-side, skipping client-side loading');
            return;
        }
        
        // Show loading spinners only if needed
        this.showProfileLoadingState();
        
        fetch('/api/profile/clinic-data')
            .then(response => {
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                if (data.success) {
                    console.log('✅ Profile data loaded successfully:', data.profile);
                    this.populateProfileDisplay(data.profile);
                } else {
                    console.error('❌ Failed to load profile data:', data.message);
                    this.showProfileError(data.message || 'Failed to load profile data');
                }
            })
            .catch(error => {
                console.error('❌ Error loading profile data:', error);
                this.showProfileError('Unable to load profile data. Please check your connection.');
            })
            .finally(() => {
                this.hideProfileLoadingState();
            });
    }

    // Populate profile display with data
    populateProfileDisplay(profile) {
        console.log('🔧 Populating profile display with data:', profile);
        
        try {
            // Basic Information
            this.safeUpdateElement('profileClinicName', profile.name || 'Clinic Name Not Set');
            this.safeUpdateElement('profileClinicAbout', profile.about || 'About information not available');
            this.safeUpdateElement('profileClinicEmail', profile.email || 'Email not set');
            this.safeUpdateElement('profileClinicPhone', profile.phone || 'Phone not set');
            this.safeUpdateElement('profileClinicAddress', profile.address || 'Address not set');
            this.safeUpdateElement('profileClinicCity', profile.city || 'City not set');
            this.safeUpdateElement('profileClinicCountry', profile.country || 'Country not set');
            
            // Website with link
            const websiteElement = document.getElementById('profileClinicWebsite');
            if (websiteElement) {
                if (profile.website && profile.website !== 'null' && profile.website.trim() !== '') {
                    websiteElement.innerHTML = `<a href="${profile.website}" target="_blank" class="text-primary">${profile.website}</a>`;
                } else {
                    websiteElement.textContent = 'Not provided';
                }
            }
            
            // Profile Image
            const profileImage = document.getElementById('profileDisplayImage');
            if (profileImage && profile.profileImage) {
                profileImage.src = profile.profileImage;
                profileImage.onerror = function() {
                    this.src = '/assets/hospital.PNG';
                };
            }
            
            // Services
            this.populateServices(profile.services || []);
            
            // Schedule
            this.populateSchedule(profile.schedule || {});
            
            // Status Badges
            this.updateStatusBadges(profile);
            
            // System Information
            this.populateSystemInfo(profile);
            
            // Statistics
            this.updateStatistics(profile);
            
            console.log('✅ Profile display populated successfully');
            
        } catch (error) {
            console.error('❌ Error populating profile display:', error);
            this.showProfileError('Error displaying profile data');
        }
    }

    // Safe update element helper
    safeUpdateElement(elementId, value) {
        const element = document.getElementById(elementId);
        if (element) {
            element.textContent = value || 'Not available';
        }
    }

    // Populate services section
    populateServices(services) {
        const servicesContainer = document.getElementById('profileServices');
        if (!servicesContainer) return;
        
        if (services && services.length > 0) {
            servicesContainer.innerHTML = services.map(service => 
                `<span class="badge bg-primary me-2 mb-2">${service}</span>`
            ).join('');
        } else {
            servicesContainer.innerHTML = `
                <div class="text-center text-muted">
                    <i class="fas fa-exclamation-circle mb-2"></i>
                    <p>No services configured yet</p>
                </div>
            `;
        }
    }

    // Populate schedule section
    populateSchedule(schedule) {
        const scheduleContainer = document.getElementById('profileSchedule');
        if (!scheduleContainer) return;
        
        if (schedule && Object.keys(schedule).length > 0) {
            scheduleContainer.innerHTML = Object.keys(schedule).map(day => `
                <div class="schedule-item">
                    <div class="schedule-day">${day}</div>
                    <div class="schedule-time">${schedule[day]}</div>
                </div>
            `).join('');
        } else {
            scheduleContainer.innerHTML = `
                <div class="text-center text-muted">
                    <i class="fas fa-clock mb-2"></i>
                    <p>No schedule configured yet</p>
                </div>
            `;
        }
    }

    // Update status badges
    updateStatusBadges(profile) {
        const statusBadges = ['profileStatusBadge', 'profileStatusBadge2'];
        const verifiedBadges = ['profileVerifiedBadge', 'profileVerifiedBadge2'];
        
        statusBadges.forEach(badgeId => {
            const badge = document.getElementById(badgeId);
            if (badge) {
                badge.textContent = profile.status === 'active' ? 'Active' : 'Inactive';
                badge.className = `badge ${profile.status === 'active' ? 'bg-success' : 'bg-danger'}`;
            }
        });
        
        verifiedBadges.forEach(badgeId => {
            const badge = document.getElementById(badgeId);
            if (badge) {
                badge.textContent = profile.isVerified ? 'Verified' : 'Unverified';
                badge.className = `badge ${profile.isVerified ? 'bg-primary' : 'bg-warning'} ms-2`;
            }
        });
    }

    // Populate system information
    populateSystemInfo(profile) {
        // Created date
        const createdElement = document.getElementById('profileClinicCreated');
        if (createdElement) {
            if (profile.createdAt) {
                try {
                    const date = new Date(profile.createdAt.seconds ? profile.createdAt.seconds * 1000 : profile.createdAt);
                    createdElement.textContent = date.toLocaleDateString();
                } catch (e) {
                    createdElement.textContent = 'Not available';
                }
            } else {
                createdElement.textContent = 'Not available';
            }
        }
        
        // Updated date
        const updatedElement = document.getElementById('profileClinicUpdated');
        if (updatedElement) {
            if (profile.updatedAt) {
                try {
                    const date = new Date(profile.updatedAt.seconds ? profile.updatedAt.seconds * 1000 : profile.updatedAt);
                    updatedElement.textContent = date.toLocaleDateString();
                } catch (e) {
                    updatedElement.textContent = 'Not available';
                }
            } else {
                updatedElement.textContent = 'Not available';
            }
        }
        
        // Verification status
        const verificationElement = document.getElementById('profileVerificationStatus');
        if (verificationElement) {
            const badgeClass = profile.isVerified ? 'bg-success' : 'bg-warning';
            const icon = profile.isVerified ? 'fa-check-circle' : 'fa-exclamation-triangle';
            const text = profile.isVerified ? 'Verified' : 'Pending Verification';
            
            verificationElement.innerHTML = `
                <span class="badge ${badgeClass}">
                    <i class="fas ${icon} me-1"></i>
                    ${text}
                </span>
            `;
        }
    }

    // Update statistics
    updateStatistics(profile) {
        // Services count
        this.safeUpdateElement('profileServicesCount', (profile.services || []).length);
        
        // Working days
        let workingDays = 0;
        if (profile.schedule) {
            workingDays = Object.values(profile.schedule).filter(time => 
                time !== 'Closed' && time !== 'Not set' && time.trim() !== ''
            ).length;
        }
        this.safeUpdateElement('profileWorkingDays', workingDays);
        
        // Meeting duration
        this.safeUpdateElement('profileMeetingDuration', profile.meetingDuration || 30);
        
        // Status
        this.safeUpdateElement('profileClinicStatus', profile.status === 'active' ? 'Active' : 'Inactive');
    }

    // Show loading state
    showProfileLoadingState() {
        const loadingElements = [
            'profileClinicName', 'profileClinicAbout', 'profileClinicEmail', 
            'profileClinicPhone', 'profileClinicAddress', 'profileClinicCity', 
            'profileClinicCountry'
        ];
        
        loadingElements.forEach(elementId => {
            const element = document.getElementById(elementId);
            if (element && element.textContent.includes('Loading...')) {
                element.innerHTML = '<div class="spinner-border spinner-border-sm text-primary" role="status"></div>';
            }
        });
        
        // Show image loading spinner
        const imageSpinner = document.getElementById('profileImageLoadingSpinner');
        if (imageSpinner) {
            imageSpinner.style.display = 'block';
        }
    }

    // Hide loading state
    hideProfileLoadingState() {
        const imageSpinner = document.getElementById('profileImageLoadingSpinner');
        if (imageSpinner) {
            imageSpinner.style.display = 'none';
        }
    }

    // Show profile error
    showProfileError(message) {
        console.error('Profile loading error:', message);
        
        // Update main elements with error message
        const errorElements = [
            'profileClinicName', 'profileClinicAbout'
        ];
        
        errorElements.forEach(elementId => {
            const element = document.getElementById(elementId);
            if (element) {
                element.innerHTML = `
                    <div class="text-danger">
                        <i class="fas fa-exclamation-triangle me-2"></i>
                        ${message}
                    </div>
                `;
            }
        });
    }
}

// Global function to navigate to appointments page
function navigateToAppointments() {
    const dashboardNavigation = new DashboardNavigation();
    dashboardNavigation.showSection('appointments', 
        document.querySelector('.dashboard-content'),
        document.getElementById('settings-content'),
        document.getElementById('profile-content'),
        document.getElementById('appointments-content')
    );
    dashboardNavigation.updateHeaderTitle('Appointments');
    
    // Initialize appointments page if not already done
    if (typeof appointmentsPage !== 'undefined' && appointmentsPage) {
        appointmentsPage.loadAllAppointments();
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new DashboardNavigation();
}); 