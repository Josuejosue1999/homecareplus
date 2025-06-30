// Gestionnaire d'authentification côté client
class AuthManager {
  constructor() {
    this.apiBase = '/api/auth';
    this.setupEventListeners();
  }

  setupEventListeners() {
    // Login form
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
      loginForm.addEventListener('submit', (e) => this.handleLogin(e));
    }

    // Register form
    const registerForm = document.getElementById('registerForm');
    if (registerForm) {
      registerForm.addEventListener('submit', (e) => this.handleRegister(e));
    }

    // Logout button
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', (e) => this.handleLogout(e));
    }
  }

  async handleLogin(e) {
    e.preventDefault();
    
    const form = e.target;
    const email = form.email.value;
    const password = form.password.value;
    const submitBtn = form.querySelector('button[type="submit"]');
    const loadingSpinner = form.querySelector('.loading-spinner');
    
    // Validation
    if (!email || !password) {
      this.showAlert('Veuillez remplir tous les champs', 'error');
      return;
    }

    try {
      // Afficher le loading
      this.setLoading(submitBtn, loadingSpinner, true);
      
      const response = await fetch(`${this.apiBase}/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password })
      });

      const data = await response.json();

      if (data.success) {
        this.showAlert('Connexion réussie!', 'success');
        setTimeout(() => {
          window.location.href = '/dashboard';
        }, 1000);
      } else {
        this.showAlert(data.message, 'error');
      }
    } catch (error) {
      console.error('Login error:', error);
      this.showAlert('Erreur de connexion', 'error');
    } finally {
      this.setLoading(submitBtn, loadingSpinner, false);
    }
  }

  async handleRegister(e) {
    e.preventDefault();
    
    const form = e.target;
    const clinicName = form.clinicName.value;
    const email = form.email.value;
    const password = form.password.value;
    const confirmPassword = form.confirmPassword.value;
    const submitBtn = form.querySelector('button[type="submit"]');
    const loadingSpinner = form.querySelector('.loading-spinner');
    
    // Validation
    if (!clinicName || !email || !password || !confirmPassword) {
      this.showAlert('Veuillez remplir tous les champs', 'error');
      return;
    }

    if (password !== confirmPassword) {
      this.showAlert('Les mots de passe ne correspondent pas', 'error');
      return;
    }

    if (password.length < 6) {
      this.showAlert('Le mot de passe doit contenir au moins 6 caractères', 'error');
      return;
    }

    try {
      // Afficher le loading
      this.setLoading(submitBtn, loadingSpinner, true);
      
      const response = await fetch(`${this.apiBase}/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ clinicName, email, password, confirmPassword })
      });

      const data = await response.json();

      if (data.success) {
        this.showAlert('Compte créé avec succès! Veuillez vous connecter.', 'success');
        setTimeout(() => {
          window.location.href = '/login';
        }, 2000);
      } else {
        this.showAlert(data.message, 'error');
      }
    } catch (error) {
      console.error('Register error:', error);
      this.showAlert('Erreur lors de la création du compte', 'error');
    } finally {
      this.setLoading(submitBtn, loadingSpinner, false);
    }
  }

  async handleLogout(e) {
    e.preventDefault();
    
    try {
      const response = await fetch(`${this.apiBase}/logout`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        }
      });

      const data = await response.json();

      if (data.success) {
        window.location.href = '/login';
      } else {
        this.showAlert('Erreur lors de la déconnexion', 'error');
      }
    } catch (error) {
      console.error('Logout error:', error);
      this.showAlert('Erreur lors de la déconnexion', 'error');
    }
  }

  setLoading(button, spinner, isLoading) {
    if (isLoading) {
      button.disabled = true;
      button.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Chargement...';
      if (spinner) spinner.style.display = 'inline-block';
    } else {
      button.disabled = false;
      button.innerHTML = button.getAttribute('data-original-text') || 'Connexion';
      if (spinner) spinner.style.display = 'none';
    }
  }

  showAlert(message, type = 'info') {
    // Supprimer les alertes existantes
    const existingAlerts = document.querySelectorAll('.alert');
    existingAlerts.forEach(alert => alert.remove());

    // Créer la nouvelle alerte
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type === 'error' ? 'danger' : type} alert-dismissible fade show`;
    alertDiv.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;

    // Insérer l'alerte
    const container = document.querySelector('.auth-container') || document.body;
    container.insertBefore(alertDiv, container.firstChild);

    // Auto-dismiss après 5 secondes
    setTimeout(() => {
      if (alertDiv.parentNode) {
        alertDiv.remove();
      }
    }, 5000);
  }
}

// Initialiser l'AuthManager quand le DOM est chargé
document.addEventListener('DOMContentLoaded', () => {
  new AuthManager();
}); 