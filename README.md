# LPL Auction System

A real-time auction system for the Lanka Premier League (LPL), designed to facilitate player auctions with a seamless experience for auctioneers and team owners. This project consists of a Node.js/Express backend and a Flutter mobile application.

## 🚀 Features

- **Real-time Bidding:** Live updates for bids using Socket.io.
- **Auctioneer Control:** dedicated interface for managing the auction flow (start round, sell player, etc.).
- **Team Management:** Dashboard for teams to view their squad and remaining budget.
- **Player Stats:** Comprehensive player profiles with role-based statistics.
- **Admin Dashboard:** Overview of the entire auction process.

## 📸 App Screenshots

|   |   |   |
|:---:|:---:|:---:|
| <img src="mobile_app/assets/appscreens/screen%20(2).png" width="250"> | <img src="mobile_app/assets/appscreens/screen%20(3).png" width="250"> | <img src="mobile_app/assets/appscreens/screen%20(5).png" width="250"> |
| <img src="mobile_app/assets/appscreens/screen%20(6).png" width="250"> | <img src="mobile_app/assets/appscreens/screen%20(1).png" width="250"> | <img src="mobile_app/assets/appscreens/screen%20(4).png" width="250"> |

## 🛠️ Tech Stack

- **Backend:** Node.js, Express, MySQL (Sequelize ORM), Socket.io
- **Frontend (Mobile):** Flutter, Provider (State Management)
- **Database:** MySQL

## 📋 Prerequisites

- [Node.js](https://nodejs.org/) (v16 or higher)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [MySQL](https://www.mysql.com/) database server
- [ngrok](https://ngrok.com/) (optional, for exposing local server)

## ⚙️ Setup & Installation

### Backend (Server)

1.  Navigate to the server directory:
    ```bash
    cd server
    ```
2.  Install dependencies:
    ```bash
    npm install
    ```
3.  Configure your database connection in `.env` (create if not exists, based on `.env.example`).
4.  Seed the database:
    ```bash
    node seed.js
    ```
5.  Start the server:
    ```bash
    node index.js
    ```
    The server will run on `http://localhost:5000` by default.

### Mobile App

1.  Navigate to the mobile app directory:
    ```bash
    cd mobile_app
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app:
    ```bash
    flutter run
    ```
    To run on a specific device (e.g., Windows, Edge):
    ```bash
    flutter run -d edge
    # or
    flutter run -d windows
    ```

## 🌐 Networking

If you are running the app on a physical device or a different network, you might need to expose your local server using ngrok:

```bash
ngrok http 5000
```
Update the API base URL in the mobile app configuration to match the ngrok URL.

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
