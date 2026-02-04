import 'package:flutter/material.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:lpl_auction_app/widgets/stats_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lpl_auction_app/widgets/user_profile_button.dart';
import 'package:lpl_auction_app/screens/player_management_screen.dart';
import 'package:lpl_auction_app/services/api_service.dart';
import 'package:lpl_auction_app/services/socket_service.dart';

class TeamManagerDashboardScreen extends StatefulWidget {
  const TeamManagerDashboardScreen({super.key});

  @override
  State<TeamManagerDashboardScreen> createState() =>
      _TeamManagerDashboardScreenState();
}

class _TeamManagerDashboardScreenState
    extends State<TeamManagerDashboardScreen> {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  String _teamName = 'Team Manager';
  String? _teamLogo;
  String _userEmail = 'manager@lpl.com';
  Map<String, dynamic>? _auctionState;
  String? _activePlayerName;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _loadTeamDetails();
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

  void _loadTeamDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teamName = prefs.getString('teamName') ?? 'Team Manager';
      _teamLogo = prefs.getString('teamLogo');
      _userEmail = prefs.getString('email') ?? 'manager@lpl.com';
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
            UserAccountsDrawerHeader(
              accountName: Text(_teamName),
              accountEmail: Text(_userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    _teamLogo != null ? NetworkImage(_teamLogo!) : null,
                child: _teamLogo == null
                    ? const Icon(Icons.shield,
                        size: 40, color: AppColors.primary)
                    : null,
              ),
              decoration: const BoxDecoration(color: AppColors.primary),
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              backgroundImage:
                  _teamLogo != null ? NetworkImage(_teamLogo!) : null,
              child: _teamLogo == null
                  ? const Icon(Icons.shield, size: 16, color: AppColors.primary)
                  : null,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_teamName),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: UserProfileButton(
              userName: _teamName,
              userRole: 'Manager',
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
            // Main Action Card - Join Bidding
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/team_home')
                  .then((_) => _fetchAuctionState()),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLive
                        ? [Colors.green.shade700, Colors.greenAccent]
                        : [Colors.purple.shade700, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: isLive
                            ? Colors.green.withValues(alpha: 0.4)
                            : Colors.purple.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(isLive ? Icons.leak_add : Icons.monetization_on,
                        size: 48, color: Colors.white),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(isLive ? 'LIVE BIDDING' : 'ENTER AUCTION',
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
                            const Text('Join the live auction room',
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
                  title: 'Opponents',
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
                  title: 'My Team',
                  value: 'Details',
                  icon: Icons.person,
                  iconColor: Colors.teal,
                  iconBgColor: Colors.teal.withValues(alpha: 0.1),
                  // For now redirecting to teams list, ideally could be a my-team specific page
                  onTap: () => Navigator.pushNamed(context, '/my_team'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
