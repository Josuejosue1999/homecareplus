// ===== ADMIN DASHBOARD JAVASCRIPT - HOMECARE PLUS =====

// Global application state
const AppState = {
    sidebarOpen: true,
    currentChart: 'users',
    notifications: [],
    users: [],
    stats: {
        totalUsers: 1248,
        totalClinics: 35,
        totalAppointments: 892,
        totalRevenue: 45678
    }
};

// Main application handler
class AdminDashboard {
    constructor() {
        this.init();
    }

    init() {
        this.createParticles();
        this.setupEventListeners();
        this.initializeChart();
        this.animateStats();
        this.loadNotifications();
        this.setupSearch();
        this.showWelcomeMessage();
    }

    // Create floating particles
    createParticles() {
        const particlesContainer = document.getElementById('particles');
        if (!particlesContainer) return;
        
        const numberOfParticles = 50;

        for (let i = 0; i < numberOfParticles; i++) {
            const particle = document.createElement('div');
            particle.className = 'particle';
            particle.style.left = Math.random() * 100 + '%';
            particle.style.top = Math.random() * 100 + '%';
            particle.style.animationDelay = Math.random() * 8 + 's';
            particle.style.animationDuration = (Math.random() * 3 + 5) + 's';
            particlesContainer.appendChild(particle);
        }
    }

    // Setup event listeners
    setupEventListeners() {
        // Toggle sidebar
        const sidebarToggle = document.getElementById('sidebarToggle');
        sidebarToggle?.addEventListener('click', () => this.toggleSidebar());

        // Navigation - Let all links work normally, don't prevent default
        const navLinks = document.querySelectorAll('.nav-link');
        navLinks.forEach(link => {
            // Only handle links with onclick="return false;" (like logout)
            if (link.getAttribute('onclick') && link.getAttribute('onclick').includes('return false')) {
                return;
            }
            
            // Add visual feedback on click without preventing navigation
            link.addEventListener('click', (e) => {
                // Remove active class from all nav items
                document.querySelectorAll('.nav-item').forEach(item => {
                    item.classList.remove('active');
                });
                
                // Add active class to clicked item
                e.target.closest('.nav-item').classList.add('active');
                
                // Let the browser handle the navigation naturally
                // Don't call preventDefault() here
            });
        });

        // Chart controls
        const chartBtns = document.querySelectorAll('.chart-btn');
        chartBtns.forEach(btn => {
            btn.addEventListener('click', (e) => this.switchChart(e));
        });

        // Notifications
        const notificationBtn = document.getElementById('notificationBtn');
        notificationBtn?.addEventListener('click', () => this.showNotifications());

        // User menu
        const userMenu = document.getElementById('userMenu');
        userMenu?.addEventListener('click', () => this.toggleUserMenu());

        // Action buttons
        const actionBtns = document.querySelectorAll('.action-btn');
        actionBtns.forEach(btn => {
            btn.addEventListener('click', (e) => this.handleAction(e));
        });

        // Responsive
        window.addEventListener('resize', () => this.handleResize());
    }

    // Toggle sidebar
    toggleSidebar() {
        const sidebar = document.getElementById('sidebar');
        sidebar.classList.toggle('active');
        AppState.sidebarOpen = !AppState.sidebarOpen;
        
        // Animation
        sidebar.style.transform = AppState.sidebarOpen ? 'translateX(0)' : 'translateX(-100%)';
    }

    // Navigation handler - No longer needed since we allow natural navigation
    // handleNavigation(e) {
    //     e.preventDefault();
    //     
    //     // Remove active class
    //     document.querySelectorAll('.nav-item').forEach(item => {
    //         item.classList.remove('active');
    //     });
    //     
    //     // Add active class
    //     e.target.closest('.nav-item').classList.add('active');
    //     
    //     // Navigation animation
    //     this.animateNavigation(e.target.textContent.trim());
    // }

    // Navigation animation
    animateNavigation(section) {
        const mainContent = document.querySelector('.dashboard-content');
        if (!mainContent) return;
        
        mainContent.style.opacity = '0';
        mainContent.style.transform = 'translateY(20px)';
        
        setTimeout(() => {
            mainContent.style.opacity = '1';
            mainContent.style.transform = 'translateY(0)';
            this.showNotification(`Navigating to ${section}`, 'info');
        }, 200);
    }

    // Initialize chart
    initializeChart() {
        const ctx = document.getElementById('growthChart');
        if (!ctx) return;

        this.chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                datasets: [{
                    label: 'Users',
                    data: [65, 78, 90, 81, 95, 105, 123, 135, 142, 158, 167, 180],
                    borderColor: '#159BBD',
                    backgroundColor: 'rgba(21, 155, 189, 0.1)',
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointBackgroundColor: '#159BBD',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2,
                    pointRadius: 6,
                    pointHoverRadius: 8
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    },
                    title: {
                        display: true,
                        text: 'Monthly Growth',
                        font: {
                            size: 18,
                            weight: 'bold'
                        },
                        color: '#1A1A1A'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: {
                            color: 'rgba(21, 155, 189, 0.1)'
                        },
                        ticks: {
                            color: '#666666'
                        }
                    },
                    x: {
                        grid: {
                            color: 'rgba(21, 155, 189, 0.1)'
                        },
                        ticks: {
                            color: '#666666'
                        }
                    }
                },
                interaction: {
                    intersect: false,
                    mode: 'index'
                },
                animation: {
                    duration: 1000,
                    easing: 'easeInOutQuart'
                }
            }
        });
    }

    // Switch chart
    switchChart(e) {
        const chartType = e.target.dataset.chart;
        if (chartType === AppState.currentChart) return;

        AppState.currentChart = chartType;
        
        // Update button states
        document.querySelectorAll('.chart-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        e.target.classList.add('active');

        // Update chart data
        this.updateChartData(chartType);
        
        // Show notification
        this.showNotification(`Chart switched to ${chartType}`, 'success');
    }

    // Update chart data
    updateChartData(type) {
        if (!this.chart) return;

        const dataMap = {
            users: [65, 78, 90, 81, 95, 105, 123, 135, 142, 158, 167, 180],
            clinics: [5, 8, 12, 15, 18, 22, 25, 28, 32, 35, 38, 42],
            appointments: [120, 150, 180, 200, 230, 260, 290, 320, 350, 380, 410, 440],
            revenue: [5000, 7500, 9000, 11000, 13500, 15000, 17500, 20000, 22500, 25000, 27500, 30000]
        };

        const labelMap = {
            users: 'Users',
            clinics: 'Clinics',
            appointments: 'Appointments',
            revenue: 'Revenue'
        };

        this.chart.data.datasets[0].data = dataMap[type];
        this.chart.data.datasets[0].label = labelMap[type];
        this.chart.update('active');
    }

    // Animate stats
    animateStats() {
        const statElements = document.querySelectorAll('[id^="total"]');
        statElements.forEach((element, index) => {
            setTimeout(() => {
                const endValue = parseInt(element.textContent.replace(/[^0-9]/g, ''));
                const prefix = element.textContent.includes('$') ? '$' : '';
                const suffix = element.textContent.includes(',') ? '' : '';
                this.animateNumber(element, 0, endValue, 2000, prefix, suffix);
            }, index * 200);
        });
    }

    // Animate number
    animateNumber(element, start, end, duration, prefix = '', suffix = '') {
        const startTime = performance.now();
        
        const updateNumber = () => {
            const currentTime = performance.now();
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            const current = Math.floor(start + (end - start) * progress);
            const formatted = current.toLocaleString();
            element.textContent = prefix + formatted + suffix;
            
            if (progress < 1) {
                requestAnimationFrame(updateNumber);
            }
        };
        
        updateNumber();
    }

    // Load notifications
    loadNotifications() {
        AppState.notifications = [
            { id: 1, message: 'New clinic registration pending', type: 'info', time: '2 min ago' },
            { id: 2, message: 'System backup completed', type: 'success', time: '1 hour ago' },
            { id: 3, message: 'Database maintenance scheduled', type: 'warning', time: '3 hours ago' }
        ];
    }

    // Show notifications
    showNotifications() {
        const notifications = AppState.notifications.map(notif => `
            <div class="notification-item ${notif.type}">
                <div class="notification-content">
                    <h6>${notif.message}</h6>
                    <span class="notification-time">${notif.time}</span>
                </div>
            </div>
        `).join('');

        const popupContent = `
            <div class="notifications-popup">
                <div class="popup-header">
                    <h5><i class="fas fa-bell"></i> Notifications</h5>
                    <button class="close-popup" onclick="this.closest('.popup-overlay').remove()">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
                <div class="popup-content">
                    ${notifications}
                </div>
                <div class="popup-footer">
                    <button class="btn-clear-all">Clear All</button>
                    <button class="btn-view-all">View All</button>
                </div>
            </div>
        `;

        this.showPopup(popupContent);
    }

    // Show popup
    showPopup(content) {
        const overlay = document.createElement('div');
        overlay.className = 'popup-overlay';
        overlay.innerHTML = content;
        
        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) {
                overlay.remove();
            }
        });
        
        document.body.appendChild(overlay);
        
        // Animation
        setTimeout(() => {
            overlay.classList.add('active');
        }, 10);
    }

    // Handle action
    handleAction(e) {
        const action = e.target.closest('.action-btn');
        if (!action) return;

        const actionType = action.classList.contains('view') ? 'view' : 
                          action.classList.contains('edit') ? 'edit' : 
                          action.classList.contains('delete') ? 'delete' : 'unknown';

        this.showNotification(`Action: ${actionType}`, 'info');
    }

    // View user
    viewUser(button) {
        const userId = button.dataset.userId;
        this.showNotification(`Viewing user ${userId}`, 'info');
    }

    // Edit user
    editUser(button) {
        const userId = button.dataset.userId;
        this.showNotification(`Editing user ${userId}`, 'info');
    }

    // Delete user
    deleteUser(button) {
        const userId = button.dataset.userId;
        if (confirm('Are you sure you want to delete this user?')) {
            this.showNotification(`User ${userId} deleted`, 'success');
            // Remove row with animation
            const row = button.closest('tr');
            row.style.opacity = '0';
            row.style.transform = 'translateX(-100%)';
            setTimeout(() => row.remove(), 300);
        }
    }

    // Add user
    addUser() {
        this.showNotification('Add user functionality coming soon', 'info');
    }

    // Export data
    exportData() {
        this.showNotification('Exporting data...', 'info');
        // Simulate export
        setTimeout(() => {
            this.showNotification('Data exported successfully', 'success');
        }, 2000);
    }

    // Setup search
    setupSearch() {
        const searchInput = document.querySelector('.search-input');
        if (!searchInput) return;

        searchInput.addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase();
            this.filterTable(query);
        });
    }

    // Filter table
    filterTable(query) {
        const rows = document.querySelectorAll('.users-table tbody tr');
        rows.forEach(row => {
            const text = row.textContent.toLowerCase();
            const shouldShow = text.includes(query);
            row.style.display = shouldShow ? '' : 'none';
            
            if (shouldShow) {
                row.style.animation = 'fadeIn 0.3s ease';
            }
        });
    }

    // Show notification
    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.innerHTML = `
            <div class="notification-content">
                <i class="fas fa-${type === 'success' ? 'check-circle' : 
                                  type === 'warning' ? 'exclamation-triangle' : 
                                  type === 'error' ? 'times-circle' : 'info-circle'}"></i>
                <span>${message}</span>
            </div>
            <button class="notification-close">
                <i class="fas fa-times"></i>
            </button>
        `;

        // Add to container
        let container = document.getElementById('notificationContainer');
        if (!container) {
            container = document.createElement('div');
            container.id = 'notificationContainer';
            container.className = 'notification-container';
            document.body.appendChild(container);
        }

        container.appendChild(notification);

        // Auto remove after 5 seconds
        setTimeout(() => {
            notification.classList.add('removing');
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }, 5000);

        // Close button
        const closeBtn = notification.querySelector('.notification-close');
        closeBtn.addEventListener('click', () => {
            notification.classList.add('removing');
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        });
    }

    // Show welcome message
    showWelcomeMessage() {
        setTimeout(() => {
            this.showNotification('Welcome to HomeCare+ Admin Dashboard', 'success');
        }, 1000);
    }

    // Handle resize
    handleResize() {
        if (window.innerWidth < 768) {
            AppState.sidebarOpen = false;
            const sidebar = document.getElementById('sidebar');
            sidebar.style.transform = 'translateX(-100%)';
        }
    }

    // Toggle user menu
    toggleUserMenu() {
        this.showNotification('User menu clicked', 'info');
    }
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    if (typeof AdminDashboard !== 'undefined') {
        window.adminDashboard = new AdminDashboard();
    }
});

// Export for global use
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AdminDashboard;
} 