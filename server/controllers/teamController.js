const { Team } = require('../models');

exports.getAllTeams = async (req, res) => {
    try {
        const { Manager, Player } = require('../models');
        const teams = await Team.findAll({
            include: [
                { model: Manager, as: 'manager' },
                { model: Player }
            ]
        });

        const formattedTeams = teams.map(team => {
            const playersCount = team.Players ? team.Players.length : 0;
            const totalBudget = parseFloat(team.total_budget);
            const remainingBudget = parseFloat(team.remaining_budget);
            const fundsSpent = totalBudget - remainingBudget;

            return {
                ...team.toJSON(),
                players_count: playersCount,
                budget: totalBudget, // Mapping for frontend
                funds_spent: fundsSpent, // Mapping for frontend
            };
        });

        res.json(formattedTeams);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.createTeam = async (req, res) => {
    try {
        const team = await Team.create(req.body);
        res.status(201).json(team);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.getTeamById = async (req, res) => {
    try {
        const { Manager } = require('../models');
        const team = await Team.findByPk(req.params.id, {
            include: [{ model: Manager, as: 'manager' }]
        });
        if (!team) return res.status(404).json({ message: 'Team not found' });
        res.json(team);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
