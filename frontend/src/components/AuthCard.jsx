import React, { useState } from 'react';
import { signup, verifyOTP, signin } from '../api/auth';

export default function AuthCard() {
  const [mode, setMode] = useState('welcome'); // 'welcome' | 'register' | 'otp' | 'login'
  const [formData, setFormData] = useState({});
  const [email, setEmail] = useState('');

  const handleRegister = async (e) => {
    e.preventDefault();
    try {
      const res = await signup(formData);
      alert(res.data.message);
      setEmail(formData.email);
      setMode('otp');
    } catch (err) {
      alert(err.response?.data?.message || 'Error');
    }
  };

  const handleVerifyOTP = async (e) => {
    e.preventDefault();
    try {
      const res = await verifyOTP({ email, otp: formData.otp });
      alert(res.data.message);
      setMode('login');
    } catch (err) {
      alert(err.response?.data?.message || 'Invalid OTP');
    }
  };

  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      const res = await signin(formData);
      alert('Login successful!');
      localStorage.setItem('token', res.data.token);
      window.location.href = '/home';
    } catch (err) {
      alert(err.response?.data?.message || 'Login failed');
    }
  };

  return (
    <div className="card mx-auto shadow" style={{ maxWidth: '500px' }}>
      <div className="card-body">
        <h3 className="card-title text-center">Chat System</h3>

        {mode === 'welcome' && (
          <>
            <p className="text-center">Please choose an option below to get started.</p>
            <div className="d-flex justify-content-center mb-3">
              <button className="btn btn-primary me-2" onClick={() => setMode('register')}>Register</button>
              <button className="btn btn-success" onClick={() => setMode('login')}>Login</button>
            </div>
          </>
        )}

        {mode === 'register' && (
          <form onSubmit={handleRegister}>
            <div className="mb-3">
              <label>Username</label>
              <input type="text" className="form-control" required
                     onChange={e => setFormData({ ...formData, username: e.target.value })}/>
            </div>
            <div className="mb-3">
              <label>Email</label>
              <input type="email" className="form-control" required
                     onChange={e => setFormData({ ...formData, email: e.target.value })}/>
            </div>
            <div className="mb-3">
              <label>Password</label>
              <input type="password" className="form-control" required
                     onChange={e => setFormData({ ...formData, password: e.target.value })}/>
            </div>
            <button type="submit" className="btn btn-primary w-100">Register</button>
          </form>
        )}

        {mode === 'otp' && (
          <form onSubmit={handleVerifyOTP}>
            <div className="mb-3">
              <label>Enter OTP</label>
              <input type="text" className="form-control" required
                     onChange={e => setFormData({ ...formData, otp: e.target.value })}/>
            </div>
            <button type="submit" className="btn btn-warning w-100">Verify OTP</button>
          </form>
        )}

        {mode === 'login' && (
          <form onSubmit={handleLogin}>
            <div className="mb-3">
              <label>Email</label>
              <input type="email" className="form-control" required
                     onChange={e => setFormData({ ...formData, email: e.target.value })}/>
            </div>
            <div className="mb-3">
              <label>Password</label>
              <input type="password" className="form-control" required
                     onChange={e => setFormData({ ...formData, password: e.target.value })}/>
            </div>
            <button type="submit" className="btn btn-success w-100">Login</button>
          </form>
        )}
      </div>
    </div>
  );
}
