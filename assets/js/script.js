/**
 * Care Companion - Main JavaScript
 * Handles interactive functionality for the website
 */

document.addEventListener('DOMContentLoaded', function() {
    // Mobile menu toggle
    const mobileMenuBtn = document.querySelector('.mobile-menu-btn');
    const navMenu = document.querySelector('.nav-menu');
    
    if (mobileMenuBtn) {
        mobileMenuBtn.addEventListener('click', function() {
            navMenu.classList.toggle('active');
            this.querySelector('i').classList.toggle('fa-bars');
            this.querySelector('i').classList.toggle('fa-times');
        });
    }
    
    // Close mobile menu when clicking outside
    document.addEventListener('click', function(event) {
        if (!event.target.closest('.navbar') && navMenu.classList.contains('active')) {
            navMenu.classList.remove('active');
            if (mobileMenuBtn) {
                mobileMenuBtn.querySelector('i').classList.add('fa-bars');
                mobileMenuBtn.querySelector('i').classList.remove('fa-times');
            }
        }
    });
    
    // Form validation for signup page
    const signupForm = document.getElementById('signupForm');
    if (signupForm) {
        signupForm.addEventListener('submit', function(event) {
            event.preventDefault();
            
            const password = document.getElementById('password').value;
            const confirmPassword = document.getElementById('confirmPassword').value;
            
            if (password !== confirmPassword) {
                alert('Passwords do not match. Please try again.');
                return false;
            }
            
            // If validation passes, you would typically submit to a server
            // For this demo, we'll just show a success message
            alert('Account created successfully! You can now log in.');
            window.location.href = 'login.html';
        });
    }
    
    // Form validation for login page
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', function(event) {
            event.preventDefault();
            
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            
            // For demo purposes, accept any non-empty credentials
            if (email && password) {
                alert('Login successful! Redirecting to chat...');
                window.location.href = 'chat.html';
            } else {
                alert('Please enter both email and password.');
            }
        });
    }
    
    // Filter buttons for medications page
    const filterButtons = document.querySelectorAll('.filter-btn');
    filterButtons.forEach(button => {
        button.addEventListener('click', function() {
            // Remove active class from all buttons
            filterButtons.forEach(btn => btn.classList.remove('active'));
            
            // Add active class to clicked button
            this.classList.add('active');
            
            // In a real app, this would filter the medication list
            // For this demo, we'll just show an alert
            alert(`Filtering by: ${this.textContent}`);
        });
    });
    
    // Search functionality for medications page
    const searchInput = document.querySelector('.search-input');
    if (searchInput) {
        searchInput.addEventListener('keyup', function(event) {
            if (event.key === 'Enter') {
                // In a real app, this would trigger a search
                // For this demo, we'll just show an alert
                alert(`Searching for: ${this.value}`);
                this.value = '';
            }
        });
    }
    
    // Chat functionality (simulated)
    const chatInput = document.getElementById('chatInput');
    const chatSubmit = document.getElementById('chatSubmit');
    const chatMessages = document.getElementById('chatMessages');
    
    if (chatInput && chatSubmit) {
        chatSubmit.addEventListener('click', function() {
            sendMessage();
        });
        
        chatInput.addEventListener('keypress', function(event) {
            if (event.key === 'Enter') {
                sendMessage();
            }
        });
        
        function sendMessage() {
            const message = chatInput.value.trim();
            if (!message) return;
            
            // Add user message
            addMessage(message, 'user');
            
            // Clear input
            chatInput.value = '';
            
            // Simulate AI response after a delay
            setTimeout(() => {
                const response = getAIResponse(message);
                addMessage(response, 'ai');
            }, 1000);
        }
        
        function addMessage(text, sender) {
            const messageDiv = document.createElement('div');
            messageDiv.className = `chat-message ${sender}`;
            messageDiv.innerHTML = `
                <div class="message-content">
                    <div class="message-sender">${sender === 'user' ? 'You' : 'Health Insight'}</div>
                    <div class="message-text">${text}</div>
                </div>
            `;
            chatMessages.appendChild(messageDiv);
            chatMessages.scrollTop = chatMessages.scrollHeight;
        }
        
        function getAIResponse(userMessage) {
            const lowerMessage = userMessage.toLowerCase();
            
            if (lowerMessage.includes('headache') && lowerMessage.includes('fever')) {
                return "Based on your symptoms of headache and fever, I recommend acetaminophen or ibuprofen. Remember to stay hydrated and rest. If symptoms persist for more than 3 days, consult a healthcare professional.";
            } else if (lowerMessage.includes('cough') || lowerMessage.includes('cold')) {
                return "For cough or cold symptoms, consider dextromethorphan for cough relief or guaifenesin for mucus. Always check with a pharmacist for potential interactions with other medications you may be taking.";
            } else if (lowerMessage.includes('allergy') || lowerMessage.includes('sneezing')) {
                return "For allergy symptoms, antihistamines like loratadine or cetirizine may help. For nasal congestion, consider a decongestant like pseudoephedrine. Remember to consult with a healthcare provider if you have other medical conditions.";
            } else {
                return "Thank you for describing your symptoms. For personalized OTC medication recommendations, please provide more details about your symptoms, duration, and any other health conditions. Remember, I'm an AI assistant and not a substitute for professional medical advice.";
            }
        }
    }
    
    // Add active class to current page in navigation
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    const navLinks = document.querySelectorAll('.nav-link');
    
    navLinks.forEach(link => {
        const linkPage = link.getAttribute('href');
        if (linkPage === currentPage || (currentPage === '' && linkPage === 'index.html')) {
            link.classList.add('active');
        } else {
            link.classList.remove('active');
        }
    });
});