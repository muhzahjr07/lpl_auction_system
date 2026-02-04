import 'package:flutter/material.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:lpl_auction_app/services/api_service.dart';
import 'package:lpl_auction_app/services/socket_service.dart';
import 'package:lpl_auction_app/utils/image_helper.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  List<dynamic> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
    _connectSocket();
  }

  void _connectSocket() {
    _socketService.connect();
    _socketService
        .joinAuction("auction_room"); // Ensure we join to hear broadcasts
    _socketService.socket.on('sold_confirmed', (data) {
      if (mounted) {
        _fetchTeams();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update: Player sold to ${data['teamName']}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _fetchTeams() async {
    try {
      final teams = await _apiService.getTeams();
      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _teams.length,
              itemBuilder: (context, index) {
                final team = _teams[index];
                return _buildTeamCard(team);
              },
            ),
    );
  }

  Widget _buildTeamCard(dynamic team) {
    // Calculate stats safely
    final double budget =
        double.tryParse(team['budget']?.toString() ?? '0') ?? 0;
    final double purseSpent =
        double.tryParse(team['funds_spent']?.toString() ?? '0') ?? 0;
    final double remaining = budget - purseSpent;
    // Assuming backend might send players count, or we might need to fetch it separately.
    // If not available, we can show a placeholder or update backend to send it.
    // For now, let's assume 'players_count' might be there or default to 0.
    final int playersCount = team['players_count'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      ImageHelper.getTeamLogoProvider(team['logo_url']),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: team['logo_url'] == null
                      ? const Icon(Icons.shield, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team['team_name'] ?? 'Unknown Team',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                              'Manager: ${team['manager'] != null ? team['manager']['name'] : 'N/A'}',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTeamStat(
                    'Players', '$playersCount', Icons.groups, Colors.blue),
                _buildTeamStat('Spent', _formatCurrency(purseSpent),
                    Icons.trending_up, Colors.orange),
                _buildTeamStat('Remaining', _formatCurrency(remaining),
                    Icons.account_balance_wallet, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    }
    return '\$${(amount / 1000).toStringAsFixed(0)}k';
  }
}
