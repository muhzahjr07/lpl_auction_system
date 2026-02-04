const { Player } = require('../models');

exports.getAllPlayers = async (req, res) => {
    try {
        const { Team } = require('../models');
        const players = await Player.findAll({
            include: [{ model: Team, as: 'team' }]
        });
        res.json(players);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.createPlayer = async (req, res) => {
    try {
        const player = await Player.create(req.body);
        if (req.io) req.io.emit('player_added', player);
        res.status(201).json(player);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.getPlayerById = async (req, res) => {
    try {
        const player = await Player.findByPk(req.params.id);
        if (!player) return res.status(404).json({ message: 'Player not found' });
        res.json(player);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.updatePlayer = async (req, res) => {
    try {
        const { id } = req.params;
        const [updated] = await Player.update(req.body, {
            where: { player_id: id }
        });
        if (updated) {
            const updatedPlayer = await Player.findByPk(id);
            if (req.io) req.io.emit('player_updated', updatedPlayer);
            return res.status(200).json(updatedPlayer);
        }
        throw new Error('Player not found');
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

exports.deletePlayer = async (req, res) => {
    try {
        const { id } = req.params;
        const { Bid } = require('../models');

        // Delete associated bids first (simulate CASCADE)
        await Bid.destroy({ where: { player_id: id } });

        const deleted = await Player.destroy({
            where: { player_id: id }
        });
        if (deleted) {
            if (req.io) req.io.emit('player_deleted', { id });
            return res.status(200).send("Player deleted");
        }
        throw new Error("Player not found");
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};
