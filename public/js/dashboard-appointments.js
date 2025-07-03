// Dashboard Appointments Management
const dashboardAppointments = {
    isLoading: false,
    appointments: [],

    init() {
        this.loadAppointments();
        this.loadMetrics();
        this.setupRefreshInterval();
        this.initTrendsChart();
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
            
            this.renderSimplifiedAppointments();
            this.updateMetrics();

        } catch (error) {
            console.error('Error loading appointments:', error);
            this.showErrorState('Failed to load appointments. Please try again.');
        } finally {
            this.isLoading = false;
        }
    },

    async loadMetrics() {
        try {
            // Calculate metrics from appointments data
            const total = this.appointments.length;
            const approved = this.appointments.filter(apt => 
                apt.status === 'confirmed' || apt.status === 'approved'
            ).length;
            const pending = this.appointments.filter(apt => 
                apt.status === 'pending' || apt.status === 'waiting'
            ).length;

            this.updateMetricsDisplay(total, approved, pending);
        } catch (error) {
            console.error('Error loading metrics:', error);
        }
    },

    updateMetricsDisplay(total, approved, pending) {
        const totalEl = document.getElementById('totalAppointments');
        const approvedEl = document.getElementById('approvedAppointments');
        const pendingEl = document.getElementById('pendingAppointments');

        if (totalEl) totalEl.textContent = total;
        if (approvedEl) approvedEl.textContent = approved;
        if (pendingEl) pendingEl.textContent = pending;
    },

    updateMetrics() {
        if (this.appointments.length > 0) {
            this.loadMetrics();
        }
    },

    showLoadingState() {
        const container = document.getElementById('upcomingAppointmentsList');
        if (container) {
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
        }
    },

    showErrorState(message) {
        const container = document.getElementById('upcomingAppointmentsList');
        if (container) {
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
        }
    },

    showAuthenticationError() {
        const container = document.getElementById('upcomingAppointmentsList');
        if (container) {
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
        }
    },

    showEmptyState() {
        const container = document.getElementById('upcomingAppointmentsList');
        if (container) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-calendar-times"></i>
                <h6>No Appointments Found</h6>
                <p>You don't have any upcoming appointments at the moment.</p>
            </div>
        `;
        }
    },

    renderSimplifiedAppointments() {
        const container = document.getElementById('upcomingAppointmentsList');
        
        if (!this.appointments || this.appointments.length === 0) {
            this.showEmptyState();
            return;
        }

        // Sort appointments by date (earliest first) and take only next 5
        const sortedAppointments = this.appointments
            .sort((a, b) => {
            const dateA = this.parseAppointmentDate(a);
            const dateB = this.parseAppointmentDate(b);
            return dateA - dateB;
            })
            .slice(0, 5); // Only show next 5 appointments

        const appointmentsHTML = sortedAppointments.map(appointment => {
            return this.createSimplifiedAppointmentCard(appointment);
        }).join('');

        container.innerHTML = `
            <div class="simplified-appointments-list">
                ${appointmentsHTML}
            </div>
        `;
    },

    createSimplifiedAppointmentCard(appointment) {
        const date = this.parseAppointmentDate(appointment);
        const formattedDate = date.toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric'
        });
        const formattedTime = date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit'
        });

        const statusClass = this.getStatusClass(appointment.status);
        const statusIcon = this.getStatusIcon(appointment.status);
        const isToday = this.isToday(date);
        const isTomorrow = this.isTomorrow(date);

        let dateDisplay = formattedDate;
        if (isToday) {
            dateDisplay = '<span style="color: var(--success-color); font-weight: 700;">Today</span>';
        } else if (isTomorrow) {
            dateDisplay = '<span style="color: var(--warning-color); font-weight: 700;">Tomorrow</span>';
        }

        // Enhanced patient name with proper fallback
        const patientName = appointment.patientName || appointment.userName || 'Patient';
        
        // Get patient initials for fallback avatar
        const initials = this.getPatientInitials(patientName);
        
        // Enhanced patient image handling with multiple fallback options
        const patientImageFields = [
            'patientProfileImage', 'patientImage', 'userProfileImage', 
            'profileImage', 'avatar', 'profileImageUrl', 'imageUrl',
            'patientAvatar', 'userAvatar', 'photo'
        ];
        
        let patientImage = null;
        for (const field of patientImageFields) {
            if (appointment[field] && appointment[field].trim()) {
                patientImage = appointment[field];
                break;
            }
        }

        // Enhanced avatar HTML with proper error handling and professional styling
        const avatarHTML = patientImage ? 
            `<img src="${patientImage}" alt="${patientName}" 
                  onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';"
                  style="width: 100%; height: 100%; object-fit: cover; border-radius: 13px; transition: transform 0.3s ease;">
             <div class="avatar-fallback" style="display: none; width: 100%; height: 100%; background: linear-gradient(135deg, var(--primary-color), var(--secondary-color)); border-radius: 13px; align-items: center; justify-content: center; color: white; font-weight: 700; font-size: 1.25rem; text-transform: uppercase; letter-spacing: 0.5px;">
                 ${initials}
             </div>` :
            `<div class="avatar-initials" style="width: 100%; height: 100%; background: linear-gradient(135deg, var(--primary-color), var(--secondary-color)); border-radius: 13px; display: flex; align-items: center; justify-content: center; color: white; font-weight: 700; font-size: 1.25rem; text-transform: uppercase; letter-spacing: 0.5px;">
                ${initials}
             </div>`;

        // Enhanced status display with better formatting
        const statusDisplay = (appointment.status || 'pending').charAt(0).toUpperCase() + 
                             (appointment.status || 'pending').slice(1).toLowerCase();

        // Enhanced appointment details
        const serviceType = appointment.serviceType || appointment.service || appointment.specialty || 'General Consultation';
        const appointmentId = appointment.id || appointment.appointmentId || Math.random().toString(36).substr(2, 9);
        
        // Professional contact information display
        const patientPhone = appointment.patientPhone || appointment.phone || appointment.phoneNumber || '';
        const patientEmail = appointment.patientEmail || appointment.email || '';

        return `
            <div class="simplified-appointment-item" data-appointment-id="${appointmentId}" data-patient-name="${patientName}">
                <div class="appointment-avatar" title="${patientName}">
                    ${avatarHTML}
                </div>
                <div class="appointment-info">
                    <div class="patient-name" title="${patientName}">${this.truncateText(patientName, 20)}</div>
                    <div class="service-info" style="font-size: 0.85rem; color: #64748b; margin-bottom: 0.5rem; font-weight: 500; display: flex; align-items: center;">
                        <i class="fas fa-stethoscope" style="margin-right: 0.5rem; color: var(--primary-color); font-size: 0.8rem;"></i>
                        ${this.truncateText(serviceType, 25)}
                    </div>
                    <div class="appointment-datetime">
                        <span class="date">${dateDisplay}</span>
                        <span class="time">${formattedTime}</span>
                    </div>
                    <div class="appointment-status">
                        <span class="status-badge ${statusClass}" title="Appointment status: ${statusDisplay}">
                            <i class="${statusIcon}"></i>
                            ${statusDisplay}
                        </span>
                    </div>
                </div>
                <div class="appointment-actions">
                    <button class="btn btn-sm btn-outline-primary" 
                            onclick="viewAppointmentDetails('${appointmentId}')" 
                            title="View full appointment details for ${patientName}">
                        <i class="fas fa-eye me-1"></i>
                        Details
                    </button>
                </div>
            </div>
        `;
    },

    // Helper function to truncate text for better display
    truncateText(text, maxLength) {
        if (!text) return '';
        if (text.length <= maxLength) return text;
        return text.substring(0, maxLength - 3) + '...';
    },

    // Enhanced function to get patient initials with better logic
    getPatientInitials(name) {
        if (!name || name === 'Patient' || name.trim() === '') {
            return 'P';
        }
        
        const cleanName = name.trim().replace(/[^a-zA-Z\s]/g, '');
        const names = cleanName.split(' ').filter(n => n.length > 0);
        
        if (names.length === 0) {
            return 'P';
        } else if (names.length === 1) {
            return names[0].charAt(0).toUpperCase();
        } else {
            return (names[0].charAt(0) + names[names.length - 1].charAt(0)).toUpperCase();
        }
    },

    // Enhanced function to try fetching patient avatar from API
    async tryFetchPatientAvatar(patientId, patientName) {
        if (!patientId) return null;
        
        try {
            const response = await fetch(`/api/patients/${patientId}/avatar`, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json'
                }
            });
            
            if (response.ok) {
                const data = await response.json();
                return data.avatar || data.profileImage || data.imageUrl;
            }
        } catch (error) {
            console.log(`Could not fetch avatar for patient ${patientName}:`, error);
        }
        
        return null;
    },

    initTrendsChart() {
        const ctx = document.getElementById('appointmentTrendsChart');
        if (ctx) {
            const chartData = this.generateTrendsData();
            
            // Enhanced chart configuration with modern styling
            new Chart(ctx.getContext('2d'), {
                type: 'line',
                data: {
                    labels: chartData.labels,
                    datasets: [{
                        label: 'Appointments',
                        data: chartData.data,
                        backgroundColor: 'rgba(21, 155, 189, 0.1)',
                        borderColor: 'rgba(21, 155, 189, 1)',
                        borderWidth: 3,
                        tension: 0.4,
                        fill: true,
                        pointBackgroundColor: 'rgba(21, 155, 189, 1)',
                        pointBorderColor: '#fff',
                        pointBorderWidth: 3,
                        pointRadius: 6,
                        pointHoverRadius: 8,
                        pointHoverBackgroundColor: 'rgba(21, 155, 189, 1)',
                        pointHoverBorderColor: '#fff',
                        pointHoverBorderWidth: 3,
                        shadowOffsetX: 3,
                        shadowOffsetY: 3,
                        shadowBlur: 10,
                        shadowColor: 'rgba(21, 155, 189, 0.2)'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    interaction: {
                        intersect: false,
                        mode: 'index'
                    },
                    plugins: { 
                        legend: { 
                            display: false 
                        },
                        tooltip: {
                            backgroundColor: 'rgba(0, 0, 0, 0.9)',
                            titleColor: '#fff',
                            bodyColor: '#fff',
                            borderColor: 'rgba(21, 155, 189, 1)',
                            borderWidth: 2,
                            cornerRadius: 12,
                            padding: 12,
                            displayColors: false,
                            titleFont: {
                                size: 14,
                                weight: 'bold'
                            },
                            bodyFont: {
                                size: 13
                            },
                            callbacks: {
                                title: function(context) {
                                    return context[0].label;
                                },
                                label: function(context) {
                                    return `${context.parsed.y} appointments`;
                                }
                            }
                        }
                    },
                    scales: {
                        y: { 
                            beginAtZero: true,
                            grid: {
                                color: 'rgba(107, 114, 128, 0.08)',
                                drawBorder: false,
                                lineWidth: 1
                            },
                            ticks: { 
                                color: '#6B7280',
                                font: {
                                    size: 12,
                                    weight: '500'
                                },
                                padding: 12,
                                stepSize: 1
                            },
                            border: {
                                display: false
                            }
                        },
                        x: { 
                            grid: {
                                color: 'rgba(107, 114, 128, 0.08)',
                                drawBorder: false,
                                lineWidth: 1
                            },
                            ticks: { 
                                color: '#6B7280',
                                font: {
                                    size: 12,
                                    weight: '500'
                                },
                                padding: 12
                            },
                            border: {
                                display: false
                            }
                        }
                    },
                    elements: {
                        point: {
                            hoverRadius: 8
                        }
                    }
                }
            });
        }
    },

    generateTrendsData() {
        // Generate more realistic sample data based on actual appointments
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        let data;
        
        if (this.appointments && this.appointments.length > 0) {
            // Generate data based on actual appointments if available
            const appointmentsByDay = new Array(7).fill(0);
            const today = new Date();
            const startOfWeek = new Date(today);
            startOfWeek.setDate(today.getDate() - today.getDay() + 1); // Start from Monday
            
            this.appointments.forEach(appointment => {
                const appointmentDate = this.parseAppointmentDate(appointment);
                const dayDiff = Math.floor((appointmentDate - startOfWeek) / (1000 * 60 * 60 * 24));
                if (dayDiff >= 0 && dayDiff < 7) {
                    appointmentsByDay[dayDiff]++;
                }
            });
            
            data = appointmentsByDay;
        } else {
            // Fallback to sample data with more realistic patterns
            data = [8, 12, 6, 15, 10, 14, 9];
        }

        return {
            labels: days,
            data: data
        };
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
        const today = new Date();
        const tomorrow = new Date(today);
        tomorrow.setDate(today.getDate() + 1);
        
        return date.toDateString() === tomorrow.toDateString();
    },

    bindAppointmentEvents() {
        // Bind any additional event listeners for appointment items
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