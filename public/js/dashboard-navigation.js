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
        const dashboardLink = document.querySelector('a[href="#dashboard"]');
        const appointmentsLink = document.querySelector('a[href="#appointments"]');
        const messagesLink = document.querySelector('a[href="#messages"]');
        
        const dashboardContent = document.querySelector('.dashboard-content');
        const settingsContent = document.getElementById('settings-content');
        const appointmentsContent = document.getElementById('appointments-content');
        const messagesContent = document.getElementById('messages-content');

        // Settings navigation
        if (settingsLink) {
            settingsLink.addEventListener('click', (e) => {
                e.preventDefault();
                this.showSection('settings', dashboardContent, settingsContent, appointmentsContent, messagesContent);
                this.updateHeaderTitle('Settings');
                // Initialize settings page if not already done
                if (typeof settingsPage !== 'undefined' && settingsPage.init) {
                    setTimeout(() => settingsPage.init(), 100);
                }
            });
        }

        // Dashboard navigation
        if (dashboardLink) {
            dashboardLink.addEventListener('click', (e) => {
                e.preventDefault();
                this.showSection('dashboard', dashboardContent, settingsContent, appointmentsContent, messagesContent);
                this.updateHeaderTitle('Dashboard');
            });
        }

        // Appointments navigation
        if (appointmentsLink) {
            appointmentsLink.addEventListener('click', (e) => {
                e.preventDefault();
                this.showSection('appointments', dashboardContent, settingsContent, appointmentsContent, messagesContent);
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
                this.showSection('messages', dashboardContent, settingsContent, appointmentsContent, messagesContent);
                this.updateHeaderTitle('Messages');
                // Initialize messages page if not already done
                if (typeof messagesPage !== 'undefined' && messagesPage.init) {
                    setTimeout(() => messagesPage.init(), 100);
                }
            });
        }
    }

    // Show specific section
    showSection(section, dashboardContent, settingsContent, appointmentsContent, messagesContent) {
        // Hide all sections
        if (dashboardContent) dashboardContent.style.display = 'none';
        if (settingsContent) settingsContent.style.display = 'none';
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

    // Set active navigation item
    setActiveNavItem(section) {
        // Remove active class from all nav items
        document.querySelectorAll('.sidebar-nav .nav-item').forEach(item => {
            item.classList.remove('active');
        });

        // Add active class to current section
        const sectionMap = {
            'dashboard': 'a[href="#dashboard"]',
            'appointments': 'a[href="#appointments"]', 
            'messages': 'a[href="#messages"]',
            'settings': 'a[href="#settings"]'
        };

        const selector = sectionMap[section];
        if (selector) {
            const activeLink = document.querySelector(selector);
            if (activeLink) {
                activeLink.closest('.nav-item').classList.add('active');
            }
        }
    }

    // Update header title
    updateHeaderTitle(title) {
        const headerTitle = document.querySelector('.header-title h1');
        if (headerTitle) {
            const icons = {
                'Dashboard': 'fas fa-tachometer-alt',
                'Settings': 'fas fa-cog',
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

    // Load clinic data into profile display
    loadClinicDataIntoProfile() {
        console.log('🔍 Loading clinic data into profile...');
        
        fetch('/api/settings/clinic-data')
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    this.populateProfileDisplay(data.clinicData);
                } else {
                    console.error('Failed to load clinic data:', data.message);
                }
            })
            .catch(error => {
                console.error('Error loading clinic data for profile:', error);
            });
    }

    // Populate profile display
    populateProfileDisplay(clinicData) {
        // Basic info
        const nameElement = document.getElementById('profileClinicName');
        const aboutElement = document.getElementById('profileClinicAbout');
        const emailElement = document.getElementById('profileClinicEmail');
        const phoneElement = document.getElementById('profileClinicPhone');
        const addressElement = document.getElementById('profileClinicAddress');
        const locationElement = document.getElementById('profileClinicLocation');

        if (nameElement) nameElement.textContent = clinicData.name || clinicData.clinicName || 'Clinic Name';
        if (aboutElement) aboutElement.textContent = clinicData.about || 'About the clinic...';
        if (emailElement) emailElement.textContent = clinicData.email || 'email@clinic.com';
        if (phoneElement) phoneElement.textContent = clinicData.phone || '+250 XXX XXX XXX';
        if (addressElement) addressElement.textContent = clinicData.address || 'Address to be updated';
        if (locationElement) locationElement.textContent = clinicData.location || 'Location to be updated';

        // Dates
        this.formatAndDisplayDate(clinicData.createdAt, 'profileClinicCreated', 'Registration date');
        this.formatAndDisplayDate(clinicData.updatedAt, 'profileClinicUpdated', 'Last update date');

        // Profile image
        const imageElement = document.getElementById('profileDisplayImage');
        if (imageElement) {
            if (clinicData.profileImageUrl) {
                imageElement.src = clinicData.profileImageUrl;
                // Mettre à jour aussi l'image dans l'en-tête
                const headerImage = document.getElementById('headerUserAvatar');
                if (headerImage) {
                    headerImage.src = clinicData.profileImageUrl;
                }
            } else {
                imageElement.src = 'https://via.placeholder.com/200x200/159BBD/FFFFFF?text=Clinic';
                // Mettre à jour aussi l'image dans l'en-tête avec l'image par défaut
                const headerImage = document.getElementById('headerUserAvatar');
                if (headerImage) {
                    headerImage.src = '/assets/hospital.PNG';
                }
            }
        }

        // Services
        this.populateServices(clinicData.facilities);

        // Schedule
        this.populateSchedule(clinicData.availableSchedule);

        // Verification status
        this.updateVerificationStatus(clinicData.isVerified);
    }

    // Format and display date
    formatAndDisplayDate(dateData, elementId, fallbackText) {
        const element = document.getElementById(elementId);
        if (!element) return;

        if (dateData) {
            try {
                let date;
                if (dateData.seconds) {
                    date = new Date(dateData.seconds * 1000);
                } else {
                    date = new Date(dateData);
                }
                element.textContent = date.toLocaleDateString('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                });
            } catch (error) {
                console.error('Error formatting date:', error);
                element.textContent = fallbackText;
            }
        } else {
            element.textContent = fallbackText;
        }
    }

    // Populate services
    populateServices(facilities) {
        const servicesContainer = document.getElementById('profileServices');
        if (!servicesContainer) return;

        servicesContainer.innerHTML = '';
        if (facilities && Array.isArray(facilities) && facilities.length > 0) {
            facilities.forEach(service => {
                const badge = document.createElement('span');
                badge.className = 'badge bg-primary me-2 mb-2';
                badge.textContent = service;
                servicesContainer.appendChild(badge);
            });
        } else {
            servicesContainer.innerHTML = '<span class="badge bg-secondary me-2 mb-2">No services listed</span>';
        }
    }

    // Populate schedule
    populateSchedule(availableSchedule) {
        const scheduleContainer = document.getElementById('profileSchedule');
        if (!scheduleContainer) return;

        scheduleContainer.innerHTML = '';
        if (availableSchedule) {
            Object.keys(availableSchedule).forEach(day => {
                const scheduleItem = document.createElement('div');
                scheduleItem.className = 'schedule-item';
                
                const daySpan = document.createElement('span');
                daySpan.className = 'schedule-day';
                daySpan.textContent = day;
                
                const timeSpan = document.createElement('span');
                timeSpan.className = 'schedule-time';
                const schedule = availableSchedule[day];
                if (schedule.start === 'Closed' || schedule.end === 'Closed') {
                    timeSpan.textContent = 'Closed';
                } else {
                    const start = schedule.start || schedule.startTime || '';
                    const end = schedule.end || schedule.endTime || '';
                    timeSpan.textContent = `${start} - ${end}`;
                }
                
                scheduleItem.appendChild(daySpan);
                scheduleItem.appendChild(timeSpan);
                scheduleContainer.appendChild(scheduleItem);
            });
        } else {
            scheduleContainer.innerHTML = '<p class="text-muted">No schedule information available</p>';
        }
    }

    // Update verification status
    updateVerificationStatus(isVerified) {
        const verificationBadge = document.getElementById('verificationStatus');
        if (verificationBadge) {
            if (isVerified) {
                verificationBadge.textContent = 'Verified';
                verificationBadge.className = 'badge bg-success';
            } else {
                verificationBadge.textContent = 'Pending Verification';
                verificationBadge.className = 'badge bg-warning';
            }
        }
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