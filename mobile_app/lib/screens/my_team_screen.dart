import 'package:flutter/material.dart';
import 'package:lpl_auction_app/services/api_service.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:lpl_auction_app/utils/image_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _teamDetails;
  List<dynamic> _squad = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTeamData();
  }

  void _fetchTeamData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teamId = prefs.getInt('teamId');

      if (teamId == null) {
        setState(() {
          _errorMessage = 'Team ID not found. Please relogin.';
          _isLoading = false;
        });
        return;
      }

      // Fetch Team Details (Budget, etc.)
      final teamData = await _apiService.getTeamById(teamId);

      // Fetch All Players and Filter for My Team
      // Note: Ideally, getTeamById should return players, or there should be a dedicated endpoint
      // But for now, we filter client-side as per assumed Plan
      final allPlayers = await _apiService.getPlayers();
      final myPlayers = allPlayers.where((p) {
        if (p['team'] == null) return false;
        // Compare as strings to be safe
        return p['team']['team_id'].toString() == teamId.toString();
      }).toList();

      if (mounted) {
        setState(() {
          _teamDetails = teamData;
          _squad = myPlayers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load team data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Team'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage,
                      style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      _buildHeaderCard(),
                      const SizedBox(height: 24),

                      // Stats Row
                      _buildStatsRow(),
                      const SizedBox(height: 24),

                      // Squad List
                      const Text(
                        'My Squad',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _squad.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text('No players purchased yet.',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _squad.length,
                              itemBuilder: (context, index) {
                                return _buildPlayerItem(_squad[index]);
                              },
                            ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    if (_teamDetails == null) return const SizedBox.shrink();

    final logoUrl = _teamDetails!['logo_url'];
    // Ensure logoUrl is absolute if needed, relying on UI helper or basic check

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: ImageHelper.getTeamLogoProvider(logoUrl),
              child: logoUrl == null
                  ? const Icon(Icons.shield, size: 40, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              _teamDetails!['team_name'] ?? 'Team Name',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Manager: ${_teamDetails!['manager']?['name'] ?? 'N/A'}',
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    if (_teamDetails == null) return const SizedBox.shrink();

    final double totalBudget = _safeParseDouble(_teamDetails!['total_budget']);

    // Calculate spent from squad list for accuracy
    double fundsSpent = 0;
    for (var player in _squad) {
      double price = _safeParseDouble(player['sold_price']);
      if (price == 0) {
        // Fallback if sold_price is missing/zero but player is in squad
        price = _safeParseDouble(player['base_price']);
      }
      fundsSpent += price;
    }

    final double remaining = totalBudget - fundsSpent;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Total', totalBudget, Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Spent', fundsSpent, Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Left', remaining, Colors.green)),
      ],
    );
  }

  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Widget _buildStatCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerItem(dynamic player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: player['image_url'] != null
              ? NetworkImage(player['image_url'])
              : null,
          child: player['image_url'] == null ? const Icon(Icons.person) : null,
        ),
        title: Text(player['name'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(player['role'] ?? ''),
        trailing: Text(
          '\$${player['sold_price'] ?? player['base_price'] ?? 0}',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(2)}M';
    }
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }
}
