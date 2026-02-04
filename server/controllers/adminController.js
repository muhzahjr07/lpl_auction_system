const { Player, Team } = require('../models');

exports.getDashboardStats = async (req, res) => {
    try {
        const totalPlayers = await Player.count();
        const teams = await Team.findAll();

        let totalPurse = 0;
        let activeTeams = teams.length;

        teams.forEach(team => {
            totalPurse += parseFloat(team.total_budget);
        });

        res.json({
            totalPlayers,
            activeTeams,
            totalPurse,
            pendingEvents: 'Live now' // Static or derived from auction state
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
const auctionState = require('../utils/auctionState');
const seed = require('../seed');

exports.resetDatabase = async (req, res) => {
    try {
        console.log('Starting DB Reset...');
        await seed(); // Call the seed function directly

        auctionState.reset();
        if (req.io) {
            req.io.emit('auction_reset');
            req.io.emit('player_updated'); // Trigger client refresh
        }
        res.json({ message: 'Database reset successfully' });
    } catch (error) {
        console.error('Reset Failed:', error);
        res.status(500).json({ error: error.message });
    }
};
