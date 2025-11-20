const socketIo = require('socket.io');
const Message = require('../models/Message');

const setupSocket = (server) => {
  const io = socketIo(server, {
    cors: { origin: '*' }
  });

  io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    socket.on('join', (userId) => {
      socket.join(userId); // join a room with userId
    });

    socket.on('sendMessage', async ({ senderId, receiverId, content }) => {
      const message = await Message.create({ sender: senderId, receiver: receiverId, content });
      io.to(receiverId).emit('receiveMessage', message); // real-time
      io.to(senderId).emit('receiveMessage', message);
    });

    socket.on('disconnect', () => {
      console.log('User disconnected:', socket.id);
    });
  });
};

module.exports = setupSocket;
