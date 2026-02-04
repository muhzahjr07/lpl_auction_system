const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { User } = require('../models');

exports.register = async (req, res) => {
    try {
        const { name, email, password, role } = req.body;
        const hashedPassword = await bcrypt.hash(password, 10);
        const user = await User.create({ name, email, password_hash: hashedPassword, role });
        res.status(201).json({ message: 'User created successfully', userId: user.user_id });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;
        const user = await User.findOne({ where: { email } });
        if (!user) return res.status(404).json({ message: 'User not found' });

        const validPassword = await bcrypt.compare(password, user.password_hash);
        if (!validPassword) return res.status(401).json({ message: 'Invalid credentials' });

        let teamDetails = null;
        if (user.role === 'TEAM_MANAGER') {
            const { Team, Manager } = require('../models');
            // Find Manager profile for this user
            const manager = await Manager.findOne({ where: { user_id: user.user_id } });

            if (manager) {
                const team = await Team.findByPk(manager.team_id);
                if (team) {
                    teamDetails = {
                        team_id: team.team_id,
                        team_name: team.team_name,
                        logo_url: team.logo_url
                    };
                }
            }
        }

        const token = jwt.sign(
            {
                user_id: user.user_id,
                role: user.role,
                name: user.name,
                team_id: teamDetails ? teamDetails.team_id : null
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );
        res.json({
            token,
            role: user.role,
            name: user.name,
            team: teamDetails
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
