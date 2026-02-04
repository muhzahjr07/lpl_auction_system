const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Player = sequelize.define('Player', {
    player_id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    name: {
        type: DataTypes.STRING,
        allowNull: false
    },
    role: {
        type: DataTypes.ENUM('BATSMAN', 'BOWLER', 'ALL_ROUNDER', 'WICKET_KEEPER'),
        allowNull: false
    },
    country: {
        type: DataTypes.STRING,
        allowNull: false
    },
    base_price: {
        type: DataTypes.DECIMAL(15, 2),
        allowNull: false
    },
    status: {
        type: DataTypes.ENUM('UNSOLD', 'SOLD', 'UNSOLD_RETAINED'),
        defaultValue: 'UNSOLD'
    },
    sold_price: {
        type: DataTypes.DECIMAL(15, 2),
        allowNull: true
    },
    image_url: {
        type: DataTypes.STRING,
        allowNull: true
    },
    total_runs: {
        type: DataTypes.INTEGER,
        allowNull: true,
        defaultValue: 0
    },
    strike_rate: {
        type: DataTypes.DECIMAL(5, 2),
        allowNull: true,
        defaultValue: 0.00
    },
    wickets: {
        type: DataTypes.INTEGER,
        allowNull: true,
        defaultValue: 0
    },
    economy_rate: {
        type: DataTypes.DECIMAL(5, 2),
        allowNull: true,
        defaultValue: 0.00
    }
});

module.exports = Player;
