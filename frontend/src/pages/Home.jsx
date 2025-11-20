import React, { useEffect, useState } from 'react';
import io from 'socket.io-client';
import axios from 'axios';
import CryptoJS from 'crypto-js';
import ChatCard from '../components/ChatCard';
import { FaCommentDots } from 'react-icons/fa'; // Message icon

const socket = io('http://localhost:5000');

export default function Home() {
  const [users, setUsers] = useState([]);
  const [selectedUser, setSelectedUser] = useState(null);
  const token = localStorage.getItem('token');

  useEffect(() => {
    // Fetch all users
    axios.get('http://localhost:5000/api/users', {
      headers: { Authorization: `Bearer ${token}` }
    }).then(res => setUsers(res.data))
      .catch(err => console.error(err));
  }, [token]);

  return (
    <div className="container mt-4">
      <h2 className="mb-4 text-center">Welcome to Chat System</h2>
      <div className="row">
        {/* Left: Users List */}
        <div className="col-md-3">
          <h4>Users</h4>
          <ul className="list-group shadow">
            {users.map(user => (
              <li key={user._id} className="list-group-item d-flex justify-content-between align-items-center">
                {user.username}
                <FaCommentDots
                  style={{ cursor: 'pointer', color: 'blue' }}
                  onClick={() => setSelectedUser(user)}
                  title="Message"
                />
              </li>
            ))}
          </ul>
        </div>

        {/* Right: Chat Section */}
        <div className="col-md-9">
          {selectedUser ? (
            <ChatCard selectedUser={selectedUser} token={token} />
          ) : (
            <div className="card shadow p-4 text-center">
              <h5>Select a user to start chatting</h5>
              <p>Click the chat icon next to a user. Messages are end-to-end encrypted.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
