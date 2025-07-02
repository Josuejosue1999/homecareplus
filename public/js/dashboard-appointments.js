// Dashboard Appointments Management
const dashboardAppointments = {
    isLoading: false,
    appointments: [],

    init() {
        this.loadAppointments();
        this.setupRefreshInterval();
    },

    async loadAppointments() {
        if (this.isLoading) return;
        
        this.isLoading = true;
        this.showLoadingState();

        try {
            const response = await fetch('/api/appointments/clinic-appointments', {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                if (response.status === 401) {
                    this.showAuthenticationError();
                    return;
                }
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            console.log('Appointments data received:', data);
            
            if (data.success) {
                this.appointments = data.appointments || [];
            } else {
                this.appointments = [];
            }
            
            this.renderAppointments();

        } catch (error) {
            console.error('Error loading appointments:', error);
            this.showErrorState('Failed to load appointments. Please try again.');
        } finally {
            this.isLoading = false;
        }
    },

    showLoadingState() {
        const container = document.getElementById('appointmentsList');
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
        const container = document.getElementById('appointmentsList');
        container.innerHTML = `
            <div class="error-state">
                <i class="fas fa-exclamation-triangle"></i>
                <h6>Error Loading Appointments</h6>
                <p>${message}</p>
                <button type="button" class="retry-btn" onclick="dashboardAppointments.loadAppointments()">
                    <i class="fas fa-refresh me-2"></i>Try Again
                </button>
            </div>
        `;
    },

    showAuthenticationError() {
        const container = document.getElementById('appointmentsList');
        container.innerHTML = `
            <div class="auth-error">
                <i class="fas fa-lock"></i>
                <h6>Authentication Required</h6>
                <p>Please log in to view your appointments.</p>
                <a href="/login" class="login-btn">
                    <i class="fas fa-sign-in-alt me-2"></i>Login
                </a>
            </div>
        `;
    },

    showEmptyState() {
        const container = document.getElementById('appointmentsList');
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-calendar-times"></i>
                <h6>No Appointments Found</h6>
                <p>You don't have any upcoming appointments at the moment.</p>
            </div>
        `;
    },

    renderAppointments() {
        const container = document.getElementById('appointmentsList');
        
        if (!this.appointments || this.appointments.length === 0) {
            this.showEmptyState();
            return;
        }

        // Sort appointments by date (earliest first)
        const sortedAppointments = this.appointments.sort((a, b) => {
            const dateA = this.parseAppointmentDate(a);
            const dateB = this.parseAppointmentDate(b);
            return dateA - dateB;
        });

        const appointmentsHTML = sortedAppointments.map(appointment => {
            return this.createAppointmentCard(appointment);
        }).join('');

        container.innerHTML = `
            <div class="appointments-grid">
                ${appointmentsHTML}
            </div>
        `;

        // Add click event listeners
        this.bindAppointmentEvents();
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

    createAppointmentCard(appointment) {
        console.log('Creating card for appointment:', appointment);
        
        const date = this.parseAppointmentDate(appointment);
        const formattedDate = date.toLocaleDateString('en-US', {
            weekday: 'short',
            month: 'short',
            day: 'numeric'
        });
        const formattedTime = date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit'
        });
        const formattedDay = date.toLocaleDateString('en-US', {
            weekday: 'long'
        });

        const statusClass = this.getStatusClass(appointment.status);
        const statusIcon = this.getStatusIcon(appointment.status);
        const isToday = this.isToday(date);
        const isTomorrow = this.isTomorrow(date);

        let dateDisplay = formattedDate;
        if (isToday) {
            dateDisplay = 'Today';
        } else if (isTomorrow) {
            dateDisplay = 'Tomorrow';
        }

        return `
            <div class="appointment-card" data-appointment-id="${appointment.id}">
                <div class="appointment-card-header">
                    <div class="appointment-header-content">
                        <div class="appointment-time-section">
                            <div class="appointment-date">${dateDisplay}</div>
                            <div class="appointment-time">${formattedTime}</div>
                            <div class="appointment-day">${formattedDay}</div>
                        </div>
                        <div class="appointment-status">
                            <span class="badge ${statusClass}">
                                <i class="${statusIcon} me-1"></i>${appointment.status}
                            </span>
                        </div>
                    </div>
                </div>
                <div class="appointment-card-body">
                    <div class="patient-section">
                        <div class="patient-name">
                            <i class="fas fa-user"></i>${appointment.patientName}
                        </div>
                        <div class="patient-info">
                            ${appointment.patientPhone ? `
                            <div class="info-item">
                                <i class="fas fa-phone"></i>
                                <span>${appointment.patientPhone}</span>
                            </div>
                            ` : ''}
                            ${appointment.patientEmail ? `
                            <div class="info-item">
                                <i class="fas fa-envelope"></i>
                                <span>${appointment.patientEmail}</span>
                            </div>
                            ` : ''}
                            ${appointment.patientAge ? `
                            <div class="info-item">
                                <i class="fas fa-birthday-cake"></i>
                                <span>Age: ${appointment.patientAge}</span>
                            </div>
                            ` : ''}
                        </div>
                    </div>
                    <div class="service-section">
                        <div class="service-title">Service</div>
                        <div class="service-name">${appointment.service || appointment.department || 'General Consultation'}</div>
                    </div>
                </div>
                <div class="appointment-card-footer">
                    <button type="button" class="view-details-btn" onclick="AppointmentDetails.showDetails('${appointment.id}')">
                        <i class="fas fa-eye me-1"></i>View Details
                    </button>
                </div>
            </div>
        `;
    },

    getStatusClass(status) {
        switch (status?.toLowerCase()) {
            case 'confirmed':
                return 'bg-success';
            case 'pending':
                return 'bg-warning';
            case 'cancelled':
            case 'rejected':
                return 'bg-danger';
            case 'completed':
                return 'bg-info';
            default:
                return 'bg-secondary';
        }
    },

    getStatusIcon(status) {
        switch (status?.toLowerCase()) {
            case 'confirmed':
                return 'fas fa-check-circle';
            case 'pending':
                return 'fas fa-clock';
            case 'cancelled':
            case 'rejected':
                return 'fas fa-times-circle';
            case 'completed':
                return 'fas fa-check-double';
            default:
                return 'fas fa-question-circle';
        }
    },

    isToday(date) {
        const today = new Date();
        return date.toDateString() === today.toDateString();
    },

    isTomorrow(date) {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        return date.toDateString() === tomorrow.toDateString();
    },

    bindAppointmentEvents() {
        // Event listeners are handled by onclick attributes in the HTML
    },

    refresh() {
        this.loadAppointments();
    },

    setupRefreshInterval() {
        // Refresh appointments every 5 minutes
        setInterval(() => {
            this.loadAppointments();
        }, 5 * 60 * 1000);
    }
};

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    dashboardAppointments.init();
});

// Make it globally available
window.dashboardAppointments = dashboardAppointments;

// Global function for backward compatibility with old template
function viewAppointment(appointmentId) {
    console.log('viewAppointment called with ID:', appointmentId);
    if (window.AppointmentDetails) {
        AppointmentDetails.showDetails(appointmentId);
    } else {
        console.error('AppointmentDetails not available');
        alert('Appointment details feature not available');
    }
}

// Make viewAppointment globally available
window.viewAppointment = viewAppointment; 