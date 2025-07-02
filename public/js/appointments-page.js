// Appointments Page Module
const appointmentsPage = {
    currentFilter: 'all',
    allAppointments: [],

    init() {
        this.bindEvents();
        this.loadAllAppointments();
    },

    bindEvents() {
        // Filter buttons
        document.querySelectorAll('[data-filter]').forEach(button => {
            button.addEventListener('click', (e) => {
                this.setActiveFilter(e.target.dataset.filter);
            });
        });
    },

    setActiveFilter(filter) {
        this.currentFilter = filter;
        
        // Update button states
        document.querySelectorAll('[data-filter]').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-filter="${filter}"]`).classList.add('active');
        
        // Filter and display appointments
        this.displayAppointments();
    },

    async loadAllAppointments() {
        try {
            this.showLoadingState();
            
            const response = await fetch('/api/appointments/clinic-appointments');
            if (!response.ok) {
                throw new Error('Failed to load appointments');
            }
            
            const data = await response.json();
            this.allAppointments = data.appointments || [];
            
            this.updateStatistics();
            this.displayAppointments();
            
        } catch (error) {
            console.error('Error loading appointments:', error);
            this.showErrorState('Failed to load appointments. Please try again.');
        }
    },

    updateStatistics() {
        const total = this.allAppointments.length;
        const pending = this.allAppointments.filter(apt => apt.status === 'pending').length;
        const confirmed = this.allAppointments.filter(apt => apt.status === 'confirmed').length;
        const cancelled = this.allAppointments.filter(apt => apt.status === 'cancelled').length;

        document.getElementById('totalAppointments').textContent = total;
        document.getElementById('pendingAppointments').textContent = pending;
        document.getElementById('confirmedAppointments').textContent = confirmed;
        document.getElementById('cancelledAppointments').textContent = cancelled;
    },

    displayAppointments() {
        const container = document.getElementById('appointmentsPageList');
        
        // Filter appointments based on current filter
        let filteredAppointments = this.allAppointments;
        if (this.currentFilter !== 'all') {
            filteredAppointments = this.allAppointments.filter(apt => apt.status === this.currentFilter);
        }

        if (filteredAppointments.length === 0) {
            this.showEmptyState();
            return;
        }

        // Sort appointments by date (most recent first)
        filteredAppointments.sort((a, b) => {
            const dateA = this.parseAppointmentDate(a);
            const dateB = this.parseAppointmentDate(b);
            return dateB - dateA;
        });

        const appointmentsHTML = filteredAppointments.map(appointment => 
            this.createAppointmentCard(appointment)
        ).join('');

        container.innerHTML = `
            <div class="appointments-page-grid">
                ${appointmentsHTML}
            </div>
        `;

        // Add click events to appointment cards
        document.querySelectorAll('.appointment-page-card').forEach(card => {
            card.addEventListener('click', (e) => {
                const appointmentId = card.dataset.appointmentId;
                AppointmentDetails.showAppointmentDetails(appointmentId);
            });
        });
    },

    createAppointmentCard(appointment) {
        const date = this.parseAppointmentDate(appointment);
        const timeString = date.toLocaleTimeString('en-US', { 
            hour: '2-digit', 
            minute: '2-digit',
            hour12: true 
        });
        const dateString = date.toLocaleDateString('en-US', { 
            month: 'short', 
            day: 'numeric', 
            year: 'numeric' 
        });
        const dayString = date.toLocaleDateString('en-US', { weekday: 'long' });
        
        const patientName = appointment.patientName || appointment.name || 'Unknown Patient';
        const service = appointment.service || appointment.serviceType || 'General Consultation';
        const phone = appointment.patientPhone || appointment.phone || 'N/A';
        const notes = appointment.notes || appointment.description || 'No additional notes';

        const statusClass = this.getStatusClass(appointment.status);
        const statusText = appointment.status || 'pending';

        return `
            <div class="appointment-page-card" data-appointment-id="${appointment.id}">
                <div class="appointment-page-card-header">
                    <div class="appointment-page-time">${timeString}</div>
                    <div class="appointment-page-date">${dateString}</div>
                    <div class="appointment-page-day">${dayString}</div>
                    <div class="appointment-page-status ${statusClass}">${statusText}</div>
                </div>
                <div class="appointment-page-card-body">
                    <div class="appointment-page-patient">
                        <div class="appointment-page-patient-avatar">
                            ${this.getInitials(patientName)}
                        </div>
                        <div class="appointment-page-patient-info">
                            <h6>${patientName}</h6>
                            <p>Patient</p>
                        </div>
                    </div>
                    <div class="appointment-page-details">
                        <div class="appointment-page-detail-item">
                            <div class="appointment-page-detail-icon">
                                <i class="fas fa-stethoscope"></i>
                            </div>
                            <div class="appointment-page-detail-content">
                                <h6>Service</h6>
                                <p>${service}</p>
                            </div>
                        </div>
                        <div class="appointment-page-detail-item">
                            <div class="appointment-page-detail-icon">
                                <i class="fas fa-phone"></i>
                            </div>
                            <div class="appointment-page-detail-content">
                                <h6>Phone</h6>
                                <p>${phone}</p>
                            </div>
                        </div>
                        <div class="appointment-page-detail-item">
                            <div class="appointment-page-detail-icon">
                                <i class="fas fa-calendar"></i>
                            </div>
                            <div class="appointment-page-detail-content">
                                <h6>Date</h6>
                                <p>${dateString}</p>
                            </div>
                        </div>
                        <div class="appointment-page-detail-item">
                            <div class="appointment-page-detail-icon">
                                <i class="fas fa-clock"></i>
                            </div>
                            <div class="appointment-page-detail-content">
                                <h6>Time</h6>
                                <p>${timeString}</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    },

    parseAppointmentDate(appointment) {
        // Handle different date formats from the database
        let dateString = appointment.date || appointment.appointmentDate;
        
        if (!dateString) {
            console.warn('No date found for appointment:', appointment);
            return new Date();
        }

        // If it's a Firestore timestamp
        if (dateString.seconds) {
            return new Date(dateString.seconds * 1000);
        }

        // If it's already a Date object
        if (dateString instanceof Date) {
            return dateString;
        }

        // Try to parse as string
        const parsed = new Date(dateString);
        if (isNaN(parsed.getTime())) {
            console.warn('Invalid date format:', dateString);
            return new Date();
        }

        return parsed;
    },

    getStatusClass(status) {
        switch (status?.toLowerCase()) {
            case 'confirmed':
                return 'confirmed';
            case 'cancelled':
                return 'cancelled';
            case 'pending':
            default:
                return 'pending';
        }
    },

    getInitials(name) {
        if (!name) return '?';
        return name.split(' ')
            .map(word => word.charAt(0))
            .join('')
            .toUpperCase()
            .slice(0, 2);
    },

    showLoadingState() {
        const container = document.getElementById('appointmentsPageList');
        container.innerHTML = `
            <div class="loading-state">
                <div class="spinner-container">
                    <div class="spinner-border text-primary" role="status">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                </div>
                <p class="loading-text">Loading appointments...</p>
            </div>
        `;
    },

    showErrorState(message) {
        const container = document.getElementById('appointmentsPageList');
        container.innerHTML = `
            <div class="error-state">
                <i class="fas fa-exclamation-triangle"></i>
                <h5>Error</h5>
                <p class="error-text">${message}</p>
                <button class="btn btn-primary" onclick="appointmentsPage.loadAllAppointments()">
                    <i class="fas fa-refresh me-2"></i>Try Again
                </button>
            </div>
        `;
    },

    showEmptyState() {
        const container = document.getElementById('appointmentsPageList');
        const filterText = this.currentFilter === 'all' ? '' : ` for ${this.currentFilter} appointments`;
        
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-calendar-times"></i>
                <h5>No Appointments Found</h5>
                <p class="empty-text">There are no appointments${filterText} at the moment.</p>
                <button class="btn btn-outline-primary" onclick="appointmentsPage.setActiveFilter('all')">
                    <i class="fas fa-list me-2"></i>View All Appointments
                </button>
            </div>
        `;
    },

    refresh() {
        this.loadAllAppointments();
    }
};

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    appointmentsPage.init();
}); 