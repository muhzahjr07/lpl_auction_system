const { Bid, Team, Player } = require('../models');
const auctionState = require('../utils/auctionState');

module.exports = (io, socket) => {
    // Join logic
    socket.on('join_auction', (room) => {
        socket.join(room); // usually "auction_room"
        console.log(`Socket ${socket.id} joined ${room}`);
    });

    socket.on('start_auction_round', (data) => {
        io.to('auction_room').emit('new_round_started', data);
    });

    // Place Bid
    socket.on('place_bid', async (data) => {
        // data: { teamId, playerId, amount }
        try {
            const { teamId, playerId, amount } = data;

            // 1. Validation (DB checks)
            const team = await Team.findByPk(teamId);
            const player = await Player.findByPk(playerId);

            if (!team || !player) {
                socket.emit('error', { message: 'Invalid Team or Player' });
                return;
            }

            if (amount > team.remaining_budget) {
                socket.emit('error', { message: 'Insufficient Budget' });
                return;
            }

            // 2. Save Bid
            const bid = await Bid.create({
                amount: amount,
                team_id: teamId,
                player_id: player.id
            });

            // 3. Update Player Current Price (in memory or separate field if needed, but last bid implies price)
            auctionState.set({
                currentPrice: amount,
                lastBidder: team.team_name,
                lastBidderId: team.team_id,
                lastBidderTeamLogo: team.logo_url
            });

            // 4. Broadcast
            io.to('auction_room').emit('new_bid', {
                amount: amount,
                teamName: team.team_name,
                teamId: team.team_id,
                teamLogo: team.logo_url
            });

        } catch (error) {
            console.error(error);
            socket.emit('error', { message: 'Bid Failed' });
        }
    });

    // Player Sold
    socket.on('player_sold', async (data) => {
        // data: { teamId, playerId, finalAmount }
        try {
            const { teamId, playerId, finalAmount } = data;

            // Update Team Budget
            const team = await Team.findByPk(teamId);
            team.remaining_budget = team.remaining_budget - finalAmount;
            await team.save();

            // Update Player Status
            const player = await Player.findByPk(playerId);
            player.status = 'SOLD';
            player.team_id = teamId; // Associate
            player.sold_price = finalAmount; // Save Sold Price
            await player.save();

            io.to('auction_room').emit('sold_confirmed', {
                playerId,
                teamName: team.team_name,
                amount: finalAmount
            });

            // Reset Auction State internally so next getAuctionState returns null
            auctionState.reset();

        } catch (error) {
            console.error(error);
        }
    });
};
