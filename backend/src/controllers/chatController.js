const Message = require('../models/Message');

// Get all messages between logged-in user and another user
const getMessages = async (req, res) => {
  try {
    const userId = req.user.id; // from auth middleware
    const otherUserId = req.params.userId;

    const messages = await Message.find({
      $or: [
        { from: userId, to: otherUserId },
        { from: otherUserId, to: userId },
      ],
    }).sort({ createdAt: 1 });

    res.status(200).json(messages);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = { getMessages };
