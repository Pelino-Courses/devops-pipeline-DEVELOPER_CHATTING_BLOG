// Detect API URL based on current location
const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
  ? 'http://localhost:5000/api'  // For local development
  : `http://${window.location.hostname}:5000/api`;  // For deployed environment

async function request(url, method = 'GET', body = null) {
    const token = localStorage.getItem('token');
    const config = {
        method,
        headers: {
            'Content-Type': 'application/json',
            ...(token && { Authorization: `Bearer ${token}` })
        }
    };
    if (body) config.body = JSON.stringify(body);
    
    try {
        const res = await fetch(API_URL + url, config);
        if (!res.ok) {
            console.error(`API Error: ${res.status} ${res.statusText}`, await res.text());
        }
        return res.json();
    } catch (error) {
        console.error('API Request Error:', error);
        throw error;
    }
}

// Helper to save logged-in user's id
function setCurrentUser(user) {
    localStorage.setItem("userId", user._id);
}

function getCurrentUserId() {
    return localStorage.getItem("userId");
}