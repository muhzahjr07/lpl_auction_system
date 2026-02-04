import 'package:flutter/material.dart';
import 'package:lpl_auction_app/services/socket_service.dart';
import 'package:lpl_auction_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:lpl_auction_app/widgets/player_hero_card.dart';
import 'package:lpl_auction_app/widgets/user_profile_button.dart';
// import 'package:lpl_auction_app/utils/image_helper.dart'; // Unused
import 'package:lpl_auction_app/widgets/custom_network_image.dart'; // Add Import

class TeamBiddingScreen extends StatefulWidget {
  const TeamBiddingScreen({super.key});

  @override
  State<TeamBiddingScreen> createState() => _TeamBiddingScreenState();
}

class _TeamBiddingScreenState extends State<TeamBiddingScreen> {
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _currentAuctionState;
  Map<String, dynamic>? _currentPlayer;
  bool _isLoading = true;
  final TextEditingController _customBidController = TextEditingController();

  // Real Team Data
  int? _myTeamId;
  String? _myTeamName;
  String? _myTeamLogo;
  double _myBudget = 0;
  double _moneySpent = 0;

  @override
  void initState() {
    super.initState();
    _loadTeamDetails();
  }

  Future<void> _loadTeamDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myTeamId = prefs.getInt('teamId');
      _myTeamName = prefs.getString('teamName');
      _myTeamLogo = prefs.getString('teamLogo');
    });

    if (_myTeamId != null) {
      _connectSocket();
      _fetchInitialState();
    } else {
      // Handle error: Not logged in as team
      setState(() => _isLoading = false);
    }
  }

  void _connectSocket() {
    _socketService.connect();
    _socketService.socket.on('new_bid', (data) {
      if (mounted) {
        setState(() {
          _currentAuctionState ??= {};
          _currentAuctionState!['currentPrice'] = data['amount'];
          _currentAuctionState!['lastBidder'] = data['teamName'];
          _currentAuctionState!['lastBidderId'] = data['teamId'];
        });
      }
    });

    _socketService.socket.on('sold_confirmed', (data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Player SOLD to ${data['teamName']} for \$${data['amount']}'),
            backgroundColor: AppColors.primary,
          ),
        );
        if (data['teamId'] == _myTeamId) {
          // My team won
          setState(() {
            _moneySpent += double.parse(data['amount'].toString());
            _myBudget -= double.parse(data['amount'].toString());
          });
        }
        _fetchInitialState();
      }
    });

    _socketService.socket.on('new_round_started', (data) {
      debugPrint('Socket: New Round Started with data: $data');
      if (mounted) {
        setState(() => _isLoading = true);
        if (data != null && data['playerId'] != null) {
          _fetchPlayerForRound(data['playerId']);
        } else {
          _fetchInitialState(); // Fallback
        }
      }
    });

    _socketService.socket.on('auction_reset', (_) {
      if (mounted) {
        setState(() {
          _currentPlayer = null;
          _currentAuctionState = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auction Suspended / Round Ended')),
        );
      }
    });

    _socketService.joinAuction("auction_room");
  }

  void _fetchPlayerForRound(int playerId) async {
    try {
      final player = await _apiService.getPlayerById(playerId);
      if (mounted) {
        setState(() {
          // Manually construct state to avoid API race condition
          _currentPlayer = player;
          _currentAuctionState = {
            'activePlayerId': playerId,
            'currentPrice': player['base_price'],
            'lastBidder': null,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching player for round: $e');
      _fetchInitialState(); // Fallback
    }
  }

  void _fetchInitialState() async {
    try {
      debugPrint('Fetching initial state...');
      // 1. Get Auction State
      final state = await _apiService.getAuctionState();
      debugPrint('Auction State: $state');

      // 2. Get My Team Details (for budget updates)
      if (_myTeamId != null) {
        try {
          final team = await _apiService.getTeamById(_myTeamId!);
          if (mounted) {
            setState(() {
              _myBudget = double.parse(team['remaining_budget'].toString());
              _moneySpent =
                  double.parse(team['total_budget'].toString()) - _myBudget;
            });
          }
        } catch (e) {
          debugPrint('Error fetching team details (non-fatal): $e');
        }
      }

      // 3. Get Player
      if (state['activePlayerId'] != null) {
        debugPrint('Active Player ID found: ${state['activePlayerId']}');
        final player = await _apiService.getPlayerById(state['activePlayerId']);
        if (mounted) {
          setState(() {
            _currentAuctionState = state;
            _currentPlayer = player;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('No active player found.');
        if (mounted) {
          setState(() {
            _currentAuctionState = state;
            _currentPlayer = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching state: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _placeBid(double increment) {
    if (_currentAuctionState == null || _currentPlayer == null) return;

    final currentPrice = double.tryParse(
            (_currentAuctionState!['currentPrice'] ??
                    _currentPlayer!['base_price'])
                .toString()) ??
        0;
    final newAmount = currentPrice + increment;

    if (newAmount > _myBudget) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Insufficient Budget!'), backgroundColor: Colors.red));
      return;
    }

    _socketService.placeBid(_myTeamId!,
        _currentPlayer!['id'] ?? _currentPlayer!['player_id'], newAmount);
  }

  void _placeCustomBid() {
    if (_customBidController.text.isEmpty) return;
    final amount = double.tryParse(_customBidController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid amount entered')));
      return;
    }

    final currentPrice = double.tryParse(
            (_currentAuctionState!['currentPrice'] ??
                    _currentPlayer!['base_price'])
                .toString()) ??
        0;

    if (amount <= currentPrice) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bid must be higher than current price!'),
          backgroundColor: Colors.red));
      return;
    }

    if (amount > _myBudget) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Insufficient Budget!'), backgroundColor: Colors.red));
      return;
    }

    _socketService.placeBid(_myTeamId!,
        _currentPlayer!['id'] ?? _currentPlayer!['player_id'], amount);
    _customBidController.clear();
    FocusScope.of(context).unfocus(); // Close keyboard
  }

  @override
  void dispose() {
    _customBidController.dispose();
    // Socket persists
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Header / Budget Stats
          Container(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 20,
                left: 16,
                right: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20)
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Back Button
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        // Team Logo/Info (Existing)
                        if (_myTeamLogo != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipOval(
                              child: Container(
                                width: 32,
                                height: 32,
                                color: Colors.white,
                                child: CustomNetworkImage(
                                  imageUrl: _myTeamLogo!,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorWidget: const Icon(Icons.shield),
                                ),
                              ),
                            ),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_myTeamName ?? 'Team Owner',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            Text('BIDDING ROOM',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    letterSpacing: 1.2,
                                    color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                    UserProfileButton(
                      userName: _myTeamName ?? 'Team',
                      userRole: 'Manager',
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBudgetStat(
                        context,
                        'REMAINING BUDGET',
                        '\$${(_myBudget / 1000000).toStringAsFixed(2)}M',
                        AppColors.primary),
                    Container(width: 1, height: 30, color: Colors.white24),
                    _buildBudgetStat(
                        context,
                        'SPENT',
                        '\$${(_moneySpent / 1000).toStringAsFixed(1)}k',
                        Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentPlayer == null
                    ? const Center(
                        child: Text('Waiting for auction to start...'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            PlayerHeroCard(
                              name: _currentPlayer!['name'],
                              role: _currentPlayer!['role'],
                              imageUrl: _currentPlayer!['image_url'] ?? '',
                              country: _currentPlayer!['country'] ?? 'Lanka',
                              basePrice: '\$${_currentPlayer!['base_price']}',
                              // Strict Role-Based Stats
                              totalRuns: (_currentPlayer!['role'] ==
                                              'BATSMAN' ||
                                          _currentPlayer!['role'] ==
                                              'WICKET_KEEPER' ||
                                          _currentPlayer!['role'] ==
                                              'ALL_ROUNDER') &&
                                      _currentPlayer!['total_runs'] != null &&
                                      _currentPlayer!['total_runs'] > 0
                                  ? _currentPlayer!['total_runs'].toString()
                                  : null,
                              strikeRate: (_currentPlayer!['role'] ==
                                              'BATSMAN' ||
                                          _currentPlayer!['role'] ==
                                              'WICKET_KEEPER' ||
                                          _currentPlayer!['role'] ==
                                              'ALL_ROUNDER') &&
                                      _currentPlayer!['strike_rate'] != null &&
                                      double.tryParse(
                                              _currentPlayer!['strike_rate']
                                                  .toString())! >
                                          0
                                  ? _currentPlayer!['strike_rate'].toString()
                                  : null,
                              wickets: (_currentPlayer!['role'] == 'BOWLER' ||
                                          _currentPlayer!['role'] ==
                                              'ALL_ROUNDER') &&
                                      _currentPlayer!['wickets'] != null &&
                                      _currentPlayer!['wickets'] > 0
                                  ? _currentPlayer!['wickets'].toString()
                                  : null,
                              economyRate: (_currentPlayer!['role'] ==
                                              'BOWLER' ||
                                          _currentPlayer!['role'] ==
                                              'ALL_ROUNDER') &&
                                      _currentPlayer!['economy_rate'] != null &&
                                      double.tryParse(
                                              _currentPlayer!['economy_rate']
                                                  .toString())! >
                                          0
                                  ? _currentPlayer!['economy_rate'].toString()
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // Current Bid Display
                            Text('CURRENT PRICE',
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              '\$${_currentAuctionState!['currentPrice'] ?? _currentPlayer!['base_price']}',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (_currentAuctionState!['lastBidder'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Top Bid: ${_currentAuctionState!['lastBidder']}',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Quick Bid Buttons
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 2.5,
                              children: [
                                _buildBidButton(5000),
                                _buildBidButton(10000),
                                _buildBidButton(25000),
                                _buildBidButton(50000),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Custom Bid Input
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CUSTOM BID',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 10,
                                          letterSpacing: 1.5,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _customBidController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            prefixIcon: Container(
                                                width: 40,
                                                alignment: Alignment.center,
                                                child: Text('\$',
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            hintText: 'Enter amount',
                                            filled: true,
                                            fillColor: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: _placeCustomBid,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.textDark,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 16),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Place Bid',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStat(
      BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBidButton(double amount) {
    return ElevatedButton(
      onPressed: () => _placeBid(amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: AppColors.primary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      child: Text('+\$${(amount / 1000).toStringAsFixed(0)}k',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
