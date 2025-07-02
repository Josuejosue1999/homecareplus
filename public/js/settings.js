// Settings Management
class SettingsManager {
  constructor() {
    this.apiBase = '/api/settings';
    this.setupEventListeners();
    this.initializeForms();
  }

  setupEventListeners() {
    // Profile form
    const profileForm = document.getElementById('profileForm');
    if (profileForm) {
      profileForm.addEventListener('submit', (e) => this.handleProfileUpdate(e));
    }

    // Contact form
    const contactForm = document.getElementById('contactForm');
    if (contactForm) {
      contactForm.addEventListener('submit', (e) => this.handleContactUpdate(e));
    }

    // Services form
    const servicesForm = document.getElementById('servicesForm');
    if (servicesForm) {
      servicesForm.addEventListener('submit', (e) => this.handleServicesUpdate(e));
    }

    // Schedule form
    const scheduleForm = document.getElementById('scheduleForm');
    if (scheduleForm) {
      scheduleForm.addEventListener('submit', (e) => this.handleScheduleUpdate(e));
    }

    // Security form
    const securityForm = document.getElementById('securityForm');
    if (securityForm) {
      securityForm.addEventListener('submit', (e) => this.handlePasswordChange(e));
    }

    // Handle closed checkboxes for schedule
    this.setupScheduleCheckboxes();
  }

  initializeForms() {
    // Initialize tooltips
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Initialize form validation
    this.setupFormValidation();
  }

  setupScheduleCheckboxes() {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    days.forEach(day => {
      const closedCheckbox = document.getElementById(`${day}_closed`);
      const startInput = document.querySelector(`input[name="${day}_start"]`);
      const endInput = document.querySelector(`input[name="${day}_end"]`);
      
      if (closedCheckbox && startInput && endInput) {
        closedCheckbox.addEventListener('change', (e) => {
          if (e.target.checked) {
            startInput.value = 'Closed';
            endInput.value = 'Closed';
            startInput.disabled = true;
            endInput.disabled = true;
          } else {
            startInput.value = '08:00';
            endInput.value = '17:00';
            startInput.disabled = false;
            endInput.disabled = false;
          }
        });
      }
    });
  }

  setupFormValidation() {
    // Add custom validation for required fields
    const requiredFields = document.querySelectorAll('[required]');
    requiredFields.forEach(field => {
      field.addEventListener('blur', () => {
        this.validateField(field);
      });
    });
  }

  validateField(field) {
    const value = field.value.trim();
    const isValid = value.length > 0;
    
    if (!isValid) {
      field.classList.add('is-invalid');
      this.showFieldError(field, 'This field is required');
    } else {
      field.classList.remove('is-invalid');
      this.removeFieldError(field);
    }
    
    return isValid;
  }

  showFieldError(field, message) {
    let errorDiv = field.parentNode.querySelector('.invalid-feedback');
    if (!errorDiv) {
      errorDiv = document.createElement('div');
      errorDiv.className = 'invalid-feedback';
      field.parentNode.appendChild(errorDiv);
    }
    errorDiv.textContent = message;
  }

  removeFieldError(field) {
    const errorDiv = field.parentNode.querySelector('.invalid-feedback');
    if (errorDiv) {
      errorDiv.remove();
    }
  }

  async handleProfileUpdate(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const data = {
      clinicName: formData.get('clinicName'),
      about: formData.get('about')
    };

    try {
      this.showLoading(e.target);
      
      const response = await fetch(`${this.apiBase}/profile`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      const result = await response.json();
      
      if (result.success) {
        this.showSuccess('Profile updated successfully!');
        // Update the header clinic name if it exists
        const headerClinicName = document.querySelector('.clinic-name');
        if (headerClinicName) {
          headerClinicName.textContent = data.clinicName;
        }
      } else {
        this.showError(result.message || 'Failed to update profile');
      }
    } catch (error) {
      console.error('Profile update error:', error);
      this.showError('An error occurred while updating profile');
    } finally {
      this.hideLoading(e.target);
    }
  }

  async handleContactUpdate(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const data = {
      phone: formData.get('phone'),
      website: formData.get('website'),
      address: formData.get('address'),
      city: formData.get('city'),
      country: formData.get('country'),
      latitude: formData.get('latitude') || null,
      longitude: formData.get('longitude') || null
    };

    try {
      this.showLoading(e.target);
      
      const response = await fetch(`${this.apiBase}/contact`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      const result = await response.json();
      
      if (result.success) {
        this.showSuccess('Contact details updated successfully!');
      } else {
        this.showError(result.message || 'Failed to update contact details');
      }
    } catch (error) {
      console.error('Contact update error:', error);
      this.showError('An error occurred while updating contact details');
    } finally {
      this.hideLoading(e.target);
    }
  }

  async handleServicesUpdate(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const selectedFacilities = formData.getAll('facilities');
    const customFacilities = formData.get('customFacilities');
    
    // Add custom facilities if provided
    let facilities = [...selectedFacilities];
    if (customFacilities && customFacilities.trim()) {
      const customList = customFacilities.split(',').map(f => f.trim()).filter(f => f);
      facilities = [...facilities, ...customList];
    }

    const data = { facilities };

    try {
      this.showLoading(e.target);
      
      const response = await fetch(`${this.apiBase}/services`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      const result = await response.json();
      
      if (result.success) {
        this.showSuccess('Services updated successfully!');
      } else {
        this.showError(result.message || 'Failed to update services');
      }
    } catch (error) {
      console.error('Services update error:', error);
      this.showError('An error occurred while updating services');
    } finally {
      this.hideLoading(e.target);
    }
  }

  async handleScheduleUpdate(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    const schedule = {};

    days.forEach(day => {
      const isClosed = formData.get(`${day}_closed`) === 'on';
      if (isClosed) {
        schedule[day.charAt(0).toUpperCase() + day.slice(1)] = {
          start: 'Closed',
          end: 'Closed'
        };
      } else {
        schedule[day.charAt(0).toUpperCase() + day.slice(1)] = {
          start: formData.get(`${day}_start`) || '08:00',
          end: formData.get(`${day}_end`) || '17:00'
        };
      }
    });

    const data = { availableSchedule: schedule };

    try {
      this.showLoading(e.target);
      
      const response = await fetch(`${this.apiBase}/schedule`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      const result = await response.json();
      
      if (result.success) {
        this.showSuccess('Working hours updated successfully!');
      } else {
        this.showError(result.message || 'Failed to update working hours');
      }
    } catch (error) {
      console.error('Schedule update error:', error);
      this.showError('An error occurred while updating working hours');
    } finally {
      this.hideLoading(e.target);
    }
  }

  async handlePasswordChange(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const currentPassword = formData.get('currentPassword');
    const newPassword = formData.get('newPassword');
    const confirmPassword = formData.get('confirmPassword');

    // Validate passwords
    if (!currentPassword || !newPassword || !confirmPassword) {
      this.showError('All password fields are required');
      return;
    }

    if (newPassword !== confirmPassword) {
      this.showError('New passwords do not match');
      return;
    }

    if (newPassword.length < 6) {
      this.showError('New password must be at least 6 characters long');
      return;
    }

    const data = {
      currentPassword,
      newPassword
    };

    try {
      this.showLoading(e.target);
      
      const response = await fetch(`${this.apiBase}/password`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      const result = await response.json();
      
      if (result.success) {
        this.showSuccess('Password changed successfully!');
        e.target.reset();
      } else {
        this.showError(result.message || 'Failed to change password');
      }
    } catch (error) {
      console.error('Password change error:', error);
      this.showError('An error occurred while changing password');
    } finally {
      this.hideLoading(e.target);
    }
  }

  showLoading(form) {
    const submitBtn = form.querySelector('button[type="submit"]');
    if (submitBtn) {
      submitBtn.disabled = true;
      submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Saving...';
    }
  }

  hideLoading(form) {
    const submitBtn = form.querySelector('button[type="submit"]');
    if (submitBtn) {
      submitBtn.disabled = false;
      const originalText = submitBtn.getAttribute('data-original-text') || 'Save';
      submitBtn.innerHTML = originalText;
    }
  }

  showSuccess(message) {
    this.showNotification(message, 'success');
  }

  showError(message) {
    this.showNotification(message, 'error');
  }

  showNotification(message, type) {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `alert alert-${type === 'success' ? 'success' : 'danger'} alert-dismissible fade show position-fixed`;
    notification.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
    notification.innerHTML = `
      <i class="fas fa-${type === 'success' ? 'check-circle' : 'exclamation-circle'} me-2"></i>
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;

    // Add to page
    document.body.appendChild(notification);

    // Auto remove after 5 seconds
    setTimeout(() => {
      if (notification.parentNode) {
        notification.remove();
      }
    }, 5000);
  }
}

// Initialize settings manager when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  new SettingsManager();
}); 