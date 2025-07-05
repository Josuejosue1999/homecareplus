// Modern Appointments Page Module
const appointmentsPage = {
    // Data and state
    allAppointments: [],
    filteredAppointments: [],
    currentFilter: 'all',
    currentSort: { field: 'date', direction: 'desc' },
    currentPage: 1,
    itemsPerPage: 10,
    searchTerm: '',

    // Initialize the module
    init() {
        this.bindEvents();
        this.loadAllAppointments();
        this.setupSearch();
        this.setupFilters();
        this.setupTableSorting();
    },

    // Bind all event listeners
    bindEvents() {
        // Search input
        const searchInput = document.getElementById('appointmentSearch');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.searchTerm = e.target.value.toLowerCase();
                this.applyFiltersAndSort();
            });
        }

        // Filter dropdown
        document.querySelectorAll('.filter-option').forEach(option => {
            option.addEventListener('click', (e) => {
                e.preventDefault();
                this.setActiveFilter(e.target.dataset.filter);
            });
        });
    },

    // Setup search functionality
    setupSearch() {
        const searchInput = document.getElementById('appointmentSearch');
        if (searchInput) {
            // Add search icon click handler
            const searchIcon = document.querySelector('.search-icon');
            if (searchIcon) {
                searchIcon.addEventListener('click', () => {
                    searchInput.focus();
                });
            }
        }
    },

    // Setup filter functionality
    setupFilters() {
        const filterDropdown = document.getElementById('filterDropdown');
        if (filterDropdown) {
            // Update dropdown text based on selection
            document.querySelectorAll('.filter-option').forEach(option => {
                option.addEventListener('click', () => {
                    // Update active state
                    document.querySelectorAll('.filter-option').forEach(opt => opt.classList.remove('active'));
                    option.classList.add('active');
                    
                    // Update dropdown button text
                    const filterText = option.textContent.trim();
                    filterDropdown.innerHTML = `<i class="fas fa-filter me-2"></i>${filterText}`;
                });
            });
        }
    },

    // Setup table sorting
    setupTableSorting() {
        document.querySelectorAll('.sortable').forEach(header => {
            header.addEventListener('click', () => {
                const sortField = header.dataset.sort;
                this.handleSort(sortField);
            });
        });
    },

    // Handle sorting
    handleSort(field) {
        if (this.currentSort.field === field) {
            this.currentSort.direction = this.currentSort.direction === 'asc' ? 'desc' : 'asc';
        } else {
            this.currentSort.field = field;
            this.currentSort.direction = 'asc';
        }

        this.updateSortIcons();
        this.applyFiltersAndSort();
    },

    // Update sort icons
    updateSortIcons() {
        document.querySelectorAll('.sortable').forEach(header => {
            header.classList.remove('sorted');
            const icon = header.querySelector('.sort-icon');
            icon.className = 'fas fa-sort sort-icon';
            
            if (header.dataset.sort === this.currentSort.field) {
                header.classList.add('sorted');
                icon.className = `fas fa-sort-${this.currentSort.direction === 'asc' ? 'up' : 'down'} sort-icon`;
            }
        });
    },

    // Set active filter
    setActiveFilter(filter) {
        this.currentFilter = filter;
        this.currentPage = 1; // Reset to first page
        this.applyFiltersAndSort();
    },

    // Load all appointments from API
    async loadAllAppointments() {
        try {
            this.showLoadingState();
            
            const response = await fetch('/api/appointments/clinic-appointments');
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const data = await response.json();
            this.allAppointments = data.appointments || [];
            
            this.updateStatistics();
            this.applyFiltersAndSort();
            
        } catch (error) {
            console.error('Error loading appointments:', error);
            this.showErrorState('Failed to load appointments. Please try again.');
        }
    },

    // Apply filters, search, and sorting
    applyFiltersAndSort() {
        let filtered = [...this.allAppointments];

        // Apply search filter
        if (this.searchTerm) {
            filtered = filtered.filter(appointment => {
                const patientName = (appointment.patientName || appointment.name || '').toLowerCase();
                const service = (appointment.service || appointment.serviceType || '').toLowerCase();
                const phone = (appointment.patientPhone || appointment.phone || '').toLowerCase();
                
                return patientName.includes(this.searchTerm) || 
                       service.includes(this.searchTerm) || 
                       phone.includes(this.searchTerm);
            });
        }

        // Apply status filter
        if (this.currentFilter !== 'all') {
            if (this.currentFilter === 'today') {
                const today = new Date();
                filtered = filtered.filter(appointment => {
                    const appointmentDate = this.parseAppointmentDate(appointment);
                    return appointmentDate.toDateString() === today.toDateString();
                });
            } else if (this.currentFilter === 'upcoming') {
                const today = new Date();
                filtered = filtered.filter(appointment => {
                    const appointmentDate = this.parseAppointmentDate(appointment);
                    return appointmentDate > today;
                });
            } else {
                filtered = filtered.filter(appointment => 
                    (appointment.status || 'pending').toLowerCase() === this.currentFilter
                );
            }
        }

        // Apply sorting
        filtered.sort((a, b) => {
            let aValue, bValue;
            
            switch (this.currentSort.field) {
                case 'patient':
                    aValue = (a.patientName || a.name || '').toLowerCase();
                    bValue = (b.patientName || b.name || '').toLowerCase();
                    break;
                case 'service':
                    aValue = (a.service || a.serviceType || '').toLowerCase();
                    bValue = (b.service || b.serviceType || '').toLowerCase();
                    break;
                case 'date':
                    aValue = this.parseAppointmentDate(a);
                    bValue = this.parseAppointmentDate(b);
                    break;
                case 'status':
                    aValue = (a.status || 'pending').toLowerCase();
                    bValue = (b.status || 'pending').toLowerCase();
                    break;
                default:
                    return 0;
            }

            let comparison = 0;
            if (aValue > bValue) comparison = 1;
            if (aValue < bValue) comparison = -1;
            
            return this.currentSort.direction === 'desc' ? -comparison : comparison;
        });

        this.filteredAppointments = filtered;
        this.updateAppointmentsCount();
        this.renderTable();
        this.renderPagination();
    },

    // Update statistics
    updateStatistics() {
        const total = this.allAppointments.length;
        const pending = this.allAppointments.filter(apt => (apt.status || 'pending') === 'pending').length;
        const confirmed = this.allAppointments.filter(apt => apt.status === 'confirmed').length;
        const cancelled = this.allAppointments.filter(apt => apt.status === 'cancelled').length;

        // Update the stats on both dashboard and appointments page
        this.updateElement('totalAppointmentsPage', total);
        this.updateElement('pendingAppointmentsPage', pending);
        this.updateElement('confirmedAppointments', confirmed);
        this.updateElement('cancelledAppointments', cancelled);
        
        // Also update dashboard stats if they exist
        this.updateElement('totalAppointments', total);
        this.updateElement('pendingAppointments', pending);
    },

    // Update appointments count
    updateAppointmentsCount() {
        this.updateElement('appointmentsCount', this.filteredAppointments.length);
    },

    // Render table
    renderTable() {
        const tbody = document.getElementById('appointmentsTableBody');
        const loadingState = document.getElementById('tableLoadingState');
        const emptyState = document.getElementById('tableEmptyState');
        
        if (!tbody) return;

        // Hide loading state
        if (loadingState) loadingState.style.display = 'none';

        if (this.filteredAppointments.length === 0) {
            tbody.innerHTML = '';
            if (emptyState) emptyState.style.display = 'flex';
            return;
        }

        if (emptyState) emptyState.style.display = 'none';

        // Calculate pagination
        const startIndex = (this.currentPage - 1) * this.itemsPerPage;
        const endIndex = startIndex + this.itemsPerPage;
        const pageAppointments = this.filteredAppointments.slice(startIndex, endIndex);

        // Render appointments
        tbody.innerHTML = pageAppointments.map(appointment => 
            this.renderAppointmentRow(appointment)
        ).join('');

        // Bind click events
        this.bindTableEvents();
        
        // Update pagination info
        this.updatePaginationInfo();
    },

    // Create table row
    renderAppointmentRow(appointment) {
        const dateObj = this.parseAppointmentDate(appointment.date, appointment.time);
        const formattedDate = dateObj ? dateObj.toLocaleDateString('fr-FR', {
            weekday: 'short',
            day: '2-digit',
            month: 'short'
        }) : 'Date invalide';
        
        const formattedTime = dateObj ? dateObj.toLocaleTimeString('fr-FR', {
            hour: '2-digit',
            minute: '2-digit'
        }) : appointment.time || 'N/A';

        const statusClass = this.getStatusClass(appointment.status);
        const statusText = this.getStatusText(appointment.status);

        return `
            <tr class="appointment-row" data-appointment-id="${appointment.id}">
                <td class="patient-cell">
                    <div class="patient-avatar-default">
                        <i class="fas fa-plus"></i>
                    </div>
                    <div class="patient-info">
                        <h6>${appointment.patientName || 'Patient non spécifié'}</h6>
                        <small>${appointment.patientAge ? appointment.patientAge + ' ans' : 'Âge non spécifié'}</small>
                    </div>
                </td>
                <td>
                    <div class="service-info">
                        <span class="service-name">${appointment.service || 'Service non spécifié'}</span>
                        <small class="service-category">${appointment.category || 'Consultation'}</small>
                    </div>
                </td>
                <td>
                    <div class="datetime-info">
                        <span class="date">${formattedDate}</span>
                        <small class="time">${formattedTime}</small>
            </div>
                </td>
                <td>
                    <span class="status-badge status-${statusClass}">${statusText}</span>
                </td>
                <td>
                    <span class="contact-info">${appointment.phone || 'N/A'}</span>
                </td>
                <td class="actions-cell">
                    <button class="action-btn view-btn" onclick="appointmentsPage.viewAppointment('${appointment.id}')" 
                            title="View Details">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="action-btn cancel-btn" onclick="appointmentsPage.cancelAppointment('${appointment.id}')" 
                            title="Cancel Appointment">
                        <i class="fas fa-times"></i>
                    </button>
                </td>
            </tr>
        `;
    },

    // Bind table events
    bindTableEvents() {
        document.querySelectorAll('.appointment-row').forEach(row => {
            row.addEventListener('click', (e) => {
                // Don't trigger row click if clicking on action buttons
                if (e.target.closest('.action-btn')) return;
                
                const appointmentId = row.dataset.appointmentId;
                this.viewAppointment(appointmentId);
            });
        });
    },

    // Render pagination
    renderPagination() {
        const pagination = document.getElementById('appointmentsPagination');
        if (!pagination) return;

        const totalPages = Math.ceil(this.filteredAppointments.length / this.itemsPerPage);
        
        if (totalPages <= 1) {
            pagination.innerHTML = '';
            return;
        }

        let paginationHTML = '';
        
        // Previous button
        paginationHTML += `
            <li class="page-item ${this.currentPage === 1 ? 'disabled' : ''}">
                <a class="page-link" href="#" onclick="appointmentsPage.goToPage(${this.currentPage - 1})">
                    <i class="fas fa-chevron-left"></i>
                </a>
            </li>
        `;

        // Page numbers
        const startPage = Math.max(1, this.currentPage - 2);
        const endPage = Math.min(totalPages, this.currentPage + 2);

        if (startPage > 1) {
            paginationHTML += `
                <li class="page-item">
                    <a class="page-link" href="#" onclick="appointmentsPage.goToPage(1)">1</a>
                </li>
            `;
            if (startPage > 2) {
                paginationHTML += `<li class="page-item disabled"><span class="page-link">...</span></li>`;
            }
        }

        for (let i = startPage; i <= endPage; i++) {
            paginationHTML += `
                <li class="page-item ${i === this.currentPage ? 'active' : ''}">
                    <a class="page-link" href="#" onclick="appointmentsPage.goToPage(${i})">${i}</a>
                </li>
            `;
        }

        if (endPage < totalPages) {
            if (endPage < totalPages - 1) {
                paginationHTML += `<li class="page-item disabled"><span class="page-link">...</span></li>`;
            }
            paginationHTML += `
                <li class="page-item">
                    <a class="page-link" href="#" onclick="appointmentsPage.goToPage(${totalPages})">${totalPages}</a>
                </li>
            `;
        }

        // Next button
        paginationHTML += `
            <li class="page-item ${this.currentPage === totalPages ? 'disabled' : ''}">
                <a class="page-link" href="#" onclick="appointmentsPage.goToPage(${this.currentPage + 1})">
                    <i class="fas fa-chevron-right"></i>
                </a>
            </li>
        `;

        pagination.innerHTML = paginationHTML;
    },

    // Go to specific page
    goToPage(page) {
        const totalPages = Math.ceil(this.filteredAppointments.length / this.itemsPerPage);
        
        if (page < 1 || page > totalPages) return;
        
        this.currentPage = page;
        this.renderTable();
        this.renderPagination();
    },

    // Update pagination info
    updatePaginationInfo() {
        const startIndex = (this.currentPage - 1) * this.itemsPerPage;
        const endIndex = Math.min(startIndex + this.itemsPerPage, this.filteredAppointments.length);
        
        this.updateElement('showingStart', startIndex + 1);
        this.updateElement('showingEnd', endIndex);
        this.updateElement('totalAppointments', this.filteredAppointments.length);
    },

    // Action methods
    viewAppointment(appointmentId) {
        console.log('Viewing appointment:', appointmentId);
        
        const appointment = this.allAppointments.find(apt => apt.id === appointmentId);
        if (!appointment) {
            this.showNotification('Appointment not found', 'error');
            return;
        }
        
        if (typeof AppointmentDetails !== 'undefined' && AppointmentDetails.showDetails) {
            AppointmentDetails.showDetails(appointmentId);
        } else {
            this.showAppointmentModal(appointment);
        }
    },

    async cancelAppointment(appointmentId) {
        try {
            const result = await Swal.fire({
                title: 'Cancel Appointment',
                text: 'Are you sure you want to cancel this appointment?',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#dc3545',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Yes, Cancel',
                cancelButtonText: 'No, Keep',
                reverseButtons: true
            });

            if (result.isConfirmed) {
                // Show loading state
                this.showLoadingState();
                
                // Find the appointment
                const appointmentIndex = this.allAppointments.findIndex(apt => apt.id === appointmentId);
                if (appointmentIndex !== -1) {
                    // Update the appointment status
                    this.allAppointments[appointmentIndex].status = 'cancelled';
                    
                    // Here you would typically make an API call to cancel the appointment
                    // For now, we'll simulate the cancellation
                    
                    // Refresh the display
                    this.applyFilters();
                    
                    // Show success message
                    await Swal.fire({
                        title: 'Cancelled!',
                        text: 'The appointment has been cancelled successfully.',
                        icon: 'success',
                        timer: 2000,
                        showConfirmButton: false
                    });
                } else {
                    throw new Error('Appointment not found');
                }
                
                this.hideLoadingState();
            }
        } catch (error) {
            console.error('Error cancelling appointment:', error);
            this.hideLoadingState();
            
            await Swal.fire({
                title: 'Error',
                text: 'An error occurred while cancelling the appointment.',
                icon: 'error',
                confirmButtonText: 'OK'
            });
        }
    },

    showAppointmentModal(appointment) {
        const modal = document.createElement('div');
        modal.className = 'modal fade';
        modal.innerHTML = `
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header bg-primary text-white">
                        <h5 class="modal-title">
                            <i class="fas fa-calendar-alt me-2"></i>
                            Appointment Details
                        </h5>
                        <button type="button" class="btn-close btn-close-white" onclick="this.closest('.modal').remove()"></button>
                    </div>
                    <div class="modal-body">
                        <div class="row">
                            <div class="col-md-6">
                                <div class="detail-section">
                                    <h6 class="text-primary mb-3">
                                        <i class="fas fa-user me-2"></i>Patient Information
                                    </h6>
                                    <div class="detail-item">
                                        <label>Name:</label>
                                        <span>${appointment.patientName || 'N/A'}</span>
                </div>
                                    <div class="detail-item">
                                        <label>Phone:</label>
                                        <span>${appointment.phoneNumber || 'N/A'}</span>
                        </div>
                                    <div class="detail-item">
                                        <label>Email:</label>
                                        <span>${appointment.email || 'N/A'}</span>
                        </div>
                    </div>
                            </div>
                            <div class="col-md-6">
                                <div class="detail-section">
                                    <h6 class="text-primary mb-3">
                                        <i class="fas fa-calendar me-2"></i>Appointment Information
                                    </h6>
                                    <div class="detail-item">
                                        <label>Service:</label>
                                        <span>${appointment.service || 'N/A'}</span>
                                    </div>
                                    <div class="detail-item">
                                        <label>Date:</label>
                                        <span>${this.formatDate(this.parseAppointmentDate(appointment))}</span>
                                    </div>
                                    <div class="detail-item">
                                        <label>Time:</label>
                                        <span>${appointment.time || 'N/A'}</span>
                                    </div>
                                    <div class="detail-item">
                                        <label>Status:</label>
                                        <span class="badge bg-${this.getStatusColor(appointment.status)}">${appointment.status || 'pending'}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        ${appointment.notes ? `
                            <div class="detail-section mt-4">
                                <h6 class="text-primary mb-3">
                                    <i class="fas fa-sticky-note me-2"></i>Notes
                                </h6>
                                <div class="bg-light p-3 rounded">
                                    <p class="mb-0">${appointment.notes}</p>
                                </div>
                            </div>
                        ` : ''}
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline-danger" onclick="appointmentsPage.deleteAppointment('${appointment.id}'); this.closest('.modal').remove();">
                            <i class="fas fa-times me-2"></i>Cancel Appointment
                        </button>
                        <button type="button" class="btn btn-secondary" onclick="this.closest('.modal').remove()">
                            <i class="fas fa-times me-2"></i>Close
                        </button>
                    </div>
                </div>
                            </div>
        `;
        
        document.body.appendChild(modal);
        
        // Show modal
        if (typeof bootstrap !== 'undefined') {
            const bootstrapModal = new bootstrap.Modal(modal);
            bootstrapModal.show();
            
            modal.addEventListener('hidden.bs.modal', () => {
                modal.remove();
            });
        } else {
            modal.style.display = 'block';
            modal.classList.add('show');
        }
    },
    
    getStatusColor(status) {
        const colorMap = {
            'pending': 'warning',
            'confirmed': 'success',
            'cancelled': 'danger',
            'completed': 'info'
        };
        return colorMap[status] || 'secondary';
    },

    editAppointment(appointmentId) {
        console.log('Editing appointment:', appointmentId);
        alert(`Edit appointment: ${appointmentId}`);
    },

    async deleteAppointment(appointmentId) {
        // Show professional confirmation dialog
        const isConfirmed = await this.showDeleteConfirmation(appointmentId);
        
        if (isConfirmed) {
            try {
                // Show loading state
                this.showLoadingState();
                
                // Here you would typically make an API call to delete the appointment
                // For now, we'll simulate the deletion
                const appointmentIndex = this.allAppointments.findIndex(apt => apt.id === appointmentId);
                if (appointmentIndex !== -1) {
                    this.allAppointments.splice(appointmentIndex, 1);
                    this.applyFiltersAndSort();
                    
                    // Show success message
                    this.showNotification('Appointment cancelled successfully!', 'success');
                }
            } catch (error) {
                console.error('Error deleting appointment:', error);
                this.showNotification('Failed to cancel appointment. Please try again.', 'error');
            }
        }
    },
    
    async showDeleteConfirmation(appointmentId) {
        return new Promise((resolve) => {
            const appointment = this.allAppointments.find(apt => apt.id === appointmentId);
            const patientName = appointment ? appointment.patientName : 'this patient';
            
            const modal = document.createElement('div');
            modal.className = 'modal fade';
            modal.innerHTML = `
                <div class="modal-dialog modal-dialog-centered">
                    <div class="modal-content">
                        <div class="modal-header bg-danger text-white">
                            <h5 class="modal-title">
                                <i class="fas fa-exclamation-triangle me-2"></i>
                                Cancel Appointment
                            </h5>
                        </div>
                        <div class="modal-body text-center">
                            <div class="mb-3">
                                <i class="fas fa-calendar-times text-danger" style="font-size: 3rem;"></i>
                            </div>
                            <h6>Are you sure you want to cancel this appointment?</h6>
                            <p class="text-muted">
                                Patient: <strong>${patientName}</strong><br>
                                This action cannot be undone.
                            </p>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-dismiss="cancel">
                                <i class="fas fa-times me-2"></i>Keep Appointment
                            </button>
                            <button type="button" class="btn btn-danger" data-dismiss="confirm">
                                <i class="fas fa-trash me-2"></i>Cancel Appointment
                            </button>
                        </div>
                    </div>
                </div>
            `;
            
            document.body.appendChild(modal);
            
            // Handle button clicks
            modal.querySelector('[data-dismiss="cancel"]').onclick = () => {
                modal.remove();
                resolve(false);
            };
            
            modal.querySelector('[data-dismiss="confirm"]').onclick = () => {
                modal.remove();
                resolve(true);
            };
            
            // Show modal using Bootstrap
            if (typeof bootstrap !== 'undefined') {
                const bootstrapModal = new bootstrap.Modal(modal);
                bootstrapModal.show();
                
                modal.addEventListener('hidden.bs.modal', () => {
                    modal.remove();
                    resolve(false);
                });
            } else {
                // Fallback for simple display
                modal.style.display = 'block';
                modal.classList.add('show');
            }
        });
    },
    
    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `alert alert-${type} notification-toast position-fixed`;
        notification.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
        
        const iconMap = {
            'success': 'check-circle',
            'error': 'exclamation-circle',
            'warning': 'exclamation-triangle',
            'info': 'info-circle'
        };
        
        notification.innerHTML = `
            <i class="fas fa-${iconMap[type]} me-2"></i>
            ${message}
            <button type="button" class="btn-close" onclick="this.parentElement.remove()"></button>
        `;
        
        document.body.appendChild(notification);
        
        // Auto remove after 5 seconds
        setTimeout(() => {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 5000);
    },

    exportAppointments() {
        console.log('Exporting appointments...');
        // Implement export logic here
        alert('Export functionality will be implemented soon');
    },

    clearFilters() {
        this.currentFilter = 'all';
        this.searchTerm = '';
        this.currentPage = 1;
        
        // Reset UI
        const searchInput = document.getElementById('appointmentSearch');
        if (searchInput) searchInput.value = '';
        
        // Reset filter dropdown
        document.querySelectorAll('.filter-option').forEach(opt => opt.classList.remove('active'));
        document.querySelector('.filter-option[data-filter="all"]')?.classList.add('active');
        
        const filterDropdown = document.getElementById('filterDropdown');
        if (filterDropdown) {
            filterDropdown.innerHTML = '<i class="fas fa-filter me-2"></i>All Appointments';
        }
        
        this.applyFiltersAndSort();
    },

    // Utility methods
    parseAppointmentDate(date, time) {
        try {
            let dateObj;
            
            // Handle Firebase timestamp
            if (date && date.seconds) {
                dateObj = new Date(date.seconds * 1000);
        }
            // Handle string date
            else if (typeof date === 'string') {
                dateObj = new Date(date);
            }
            // Handle Date object
            else if (date instanceof Date) {
                dateObj = new Date(date);
            }
            // Default to today
            else {
                dateObj = new Date();
        }

            // If time is provided, parse and set it
            if (time && typeof time === 'string') {
                const timeMatch = time.match(/(\d{1,2}):(\d{2})\s*(AM|PM)?/i);
                if (timeMatch) {
                    let hours = parseInt(timeMatch[1]);
                    const minutes = parseInt(timeMatch[2]);
                    const period = timeMatch[3];
                    
                    // Convert to 24-hour format if needed
                    if (period) {
                        if (period.toUpperCase() === 'PM' && hours !== 12) {
                            hours += 12;
                        } else if (period.toUpperCase() === 'AM' && hours === 12) {
                            hours = 0;
                        }
                    }
                    
                    dateObj.setHours(hours, minutes, 0, 0);
                }
            }
            
            return dateObj;
        } catch (error) {
            console.error('Error parsing date:', error);
            return new Date(); // Return current date as fallback
        }
    },

    getStatusClass(status) {
        const statusMap = {
            'pending': 'status-pending',
            'confirmed': 'status-confirmed',
            'cancelled': 'status-cancelled',
            'completed': 'status-completed'
        };
        return statusMap[status] || 'status-pending';
    },

    getStatusText(status) {
        const textMap = {
            'pending': 'Pending',
            'confirmed': 'Confirmed',
            'cancelled': 'Cancelled',
            'completed': 'Completed'
        };
        return textMap[status] || 'Pending';
    },

    formatDate(date) {
        if (!date) return 'N/A';
        
        const options = {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        };
        
        return date.toLocaleDateString('en-US', options);
    },

    updateElement(id, value) {
        const element = document.getElementById(id);
        if (element) {
            element.textContent = value;
        }
    },

    showLoadingState() {
        const loadingState = document.getElementById('tableLoadingState');
        const emptyState = document.getElementById('tableEmptyState');
        const tbody = document.getElementById('appointmentsTableBody');
        
        if (loadingState) loadingState.style.display = 'flex';
        if (emptyState) emptyState.style.display = 'none';
        if (tbody) tbody.innerHTML = '';
    },

    showErrorState(message) {
        const tbody = document.getElementById('appointmentsTableBody');
        const loadingState = document.getElementById('tableLoadingState');
        const emptyState = document.getElementById('tableEmptyState');
        
        if (loadingState) loadingState.style.display = 'none';
        if (emptyState) emptyState.style.display = 'none';
        
        if (tbody) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="6" class="text-center py-4">
                        <div class="text-danger">
                            <i class="fas fa-exclamation-triangle mb-2" style="font-size: 2rem;"></i>
                            <h6>${message}</h6>
                            <button class="btn btn-outline-primary btn-sm mt-2" onclick="appointmentsPage.refresh()">
                                <i class="fas fa-retry me-1"></i>Try Again
                </button>
            </div>
                    </td>
                </tr>
        `;
        }
    },

    refresh() {
        this.loadAllAppointments();
    }
};

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    // Only initialize if we're on the appointments page or dashboard
    if (document.getElementById('appointmentsTable') || document.getElementById('appointmentsTableBody')) {
    appointmentsPage.init();
    }
}); 