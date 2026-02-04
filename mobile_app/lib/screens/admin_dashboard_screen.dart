import 'package:flutter/material.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:lpl_auction_app/widgets/stats_card.dart';
import 'package:lpl_auction_app/services/api_service.dart';
import 'package:lpl_auction_app/services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lpl_auction_app/widgets/user_profile_button.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  Map<String, dynamic> _stats = {
    'totalPlayers': '-',
    'activeTeams': '-',
    'totalPurse': '-',
    'pendingEvents': '-'
  };
  bool _isLoading = true;
  bool _isBiddingLive = false;
  String? _activePlayerName;
  String? _currentPrice;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _fetchStats();
    _fetchAuctionStatus();
  }

  void _connectSocket() {
    _socketService.connect();
    _socketService.joinAuction("auction_room");

    _socketService.socket.on('new_round_started', (data) {
      if (mounted) {
        _fetchAuctionStatus(); // Refresh status on new round
      }
    });

    _socketService.socket.on('player_added', (_) {
      debugPrint('SOCKET: player_added received');
      if (mounted) _fetchStats();
    });
    _socketService.socket.on('player_updated', (_) {
      debugPrint('SOCKET: player_updated received');
      if (mounted) _fetchStats();
    });
    _socketService.socket.on('player_deleted', (_) {
      if (mounted) _fetchStats();
    });

    _socketService.socket.on('new_bid', (data) {
      if (mounted) {
        setState(() {
          _isBiddingLive = true; // Ensure live state
          _currentPrice = '\$${data['amount']}';
        });
      }
    });

    _socketService.socket.on('sold_confirmed', (data) {
      if (mounted) {
        setState(() {
          _isBiddingLive = false;
          _activePlayerName = null;
          _currentPrice = null;
        });
        _fetchStats(); // Update stats (purse etc)
      }
    });

    _socketService.socket.on('auction_reset', (_) {
      if (mounted) {
        setState(() {
          _isBiddingLive = false;
          _activePlayerName = null;
          _currentPrice = null;
        });
      }
    });
  }

  void _fetchAuctionStatus() async {
    try {
      final state = await _apiService.getAuctionState();
      if (mounted) {
        if (state['activePlayerId'] != null) {
          final player =
              await _apiService.getPlayerById(state['activePlayerId']);
          setState(() {
            _isBiddingLive = true;
            _activePlayerName = player['name'];
            _currentPrice =
                '\$${state['currentPrice'] ?? player['base_price']}';
          });
        } else {
          setState(() {
            _isBiddingLive = false;
            _activePlayerName = null;
            _currentPrice = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching auction status: $e');
    }
  }

  void _fetchStats() async {
    try {
      final stats = await _apiService.getAdminStats();
      if (mounted) {
        setState(() {
          _stats = {
            'totalPlayers': stats['totalPlayers'].toString(),
            'activeTeams': stats['activeTeams'].toString(),
            'totalPurse':
                '\$${(stats['totalPurse'] / 1000000).toStringAsFixed(1)}M',
            'pendingEvents': stats['pendingEvents']
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    // Socket persists across screens
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('System Admin'),
              accountEmail: Text('admin@lpl.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: AppColors.primary),
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
            ListTile(
              leading: const Icon(Icons.gavel),
              title: const Text('Auctioneer View'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/auctioneer_view');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                // Clear prefs and navigate to login
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
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: UserProfileButton(
              userName: 'System Admin',
              userRole: 'Administrator',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dashboard Overview',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      StatsCard(
                        title: 'Total Players',
                        value: _stats['totalPlayers'],
                        icon: Icons.groups,
                        iconColor: AppColors.primary,
                        iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                        subtitle: 'Registered',
                        onTap: () =>
                            Navigator.pushNamed(context, '/admin/players'),
                      ),
                      StatsCard(
                          title: 'Active Teams',
                          value: _stats['activeTeams'],
                          icon: Icons.shield,
                          iconColor: AppColors.primary,
                          iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                          onTap: () =>
                              Navigator.pushNamed(context, '/admin/teams')),
                      StatsCard(
                          title: 'Total Purse',
                          value: _stats['totalPurse'],
                          icon: Icons.payments,
                          iconColor: Colors.orange,
                          iconBgColor: const Color(0xFFFFF3E0),
                          onTap: () =>
                              Navigator.pushNamed(context, '/reports')),
                      // Dynamic Status Card
                      _isBiddingLive
                          ? StatsCard(
                              title: _activePlayerName ?? 'Unknown',
                              value: _currentPrice ?? 'LIVE NOW',
                              icon: Icons.cell_tower,
                              iconColor: Colors.green,
                              iconBgColor: Colors.green.withValues(alpha: 0.1),
                              subtitle: 'Bidding Active',
                              onTap: () => Navigator.pushNamed(
                                  context, '/auctioneer_view'),
                            )
                          : StatsCard(
                              title: 'Auction Status',
                              value: 'Suspended',
                              icon: Icons.power_settings_new,
                              iconColor: Colors.red,
                              iconBgColor: Colors.red.withValues(alpha: 0.1),
                              onTap: () => Navigator.pushNamed(
                                  context, '/auctioneer_view'),
                            ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Management',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildManagementTile(
                      context,
                      'User Management',
                      'Admins, Auctioneers',
                      Icons.manage_accounts,
                      AppColors.primary,
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin/users')),
                  _buildManagementTile(
                      context,
                      'Player Management',
                      'Registrations, Base Prices',
                      Icons.sports_cricket,
                      Colors.purple,
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin/players')),
                  _buildManagementTile(context, 'Team Management',
                      'Budgets, Owners', Icons.local_police, Colors.orange,
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin/teams')),
                  _buildManagementTile(context, 'Reports', 'Auction Stats',
                      Icons.bar_chart, Colors.teal,
                      onTap: () => Navigator.pushNamed(context, '/reports')),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Players'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 40, color: AppColors.primary),
              label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Teams'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/admin/players');
          if (index == 2) {
            _showAddOptionsDialog(context);
          }
          if (index == 3) Navigator.pushNamed(context, '/admin/teams');
          if (index == 4) Navigator.pushNamed(context, '/settings');
        },
      ),
    );
  }

  Widget _buildManagementTile(BuildContext context, String title,
      String subtitle, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showAddOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.blue),
              title: const Text('Add User'),
              subtitle: const Text('New Admin or Manager'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/users',
                    arguments: {'showAddDialog': true});
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.sports_cricket, color: Colors.green),
              title: const Text('Add Player'),
              subtitle: const Text('New Player for Auction'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/players',
                    arguments: {'showAddDialog': true});
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
