class RemoteMouseClient {
    constructor() {
        this.ws = null;
        this.isConnected = false;
        this.lastTouch = { x: 0, y: 0 };
        this.isTouching = false;
        
        this.init();
    }
    
    init() {
        this.setupWebSocket();
        this.setupTouchEvents();
        this.updateConnectionStatus('Connecting...', 'disconnected');
    }
    
    setupWebSocket() {
        // Get the server IP from the current hostname
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws`;
        
        console.log('Connecting to WebSocket:', wsUrl);
        
        this.ws = new WebSocket(wsUrl);
        
        this.ws.onopen = () => {
            console.log('WebSocket connected');
            this.isConnected = true;
            this.updateConnectionStatus('Connected', 'connected');
        };
        
        this.ws.onmessage = (event) => {
            console.log('Received message:', event.data);
        };
        
        this.ws.onclose = () => {
            console.log('WebSocket disconnected');
            this.isConnected = false;
            this.updateConnectionStatus('Disconnected', 'disconnected');
            
            // Attempt to reconnect after 3 seconds
            setTimeout(() => {
                if (!this.isConnected) {
                    this.setupWebSocket();
                }
            }, 3000);
        };
        
        this.ws.onerror = (error) => {
            console.error('WebSocket error:', error);
            this.updateConnectionStatus('Connection Error', 'disconnected');
        };
    }
    
    setupTouchEvents() {
        const touchpad = document.getElementById('touchpad');
        
        // Touch events
        touchpad.addEventListener('touchstart', (e) => {
            e.preventDefault();
            this.isTouching = true;
            touchpad.classList.add('touching');
            
            if (e.touches.length > 0) {
                this.lastTouch = {
                    x: e.touches[0].clientX,
                    y: e.touches[0].clientY
                };
            }
        });
        
        touchpad.addEventListener('touchmove', (e) => {
            e.preventDefault();
            
            if (!this.isConnected || !this.isTouching || e.touches.length === 0) {
                return;
            }
            
            const currentTouch = {
                x: e.touches[0].clientX,
                y: e.touches[0].clientY
            };
            
            const dx = currentTouch.x - this.lastTouch.x;
            const dy = currentTouch.y - this.lastTouch.y;
            
            // Only send if there's significant movement
            if (Math.abs(dx) > 1 || Math.abs(dy) > 1) {
                this.sendPointerMove(dx, dy);
                this.lastTouch = currentTouch;
            }
        });
        
        touchpad.addEventListener('touchend', (e) => {
            e.preventDefault();
            this.isTouching = false;
            touchpad.classList.remove('touching');
        });
        
        // Mouse events for desktop testing
        touchpad.addEventListener('mousedown', (e) => {
            e.preventDefault();
            this.isTouching = true;
            touchpad.classList.add('touching');
            this.lastTouch = { x: e.clientX, y: e.clientY };
        });
        
        touchpad.addEventListener('mousemove', (e) => {
            e.preventDefault();
            
            if (!this.isConnected || !this.isTouching) {
                return;
            }
            
            const dx = e.clientX - this.lastTouch.x;
            const dy = e.clientY - this.lastTouch.y;
            
            if (Math.abs(dx) > 1 || Math.abs(dy) > 1) {
                this.sendPointerMove(dx, dy);
                this.lastTouch = { x: e.clientX, y: e.clientY };
            }
        });
        
        touchpad.addEventListener('mouseup', (e) => {
            e.preventDefault();
            this.isTouching = false;
            touchpad.classList.remove('touching');
        });
        
        // Prevent context menu
        touchpad.addEventListener('contextmenu', (e) => {
            e.preventDefault();
        });
    }
    
    sendPointerMove(dx, dy) {
        if (!this.isConnected) return;
        
        const message = {
            type: 'pointer_move',
            dx: Math.round(dx),
            dy: Math.round(dy),
            timestamp: Date.now()
        };
        
        try {
            this.ws.send(JSON.stringify(message));
            console.log('Sent pointer move:', message);
        } catch (error) {
            console.error('Failed to send message:', error);
        }
    }
    
    updateConnectionStatus(text, className) {
        const statusElement = document.getElementById('connection-status');
        statusElement.textContent = text;
        statusElement.className = `status-item ${className}`;
    }
}

// Initialize the client when the page loads
document.addEventListener('DOMContentLoaded', () => {
    new RemoteMouseClient();
});
