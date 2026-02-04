const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Manager = sequelize.define('Manager', {
    manager_id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    name: {
        type: DataTypes.STRING,
        allowNull: false
    },
    image_url: {
        type: DataTypes.STRING,
        allowNull: true
    },
    user_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        unique: true
    },
    team_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        unique: true
    }
});

module.exports = Manager;
