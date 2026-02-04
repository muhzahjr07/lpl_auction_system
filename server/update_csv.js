const fs = require('fs');
const path = require('path');

const csvPath = path.join(__dirname, 'players.csv');
const wikiImagesPath = path.join(__dirname, 'wiki_images.json');

const wikiImages = JSON.parse(fs.readFileSync(wikiImagesPath, 'utf8'));
const placeholder = "https://resources.pulse.icc-cricket.com/players/210/Photo-Missing.png";

let csvContent = fs.readFileSync(csvPath, 'utf8');
let lines = csvContent.split(/\r?\n/);
let headers = lines[0];

let newLines = [headers];

for (let i = 1; i < lines.length; i++) {
    let line = lines[i].trim();
    if (!line) continue;

    // Simple CSV parser for this specific file format
    // Assuming no commas inside fields EXCEPT possibly image_url wrapped in quotes
    // But actually, seeing the file, names don't have commas.
    // We can split by comma BUT handle quotes if necessary.
    // However, the current CSV has quotes around URLs sometimes.

    // Regex to split by comma but ignore commas in quotes
    const regex = /,(?=(?:(?:[^"]*"){2})*[^"]*$)/;
    let parts = line.split(regex);

    // player_id,name,role,country,base_price,status,sold_price,image_url,createdAt,updatedAt,team_id
    // Index 7 is image_url

    if (parts.length >= 8) {
        let name = parts[1];
        let currentUrl = parts[7];

        // Remove quotes if present
        if (currentUrl.startsWith('"') && currentUrl.endsWith('"')) {
            currentUrl = currentUrl.slice(1, -1);
        }

        if (currentUrl === 'NULL' || currentUrl === '' || currentUrl === 'null' || !currentUrl) {
            // Needs update
            if (wikiImages[name]) {
                parts[7] = wikiImages[name];
            } else {
                // Check if we have wiki image even if not in loop
                // (Already covered by wikiImages map)
                parts[7] = placeholder;
            }
        }
    }

    newLines.push(parts.join(','));
}

fs.writeFileSync(csvPath, newLines.join('\n'));
console.log('Updated players.csv with images and placeholders.');
