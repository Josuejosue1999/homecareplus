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
    
    console.log('🚀 Starting registration process...');
    
    const form = e.target;
    const email = form.email.value.trim();
    const password = form.password.value.trim();
    const confirmPassword = form.confirmPassword.value.trim();
    const clinicName = form.clinicName ? form.clinicName.value.trim() : '';
    const submitBtn = form.querySelector('button[type="submit"]');
    const loadingSpinner = form.querySelector('.loading-spinner');
    
    console.log('📋 Form data:', { 
      email, 
      hasPassword: !!password, 
      hasConfirmPassword: !!confirmPassword,
      clinicName 
    });
    
    // Validation côté client
    if (!email || !password || !confirmPassword) {
      this.showAlert('Veuillez remplir tous les champs obligatoires', 'error');
      return;
    }

    // Validation email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      this.showAlert('Format d\'email invalide', 'error');
      return;
    }

    // Validation mot de passe
    if (password.length < 6) {
      this.showAlert('Le mot de passe doit contenir au moins 6 caractères', 'error');
      return;
    }

    if (password !== confirmPassword) {
      this.showAlert('Les mots de passe ne correspondent pas', 'error');
      return;
    }

    try {
      // Afficher le loading
      this.setLoading(submitBtn, loadingSpinner, true);
      
      console.log('📤 Sending registration request...');
      
      // Envoyer seulement email et password (pas confirmPassword ni clinicName)
      const requestData = { email, password };
      console.log('📋 Request data:', requestData);
      
      const response = await fetch(`${this.apiBase}/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestData)
      });

      console.log('📨 Response status:', response.status);
      
      const data = await response.json();
      console.log('📋 Response data:', data);

      if (response.ok && data.success) {
        this.showAlert('Compte créé avec succès! Redirection vers la connexion...', 'success');
        setTimeout(() => {
          window.location.href = '/login';
        }, 2000);
      } else {
        console.error('❌ Registration failed:', data);
        this.showAlert(data.message || 'Erreur lors de la création du compte', 'error');
      }
    } catch (error) {
      console.error('❌ Registration error:', error);
      this.showAlert('Erreur de connexion au serveur', 'error');
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
        this.showAlert('Déconnexion réussie', 'success');
        setTimeout(() => {
          window.location.href = '/login';
        }, 1000);
      } else {
        this.showAlert('Erreur lors de la déconnexion', 'error');
      }
    } catch (error) {
      console.error('Logout error:', error);
      this.showAlert('Erreur de déconnexion', 'error');
    }
  }

  setLoading(btn, spinner, isLoading) {
    if (!btn) return;
    
    const originalText = btn.getAttribute('data-original-text') || btn.textContent;
    
    if (isLoading) {
      btn.disabled = true;
      btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Chargement...';
      if (spinner) spinner.style.display = 'inline-block';
    } else {
      btn.disabled = false;
      btn.innerHTML = originalText;
      if (spinner) spinner.style.display = 'none';
    }
  }

  showAlert(message, type) {
    // Supprimer les alertes existantes
    const existingAlerts = document.querySelectorAll('.auth-alert');
    existingAlerts.forEach(alert => alert.remove());

    // Créer une nouvelle alerte
    const alertDiv = document.createElement('div');
    alertDiv.className = `auth-alert alert ${type === 'success' ? 'alert-success' : 'alert-danger'}`;
    alertDiv.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      z-index: 9999;
      max-width: 400px;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      animation: slideInRight 0.3s ease-out;
    `;
    
    alertDiv.innerHTML = `
      <div class="d-flex align-items-center">
        <i class="fas ${type === 'success' ? 'fa-check-circle' : 'fa-exclamation-triangle'} me-2"></i>
        <span>${message}</span>
        <button type="button" class="btn-close ms-auto" onclick="this.parentElement.parentElement.remove()"></button>
      </div>
    `;

    document.body.appendChild(alertDiv);

    // Supprimer automatiquement après 5 secondes
    setTimeout(() => {
      if (alertDiv && alertDiv.parentNode) {
        alertDiv.remove();
      }
    }, 5000);
  }
}

// Initialiser l'AuthManager quand le DOM est chargé
document.addEventListener('DOMContentLoaded', () => {
  console.log('🔐 Initializing AuthManager...');
  new AuthManager();
}); 