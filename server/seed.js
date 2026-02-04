const sequelize = require('./config/database');
const { Team, Player, User } = require('./models');
const bcrypt = require('bcrypt');

async function seed() {
    try {
        await sequelize.sync({ force: true }); // WARNING: Wipes DB
        console.log('Database Synced. Seeding...');

        // 1. Create Users
        const passwordHash = await bcrypt.hash('password123', 10);

        // Admin & Auctioneer
        await User.bulkCreate([
            { name: 'System Admin', email: 'admin@lpl.com', password_hash: passwordHash, role: 'ADMIN' },
            { name: 'Official Auctioneer', email: 'auctioneer@lpl.com', password_hash: passwordHash, role: 'AUCTIONEER' },
        ]);

        // Team Managers
        const managers = await User.bulkCreate([
            { name: 'Sanath Jayasuriya', email: 'jaffna@lpl.com', password_hash: passwordHash, role: 'TEAM_MANAGER' },
            { name: 'Chaminda Vaas', email: 'colombo@lpl.com', password_hash: passwordHash, role: 'TEAM_MANAGER' },
            { name: 'Lasith Malinga', email: 'galle@lpl.com', password_hash: passwordHash, role: 'TEAM_MANAGER' },
            { name: 'Mahela Jayawardene', email: 'dambulla@lpl.com', password_hash: passwordHash, role: 'TEAM_MANAGER' },
            { name: 'Kumar Sangakkara', email: 'kandy@lpl.com', password_hash: passwordHash, role: 'TEAM_MANAGER' },
        ]);

        // 2. Create Teams (All 5 LPL Teams)
        const teams = await Team.bulkCreate([
            { team_name: 'Jaffna Kings', logo_url: 'assets/teams/jaffna.jpg', total_budget: 1000000, remaining_budget: 1000000 },
            { team_name: 'Colombo Strikers', logo_url: 'assets/teams/colombo.jpg', total_budget: 1000000, remaining_budget: 1000000 },
            { team_name: 'Galle Titans', logo_url: 'assets/teams/galle.jpg', total_budget: 1000000, remaining_budget: 1000000 },
            { team_name: 'Dambulla Aura', logo_url: 'assets/teams/dambulla.jpg', total_budget: 1000000, remaining_budget: 1000000 },
            { team_name: 'B-Love Kandy', logo_url: 'assets/teams/kandy.jpg', total_budget: 1000000, remaining_budget: 1000000 },
        ]);

        // 2.5 Create Managers linked to Teams and Users
        // Note: Managers array order matches Teams array order (0-4)
        const { Manager } = require('./models');
        await Manager.bulkCreate([
            { name: managers[0].name, user_id: managers[0].user_id, team_id: teams[0].team_id },
            { name: managers[1].name, user_id: managers[1].user_id, team_id: teams[1].team_id },
            { name: managers[2].name, user_id: managers[2].user_id, team_id: teams[2].team_id },
            { name: managers[3].name, user_id: managers[3].user_id, team_id: teams[3].team_id },
            { name: managers[4].name, user_id: managers[4].user_id, team_id: teams[4].team_id },
        ]);


        // 3. Create Players (From CSV)
        const fs = require('fs');
        const path = require('path');

        console.log('Reading players from CSV...');
        const csvPath = path.join(__dirname, 'players.csv');
        const csvContent = fs.readFileSync(csvPath, 'utf8');
        const dataLines = csvContent.split(/\r?\n/).slice(1);

        const realPlayers = [];
        const regex = /,(?=(?:(?:[^"]*"){2})*[^"]*$)/;

        for (const line of dataLines) {
            if (!line.trim()) continue;
            const parts = line.split(regex);

            if (parts.length >= 8) {
                // player_id,name,role,country,base_price,status,sold_price,image_url
                const name = parts[1].replace(/^"|"$/g, '');
                const role = parts[2].replace(/^"|"$/g, '');
                const country = parts[3].replace(/^"|"$/g, '');
                const base_price = parseInt(parts[4]) || 0;
                const status = parts[5].replace(/^"|"$/g, '');
                let image_url = parts[7];

                if (image_url) {
                    image_url = image_url.replace(/^"|"$/g, '');
                    if (image_url === 'NULL' || image_url === 'null') image_url = null;
                }

                const total_runs = parseInt(parts[8]) || 0;
                const strike_rate = parseFloat(parts[9]) || 0.0;
                const wickets = parseInt(parts[10]) || 0;
                const economy_rate = parseFloat(parts[11]) || 0.0;

                realPlayers.push({
                    name,
                    role,
                    country,
                    base_price,
                    status,
                    image_url,
                    total_runs,
                    strike_rate,
                    wickets,
                    economy_rate
                });
            }
        }

        await Player.bulkCreate(realPlayers);

        console.log(`Seeding Complete! Created ${managers.length} Managers, 5 Teams, and ${realPlayers.length} Players.`);
        if (require.main === module) process.exit(0);
    } catch (err) {
        console.error('Seeding Failed:', err);
        if (require.main === module) process.exit(1);
        throw err; // Re-throw so controller catches it
    }
}


if (require.main === module) {
    seed();
}

module.exports = seed;
