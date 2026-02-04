const fs = require('fs');
const path = require('path');

const csvPath = path.join(__dirname, 'players.csv');
const content = fs.readFileSync(csvPath, 'utf8');
const lines = content.split(/\r?\n/);
const headers = lines[0]; // player_id,name,...

const badDomains = [
    'resources.pulse.icc-cricket.com',
    'img1.hscicdn.com',
    'srilankacricket.lk', // Reported as status 0
    'e0.365dm.com',
    'sacricketmag.com',
    'newswire.lk',
    'amu.tv',
    'i.dawn.com',
    'encrypted-tbn0.gstatic.com', // Often works but maybe not reliable hotlinking? User didn't explicitly list ALL of them but listed a lot. 
    // Wait, user DID list encrypted-tbn0.gstatic.com? No, looking at logs:
    // User listed: srilankacricket.lk, resources.pulse..., img1.hscicdn.com, e0.365dm.com, w.sacricketmag.com, newswire.lk, amu.tv, i.dawn.com
    // NOT listed: encrypted-tbn0.gstatic.com (Wait, lines 8, 9, 11 etc use encrypted-tbn0).
    // Let's look closer at the user log.
    // "Image provider: NetworkImage(...srilankacricket.lk...)"
    // "HTTP request failed... pulse.icc-cricket.com"
    // "HTTP request failed... img1.hscicdn.com"
    // "HTTP request failed... e0.365dm.com"
    // "HTTP request failed... srilankacricket.lk"
    // "HTTP request failed... sucricketmag.com"
    // "HTTP request failed... newswire.lk"
    // "HTTP request failed... amu.tv"
    // "HTTP request failed... i.dawn.com"
];

// I don't see encrypted-tbn0 in the FAILURE list. So I will keep them.
// I WILL replace the defined bad domains.

const placeholder = "https://placehold.co/600x400.png?text=No+Image";

let newContent = [headers];

// Regex to handle CSV parsing with quotes
const regex = /,(?=(?:(?:[^"]*"){2})*[^"]*$)/;

for (let i = 1; i < lines.length; i++) {
    let line = lines[i]; // Don't trim yet, might break csv structure if empty fields
    if (!line.trim()) continue;

    let parts = line.split(regex);

    if (parts.length >= 8) {
        // Clean each part
        parts = parts.map(p => {
            let s = p.trim();
            if (s.startsWith('"') && s.endsWith('"')) {
                s = s.slice(1, -1).trim();
            }
            return s;
        });

        let imageUrl = parts[7];

        // Check format
        if (imageUrl && imageUrl !== 'NULL' && imageUrl !== 'null') {
            // Fix leading space was already handled by trim() above

            // Check domain
            let isBad = false;
            try {
                // Handle cases where url might still be " https://..." if my trim logic failed (it shouldn't)
                if (imageUrl.includes(' ')) {
                    // Double check
                    imageUrl = imageUrl.trim();
                }

                const urlObj = new URL(imageUrl);
                if (badDomains.some(d => urlObj.hostname.includes(d))) {
                    isBad = true;
                }
            } catch (e) {
                // Invalid URL
                console.log(`Invalid URL found: ${imageUrl}`);
                isBad = true;
            }

            if (isBad) {
                console.log(`Replacing bad URL for ${parts[1]}: ${imageUrl}`);
                parts[7] = placeholder;
            } else {
                parts[7] = imageUrl; // Keep it (cleaned)
            }
        } else {
            // Use placeholder for NULLs too if we want, or keep NULL.
            // User wants images for everyone.
            // If it was NULL, let's put placeholder.
            parts[7] = placeholder;
        }

        // Reconstruct line
        // We only quote if necessary? Or just verify logic.
        // Simple join should work since we stripped quotes.
        // But if name has comma (none do), we'd need quotes.
        // Current names are simple.
        newContent.push(parts.join(','));
    } else {
        newContent.push(line);
    }
}

fs.writeFileSync(csvPath, newContent.join('\n'));
console.log("CSV Fixed.");
