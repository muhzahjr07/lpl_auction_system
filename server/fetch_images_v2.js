const fs = require('fs');
const path = require('path');

const csvPath = path.join(__dirname, 'players.csv');
const content = fs.readFileSync(csvPath, 'utf8');
const lines = content.split(/\r?\n/);
const headers = lines[0];

// Helper to delay
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Helper to fetch json
async function fetchJson(url) {
    try {
        const res = await fetch(url);
        if (!res.ok) return null;
        return await res.json();
    } catch (e) {
        return null;
    }
}

async function getWikiImage(playerName) {
    // 1. Try direct search for the title
    let searchUrl = `https://en.wikipedia.org/w/api.php?action=opensearch&search=${encodeURIComponent(playerName)}&limit=1&namespace=0&format=json&origin=*`;
    let searchRes = await fetchJson(searchUrl);

    let title = null;
    if (searchRes && searchRes[1] && searchRes[1].length > 0) {
        title = searchRes[1][0];
    } else {
        // Try with suffix
        let searchUrl2 = `https://en.wikipedia.org/w/api.php?action=opensearch&search=${encodeURIComponent(playerName + " (cricketer)")}&limit=1&namespace=0&format=json&origin=*`;
        let searchRes2 = await fetchJson(searchUrl2);
        if (searchRes2 && searchRes2[1] && searchRes2[1].length > 0) {
            title = searchRes2[1][0];
        }
    }

    if (!title) return null;

    // 2. Get image for title
    let imgUrl = `https://en.wikipedia.org/w/api.php?action=query&titles=${encodeURIComponent(title)}&prop=pageimages&format=json&pithumbsize=600&origin=*`;
    let imgData = await fetchJson(imgUrl);

    if (!imgData || !imgData.query || !imgData.query.pages) return null;

    let pages = imgData.query.pages;
    let pageId = Object.keys(pages)[0];
    if (pageId === '-1') return null;

    let page = pages[pageId];
    if (page.thumbnail && page.thumbnail.source) {
        return page.thumbnail.source;
    }

    return null;
}

async function run() {
    let newContent = [headers];
    const regex = /,(?=(?:(?:[^"]*"){2})*[^"]*$)/;

    console.log("Starting image update...");

    // Parse lines to get index of rows to update
    // We will update in place.

    for (let i = 1; i < lines.length; i++) {
        let line = lines[i];
        if (!line.trim()) continue;

        let parts = line.split(regex);
        let name = parts[1];
        let currentUrl = parts[7];

        // Normalize current Url
        if (currentUrl.startsWith('"')) currentUrl = currentUrl.slice(1, -1);

        // If it's a placeholder, try to fetch
        if (currentUrl.includes('placehold.co') || currentUrl.includes('Photo-Missing') || !currentUrl || currentUrl === 'NULL') {
            process.stdout.write(`Fetching for ${name}... `);
            let newUrl = await getWikiImage(name);
            if (newUrl) {
                console.log(`FOUND: ${newUrl}`);
                parts[7] = newUrl;
            } else {
                console.log(`NOT FOUND`);
                // Keep placeholder
                parts[7] = "https://placehold.co/600x400.png?text=" + encodeURIComponent(name);
            }
            await sleep(200); // Rate limit
        } else {
            console.log(`Skipping ${name} (Already has image)`);
        }

        newContent.push(parts.join(','));
    }

    fs.writeFileSync(csvPath, newContent.join('\n'));
    console.log("Completed. Updated players.csv");
}

run();
