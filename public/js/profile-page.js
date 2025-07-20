// Profile Page Management
const profilePage = {
    // Initialize the profile page
    init() {
        console.log('🏥 Profile page initializing...');
        this.loadHospitalInfo();
        this.loadServices();
        this.loadSchedule();
    },

    // Refresh all profile data
    refresh() {
        console.log('🔄 Refreshing profile data...');
        this.loadHospitalInfo();
        this.loadServices();
        this.loadSchedule();
    },

    // Load hospital information
    async loadHospitalInfo() {
        const hospitalInfoContainer = document.getElementById('hospitalInfo');
        if (!hospitalInfoContainer) return;

        try {
            console.log('📋 Loading hospital information...');
            
            // Show loading state
            hospitalInfoContainer.innerHTML = `
                <div class="loading-state">
                    <div class="spinner-container">
                        <div class="spinner-border text-primary" role="status">
                            <span class="visually-hidden">Loading...</span>
                        </div>
                    </div>
                    <p class="loading-text">Loading hospital information...</p>
                </div>
            `;

            const response = await fetch('/api/profile/hospital-info');
            if (response.ok) {
                const data = await response.json();
                this.displayHospitalInfo(data.hospital || {});
            } else {
                throw new Error('Failed to load hospital information');
            }
        } catch (error) {
            console.error('❌ Error loading hospital info:', error);
            hospitalInfoContainer.innerHTML = `
                <div class="alert alert-warning">
                    <i class="fas fa-exclamation-triangle me-2"></i>
                    Unable to load hospital information. Please try refreshing the page.
                </div>
            `;
        }
    },

    // Display hospital information
    displayHospitalInfo(hospital) {
        const hospitalInfoContainer = document.getElementById('hospitalInfo');
        if (!hospitalInfoContainer) return;

        hospitalInfoContainer.innerHTML = `
            <div class="hospital-info-grid">
                <div class="info-item">
                    <div class="info-label">
                        <i class="fas fa-hospital text-primary me-2"></i>
                        Hospital Name
                    </div>
                    <div class="info-value">${hospital.clinicName || hospital.name || 'Not specified'}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">
                        <i class="fas fa-envelope text-primary me-2"></i>
                        Email Address
                    </div>
                    <div class="info-value">${hospital.email || 'Not specified'}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">
                        <i class="fas fa-map-marker-alt text-primary me-2"></i>
                        Address
                    </div>
                    <div class="info-value">${hospital.address || hospital.location || 'Not specified'}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">
                        <i class="fas fa-phone text-primary me-2"></i>
                        Phone Number
                    </div>
                    <div class="info-value">${hospital.phone || 'Not specified'}</div>
                </div>
                <div class="info-item full-width">
                    <div class="info-label">
                        <i class="fas fa-info-circle text-primary me-2"></i>
                        About Hospital
                    </div>
                    <div class="info-value">${hospital.about || 'No description available'}</div>
                </div>
            </div>
        `;
    },

    // Load services
    async loadServices() {
        const servicesContainer = document.getElementById('servicesList');
        if (!servicesContainer) return;

        try {
            console.log('🏥 Loading services...');
            
            servicesContainer.innerHTML = `
                <div class="loading-state">
                    <div class="spinner-border text-primary" role="status"></div>
                    <p class="loading-text">Loading services...</p>
                </div>
            `;

            const response = await fetch('/api/profile/services');
            if (response.ok) {
                const data = await response.json();
                this.displayServices(data.services || []);
            } else {
                throw new Error('Failed to load services');
            }
        } catch (error) {
            console.error('❌ Error loading services:', error);
            servicesContainer.innerHTML = `
                <div class="alert alert-warning">
                    <i class="fas fa-exclamation-triangle me-2"></i>
                    Unable to load services.
                </div>
            `;
        }
    },

    // Display services
    displayServices(services) {
        const servicesContainer = document.getElementById('servicesList');
        if (!servicesContainer) return;

        if (services.length === 0) {
            servicesContainer.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-stethoscope text-muted mb-3"></i>
                    <p class="text-muted">No services configured yet</p>
                </div>
            `;
            return;
        }

        const servicesHTML = services.map(service => `
            <div class="service-item">
                <i class="fas fa-check-circle text-success me-2"></i>
                <span>${service}</span>
            </div>
        `).join('');

        servicesContainer.innerHTML = `
            <div class="services-grid">
                ${servicesHTML}
            </div>
            <div class="services-count mt-3">
                <small class="text-muted">
                    <i class="fas fa-info-circle me-1"></i>
                    ${services.length} service${services.length !== 1 ? 's' : ''} available
                </small>
            </div>
        `;
    },

    // Load schedule
    async loadSchedule() {
        const scheduleContainer = document.getElementById('scheduleList');
        if (!scheduleContainer) return;

        try {
            console.log('📅 Loading schedule...');
            
            scheduleContainer.innerHTML = `
                <div class="loading-state">
                    <div class="spinner-border text-primary" role="status"></div>
                    <p class="loading-text">Loading schedule...</p>
                </div>
            `;

            const response = await fetch('/api/profile/schedule');
            if (response.ok) {
                const data = await response.json();
                this.displaySchedule(data.schedule || {});
            } else {
                throw new Error('Failed to load schedule');
            }
        } catch (error) {
            console.error('❌ Error loading schedule:', error);
            scheduleContainer.innerHTML = `
                <div class="alert alert-warning">
                    <i class="fas fa-exclamation-triangle me-2"></i>
                    Unable to load schedule.
                </div>
            `;
        }
    },

    // Display schedule
    displaySchedule(schedule) {
        const scheduleContainer = document.getElementById('scheduleList');
        if (!scheduleContainer) return;

        const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
        const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

        const scheduleHTML = days.map((day, index) => {
            const daySchedule = schedule[day];
            const isActive = daySchedule && daySchedule.active;
            const slots = daySchedule && daySchedule.slots ? daySchedule.slots : [];

            return `
                <div class="schedule-item ${isActive ? 'active' : 'inactive'}">
                    <div class="day-header">
                        <span class="day-name">${dayNames[index]}</span>
                        <span class="status-badge ${isActive ? 'bg-success' : 'bg-secondary'}">
                            ${isActive ? 'Open' : 'Closed'}
                        </span>
                    </div>
                    ${isActive && slots.length > 0 ? `
                        <div class="time-slots">
                            ${slots.map(slot => `
                                <span class="time-slot">${slot.start} - ${slot.end}</span>
                            `).join('')}
                        </div>
                    ` : ''}
                </div>
            `;
        }).join('');

        scheduleContainer.innerHTML = `
            <div class="schedule-grid">
                ${scheduleHTML}
            </div>
        `;
    },

    // Edit hospital info
    editInfo() {
        console.log('✏️ Edit hospital info clicked');
        // This would open a modal or navigate to edit page
        alert('Edit hospital information feature coming soon!');
    },

    // Edit services
    editServices() {
        console.log('✏️ Edit services clicked');
        // This would open a modal or navigate to edit page
        alert('Edit services feature coming soon!');
    },

    // Edit schedule
    editSchedule() {
        console.log('✏️ Edit schedule clicked');
        // This would open a modal or navigate to edit page
        alert('Edit schedule feature coming soon!');
    }
};

// Auto-initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    console.log('📋 Profile page script loaded');
}); 