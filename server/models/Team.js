const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Team = sequelize.define('Team', {
    team_id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    team_name: {
        type: DataTypes.STRING,
        allowNull: false
    },
    logo_url: {
        type: DataTypes.STRING,
        allowNull: true
    },
    total_budget: {
        type: DataTypes.DECIMAL(15, 2),
        allowNull: false,
        defaultValue: 0.00
    },
    remaining_budget: {
        type: DataTypes.DECIMAL(15, 2),
        allowNull: false,
        defaultValue: 0.00
    },
    user_id: { // Linked Team Manager
        type: DataTypes.INTEGER,
        allowNull: true
    }
});

module.exports = Team;
