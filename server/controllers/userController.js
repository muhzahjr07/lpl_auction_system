const { User } = require('../models');
const bcrypt = require('bcrypt');

exports.getAllUsers = async (req, res) => {
    try {
        const users = await User.findAll({
            attributes: { exclude: ['password_hash'] }
        });
        res.json(users);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.createUser = async (req, res) => {
    try {
        const { name, email, password, role } = req.body;

        // Basic validation
        if (!email || !password || !name) {
            return res.status(400).json({ message: 'Name, email and password are required' });
        }

        const existingUser = await User.findOne({ where: { email } });
        if (existingUser) {
            return res.status(400).json({ message: 'Email already exists' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const user = await User.create({
            name,
            email,
            password_hash: hashedPassword,
            role: role || 'AUCTIONEER'
        });

        // Return user without password hash
        const { password_hash, ...userData } = user.toJSON();
        res.status(201).json(userData);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.deleteUser = async (req, res) => {
    try {
        const { id } = req.params;

        // Prevent deleting self (optional but good practice)
        if (req.user && req.user.user_id == id) {
            return res.status(400).json({ message: 'Cannot delete yourself' });
        }

        const deleted = await User.destroy({
            where: { user_id: id }
        });

        if (deleted) {
            return res.status(200).json({ message: 'User deleted successfully' });
        }
        throw new Error('User not found');
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.updateUser = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, email, role, password } = req.body;

        const user = await User.findByPk(id);
        if (!user) return res.status(404).json({ message: 'User not found' });

        const updates = { name, email, role };

        if (password && password.trim() !== '') {
            updates.password_hash = await bcrypt.hash(password, 10);
        }

        await user.update(updates);

        const { password_hash, ...userData } = user.toJSON();
        res.json(userData);

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
