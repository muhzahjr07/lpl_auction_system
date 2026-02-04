const fs = require('fs');
const path = require('path');

const csvPath = path.join(__dirname, 'players.csv');
const csvContent = fs.readFileSync(csvPath, 'utf8');
const lines = csvContent.split(/\r?\n/);

const header = lines[0];
// Check if already updated
if (header.includes('total_runs')) {
    console.log('CSV already has stats columns.');
    process.exit(0);
}

// Map old header to new header
// Old: player_id,name,role,country,base_price,status,sold_price,image_url,createdAt,updatedAt,team_id
// We will replace everything after image_url with our new stats columns for clarity, or just append.
// The file viewed earlier had extra columns created by DB export probably.
// Let's stick to the core columns for the new CSV:
// player_id,name,role,country,base_price,status,sold_price,image_url,total_runs,strike_rate,wickets,economy_rate

const newHeader = "player_id,name,role,country,base_price,status,sold_price,image_url,total_runs,strike_rate,wickets,economy_rate";
const newLines = [newHeader];

const regex = /,(?=(?:(?:[^"]*"){2})*[^"]*$)/;

for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    const parts = line.split(regex);
    if (parts.length < 8) continue; // Skip invalid lines

    // Extract existing data
    const id = parts[0];
    const name = parts[1];
    const role = parts[2].replace(/^"|"$/g, '');
    const country = parts[3];
    const basePrice = parts[4];
    const status = parts[5];
    const soldPrice = parts[6];
    const imageUrl = parts[7];

    // Generate Stats based on Role
    let runs = 0;
    let sr = 0.0;
    let wickets = 0;
    let econ = 0.0;

    // Helper for random Int
    const rnd = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
    // Helper for random Float
    const rndF = (min, max) => (Math.random() * (max - min) + min).toFixed(2);

    if (role === 'BATSMAN') {
        runs = rnd(2000, 10000);
        sr = rndF(120, 155);
        wickets = rnd(0, 10);
        econ = rndF(7, 10); // Part timers
    } else if (role === 'BOWLER') {
        runs = rnd(50, 600);
        sr = rndF(80, 120);
        wickets = rnd(150, 400);
        econ = rndF(6, 8.5);
    } else if (role === 'ALL_ROUNDER') {
        runs = rnd(1000, 5000);
        sr = rndF(130, 150);
        wickets = rnd(50, 200);
        econ = rndF(7, 9);
    } else if (role === 'WICKET_KEEPER') {
        runs = rnd(1500, 8000);
        sr = rndF(125, 145);
        wickets = 0;
        econ = 0.0;
    }

    // Construct new line
    // Ensure properly quoted if needed (csv logic), but for simple numbers/std strings it's fine.
    // imageUrl might contain commas, it was handled by regex split but we need to put it back carefully if we stripped quotes.
    // The previous parts[7] was raw from split.

    // Simplification: Reconstruct CSV line standardly
    const newLine = `${id},${name},"${role}",${country},${basePrice},${status},${soldPrice},${imageUrl},${runs},${sr},${wickets},${econ}`;
    newLines.push(newLine);
}

fs.writeFileSync(csvPath, newLines.join('\n'), 'utf8');
console.log('players.csv updated with stats!');
