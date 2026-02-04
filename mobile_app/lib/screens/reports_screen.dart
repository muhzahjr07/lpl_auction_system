import 'package:flutter/material.dart';
import 'package:lpl_auction_app/services/api_service.dart';
import 'package:lpl_auction_app/services/socket_service.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:lpl_auction_app/widgets/stats_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  List<dynamic> _players = [];
  List<dynamic> _allPlayers = [];
  bool _isLoading = true;
  double _totalSpent = 0;
  String _currentSortOption = 'Name (A-Z)';
  String? _selectedRole;
  String? _selectedTeam;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _socketService.connect();
    _socketService.socket.on('sold_confirmed', _onSoldConfirmed);
  }

  void _onSoldConfirmed(dynamic data) {
    _fetchData(); // Simplest way to ensure consistent state
  }

  @override
  void dispose() {
    _socketService.socket.off('sold_confirmed', _onSoldConfirmed);
    super.dispose();
  }

  void _fetchData() async {
    try {
      final players = await _apiService.getPlayers();
      final soldPlayers = players.where((p) => p['status'] == 'SOLD').toList();

      double total = 0;
      for (var p in soldPlayers) {
        total += double.tryParse(p['sold_price']?.toString() ?? '0') ?? 0;
      }

      if (mounted) {
        setState(() {
          _allPlayers = soldPlayers;
          _players = List.from(soldPlayers);
          _totalSpent = total;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Reports'),
        centerTitle: false,
        actions: [
          IconButton(
              onPressed: _showSortOptions, icon: const Icon(Icons.filter_list)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Auction Summary',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('LPL 2025',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      StatsCard(
                        title: 'Total Spent',
                        value:
                            '\$${(_totalSpent / 1000000).toStringAsFixed(1)}M',
                        icon: Icons.payments,
                        iconColor: AppColors.primary,
                        iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                        subtitle: '+12% vs LY',
                      ),
                      StatsCard(
                        title: 'Players Sold',
                        value: '${_players.length}',
                        icon: Icons.groups,
                        iconColor: Colors.blue,
                        iconBgColor: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Recent Transactions Table
                  Text('Recent Buys',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: _players.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: Text("No sales yet.")))
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _players.length,
                            separatorBuilder: (c, i) => Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor),
                            itemBuilder: (context, index) {
                              final player = _players[index];
                              return ListTile(
                                title: Text(player['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(player['role'] ?? 'Player'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('\$${player['sold_price'] ?? 0}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        player['team'] != null
                                            ? player['team']['team_name']
                                            : 'SOLD',
                                        style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10)),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  void _applyFilters() {
    setState(() {
      _players = _allPlayers.where((p) {
        if (_selectedRole != null && p['role'] != _selectedRole) return false;
        if (_selectedTeam != null && p['team']['team_name'] != _selectedTeam) {
          return false;
        }
        return true;
      }).toList();
      _sortPlayers();
    });
  }

  void _sortPlayers() {
    setState(() {
      switch (_currentSortOption) {
        case 'Name (A-Z)':
          _players.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
          break;
        case 'Name (Z-A)':
          _players.sort((a, b) => (b['name'] ?? '').compareTo(a['name'] ?? ''));
          break;
        case 'Price (High-Low)':
          _players.sort((a, b) {
            double priceA =
                double.tryParse(a['sold_price']?.toString() ?? '0') ?? 0;
            double priceB =
                double.tryParse(b['sold_price']?.toString() ?? '0') ?? 0;
            return priceB.compareTo(priceA);
          });
          break;
        case 'Price (Low-High)':
          _players.sort((a, b) {
            double priceA =
                double.tryParse(a['sold_price']?.toString() ?? '0') ?? 0;
            double priceB =
                double.tryParse(b['sold_price']?.toString() ?? '0') ?? 0;
            return priceA.compareTo(priceB);
          });
          break;
        case 'Role':
          _players.sort((a, b) => (a['role'] ?? '').compareTo(b['role'] ?? ''));
          break;
        case 'Team':
          _players.sort((a, b) {
            String teamA = a['team'] != null ? a['team']['team_name'] : '';
            String teamB = b['team'] != null ? b['team']['team_name'] : '';
            return teamA.compareTo(teamB);
          });
          break;
      }
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sort & Filter',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              // Filter Buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    ActionChip(
                      label: Text(_selectedRole ?? 'Filter Role'),
                      avatar: _selectedRole != null
                          ? const Icon(Icons.close, size: 16)
                          : const Icon(Icons.arrow_drop_down),
                      onPressed: () {
                        if (_selectedRole != null) {
                          setState(() {
                            _selectedRole = null;
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        } else {
                          Navigator.pop(context);
                          _showFilterDialog('Role');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: Text(_selectedTeam ?? 'Filter Team'),
                      avatar: _selectedTeam != null
                          ? const Icon(Icons.close, size: 16)
                          : const Icon(Icons.arrow_drop_down),
                      onPressed: () {
                        if (_selectedTeam != null) {
                          setState(() {
                            _selectedTeam = null;
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        } else {
                          Navigator.pop(context);
                          _showFilterDialog('Team');
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
              const Divider(),
              _buildSortOption('Name (A-Z)'),
              _buildSortOption('Name (Z-A)'),
              _buildSortOption('Price (High-Low)'),
              _buildSortOption('Price (Low-High)'),
              _buildSortOption('Role'),
              _buildSortOption('Team'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String option) {
    bool isSelected = _currentSortOption == option;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color:
            isSelected ? AppColors.primary : Theme.of(context).iconTheme.color,
      ),
      title: Text(
        option,
        style: TextStyle(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() {
          _currentSortOption = option;
          _sortPlayers();
        });
        Navigator.pop(context);
      },
    );
  }

  void _showFilterDialog(String type) {
    // Collect unique values
    final Set<String> values = {};
    for (var p in _allPlayers) {
      if (type == 'Role' && p['role'] != null) values.add(p['role']);
      if (type == 'Team' && p['team'] != null) {
        values.add(p['team']['team_name']);
      }
    }
    final sortedValues = values.toList()..sort();

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Select $type'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() {
                if (type == 'Role') _selectedRole = null;
                if (type == 'Team') _selectedTeam = null;
                _applyFilters();
              });
              Navigator.pop(context);
            },
            child: const Text('All',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...sortedValues.map((value) => SimpleDialogOption(
                onPressed: () {
                  setState(() {
                    if (type == 'Role') _selectedRole = value;
                    if (type == 'Team') _selectedTeam = value;
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
                child: Text(value),
              )),
        ],
      ),
    );
  }
}
