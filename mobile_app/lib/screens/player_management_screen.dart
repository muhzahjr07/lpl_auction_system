import 'package:flutter/material.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:lpl_auction_app/services/api_service.dart';

class PlayerManagementScreen extends StatefulWidget {
  final bool isReadOnly;

  const PlayerManagementScreen({super.key, this.isReadOnly = false});

  @override
  State<PlayerManagementScreen> createState() => _PlayerManagementScreenState();
}

class _PlayerManagementScreenState extends State<PlayerManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _players = [];
  List<dynamic> _filteredPlayers = [];
  String _currentSortOption = 'Name (A-Z)'; // Default sort
  String? _selectedRole;
  String? _selectedTeam;
  String? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
    _fetchPlayers();
    _searchController.addListener(_filterPlayers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['showAddDialog'] == true && !widget.isReadOnly) {
        _showPlayerDialog();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPlayers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPlayers = _players.where((player) {
        final name = player['name'].toString().toLowerCase();
        final role = (player['role'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(query) || role.contains(query);

        final matchesRole =
            _selectedRole == null || player['role'] == _selectedRole;

        String? playerTeamName =
            player['team'] != null ? player['team']['team_name'] : null;
        final matchesTeam =
            _selectedTeam == null || playerTeamName == _selectedTeam;

        final playerStatus = player['status'] ?? 'PENDING';
        final matchesStatus =
            _selectedStatus == null || playerStatus == _selectedStatus;

        return matchesSearch && matchesRole && matchesTeam && matchesStatus;
      }).toList();
      _sortPlayers();
    });
  }

  void _sortPlayers() {
    switch (_currentSortOption) {
      case 'Name (A-Z)':
        _filteredPlayers.sort(
            (a, b) => a['name'].toString().compareTo(b['name'].toString()));
        break;
      case 'Price (High-Low)':
        _filteredPlayers.sort((a, b) {
          final priceA = double.tryParse(a['base_price'].toString()) ?? 0;
          final priceB = double.tryParse(b['base_price'].toString()) ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'Price (Low-High)':
        _filteredPlayers.sort((a, b) {
          final priceA = double.tryParse(a['base_price'].toString()) ?? 0;
          final priceB = double.tryParse(b['base_price'].toString()) ?? 0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'Status':
        _filteredPlayers.sort((a, b) =>
            (a['status'] ?? 'PENDING').compareTo(b['status'] ?? 'PENDING'));
        break;
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => Container(
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  _buildFilterChip('Role', _selectedRole),
                  const SizedBox(width: 8),
                  _buildFilterChip('Team', _selectedTeam),
                  const SizedBox(width: 8),
                  _buildFilterChip('Status', _selectedStatus),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const Divider(),
            _buildSortOption('Name (A-Z)'),
            _buildSortOption('Price (High-Low)'),
            _buildSortOption('Price (Low-High)'),
            _buildSortOption('Status'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String option) {
    return ListTile(
      title: Text(option),
      trailing: _currentSortOption == option
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() {
          _currentSortOption = option;
          _sortPlayers();
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFilterChip(String label, String? selectedValue) {
    return ActionChip(
      label: Text(selectedValue ?? label),
      avatar: selectedValue != null
          ? const Icon(Icons.close, size: 16)
          : const Icon(Icons.arrow_drop_down),
      onPressed: () {
        if (selectedValue != null) {
          setState(() {
            if (label == 'Role') _selectedRole = null;
            if (label == 'Team') _selectedTeam = null;
            if (label == 'Status') _selectedStatus = null;
            _filterPlayers();
          });
        } else {
          Navigator.pop(context); // Close bottom sheet to show dialog
          _showFilterDialog(label);
        }
      },
    );
  }

  void _showFilterDialog(String type) {
    final Set<String> values = {};
    if (type == 'Status') {
      values.addAll(['SOLD', 'UNSOLD', 'PENDING']);
    } else {
      for (var p in _players) {
        if (type == 'Role' && p['role'] != null) values.add(p['role']);
        if (type == 'Team' && p['team'] != null) {
          values.add(p['team']['team_name']);
        }
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
                if (type == 'Status') _selectedStatus = null;
                _filterPlayers();
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
                    if (type == 'Status') _selectedStatus = value;
                    _filterPlayers();
                  });
                  Navigator.pop(context);
                },
                child: Text(value),
              )),
        ],
      ),
    );
  }

  void _showPlayerDialog([Map<String, dynamic>? player]) {
    final isEditing = player != null;
    final nameController = TextEditingController(text: player?['name']);
    final countryController =
        TextEditingController(text: player?['country'] ?? 'Sri Lanka');
    final priceController =
        TextEditingController(text: player?['base_price']?.toString());
    final imageController = TextEditingController(text: player?['image_url']);

    // Stats Controllers
    final runsController =
        TextEditingController(text: player?['total_runs']?.toString());
    final srController =
        TextEditingController(text: player?['strike_rate']?.toString());
    final wicketsController =
        TextEditingController(text: player?['wickets']?.toString());
    final economyController =
        TextEditingController(text: player?['economy_rate']?.toString());

    String roleRaw = player?['role'] ?? 'BATSMAN';
    String role = 'Batsman';
    final roleMap = {
      'BATSMAN': 'Batsman',
      'BOWLER': 'Bowler',
      'ALL_ROUNDER': 'All Rounder',
      'WICKET_KEEPER': 'Wicket Keeper',
    };
    final reverseRoleMap = {
      'Batsman': 'BATSMAN',
      'Bowler': 'BOWLER',
      'All Rounder': 'ALL_ROUNDER',
      'Wicket Keeper': 'WICKET_KEEPER',
    };

    if (roleMap.containsKey(roleRaw)) {
      role = roleMap[roleRaw]!;
    } else if (reverseRoleMap.containsKey(roleRaw)) {
      // Handle case where it might already be in display format or generic
      role = roleRaw;
    }

    final roles = ['Batsman', 'Bowler', 'All Rounder', 'Wicket Keeper'];
    if (!roles.contains(role)) role = 'Batsman';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Player' : 'Add Player'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: countryController,
                    decoration: const InputDecoration(labelText: 'Country'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    items: roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) => setState(() => role = val!),
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                  const SizedBox(height: 8),

                  // Conditional Stats Fields
                  if (role == 'Batsman' ||
                      role == 'Wicket Keeper' ||
                      role == 'All Rounder') ...[
                    TextField(
                      controller: runsController,
                      decoration:
                          const InputDecoration(labelText: 'Total Runs'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (role == 'Batsman' ||
                      role == 'Wicket Keeper' ||
                      role == 'All Rounder') ...[
                    TextField(
                      controller: srController,
                      decoration:
                          const InputDecoration(labelText: 'Strike Rate'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (role == 'Bowler' || role == 'All Rounder') ...[
                    TextField(
                      controller: wicketsController,
                      decoration: const InputDecoration(labelText: 'Wickets'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: economyController,
                      decoration:
                          const InputDecoration(labelText: 'Economy Rate'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Base Price'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(labelText: 'Image URL'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name is required')),
                    );
                    return;
                  }
                  if (countryController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Country is required')),
                    );
                    return;
                  }
                  if (priceController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Base Price is required')),
                    );
                    return;
                  }

                  final price = double.tryParse(priceController.text);
                  if (price == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid Price')),
                    );
                    return;
                  }

                  final playerData = {
                    'name': nameController.text.trim(),
                    'country': countryController.text.trim(),
                    'role': reverseRoleMap[role] ?? 'BATSMAN',
                    'base_price': price,
                    'image_url': imageController.text.trim().isNotEmpty
                        ? imageController.text.trim()
                        : null,
                    'total_runs': int.tryParse(runsController.text) ?? 0,
                    'strike_rate': double.tryParse(srController.text) ?? 0.0,
                    'wickets': int.tryParse(wicketsController.text) ?? 0,
                    'economy_rate':
                        double.tryParse(economyController.text) ?? 0.0,
                  };

                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  bool success;
                  if (isEditing) {
                    success = await _apiService.updatePlayer(
                        player['player_id'], playerData);
                  } else {
                    success = await _apiService.addPlayer(playerData);
                  }

                  if (success && mounted) {
                    navigator.pop();
                    _fetchPlayers();
                    messenger.showSnackBar(
                      SnackBar(
                          content: Text(
                              isEditing ? 'Player updated' : 'Player added')),
                    );
                  } else if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Operation failed')),
                    );
                  }
                },
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          );
        });
      },
    );
  }

  void _fetchPlayers() async {
    try {
      final players = await _apiService.getPlayers();
      if (mounted) {
        setState(() {
          _players = players;
          _filteredPlayers = List.from(players);
          _sortPlayers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePlayer(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Player'),
        content: const Text('Are you sure you want to delete this player?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiService.deletePlayer(id);
      if (success) {
        _fetchPlayers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Player deleted')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete player')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Management'),
        actions: [
          IconButton(
              onPressed: _showSortOptions, icon: const Icon(Icons.filter_list)),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, role...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          // The listener already handles filtering, but we might want to ensure UI update or focus remains
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = _filteredPlayers[index];
                      return _buildPlayerItem(player);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.isReadOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showPlayerDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Player'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textDark,
            ),
    );
  }

  Widget _buildPlayerItem(dynamic player) {
    final status = player['status'] ?? 'PENDING';
    final isSold = status == 'SOLD';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: player['image_url'] != null
                      ? NetworkImage(player['image_url'])
                      : null,
                  child: player['image_url'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSold ? AppColors.primary : Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(status,
                        style: const TextStyle(
                            fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player['name'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(player['role'] ?? 'Unknown Role',
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                          isSold
                              ? '\$${player['sold_price'] ?? player['base_price']}'
                              : '\$${player['base_price']}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: isSold ? Colors.green : Colors.grey[700],
                            decoration: isSold
                                ? null
                                : null, // Could add strikethrough to base if sold, but user asked to UPDATE it.
                          )),
                      if (isSold) ...[
                        const SizedBox(width: 4),
                        const Text('(Sold)',
                            style:
                                TextStyle(fontSize: 10, color: Colors.green)),
                      ],
                      if (isSold && player['team'] != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.circle, size: 4, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(player['team']['team_name'] ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Stats Display
                  Wrap(
                    spacing: 8,
                    children: [
                      if (player['role'] == 'BATSMAN' ||
                          player['role'] == 'WICKET_KEEPER' ||
                          player['role'] == 'ALL_ROUNDER') ...[
                        if (player['total_runs'] != null &&
                            player['total_runs'] > 0)
                          Text('Runs: ${player['total_runs']}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        if (player['strike_rate'] != null &&
                            double.tryParse(player['strike_rate'].toString())! >
                                0)
                          Text('SR: ${player['strike_rate']}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                      ],
                      if (player['role'] == 'BOWLER' ||
                          player['role'] == 'ALL_ROUNDER') ...[
                        if (player['wickets'] != null && player['wickets'] > 0)
                          Text('Wkts: ${player['wickets']}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        if (player['economy_rate'] != null &&
                            double.tryParse(
                                    player['economy_rate'].toString())! >
                                0)
                          Text('Econ: ${player['economy_rate']}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                      ]
                    ],
                  )
                ],
              ),
            ),
            if (!widget.isReadOnly) ...[
              IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _showPlayerDialog(player)),
              IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePlayer(player['player_id'])),
            ]
          ],
        ),
      ),
    );
  }
}
