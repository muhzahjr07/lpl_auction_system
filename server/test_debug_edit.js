const API_URL = 'http://localhost:5000/api';

async function testEdit() {
    try {
        // 1. Login
        console.log('Logging in...');
        const loginRes = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: 'admin@lpl.com', password: 'password123' })
        });

        if (!loginRes.ok) throw new Error(`Login failed: ${loginRes.status}`);
        const loginData = await loginRes.json();
        const token = loginData.token;
        console.log('Logged in.');

        // 2. Scan players
        console.log('Fetching players...');
        const playersRes = await fetch(`${API_URL}/players`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const players = await playersRes.json();

        if (players.length === 0) {
            console.log('No players found.');
            return;
        }

        const player = players[0];
        console.log(`Editing player: ${player.name} (ID: ${player.player_id})`);

        // 3. Update
        const updateData = {
            name: player.name + ' (Edited)',
            role: 'BATSMAN',
            base_price: 200.0,
            country: 'Sri Lanka',
            image_url: player.image_url
        };

        console.log('Payload:', JSON.stringify(updateData));

        const updateRes = await fetch(`${API_URL}/players/${player.player_id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(updateData)
        });

        if (!updateRes.ok) {
            const errText = await updateRes.text();
            throw new Error(`Update Failed: ${updateRes.status} - ${errText}`);
        }

        const updatedPlayer = await updateRes.json();
        console.log('Update Success:', updatedPlayer);

    } catch (e) {
        console.error(e);
    }
}

testEdit();
