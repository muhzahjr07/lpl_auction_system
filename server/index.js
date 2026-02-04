const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const dotenv = require('dotenv');
const sequelize = require('./config/database');

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*", // Allow all for mobile app dev
        methods: ["GET", "POST"]
    }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use((req, res, next) => {
    req.io = io;
    next();
});
const path = require('path');
app.use('/assets', express.static(path.join(__dirname, 'assets'), {
    setHeaders: (res, path, stat) => {
        res.set('Access-Control-Allow-Origin', '*');
    }
}));

// Routes
const authRoutes = require('./routes/authRoutes');
const playerRoutes = require('./routes/playerRoutes');
const teamRoutes = require('./routes/teamRoutes');
const auctionRoutes = require('./routes/auctionRoutes');
const adminRoutes = require('./routes/adminRoutes'); // New
const userRoutes = require('./routes/userRoutes');
const auctionSocketHandler = require('./sockets/auctionHandler');

app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/players', playerRoutes);
app.use('/api/teams', teamRoutes);
app.use('/api/auction', auctionRoutes);

// Socket.IO Logic
io.on('connection', (socket) => {
    console.log('New client connected:', socket.id);

    // Attach handlers
    auctionSocketHandler(io, socket);

    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
    });
});

const PORT = process.env.PORT || 5000;

// Test DB and Start Server
sequelize.sync({ alter: true }) // Auto-update schema
    .then(() => {
        console.log('Database connected!');
        server.listen(PORT, '0.0.0.0', () => {
            console.log(`Server running on port ${PORT}`);
        });
    })
    .catch(err => console.log('Error syncing database:', err));
