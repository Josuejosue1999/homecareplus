// Appointment Details Modal Module
const AppointmentDetails = {
    modal: null,
    currentAppointment: null,

    init() {
        this.createModal();
        this.bindEvents();
    },

    createModal() {
        const modalHTML = `
            <div class="modal fade" id="appointmentDetailsModal" tabindex="-1" aria-labelledby="appointmentDetailsModalLabel" aria-hidden="true">
                <div class="modal-dialog modal-lg modal-dialog-centered">
                    <div class="modal-content border-0 shadow-lg">
                        <div class="modal-header bg-gradient-primary text-white border-0">
                            <h5 class="modal-title" id="appointmentDetailsModalLabel">
                                <i class="fas fa-calendar-check me-2"></i>
                                Appointment Details
                            </h5>
                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                        <div class="modal-body p-0">
                            <div id="appointmentDetailsContent">
                                <!-- Content will be loaded dynamically -->
                            </div>
                        </div>
                        <div class="modal-footer bg-light border-0">
                            <div class="d-flex justify-content-between w-100">
                                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
                                    <i class="fas fa-times me-2"></i>Close
                                </button>
                                <div class="action-buttons">
                                    <button type="button" class="btn btn-success me-2" id="approveBtn" style="display: none;">
                                        <i class="fas fa-check me-2"></i>Approve
                                    </button>
                                    <button type="button" class="btn btn-danger" id="rejectBtn" style="display: none;">
                                        <i class="fas fa-times me-2"></i>Reject
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalHTML);
        this.modal = new bootstrap.Modal(document.getElementById('appointmentDetailsModal'));
    },

    bindEvents() {
        document.getElementById('approveBtn').addEventListener('click', () => this.confirmApprove());
        document.getElementById('rejectBtn').addEventListener('click', () => this.confirmReject());
    },

    async showDetails(appointmentId) {
        try {
            console.log('=== SHOWING APPOINTMENT DETAILS ===');
            console.log('Appointment ID:', appointmentId);
            
            // Show loading state
            this.showLoadingState();
            this.modal.show();

            // Fetch appointment details
            const response = await fetch(`/api/appointments/${appointmentId}`, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            console.log('Response status:', response.status);
            console.log('Response headers:', response.headers);

            if (!response.ok) {
                const errorText = await response.text();
                console.error('Response error text:', errorText);
                
                if (response.status === 401) {
                    throw new Error('Authentication required. Please log in again.');
                } else if (response.status === 404) {
                    throw new Error('Appointment not found.');
                } else if (response.status === 403) {
                    throw new Error('You don\'t have permission to view this appointment.');
                } else {
                    throw new Error(`Server error: ${response.status} ${response.statusText}`);
                }
            }

            const appointment = await response.json();
            console.log('Appointment details received:', appointment);
            
            if (!appointment || !appointment.success) {
                throw new Error(appointment?.message || 'Invalid appointment data received');
            }
            
            const appointmentData = appointment.appointment;
            if (!appointmentData || !appointmentData.id) {
                throw new Error('Invalid appointment data structure');
            }
            
            this.currentAppointment = appointmentData;
            this.renderDetails(appointmentData);

        } catch (error) {
            console.error('Error fetching appointment details:', error);
            this.showErrorState(error.message || 'Failed to load appointment details');
        }
    },

    showLoadingState() {
        const content = document.getElementById('appointmentDetailsContent');
        content.innerHTML = `
            <div class="text-center py-5">
                <div class="spinner-border text-primary mb-3" role="status">
                    <span class="visually-hidden">Loading...</span>
                </div>
                <p class="text-muted">Loading appointment details...</p>
            </div>
        `;
    },

    showErrorState(message) {
        const content = document.getElementById('appointmentDetailsContent');
        content.innerHTML = `
            <div class="text-center py-5">
                <div class="text-danger mb-3">
                    <i class="fas fa-exclamation-triangle fa-3x"></i>
                </div>
                <h6 class="text-danger">Error</h6>
                <p class="text-muted">${message}</p>
                <button type="button" class="btn btn-outline-primary" onclick="AppointmentDetails.modal.hide()">
                    <i class="fas fa-times me-2"></i>Close
                </button>
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

    renderDetails(appointment) {
        const content = document.getElementById('appointmentDetailsContent');
        const statusClass = this.getStatusClass(appointment.status);
        const statusIcon = this.getStatusIcon(appointment.status);
        
        const date = this.parseAppointmentDate(appointment);
        const formattedDate = date.toLocaleDateString('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
        const formattedTime = date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit'
        });

        content.innerHTML = `
            <div class="appointment-details-container">
                <!-- Header Section -->
                <div class="appointment-header bg-light p-4 border-bottom">
                    <div class="row align-items-center">
                        <div class="col-md-8">
                            <h4 class="mb-1 text-primary">${appointment.patientName}</h4>
                            <p class="text-muted mb-0">
                                <i class="fas fa-calendar me-2"></i>${formattedDate} at ${formattedTime}
                            </p>
                        </div>
                        <div class="col-md-4 text-end">
                            <span class="badge ${statusClass} fs-6 px-3 py-2">
                                <i class="${statusIcon} me-2"></i>${appointment.status}
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Details Section -->
                <div class="appointment-body p-4">
                    <div class="row">
                        <!-- Patient Information -->
                        <div class="col-md-6 mb-4">
                            <div class="detail-section">
                                <h6 class="section-title">
                                    <i class="fas fa-user text-primary me-2"></i>Patient Information
                                </h6>
                                <div class="detail-item">
                                    <label>Name:</label>
                                    <span>${appointment.patientName}</span>
                                </div>
                                <div class="detail-item">
                                    <label>Phone:</label>
                                    <span>${appointment.patientPhone || 'Not provided'}</span>
                                </div>
                                <div class="detail-item">
                                    <label>Email:</label>
                                    <span>${appointment.patientEmail || 'Not provided'}</span>
                                </div>
                                <div class="detail-item">
                                    <label>Age:</label>
                                    <span>${appointment.patientAge || 'Not specified'}</span>
                                </div>
                            </div>
                        </div>

                        <!-- Appointment Information -->
                        <div class="col-md-6 mb-4">
                            <div class="detail-section">
                                <h6 class="section-title">
                                    <i class="fas fa-calendar-alt text-primary me-2"></i>Appointment Details
                                </h6>
                                <div class="detail-item">
                                    <label>Hospital:</label>
                                    <span>${appointment.hospital || appointment.hospitalName}</span>
                                </div>
                                <div class="detail-item">
                                    <label>Service:</label>
                                    <span>${appointment.service || appointment.department || 'General Consultation'}</span>
                                </div>
                                <div class="detail-item">
                                    <label>Duration:</label>
                                    <span>${appointment.duration || '30 minutes'}</span>
                                </div>
                                <div class="detail-item">
                                    <label>Created:</label>
                                    <span>${new Date(appointment.createdAt).toLocaleDateString()}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Notes Section -->
                    ${appointment.notes ? `
                    <div class="row">
                        <div class="col-12">
                            <div class="detail-section">
                                <h6 class="section-title">
                                    <i class="fas fa-sticky-note text-primary me-2"></i>Notes
                                </h6>
                                <div class="notes-content">
                                    <p class="mb-0">${appointment.notes}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                    ` : ''}
                </div>
            </div>
        `;

        // Show action buttons only for pending appointments
        const approveBtn = document.getElementById('approveBtn');
        const rejectBtn = document.getElementById('rejectBtn');
        
        if (appointment.status?.toLowerCase() === 'pending') {
            approveBtn.style.display = 'inline-block';
            rejectBtn.style.display = 'inline-block';
        } else {
            approveBtn.style.display = 'none';
            rejectBtn.style.display = 'none';
        }
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

    confirmApprove() {
        // Hide the modal first to avoid z-index issues
        this.modal.hide();
        
        setTimeout(() => {
            Swal.fire({
                title: 'Confirm Approval',
                text: 'Are you sure you want to approve this appointment?',
                icon: 'question',
                showCancelButton: true,
                confirmButtonColor: '#28a745',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Yes, Approve',
                cancelButtonText: 'Cancel',
                allowOutsideClick: false,
                allowEscapeKey: false
            }).then((result) => {
                if (result.isConfirmed) {
                    this.approveAppointment();
                } else {
                    // Show the modal again if cancelled
                    this.modal.show();
                }
            });
        }, 300);
    },

    confirmReject() {
        // Hide the modal first to avoid z-index issues
        this.modal.hide();
        
        setTimeout(() => {
            Swal.fire({
                title: 'Confirm Rejection',
                text: 'Are you sure you want to reject this appointment?',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#dc3545',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Yes, Reject',
                cancelButtonText: 'Cancel',
                allowOutsideClick: false,
                allowEscapeKey: false
            }).then((result) => {
                if (result.isConfirmed) {
                    this.rejectAppointment();
                } else {
                    // Show the modal again if cancelled
                    this.modal.show();
                }
            });
        }, 300);
    },

    async approveAppointment() {
        if (!this.currentAppointment) return;

        try {
            const response = await fetch(`/api/appointments/${this.currentAppointment.id}/approve`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error('Failed to approve appointment');
            }

            const result = await response.json();
            
            if (result.success) {
                Swal.fire({
                    title: 'Success!',
                    text: 'Appointment approved successfully',
                    icon: 'success',
                    timer: 2000,
                    showConfirmButton: false
                });
                
                this.modal.hide();
                dashboardAppointments.refresh();
            } else {
                throw new Error(result.message || 'Failed to approve appointment');
            }

        } catch (error) {
            console.error('Error approving appointment:', error);
            Swal.fire({
                title: 'Error!',
                text: 'Failed to approve appointment. Please try again.',
                icon: 'error'
            });
        }
    },

    async rejectAppointment() {
        if (!this.currentAppointment) return;

        try {
            const response = await fetch(`/api/appointments/${this.currentAppointment.id}/reject`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error('Failed to reject appointment');
            }

            const result = await response.json();
            
            if (result.success) {
                Swal.fire({
                    title: 'Success!',
                    text: 'Appointment rejected successfully',
                    icon: 'success',
                    timer: 2000,
                    showConfirmButton: false
                });
                
                this.modal.hide();
                dashboardAppointments.refresh();
            } else {
                throw new Error(result.message || 'Failed to reject appointment');
            }

        } catch (error) {
            console.error('Error rejecting appointment:', error);
            Swal.fire({
                title: 'Error!',
                text: 'Failed to reject appointment. Please try again.',
                icon: 'error'
            });
        }
    }
};

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    AppointmentDetails.init();
});

// Make it globally available
window.AppointmentDetails = AppointmentDetails; 