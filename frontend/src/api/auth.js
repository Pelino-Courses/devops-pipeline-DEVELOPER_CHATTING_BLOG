import axios from 'axios';

const API_URL = 'http://localhost:5000/api';

export const signup = (data) => axios.post(`${API_URL}/signup`, data);
export const verifyOTP = (data) => axios.post(`${API_URL}/verify-otp`, data);
export const signin = (data) => axios.post(`${API_URL}/signin`, data);
