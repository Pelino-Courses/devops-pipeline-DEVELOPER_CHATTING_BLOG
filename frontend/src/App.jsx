import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import AuthCard from './components/AuthCard';
import Home from './pages/Home';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<AuthCard />} />
        <Route path="/home" element={<Home />} />
      </Routes>
    </Router>
  );
}

export default App;
