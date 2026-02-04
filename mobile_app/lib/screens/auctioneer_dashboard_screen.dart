import 'package:flutter/material.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:lpl_auction_app/widgets/stats_card.dart';
import 'package:lpl_auction_app/widgets/user_profile_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lpl_auction_app/screens/player_management_screen.dart';

import 'package:lpl_auction_app/services/api_service.dart';
import 'package:lpl_auction_app/services/socket_service.dart';

class AuctioneerDashboardScreen extends StatefulWidget {
  const AuctioneerDashboardScreen({super.key});

  @override
  State<AuctioneerDashboardScreen> createState() =>
      _AuctioneerDashboardScreenState();
}

class _AuctioneerDashboardScreenState extends State<AuctioneerDashboardScreen> {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  Map<String, dynamic>? _auctionState;
  String? _activePlayerName;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _fetchAuctionState();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  void _connectSocket() {
    _socketService.connect();
    _socketService.joinAuction('auction_room');

    _socketService.on('new_bid', (data) {
      if (mounted) _fetchAuctionState();
    });

    _socketService.on('new_round_started', (data) {
      if (mounted) _fetchAuctionState();
    });

    _socketService.on('start_auction_round', (data) {
      if (mounted) _fetchAuctionState();
    });

    _socketService.on('sold_confirmed', (data) {
      if (mounted) _fetchAuctionState();
    });

    _socketService.on('unsold_confirmed', (data) {
      if (mounted) _fetchAuctionState();
    });

    _socketService.on('auction_reset', (data) {
      if (mounted) _fetchAuctionState();
    });
  }

  void _fetchAuctionState() async {
    try {
      final state = await _apiService.getAuctionState();
      String? playerName;

      if (state['activePlayerId'] != null) {
        try {
          final player =
              await _apiService.getPlayerById(state['activePlayerId']);
          playerName = player['name'];
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _auctionState = state;
          _activePlayerName = playerName;
        });
      }
    } catch (e) {
      // Handle error cleanly
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLive =
        _auctionState != null && _auctionState!['activePlayerId'] != null;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('Auctioneer'),
              accountEmail: Text('auctioneer@lpl.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.gavel, size: 40, color: AppColors.primary),
              ),
              decoration: BoxDecoration(color: AppColors.primary),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/reports');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false);
                }
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Auctioneer Dashboard'),
        centerTitle: true,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: UserProfileButton(
              userName: 'Auctioneer',
              userRole: 'Official',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Main Action Card - Live Bidding
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/auctioneer_home')
                  .then((_) => _fetchAuctionState()), // Refresh on return
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLive
                        ? [Colors.green.shade700, Colors.greenAccent]
                        : [Colors.redAccent.shade700, Colors.redAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: isLive
                            ? Colors.green.withValues(alpha: 0.4)
                            : Colors.redAccent.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(isLive ? Icons.leak_add : Icons.gavel,
                        size: 48, color: Colors.white),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(isLive ? 'LIVE BIDDING' : 'AUCTION ROOM',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              if (isLive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              ]
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (isLive) ...[
                            Text('Player: $_activePlayerName',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            Text(
                                'Current Bid: \$${_auctionState!['currentPrice']}',
                                style: const TextStyle(color: Colors.white70)),
                          ] else
                            const Text('No active round. Enter to start.',
                                style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatsCard(
                  title: 'Players',
                  value: 'View List',
                  icon: Icons.groups,
                  iconColor: Colors.blue,
                  iconBgColor: Colors.blue.withValues(alpha: 0.1),
                  subtitle: 'Read Only',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PlayerManagementScreen(isReadOnly: true),
                      ),
                    );
                  },
                ),
                StatsCard(
                  title: 'Teams',
                  value: 'View Teams',
                  icon: Icons.shield,
                  iconColor: Colors.green,
                  iconBgColor: Colors.green.withValues(alpha: 0.1),
                  onTap: () => Navigator.pushNamed(context, '/admin/teams'),
                ),
                StatsCard(
                  title: 'Reports',
                  value: 'Statistics',
                  icon: Icons.bar_chart,
                  iconColor: Colors.orange,
                  iconBgColor: Colors.orange.withValues(alpha: 0.1),
                  onTap: () => Navigator.pushNamed(context, '/reports'),
                ),
                StatsCard(
                  title: 'Settings',
                  value: 'Configure',
                  icon: Icons.settings,
                  iconColor: Colors.grey,
                  iconBgColor: Colors.grey.withValues(alpha: 0.1),
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
