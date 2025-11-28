const socketIo = require('socket.io');

const Message = require('../models/Message');

const setupSocket = (server) => {
  const io = socketIo(server, {
    cors: { origin: '*' }
  });

  io.on('connection', (socket) => {
    // eslint-disable-next-line no-console
    console.log('User connected:', socket.id);

    socket.on('join', (userId) => {
      socket.join(userId); // join a room with userId
    });

    socket.on('sendMessage', async ({ senderId, receiverId, content }) => {
      try {
        const message = await Message.create({ sender: senderId, receiver: receiverId, content });
        // Emit to both users
        io.to(receiverId).emit('receiveMessage', message);
        io.to(senderId).emit('receiveMessage', message);
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error('Error sending message:', err);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    socket.on('disconnect', () => {
      // eslint-disable-next-line no-console
      console.log('User disconnected:', socket.id);
    });
  });
};

module.exports = setupSocket;