// Water Ripple Effect - Interactive Mouse Movement
class WaterRippleEffect {
    constructor() {
        this.rippleContainer = null;
        this.particles = [];
        this.lastRippleTime = 0;
        this.rippleDelay = 150; // Minimum delay between ripples
        this.init();
    }

    init() {
        this.createRippleContainer();
        this.createParticles();
        this.bindEvents();
    }

    createRippleContainer() {
        // Create the main ripple background
        const rippleBackground = document.createElement('div');
        rippleBackground.className = 'water-ripple-background';
        document.body.appendChild(rippleBackground);

        // Create container for interactive ripples
        this.rippleContainer = document.createElement('div');
        this.rippleContainer.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            z-index: 0;
        `;
        document.body.appendChild(this.rippleContainer);
    }

    createParticles() {
        const particleCount = 12;
        
        for (let i = 0; i < particleCount; i++) {
            const particle = document.createElement('div');
            particle.className = 'water-particle';
            
            // Random positioning
            const x = Math.random() * 100;
            const y = Math.random() * 100;
            
            particle.style.cssText = `
                left: ${x}%;
                top: ${y}%;
                animation-delay: ${Math.random() * 8}s;
            `;
            
            this.rippleContainer.appendChild(particle);
            this.particles.push(particle);
        }
    }

    createRipple(x, y, isInteractive = false) {
        const now = Date.now();
        
        // Throttle ripple creation
        if (isInteractive && now - this.lastRippleTime < this.rippleDelay) {
            return;
        }
        
        this.lastRippleTime = now;

        const ripple = document.createElement('div');
        ripple.className = isInteractive ? 'interactive-ripple' : 'ripple-circle';
        
        // Random size for variety
        const size = isInteractive ? 
            Math.random() * 200 + 100 : 
            Math.random() * 300 + 150;
        
        ripple.style.cssText = `
            left: ${x - size/2}px;
            top: ${y - size/2}px;
            width: ${size}px;
            height: ${size}px;
        `;
        
        this.rippleContainer.appendChild(ripple);
        
        // Remove ripple after animation
        setTimeout(() => {
            if (ripple.parentNode) {
                ripple.parentNode.removeChild(ripple);
            }
        }, isInteractive ? 1500 : 2000);
    }

    // Create automatic ripples at random intervals
    createAutomaticRipples() {
        const createRandomRipple = () => {
            const x = Math.random() * window.innerWidth;
            const y = Math.random() * window.innerHeight;
            this.createRipple(x, y, false);
            
            // Schedule next ripple
            setTimeout(createRandomRipple, Math.random() * 3000 + 2000);
        };
        
        // Start automatic ripples
        setTimeout(createRandomRipple, 1000);
    }

    bindEvents() {
        let mouseMoveTimer;
        
        // Mouse move ripples
        document.addEventListener('mousemove', (e) => {
            clearTimeout(mouseMoveTimer);
            mouseMoveTimer = setTimeout(() => {
                this.createRipple(e.clientX, e.clientY, true);
            }, 50);
        });

        // Click ripples
        document.addEventListener('click', (e) => {
            // Create a larger ripple on click
            const ripple = document.createElement('div');
            ripple.className = 'ripple-circle';
            
            const size = Math.random() * 150 + 200;
            ripple.style.cssText = `
                left: ${e.clientX - size/2}px;
                top: ${e.clientY - size/2}px;
                width: ${size}px;
                height: ${size}px;
                background: radial-gradient(circle, rgba(21, 155, 189, 0.15) 0%, rgba(66, 165, 245, 0.08) 50%, transparent 100%);
            `;
            
            this.rippleContainer.appendChild(ripple);
            
            setTimeout(() => {
                if (ripple.parentNode) {
                    ripple.parentNode.removeChild(ripple);
                }
            }, 2000);
        });

        // Window resize handler
        window.addEventListener('resize', () => {
            this.repositionParticles();
        });

        // Start automatic ripples
        this.createAutomaticRipples();
    }

    repositionParticles() {
        this.particles.forEach(particle => {
            const x = Math.random() * 100;
            const y = Math.random() * 100;
            particle.style.left = `${x}%`;
            particle.style.top = `${y}%`;
        });
    }

    // Method to adjust intensity based on user preference
    setIntensity(level) {
        const intensity = Math.max(0.1, Math.min(1, level));
        this.rippleDelay = 300 - (intensity * 200);
        
        // Adjust particle opacity
        this.particles.forEach(particle => {
            particle.style.opacity = intensity * 0.3;
        });
    }
}

// Initialize the water ripple effect when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    // Only initialize on login and register pages
    if (window.location.pathname.includes('/login') || 
        window.location.pathname.includes('/register') ||
        document.querySelector('.auth-container')) {
        
        new WaterRippleEffect();
    }
});

// Export for potential external use
window.WaterRippleEffect = WaterRippleEffect; 