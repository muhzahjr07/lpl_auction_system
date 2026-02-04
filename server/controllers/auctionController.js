const { Player, Bid } = require('../models');

const auctionState = require('../utils/auctionState');

exports.getAuctionState = (req, res) => {
    res.json(auctionState.get());
};

exports.getUnsoldPlayers = async (req, res) => {
    try {
        const players = await Player.findAll({
            where: { status: 'UNSOLD' },
            order: [['name', 'ASC']]
        });
        res.json(players);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.startRound = async (req, res) => {
    try {
        const { playerId } = req.body;
        const player = await Player.findByPk(playerId);

        if (!player) return res.status(404).json({ message: 'Player not found' });
        if (player.status !== 'UNSOLD') return res.status(400).json({ message: 'Player already sold' });

        auctionState.set({
            activePlayerId: player.player_id,
            currentPrice: parseFloat(player.base_price),
            startTime: new Date(),
            lastBidder: null,
            lastBidderId: null,
            lastBidderTeamLogo: null
        });

        // Notify via Socket (handled in socket layer, but controller triggers it usually via event emitter)
        // For simplicity, we assume the Auctioneer client emits the socket event "start_bidding" 
        // OR we export io instance to here. 
        // For this architecture, we will reply success and let client emit socket event.

        res.json({ message: 'Round started', state: auctionState.get() });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.markUnsold = async (req, res) => {
    try {
        const { playerId } = req.body;
        // Optionally update player status to 'PASSED' or keep 'UNSOLD'
        // For now, we just reset the auction state
        auctionState.reset();

        // Notify socket room
        if (req.io) {
            req.io.to('auction_room').emit('auction_reset');
        }

        res.json({ message: 'Player marked unsold', state: auctionState.get() });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.resetState = (req, res) => {
    try {
        auctionState.reset();
        if (req.io) {
            req.io.to('auction_room').emit('auction_reset');
        }
        res.json({ message: 'Auction state suspended/reset', state: auctionState.get() });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
