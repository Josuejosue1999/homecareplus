// Settings Location Detection Module
const SettingsLocation = {
    // Configuration
    config: {
        googleMapsApiKey: 'AIzaSyBYKxOGQl4sEGGZQ7Q8wJxGQGZGZ7Q8wJx', // À remplacer par votre clé API
        timeout: 10000, // 10 secondes
        enableHighAccuracy: true,
        maximumAge: 300000 // 5 minutes
    },

    // État de l'application
    state: {
        isDetecting: false,
        lastDetection: null
    },

    // Initialiser le module
    init() {
        this.bindEvents();
        this.setupAddressAutoGeneration();
        console.log('✅ Settings Location module initialized');
    },

    // Lier les événements
    bindEvents() {
        const detectBtn = document.getElementById('detectLocationBtn');
        if (detectBtn) {
            detectBtn.addEventListener('click', () => this.detectLocation());
        }

        // Écouter les changements dans les champs d'adresse pour auto-générer l'adresse complète
        const addressFields = ['street', 'city', 'sector', 'country'];
        addressFields.forEach(fieldId => {
            const field = document.getElementById(fieldId);
            if (field) {
                field.addEventListener('input', () => this.generateFullAddress());
            }
        });
    },

    // Configuration pour l'auto-génération d'adresse
    setupAddressAutoGeneration() {
        // Générer l'adresse complète au chargement si les champs sont remplis
        this.generateFullAddress();
    },

    // Générer automatiquement l'adresse complète
    generateFullAddress() {
        const street = document.getElementById('street')?.value?.trim() || '';
        const city = document.getElementById('city')?.value?.trim() || '';
        const sector = document.getElementById('sector')?.value?.trim() || '';
        const country = document.getElementById('country')?.value?.trim() || '';

        const addressParts = [];
        
        if (street) addressParts.push(street);
        if (sector) addressParts.push(sector);
        if (city) addressParts.push(city);
        if (country) addressParts.push(country);

        const fullAddress = addressParts.join(', ');
        const addressField = document.getElementById('address');
        
        if (addressField) {
            addressField.value = fullAddress;
        }
    },

    // Détecter la localisation
    async detectLocation() {
        if (this.state.isDetecting) {
            console.log('⚠️ Location detection already in progress');
            return;
        }

        this.state.isDetecting = true;
        this.updateUI('detecting');

        try {
            console.log('🔍 Starting location detection...');
            
            // Vérifier si la géolocalisation est supportée
            if (!navigator.geolocation) {
                throw new Error('Geolocation is not supported by this browser');
            }

            // Obtenir la position
            const position = await this.getCurrentPosition();
            console.log('📍 Position obtained:', position.coords);

            // Obtenir l'adresse via géocodage inverse
            const addressData = await this.reverseGeocode(position.coords.latitude, position.coords.longitude);
            console.log('🏠 Address data obtained:', addressData);

            // Mettre à jour les champs
            this.updateLocationFields(addressData, position.coords);
            
            this.updateUI('success', 'Location detected successfully!');
            this.state.lastDetection = new Date();

        } catch (error) {
            console.error('❌ Location detection failed:', error);
            this.updateUI('error', `Failed to detect location: ${error.message}`);
        } finally {
            this.state.isDetecting = false;
        }
    },

    // Obtenir la position actuelle (promisifiée)
    getCurrentPosition() {
        return new Promise((resolve, reject) => {
            const options = {
                enableHighAccuracy: this.config.enableHighAccuracy,
                timeout: this.config.timeout,
                maximumAge: this.config.maximumAge
            };

            navigator.geolocation.getCurrentPosition(resolve, reject, options);
        });
    },

    // Géocodage inverse pour obtenir l'adresse
    async reverseGeocode(latitude, longitude) {
        try {
            // Essayer d'abord avec l'API Nominatim (gratuite)
            const nominatimResponse = await fetch(
                `https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=json&addressdetails=1`
            );

            if (nominatimResponse.ok) {
                const data = await nominatimResponse.json();
                return this.parseNominatimResponse(data);
            }

            // Fallback vers une API alternative si nécessaire
            throw new Error('Geocoding service unavailable');

        } catch (error) {
            console.error('❌ Reverse geocoding failed:', error);
            
            // Retourner des coordonnées au minimum
            return {
                street: '',
                city: '',
                sector: '',
                country: '',
                latitude: latitude,
                longitude: longitude,
                fullAddress: `Coordinates: ${latitude.toFixed(6)}, ${longitude.toFixed(6)}`
            };
        }
    },

    // Parser la réponse de Nominatim
    parseNominatimResponse(data) {
        const address = data.address || {};
        
        // Extraire les composants d'adresse
        const street = this.getStreetAddress(address);
        const city = address.city || address.town || address.village || address.municipality || '';
        const sector = address.suburb || address.neighbourhood || address.quarter || address.county || '';
        const country = address.country || '';

        return {
            street: street,
            city: city,
            sector: sector,
            country: country,
            latitude: parseFloat(data.lat),
            longitude: parseFloat(data.lon),
            fullAddress: data.display_name || '',
            rawData: address
        };
    },

    // Construire l'adresse de rue
    getStreetAddress(address) {
        const components = [];
        
        if (address.house_number) components.push(address.house_number);
        if (address.road) components.push(address.road);
        if (!address.road && address.pedestrian) components.push(address.pedestrian);
        if (!address.road && !address.pedestrian && address.footway) components.push(address.footway);

        return components.join(' ');
    },

    // Mettre à jour les champs de localisation
    updateLocationFields(addressData, coords) {
        const fields = {
            'street': addressData.street,
            'city': addressData.city,
            'sector': addressData.sector,
            'country': addressData.country,
            'latitude': coords ? coords.latitude.toFixed(6) : addressData.latitude,
            'longitude': coords ? coords.longitude.toFixed(6) : addressData.longitude
        };

        Object.entries(fields).forEach(([fieldId, value]) => {
            const field = document.getElementById(fieldId);
            if (field && value) {
                field.value = value;
                console.log(`✅ Updated ${fieldId}: ${value}`);
            }
        });

        // Générer l'adresse complète
        this.generateFullAddress();
    },

    // Mettre à jour l'interface utilisateur
    updateUI(status, message = '') {
        const statusDiv = document.getElementById('locationStatus');
        const statusText = document.getElementById('locationStatusText');
        const detectBtn = document.getElementById('detectLocationBtn');

        if (!statusDiv || !statusText || !detectBtn) return;

        // Réinitialiser les classes
        statusDiv.className = 'alert d-none';
        
        switch (status) {
            case 'detecting':
                statusDiv.classList.add('alert-warning');
                statusDiv.classList.remove('d-none');
                statusText.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Detecting your location...';
                detectBtn.disabled = true;
                detectBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Detecting...';
                break;

            case 'success':
                statusDiv.classList.add('alert-success');
                statusDiv.classList.remove('d-none');
                statusText.innerHTML = `<i class="fas fa-check-circle me-2"></i>${message}`;
                detectBtn.disabled = false;
                detectBtn.innerHTML = '<i class="fas fa-location-arrow me-2"></i>Detect My Location';
                
                // Masquer le message de succès après 5 secondes
                setTimeout(() => {
                    statusDiv.classList.add('d-none');
                }, 5000);
                break;

            case 'error':
                statusDiv.classList.add('alert-danger');
                statusDiv.classList.remove('d-none');
                statusText.innerHTML = `<i class="fas fa-exclamation-triangle me-2"></i>${message}`;
                detectBtn.disabled = false;
                detectBtn.innerHTML = '<i class="fas fa-location-arrow me-2"></i>Detect My Location';
                
                // Masquer le message d'erreur après 8 secondes
                setTimeout(() => {
                    statusDiv.classList.add('d-none');
                }, 8000);
                break;

            default:
                statusDiv.classList.add('d-none');
                detectBtn.disabled = false;
                detectBtn.innerHTML = '<i class="fas fa-location-arrow me-2"></i>Detect My Location';
                break;
        }
    },

    // Obtenir les données de localisation actuelles
    getCurrentLocationData() {
        return {
            street: document.getElementById('street')?.value || '',
            city: document.getElementById('city')?.value || '',
            sector: document.getElementById('sector')?.value || '',
            country: document.getElementById('country')?.value || '',
            address: document.getElementById('address')?.value || '',
            latitude: parseFloat(document.getElementById('latitude')?.value) || null,
            longitude: parseFloat(document.getElementById('longitude')?.value) || null
        };
    },

    // Valider les données de localisation
    validateLocationData() {
        const data = this.getCurrentLocationData();
        const errors = [];

        if (!data.street.trim()) errors.push('Street address is required');
        if (!data.city.trim()) errors.push('City is required');
        if (!data.country.trim()) errors.push('Country is required');
        if (!data.latitude || !data.longitude) errors.push('Coordinates are required for distance calculation');

        return {
            isValid: errors.length === 0,
            errors: errors,
            data: data
        };
    }
};

// Initialiser quand le DOM est chargé
document.addEventListener('DOMContentLoaded', () => {
    if (document.getElementById('detectLocationBtn')) {
        SettingsLocation.init();
    }
});

// Exporter pour utilisation globale
window.SettingsLocation = SettingsLocation; 