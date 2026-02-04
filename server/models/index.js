const User = require('./User');
const Team = require('./Team');
const Player = require('./Player');
const Bid = require('./Bid');
const Manager = require('./Manager');

// Associations

// User has one Manager profile
User.hasOne(Manager, { foreignKey: 'user_id' });
Manager.belongsTo(User, { foreignKey: 'user_id' });

// Team has one Manager
Team.hasOne(Manager, { foreignKey: 'team_id', as: 'manager' });
Manager.belongsTo(Team, { foreignKey: 'team_id', as: 'team' });

// Player belongs to a Team (if sold)
Player.belongsTo(Team, { foreignKey: 'team_id', as: 'team' });
Team.hasMany(Player, { foreignKey: 'team_id' });

// Bids
Bid.belongsTo(Player, { foreignKey: 'player_id' });
Bid.belongsTo(Team, { foreignKey: 'team_id' });
Player.hasMany(Bid, { foreignKey: 'player_id' });
Team.hasMany(Bid, { foreignKey: 'team_id' });

module.exports = {
    User,
    Team,
    Player,
    Bid,
    Manager
};
