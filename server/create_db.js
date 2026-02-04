const mysql = require('mysql2/promise');
require('dotenv').config();

async function createDb() {
    try {
        const connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD
        });
        await connection.query(`CREATE DATABASE IF NOT EXISTS \`${process.env.DB_NAME}\`;`);
        console.log(`Database ${process.env.DB_NAME} checked/created successfully.`);
        await connection.end();
        process.exit(0);
    } catch (err) {
        console.error('Error creating database:', err);
        process.exit(1);
    }
}

createDb();
