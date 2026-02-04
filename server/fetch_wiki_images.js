const fs = require('fs');

const players = [
    "Litton Das", "Afif Hossain", "Shoriful Islam", "Taskin Ahmed", "Towhid Hridoy",
    "Kamindu Mendis", "Nuwanidu Fernando", "Sahan Arachchige", "Ashen Bandara", "Janith Liyanage",
    "Dushan Hemantha", "Lasith Croospulle", "Shevon Daniel", "Vijayakanth Viyaskanth",
    "Nuwan Pradeep", "Kasun Rajitha", "Asitha Fernando", "Vishwa Fernando",
    "Praveen Jayawickrama", "Lakshan Sandakan", "Seekkuge Prasanna", "Chaturanga de Silva",
    "Minod Bhanuka", "Lahiru Udara", "Niroshan Dickwella", "Oshada Fernando",
    "Pulina Tharanga", "Movin Subasingha", "Ravindu Fernando", "Nipun Malinga"
];

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function fetchImage(name) {
    try {
        const url = `https://en.wikipedia.org/w/api.php?action=query&titles=${encodeURIComponent(name)}&prop=pageimages&format=json&pithumbsize=600&redirects=1&origin=*`;
        const res = await fetch(url);
        const data = await res.json();
        
        const pages = data.query.pages;
        const pageId = Object.keys(pages)[0];
        
        if (pageId === "-1") {
            console.log(`No Wikipedia page found for: ${name}`);
            return null;
        }
        
        const page = pages[pageId];
        if (page.thumbnail && page.thumbnail.source) {
            return page.thumbnail.source;
        } else {
            console.log(`No image found on Wikipedia for: ${name}`);
            return null;
        }
    } catch (e) {
        console.error(`Error fetching for ${name}:`, e.message);
        return null;
    }
}

async function run() {
    const results = {};
    
    console.log("Starting fetch...");
    for (const player of players) {
        process.stdout.write(`Fetching ${player}... `);
        const url = await fetchImage(player);
        if (url) {
            results[player] = url;
            console.log("FOUND");
        } else {
            // Try fetching with "Cricketer" suffix if failed
            const url2 = await fetchImage(player + " (cricketer)");
            if (url2) {
                results[player] = url2;
                console.log("FOUND (with disambiguation)");
            } else {
                console.log("NOT FOUND");
                results[player] = null;
            }
        }
        await sleep(500); // polite rate limit
    }
    
    fs.writeFileSync('wiki_images.json', JSON.stringify(results, null, 2));
    console.log("Done. Saved to wiki_images.json");
}

run();
