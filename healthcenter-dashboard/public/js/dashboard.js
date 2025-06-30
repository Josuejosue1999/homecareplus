// ===== DASHBOARD CLINIQUE - JAVASCRIPT =====

document.addEventListener('DOMContentLoaded', function() {
    console.log('🏥 Health Center Dashboard - Initialisation...');
    
    // Initialisation des composants
    initializeSidebar();
    initializeCharts();
    initializeNotifications();
    initializeAppointments();
    initializeStats();
    
    // Mise à jour automatique des données
    setInterval(refreshDashboardData, 30000); // Toutes les 30 secondes
});

// ===== INITIALISATION =====

function initializeSidebar() {
    const sidebarToggle = document.querySelector('.sidebar-toggle');
    const sidebar = document.querySelector('.sidebar');
    const mainContent = document.querySelector('.main-content');
    
    if (sidebarToggle) {
        sidebarToggle.addEventListener('click', function() {
            sidebar.classList.toggle('active');
        });
    }
    
    // Close sidebar when clicking outside on mobile
    document.addEventListener('click', function(e) {
        if (window.innerWidth <= 1024) {
            if (!sidebar.contains(e.target) && !sidebarToggle.contains(e.target)) {
                sidebar.classList.remove('active');
            }
        }
    });
    
    // Handle navigation
    const navLinks = document.querySelectorAll('.sidebar-nav .nav-link');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            
            // Remove active class from all links
            navLinks.forEach(l => l.parentElement.classList.remove('active'));
            
            // Add active class to clicked link
            this.parentElement.classList.add('active');
            
            // Update page title
            const pageTitle = this.querySelector('span').textContent;
            document.querySelector('.header-left h1').textContent = pageTitle;
            
            // Here you would typically load the corresponding page content
            console.log('Navigating to:', pageTitle);
        });
    });
}

function initializeCharts() {
    // Appointment Trends Chart
    const appointmentCtx = document.getElementById('appointmentChart');
    if (appointmentCtx) {
        new Chart(appointmentCtx, {
            type: 'line',
            data: {
                labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                datasets: [{
                    label: 'Appointments',
                    data: [12, 19, 15, 25, 22, 18, 24],
                    borderColor: '#3b82f6',
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: {
                            color: '#e2e8f0'
                        }
                    },
                    x: {
                        grid: {
                            display: false
                        }
                    }
                }
            }
        });
    }
    
    // Department Distribution Chart
    const departmentCtx = document.getElementById('departmentChart');
    if (departmentCtx) {
        new Chart(departmentCtx, {
            type: 'doughnut',
            data: {
                labels: ['General', 'Dental', 'Cardiology', 'Neurology', 'Pediatrics'],
                datasets: [{
                    data: [30, 25, 20, 15, 10],
                    backgroundColor: [
                        '#3b82f6',
                        '#10b981',
                        '#f59e0b',
                        '#ef4444',
                        '#8b5cf6'
                    ],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            padding: 20,
                            usePointStyle: true
                        }
                    }
                }
            }
        });
    }
}

function initializeNotifications() {
    console.log('🔔 Initialisation des notifications...');
    
    const notificationItems = document.querySelectorAll('.notification-item');
    
    notificationItems.forEach(item => {
        item.addEventListener('click', function() {
            // Mark as read
            this.style.opacity = '0.6';
            
            // Update notification count
            const badge = document.querySelector('.notifications .badge');
            if (badge) {
                const currentCount = parseInt(badge.textContent);
                if (currentCount > 0) {
                    badge.textContent = currentCount - 1;
                }
            }
        });
    });
    
    // Notification bell click
    const notificationBell = document.querySelector('.notifications');
    if (notificationBell) {
        notificationBell.addEventListener('click', function() {
            // Here you would typically show a notification dropdown
            console.log('Show notifications dropdown');
        });
    }
}

function initializeAppointments() {
    const appointmentActions = document.querySelectorAll('.appointment-actions .btn');
    
    appointmentActions.forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.stopPropagation();
            
            const appointmentItem = this.closest('.appointment-item');
            const isConfirm = this.classList.contains('btn-outline-success');
            const isCancel = this.classList.contains('btn-outline-danger');
            
            if (isConfirm) {
                // Confirm appointment
                const statusElement = appointmentItem.querySelector('.status');
                if (statusElement) {
                    statusElement.textContent = 'Confirmed';
                    statusElement.className = 'status confirmed';
                }
                
                // Show success message
                showToast('Appointment confirmed successfully!', 'success');
                
                // Update stats
                updateStats('confirmed');
                
            } else if (isCancel) {
                // Cancel appointment
                appointmentItem.style.opacity = '0.5';
                appointmentItem.style.textDecoration = 'line-through';
                
                // Show warning message
                showToast('Appointment cancelled', 'warning');
                
                // Update stats
                updateStats('cancelled');
            }
        });
    });
}

function initializeStats() {
    // Animate stats on page load
    const statNumbers = document.querySelectorAll('.stat-content h3');
    
    statNumbers.forEach(stat => {
        const finalValue = stat.textContent;
        const isPercentage = finalValue.includes('%');
        const numericValue = parseInt(finalValue.replace(/[^\d]/g, ''));
        
        animateNumber(stat, 0, numericValue, isPercentage);
    });
}

function animateNumber(element, start, end, isPercentage) {
    const duration = 2000;
    const startTime = performance.now();
    
    function updateNumber(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        
        const current = Math.floor(start + (end - start) * progress);
        element.textContent = isPercentage ? `${current}%` : current;
        
        if (progress < 1) {
            requestAnimationFrame(updateNumber);
        }
    }
    
    requestAnimationFrame(updateNumber);
}

function updateStats(action) {
    const statsCards = document.querySelectorAll('.stat-card');
    
    statsCards.forEach(card => {
        const statNumber = card.querySelector('h3');
        const statLabel = card.querySelector('p');
        
        if (action === 'confirmed' && statLabel.textContent.includes('Today')) {
            const current = parseInt(statNumber.textContent);
            statNumber.textContent = current + 1;
        } else if (action === 'cancelled' && statLabel.textContent.includes('Pending')) {
            const current = parseInt(statNumber.textContent);
            if (current > 0) {
                statNumber.textContent = current - 1;
            }
        }
    });
}

function showToast(message, type = 'info') {
    // Create toast element
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `
        <div class="toast-content">
            <i class="fas fa-${getToastIcon(type)}"></i>
            <span>${message}</span>
        </div>
    `;
    
    // Add styles
    toast.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: ${getToastColor(type)};
        color: white;
        padding: 1rem 1.5rem;
        border-radius: 0.5rem;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        z-index: 10000;
        transform: translateX(100%);
        transition: transform 0.3s ease;
        max-width: 300px;
    `;
    
    // Add to page
    document.body.appendChild(toast);
    
    // Animate in
    setTimeout(() => {
        toast.style.transform = 'translateX(0)';
    }, 100);
    
    // Remove after 3 seconds
    setTimeout(() => {
        toast.style.transform = 'translateX(100%)';
        setTimeout(() => {
            document.body.removeChild(toast);
        }, 300);
    }, 3000);
}

function getToastIcon(type) {
    const icons = {
        success: 'check-circle',
        error: 'exclamation-circle',
        warning: 'exclamation-triangle',
        info: 'info-circle'
    };
    return icons[type] || 'info-circle';
}

function getToastColor(type) {
    const colors = {
        success: '#10b981',
        error: '#ef4444',
        warning: '#f59e0b',
        info: '#3b82f6'
    };
    return colors[type] || '#3b82f6';
}

function refreshDashboardData() {
    // Simulate data refresh
    console.log('Refreshing dashboard data...');
    
    // Update notification count randomly
    const badge = document.querySelector('.notifications .badge');
    if (badge) {
        const currentCount = parseInt(badge.textContent);
        const newCount = Math.max(0, currentCount + Math.floor(Math.random() * 3) - 1);
        badge.textContent = newCount;
    }
    
    // Update stats slightly
    const statCards = document.querySelectorAll('.stat-card');
    statCards.forEach(card => {
        const statNumber = card.querySelector('h3');
        const current = parseInt(statNumber.textContent.replace(/[^\d]/g, ''));
        const change = Math.floor(Math.random() * 5) - 2; // -2 to +2
        const newValue = Math.max(0, current + change);
        
        if (statNumber.textContent.includes('%')) {
            statNumber.textContent = `${newValue}%`;
        } else {
            statNumber.textContent = newValue;
        }
    });
}

// ===== GESTION DES ERREURS =====

window.addEventListener('error', function(e) {
    console.error('❌ Erreur JavaScript:', e.error);
    showToast('Une erreur est survenue', 'danger');
});

// ===== EXPORT DES FONCTIONS =====

// Rendre les fonctions disponibles globalement
window.Dashboard = {
    showToast,
    showLoading,
    hideLoading,
    refreshDashboardData
};

console.log('✅ Dashboard JavaScript chargé avec succès'); 