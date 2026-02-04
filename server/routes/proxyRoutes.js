const express = require('express');
const router = express.Router();
const axios = require('axios');

router.get('/', async (req, res) => {
    const { url } = req.query;

    if (!url) {
        return res.status(400).send('URL is required');
    }

    try {
        const response = await axios({
            url,
            method: 'GET',
            responseType: 'stream'
        });

        // Set Access-Control-Allow-Origin to allow the browser to see the image
        res.set('Access-Control-Allow-Origin', '*');
        res.set('Content-Type', response.headers['content-type']);

        response.data.pipe(res);
    } catch (error) {
        console.error('Proxy Error:', error.message);
        res.status(500).send('Error fetching image');
    }
});

module.exports = router;
