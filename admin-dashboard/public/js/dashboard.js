// ===== ADMIN DASHBOARD JAVASCRIPT - HOMECARE PLUS =====

// État global de l'application
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

// Gestionnaire principal de l'application
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

    // Création des particules flottantes
    createParticles() {
        const particlesContainer = document.getElementById('particles');
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

    // Configuration des événements
    setupEventListeners() {
        // Toggle sidebar
        const sidebarToggle = document.getElementById('sidebarToggle');
        sidebarToggle?.addEventListener('click', () => this.toggleSidebar());

        // Navigation
        const navLinks = document.querySelectorAll('.nav-link');
        navLinks.forEach(link => {
            link.addEventListener('click', (e) => this.handleNavigation(e));
        });

        // Contrôles de graphique
        const chartBtns = document.querySelectorAll('.chart-btn');
        chartBtns.forEach(btn => {
            btn.addEventListener('click', (e) => this.switchChart(e));
        });

        // Notifications
        const notificationBtn = document.getElementById('notificationBtn');
        notificationBtn?.addEventListener('click', () => this.showNotifications());

        // Menu utilisateur
        const userMenu = document.getElementById('userMenu');
        userMenu?.addEventListener('click', () => this.toggleUserMenu());

        // Boutons d'action
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

    // Navigation
    handleNavigation(e) {
        e.preventDefault();
        
        // Retirer classe active
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        
        // Ajouter classe active
        e.target.closest('.nav-item').classList.add('active');
        
        // Animation de navigation
        this.animateNavigation(e.target.textContent.trim());
    }

    // Animation de navigation
    animateNavigation(section) {
        const mainContent = document.querySelector('.dashboard-content');
        mainContent.style.opacity = '0';
        mainContent.style.transform = 'translateY(20px)';
        
        setTimeout(() => {
            mainContent.style.opacity = '1';
            mainContent.style.transform = 'translateY(0)';
            this.showNotification(`Navigation vers ${section}`, 'info');
        }, 200);
    }

    // Initialisation du graphique
    initializeChart() {
        const ctx = document.getElementById('growthChart');
        if (!ctx) return;

        this.chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'],
                datasets: [{
                    label: 'Utilisateurs',
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
                        text: 'Croissance Mensuelle',
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

    // Changement de graphique
    switchChart(e) {
        const chartType = e.target.dataset.chart;
        if (chartType === AppState.currentChart) return;

        // Mise à jour des boutons
        document.querySelectorAll('.chart-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        e.target.classList.add('active');

        // Données pour chaque type de graphique
        const chartData = {
            users: {
                label: 'Utilisateurs',
                data: [65, 78, 90, 81, 95, 105, 123, 135, 142, 158, 167, 180],
                borderColor: '#159BBD',
                backgroundColor: 'rgba(21, 155, 189, 0.1)'
            },
            clinics: {
                label: 'Cliniques',
                data: [5, 8, 12, 15, 18, 22, 25, 28, 30, 32, 34, 35],
                borderColor: '#28a745',
                backgroundColor: 'rgba(40, 167, 69, 0.1)'
            },
            revenue: {
                label: 'Revenus ($)',
                data: [5000, 8000, 12000, 15000, 18000, 22000, 28000, 32000, 38000, 42000, 44000, 45678],
                borderColor: '#17a2b8',
                backgroundColor: 'rgba(23, 162, 184, 0.1)'
            }
        };

        // Mise à jour du graphique avec animation
        const newData = chartData[chartType];
        this.chart.data.datasets[0] = {
            ...this.chart.data.datasets[0],
            ...newData
        };
        
        this.chart.update('active');
        AppState.currentChart = chartType;
    }

    // Animation des statistiques
    animateStats() {
        const stats = [
            { element: 'totalUsers', target: AppState.stats.totalUsers, suffix: '' },
            { element: 'totalClinics', target: AppState.stats.totalClinics, suffix: '' },
            { element: 'totalAppointments', target: AppState.stats.totalAppointments, suffix: '' },
            { element: 'totalRevenue', target: AppState.stats.totalRevenue, suffix: '$', prefix: '$' }
        ];

        stats.forEach(stat => {
            const element = document.getElementById(stat.element);
            if (!element) return;

            this.animateNumber(element, 0, stat.target, 2000, stat.prefix, stat.suffix);
        });
    }

    // Animation des nombres
    animateNumber(element, start, end, duration, prefix = '', suffix = '') {
        const startTime = Date.now();
        
        const updateNumber = () => {
            const elapsed = Date.now() - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            // Fonction d'easing
            const easeOutQuart = 1 - Math.pow(1 - progress, 4);
            const current = Math.floor(start + (end - start) * easeOutQuart);
            
            element.textContent = prefix + current.toLocaleString() + suffix;
            
            if (progress < 1) {
                requestAnimationFrame(updateNumber);
            }
        };
        
        updateNumber();
    }

    // Gestion des notifications
    loadNotifications() {
        AppState.notifications = [
            { id: 1, title: 'Nouveau message', message: 'Vous avez reçu un nouveau message', time: '2 min', type: 'info' },
            { id: 2, title: 'Rendez-vous confirmé', message: 'Un rendez-vous a été confirmé', time: '1h', type: 'success' },
            { id: 3, title: 'Alerte système', message: 'Maintenance programmée ce soir', time: '3h', type: 'warning' }
        ];
    }

    showNotifications() {
        const notifications = AppState.notifications;
        let notificationHtml = `
            <div class="notification-dropdown">
                <div class="notification-header">
                    <h6>Notifications (${notifications.length})</h6>
                    <button class="btn-clear-all">Tout effacer</button>
                </div>
                <div class="notification-list">
        `;

        notifications.forEach(notif => {
            notificationHtml += `
                <div class="notification-item ${notif.type}">
                    <div class="notification-icon">
                        <i class="fas fa-${notif.type === 'info' ? 'info' : notif.type === 'success' ? 'check' : 'exclamation'}"></i>
                    </div>
                    <div class="notification-content">
                        <h6>${notif.title}</h6>
                        <p>${notif.message}</p>
                        <span class="notification-time">${notif.time}</span>
                    </div>
                </div>
            `;
        });

        notificationHtml += `
                </div>
            </div>
        `;

        this.showPopup(notificationHtml);
    }

    // Affichage des popups
    showPopup(content) {
        const popup = document.createElement('div');
        popup.className = 'popup-overlay';
        popup.innerHTML = `
            <div class="popup-content">
                <button class="popup-close">&times;</button>
                ${content}
            </div>
        `;

        document.body.appendChild(popup);

        // Animation d'entrée
        setTimeout(() => popup.classList.add('show'), 10);

        // Fermeture
        popup.addEventListener('click', (e) => {
            if (e.target.classList.contains('popup-overlay') || e.target.classList.contains('popup-close')) {
                popup.classList.remove('show');
                setTimeout(() => popup.remove(), 300);
            }
        });
    }

    // Gestion des actions
    handleAction(e) {
        const action = e.target.closest('.action-btn');
        const icon = action.querySelector('i');
        
        if (icon.classList.contains('fa-eye')) {
            this.viewUser(action);
        } else if (icon.classList.contains('fa-edit')) {
            this.editUser(action);
        } else if (icon.classList.contains('fa-trash')) {
            this.deleteUser(action);
        } else if (icon.classList.contains('fa-plus')) {
            this.addUser();
        } else if (icon.classList.contains('fa-download')) {
            this.exportData();
        }
    }

    // Actions utilisateur
    viewUser(button) {
        const row = button.closest('tr');
        const userName = row.querySelector('.user-name strong').textContent;
        this.showNotification(`Affichage du profil de ${userName}`, 'info');
    }

    editUser(button) {
        const row = button.closest('tr');
        const userName = row.querySelector('.user-name strong').textContent;
        this.showNotification(`Modification de ${userName}`, 'info');
    }

    deleteUser(button) {
        const row = button.closest('tr');
        const userName = row.querySelector('.user-name strong').textContent;
        
        if (confirm(`Êtes-vous sûr de vouloir supprimer ${userName} ?`)) {
            row.style.transition = 'all 0.3s ease';
            row.style.opacity = '0';
            row.style.transform = 'translateX(-100%)';
            
            setTimeout(() => {
                row.remove();
                this.showNotification(`${userName} supprimé avec succès`, 'success');
            }, 300);
        }
    }

    addUser() {
        this.showNotification('Ouverture du formulaire d\'ajout', 'info');
    }

    exportData() {
        this.showNotification('Exportation des données en cours...', 'info');
        
        // Simulation d'exportation
        setTimeout(() => {
            this.showNotification('Données exportées avec succès', 'success');
        }, 2000);
    }

    // Recherche
    setupSearch() {
        const searchInput = document.querySelector('.search-input');
        if (!searchInput) return;

        searchInput.addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase();
            this.filterTable(query);
        });
    }

    filterTable(query) {
        const rows = document.querySelectorAll('.users-table tbody tr');
        
        rows.forEach(row => {
            const name = row.querySelector('.user-name strong').textContent.toLowerCase();
            const email = row.cells[1].textContent.toLowerCase();
            
            if (name.includes(query) || email.includes(query)) {
                row.style.display = '';
                row.style.animation = 'fadeInUp 0.3s ease';
            } else {
                row.style.display = 'none';
            }
        });
    }

    // Notifications toast
    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `notification-toast ${type}`;
        notification.innerHTML = `
            <div class="toast-icon">
                <i class="fas fa-${type === 'success' ? 'check' : type === 'error' ? 'times' : 'info'}"></i>
            </div>
            <div class="toast-content">
                <p>${message}</p>
            </div>
            <button class="toast-close">&times;</button>
        `;

        document.body.appendChild(notification);

        // Animation d'entrée
        setTimeout(() => notification.classList.add('show'), 100);

        // Fermeture automatique
        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => notification.remove(), 300);
        }, 3000);

        // Fermeture manuelle
        notification.querySelector('.toast-close').addEventListener('click', () => {
            notification.classList.remove('show');
            setTimeout(() => notification.remove(), 300);
        });
    }

    // Message de bienvenue
    showWelcomeMessage() {
        setTimeout(() => {
            this.showNotification('Bienvenue dans le Dashboard Admin HomeCare Plus!', 'success');
        }, 1000);
    }

    // Gestion du responsive
    handleResize() {
        if (window.innerWidth <= 768) {
            const sidebar = document.getElementById('sidebar');
            sidebar.style.transform = 'translateX(-100%)';
            AppState.sidebarOpen = false;
        }
    }

    // Toggle menu utilisateur
    toggleUserMenu() {
        const userMenu = document.getElementById('userMenu');
        userMenu.classList.toggle('active');
        
        // Créer dropdown si n'existe pas
        if (!document.querySelector('.user-dropdown')) {
            const dropdown = document.createElement('div');
            dropdown.className = 'user-dropdown';
            dropdown.innerHTML = `
                <div class="user-dropdown-item">
                    <i class="fas fa-user"></i>
                    <span>Mon Profil</span>
                </div>
                <div class="user-dropdown-item">
                    <i class="fas fa-cog"></i>
                    <span>Paramètres</span>
                </div>
                <div class="user-dropdown-item">
                    <i class="fas fa-sign-out-alt"></i>
                    <span>Déconnexion</span>
                </div>
            `;
            
            userMenu.appendChild(dropdown);
        }
    }
}

// Styles CSS additionnels pour les nouvelles fonctionnalités
const additionalStyles = `
    <style>
        /* Popup Overlay */
        .popup-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            z-index: 9999;
            display: flex;
            align-items: center;
            justify-content: center;
            opacity: 0;
            visibility: hidden;
            transition: all 0.3s ease;
        }

        .popup-overlay.show {
            opacity: 1;
            visibility: visible;
        }

        .popup-content {
            background: white;
            border-radius: 12px;
            padding: 30px;
            max-width: 500px;
            width: 90%;
            max-height: 80vh;
            overflow-y: auto;
            position: relative;
            transform: scale(0.9);
            transition: transform 0.3s ease;
        }

        .popup-overlay.show .popup-content {
            transform: scale(1);
        }

        .popup-close {
            position: absolute;
            top: 15px;
            right: 15px;
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #666;
        }

        /* Notification Dropdown */
        .notification-dropdown {
            width: 350px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }

        .notification-header {
            padding: 20px;
            background: linear-gradient(135deg, var(--primary-color), var(--primary-dark));
            color: white;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .notification-header h6 {
            margin: 0;
            font-size: 16px;
        }

        .btn-clear-all {
            background: rgba(255, 255, 255, 0.2);
            border: none;
            color: white;
            padding: 5px 10px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 12px;
        }

        .notification-list {
            max-height: 400px;
            overflow-y: auto;
        }

        .notification-item {
            padding: 15px 20px;
            border-bottom: 1px solid #f0f0f0;
            display: flex;
            gap: 15px;
            transition: background 0.2s ease;
        }

        .notification-item:hover {
            background: #f8f9fa;
        }

        .notification-icon {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }

        .notification-item.info .notification-icon {
            background: rgba(23, 162, 184, 0.1);
            color: #17a2b8;
        }

        .notification-item.success .notification-icon {
            background: rgba(40, 167, 69, 0.1);
            color: #28a745;
        }

        .notification-item.warning .notification-icon {
            background: rgba(255, 193, 7, 0.1);
            color: #ffc107;
        }

        .notification-content h6 {
            margin: 0 0 5px 0;
            font-size: 14px;
            color: #333;
        }

        .notification-content p {
            margin: 0 0 8px 0;
            font-size: 13px;
            color: #666;
        }

        .notification-time {
            font-size: 12px;
            color: #999;
        }

        /* Toast Notifications */
        .notification-toast {
            position: fixed;
            top: 20px;
            right: 20px;
            background: white;
            border-radius: 12px;
            padding: 15px 20px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            display: flex;
            align-items: center;
            gap: 15px;
            z-index: 10000;
            transform: translateX(100%);
            transition: transform 0.3s ease;
            border-left: 4px solid var(--primary-color);
        }

        .notification-toast.show {
            transform: translateX(0);
        }

        .notification-toast.success {
            border-left-color: #28a745;
        }

        .notification-toast.error {
            border-left-color: #dc3545;
        }

        .notification-toast.warning {
            border-left-color: #ffc107;
        }

        .toast-icon {
            width: 30px;
            height: 30px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            background: var(--primary-color);
            color: white;
        }

        .toast-content p {
            margin: 0;
            font-size: 14px;
            color: #333;
        }

        .toast-close {
            background: none;
            border: none;
            font-size: 18px;
            cursor: pointer;
            color: #666;
            margin-left: auto;
        }

        /* User Dropdown */
        .user-dropdown {
            position: absolute;
            top: 100%;
            right: 0;
            background: white;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            padding: 10px;
            min-width: 200px;
            z-index: 1000;
            transform: translateY(-10px);
            opacity: 0;
            visibility: hidden;
            transition: all 0.3s ease;
        }

        .user-menu.active .user-dropdown {
            transform: translateY(0);
            opacity: 1;
            visibility: visible;
        }

        .user-dropdown-item {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 15px;
            border-radius: 8px;
            cursor: pointer;
            transition: background 0.2s ease;
        }

        .user-dropdown-item:hover {
            background: #f8f9fa;
        }

        .user-dropdown-item i {
            width: 16px;
            text-align: center;
        }

        /* Animations */
        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        @keyframes slideInLeft {
            from {
                opacity: 0;
                transform: translateX(-20px);
            }
            to {
                opacity: 1;
                transform: translateX(0);
            }
        }

        .fade-in-up {
            animation: fadeInUp 0.6s ease-out;
        }

        .slide-in-left {
            animation: slideInLeft 0.6s ease-out;
        }
    </style>
`;

// Injection des styles
document.head.insertAdjacentHTML('beforeend', additionalStyles);

// Initialisation de l'application
document.addEventListener('DOMContentLoaded', () => {
    new AdminDashboard();
});

// Gestion des erreurs globales
window.addEventListener('error', (e) => {
    console.error('Erreur dashboard:', e.error);
});

// Performance monitoring
window.addEventListener('load', () => {
    const loadTime = performance.now();
    console.log(`Dashboard chargé en ${loadTime.toFixed(2)}ms`);
}); 