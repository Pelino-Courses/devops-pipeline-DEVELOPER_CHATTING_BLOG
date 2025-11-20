import React, { useState, useEffect, useRef } from 'react';
import io from 'socket.io-client';
import CryptoJS from 'crypto-js';

const socket = io('http://localhost:5000');

export default function ChatCard({ selectedUser, token }) {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const secretKey = 'secret123'; // AES key
  const messagesEndRef = useRef(null);

  useEffect(() => {
    // Scroll to bottom when messages change
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });

    // Listen for messages from backend
    socket.on('receive_message', (data) => {
      if (data.from === selectedUser._id) {
        const decrypted = CryptoJS.AES.decrypt(data.message, secretKey).toString(CryptoJS.enc.Utf8);
        setMessages(prev => [...prev, { from: data.from, message: decrypted }]);
      }
    });

    return () => socket.off('receive_message');
  }, [selectedUser]);

  const handleSend = () => {
    if (!input) return;

    const encrypted = CryptoJS.AES.encrypt(input, secretKey).toString();
    socket.emit('send_message', { to: selectedUser._id, message: encrypted });
    setMessages(prev => [...prev, { from: 'Me', message: input }]);
    setInput('');
  };

  return (
    <div className="card shadow" style={{ height: '500px' }}>
      <div className="card-header">
        Chat with {selectedUser.username}
      </div>
      <div className="card-body" style={{ overflowY: 'auto', maxHeight: '380px' }}>
        {messages.map((msg, i) => (
          <div key={i}><strong>{msg.from === 'Me' ? 'Me' : selectedUser.username}:</strong> {msg.message}</div>
        ))}
        <div ref={messagesEndRef}></div>
      </div>
      <div className="card-footer d-flex">
        <input
          type="text"
          className="form-control me-2"
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleSend()}
        />
        <button className="btn btn-primary" onClick={handleSend}>Send</button>
      </div>
    </div>
  );
}
