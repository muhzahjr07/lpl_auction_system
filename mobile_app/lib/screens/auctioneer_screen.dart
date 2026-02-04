import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lpl_auction_app/services/socket_service.dart';
import 'package:lpl_auction_app/services/api_service.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:lpl_auction_app/widgets/user_profile_button.dart';
import 'package:lpl_auction_app/widgets/player_hero_card.dart';
import 'package:lpl_auction_app/utils/image_helper.dart';

class AuctioneerScreen extends StatefulWidget {
  final bool isViewer;
  const AuctioneerScreen({super.key, this.isViewer = false});

  @override
  State<AuctioneerScreen> createState() => _AuctioneerScreenState();
}

class _AuctioneerScreenState extends State<AuctioneerScreen> {
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _currentAuctionState;
  Map<String, dynamic>? _currentPlayer;
  final List<dynamic> _bidHistory = [];
  bool _isLoading = true;
  bool _isDecisionMode = false;

  // Placeholder for design
  final String _mockPlayerImage =
      "https://lh3.googleusercontent.com/aida-public/AB6AXuBZkQ5E_6hq-vok3PywSsdtdvvAqgp_wT2GE1_Ha121kZrKmDAZrmcejDZ5jhUsF6KFLJpM4Vi4AgAdzPw1MvJddSviZ2zjIIgMLHt_ZDfTA_eByeiUDeCFa5T2_kDfD8yJGi1IOTxvTxd-_HGbiVkfXCd0lZSp-m9Uz16EnNEo87TvHHRlZRM8LERkPAXdfJeobt5cCRvjnNA7JZSj_dkWdGf1X0SkbAx7HuTl5J-0X1DMKjPHN7Ugf3AUy3mjvQOqBmR7p-E9MFNT";

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _fetchInitialState();
  }

  void _connectSocket() {
    _socketService.connect();
    _socketService.joinAuction("auction_room");
    _socketService.socket.on('new_bid', _onNewBid);
    _socketService.socket.on('sold_confirmed', _onSoldConfirmed);
    _socketService.socket.on('new_round_started', (_) {
      if (mounted) _fetchInitialState();
    });
    _socketService.socket.on('auction_reset', (_) {
      if (mounted) {
        setState(() {
          _isDecisionMode = false;
          _currentPlayer = null;
          _currentAuctionState = null;
          _bidHistory.clear();
        });
      }
    });
  }

  void _onNewBid(dynamic data) {
    if (mounted) {
      setState(() {
        _currentAuctionState ??= {};
        _currentAuctionState!['currentPrice'] = data['amount'];
        _currentAuctionState!['lastBidder'] = data['teamName'];
        _currentAuctionState!['lastBidderId'] = data['teamId'];
        _currentAuctionState!['lastBidderTeamLogo'] = data['teamLogo'];

        _bidHistory.insert(0, data);
        if (_bidHistory.length > 5) _bidHistory.removeLast();
      });
    }
  }

  void _onSoldConfirmed(dynamic data) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Player SOLD to ${data['teamName']} for \$${data['amount']}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );

      setState(() {
        _currentPlayer = null;
        _currentAuctionState = null;
        _isDecisionMode = false;
      });

      // Small delay to let user read SnackBar then open modal
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _showStartRoundModal();
      });
    }
  }

  void _fetchInitialState() async {
    // 1. Get Auction State
    final state = await _apiService.getAuctionState();

    // 2. Get Player Details if active
    if (state['activePlayerId'] != null) {
      final player = await _apiService.getPlayerById(state['activePlayerId']);
      setState(() {
        _currentAuctionState = state;
        _currentPlayer = player;
        _isLoading = false;
        _bidHistory.clear(); // Clear history for new load
      });
    } else {
      setState(() {
        _currentAuctionState = state;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _socketService.socket.off('new_bid', _onNewBid);
    _socketService.socket.off('sold_confirmed', _onSoldConfirmed);
    super.dispose();
  }

  void _startRound(int playerId) async {
    final success = await _apiService.startRound(playerId);
    if (success) {
      _fetchInitialState();
      _socketService.socket.emit('start_auction_round', {'playerId': playerId});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Failed to start round. Check connection or player status.')),
        );
      }
    }
  }

  void _markSold() {
    if (_currentAuctionState != null &&
        _currentAuctionState!['activePlayerId'] != null) {
      final price = _currentAuctionState!['currentPrice'];
      final teamId = _currentAuctionState!['lastBidderId'];

      if (teamId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No bids yet! Cannot sell.')));
        return;
      }

      _socketService.socket.emit('player_sold', {
        'teamId': teamId,
        'playerId': _currentAuctionState!['activePlayerId'],
        'finalAmount': price
      });
      setState(() => _isDecisionMode = false);
    }
  }

  void _markUnsold() async {
    if (_currentAuctionState != null &&
        _currentAuctionState!['activePlayerId'] != null) {
      await _apiService.markUnsold(_currentAuctionState!['activePlayerId']);
      setState(() {
        _isDecisionMode = false;
        _currentPlayer = null;
        _currentAuctionState = null;
      });
      // Prompt for next player immediately
      if (mounted) _showStartRoundModal();
    }
  }

  void _suspendBidding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Bidding?'),
        content: const Text(
            'This will cancel the current round and reset the auction state. No player will be sold.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Suspend', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiService.resetAuction();
      if (success) {
        if (mounted) {
          setState(() {
            _isDecisionMode = false;
            _currentPlayer = null;
            _currentAuctionState = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bidding Suspended')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to suspend bidding')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Custom App Bar
          Container(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 10,
                left: 16,
                right: 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.gavel, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LPL Auction',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('AUCTION PANEL',
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: AppColors.textMuted)),
                  ],
                ),
                const Spacer(),
                UserProfileButton(
                  userName: 'Auctioneer',
                  userRole: widget.isViewer ? 'Viewer' : 'Match Official',
                  color: Colors.white,
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentPlayer == null
                    ? _buildEmptyState()
                    : _buildAuctionContent(),
          ),

          // Bottom Footer Actions
          if (!widget.isViewer && _currentPlayer != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5))
                ],
              ),
              // Decision Mode Logic
              child: _isDecisionMode
                  ? Row(
                      children: [
                        // UNSOLD
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _markUnsold,
                            icon: const Icon(Icons.close),
                            label: const Text('UNSOLD'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // SOLD
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _markSold,
                            icon: const Icon(Icons.check),
                            label: const Text('SOLD'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[50],
                              foregroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Cancel
                        IconButton(
                          onPressed: () =>
                              setState(() => _isDecisionMode = false),
                          icon: const Icon(Icons.cancel_outlined),
                          color: Colors.grey,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // SOLD/UNSOLD
                        Expanded(
                          flex: 1,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                setState(() => _isDecisionMode = true),
                            icon: const Icon(Icons.gavel),
                            label: const Text('SOLD/UNSOLD',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[50],
                              foregroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: Colors.orange
                                          .withValues(alpha: 0.2))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // NEXT PLAYER
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _showStartRoundModal,
                            icon: const Icon(Icons.skip_next),
                            label: const Text('NEXT PLAYER',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

          // Suspend Button (Only when active and NOT in decision mode)
          if (!widget.isViewer && _currentPlayer != null && !_isDecisionMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton.icon(
                onPressed: _suspendBidding,
                icon: const Icon(Icons.pause_circle_filled, color: Colors.red),
                label: const Text('Suspend Bidding',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
        ],
      ),
    );
  }

  void _showStartRoundModal() async {
    // Check role - only Auctioneer can start round
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    if (role != 'AUCTIONEER') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Only the Auctioneer can start a round.')),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final navigator = Navigator.of(context);
      final players = await _apiService.getUnsoldPlayers();
      if (mounted) navigator.pop(); // Remove loader

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return _PlayerSelectionWidget(
              players: players,
              onPlayerSelected: _startRound,
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_cricket, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No Active Auction Round'),
          const SizedBox(height: 16),
          // We can remove this button for non-Auctioneers if we want strict UI
          // But check is done inside the modal method too.
          ElevatedButton(
            onPressed: _showStartRoundModal,
            child: const Text('Start New Round'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status Indicator
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: AppColors.primary),
                SizedBox(width: 8),
                Text('BIDDING ACTIVE',
                    style: TextStyle(
                        color: Color(0xFF0FB880),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          ),

          // Hero Card
          PlayerHeroCard(
            name: _currentPlayer!['name'],
            role: _currentPlayer!['role'],
            imageUrl: _currentPlayer!['image_url'] ?? _mockPlayerImage,
            country: _currentPlayer!['country'],
            basePrice: '\$${_currentPlayer!['base_price']}',
            lotNumber: "084", // Mock
            totalRuns: (_currentPlayer!['role'] == 'BATSMAN' ||
                        _currentPlayer!['role'] == 'WICKET_KEEPER' ||
                        _currentPlayer!['role'] == 'ALL_ROUNDER') &&
                    _currentPlayer!['total_runs'] != null &&
                    _currentPlayer!['total_runs'] > 0
                ? _currentPlayer!['total_runs'].toString()
                : null,
            strikeRate: (_currentPlayer!['role'] == 'BATSMAN' ||
                        _currentPlayer!['role'] == 'WICKET_KEEPER' ||
                        _currentPlayer!['role'] == 'ALL_ROUNDER') &&
                    _currentPlayer!['strike_rate'] != null &&
                    double.tryParse(
                            _currentPlayer!['strike_rate'].toString())! >
                        0
                ? _currentPlayer!['strike_rate'].toString()
                : null,
            wickets: (_currentPlayer!['role'] == 'BOWLER' ||
                        _currentPlayer!['role'] == 'ALL_ROUNDER') &&
                    _currentPlayer!['wickets'] != null &&
                    _currentPlayer!['wickets'] > 0
                ? _currentPlayer!['wickets'].toString()
                : null,
            economyRate: (_currentPlayer!['role'] == 'BOWLER' ||
                        _currentPlayer!['role'] == 'ALL_ROUNDER') &&
                    _currentPlayer!['economy_rate'] != null &&
                    double.tryParse(
                            _currentPlayer!['economy_rate'].toString())! >
                        0
                ? _currentPlayer!['economy_rate'].toString()
                : null,
          ),

          const SizedBox(height: 20),

          // Live Bidding Stats
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20)
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.red),
                    SizedBox(width: 8),
                    Text('CURRENT HIGHEST BID',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '\$${_currentAuctionState!['currentPrice']}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      height: 1),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _currentAuctionState!['lastBidderTeamLogo'] != null
                          ? Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  image: DecorationImage(
                                      image: ImageHelper.getTeamLogoProvider(
                                          _currentAuctionState![
                                              'lastBidderTeamLogo']),
                                      fit: BoxFit.cover)),
                            )
                          : Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(4)),
                              child: Center(
                                  child: Text(
                                      _currentAuctionState!['lastBidder'] !=
                                              null
                                          ? _currentAuctionState!['lastBidder']
                                              .toString()
                                              .substring(0, 1)
                                          : '?',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold))),
                            ),
                      const SizedBox(width: 8),
                      Text(
                        _currentAuctionState!['lastBidder'] != null
                            ? (_currentAuctionState!['lastBidder']
                                        .toString()
                                        .length >
                                    15
                                ? '${_currentAuctionState!['lastBidder'].toString().substring(0, 15)}...'
                                : _currentAuctionState!['lastBidder'])
                            : 'Waiting for bids...',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Check _bidHistory
          Align(
            alignment: Alignment.centerLeft,
            child: Text('RECENT BIDS',
                style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2)),
          ),
          const SizedBox(height: 12),
          ..._bidHistory.map((bid) => _buildBidItem(bid)),
        ],
      ),
    );
  }

  Widget _buildBidItem(Map<String, dynamic> bid) {
    final bool isSold = bid['isSold'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSold
            ? Colors.green.withValues(alpha: 0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isSold ? Colors.green : Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isSold)
                bid['teamLogo'] != null
                    ? Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                                image: ImageHelper.getTeamLogoProvider(
                                    bid['teamLogo']),
                                fit: BoxFit.cover)),
                      )
                    : Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                                bid['teamName'] != null
                                    ? bid['teamName'].toString().substring(0, 1)
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10))),
                      ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isSold ? 'SOLD TO' : (bid['teamName'] as String),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSold ? Colors.green : null)),
                  if (isSold)
                    Text(bid['teamName'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13)),
                  Text(isSold ? (bid['playerName'] ?? 'Player') : 'Just now',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                ],
              ),
            ],
          ),
          Text('\$${bid['amount']}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSold ? Colors.green : null)),
        ],
      ),
    );
  }
}

class _PlayerSelectionWidget extends StatefulWidget {
  final List<dynamic> players;
  final Function(int) onPlayerSelected;

  const _PlayerSelectionWidget(
      {required this.players, required this.onPlayerSelected});

  @override
  State<_PlayerSelectionWidget> createState() => _PlayerSelectionWidgetState();
}

class _PlayerSelectionWidgetState extends State<_PlayerSelectionWidget> {
  late List<dynamic> _filteredPlayers;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredPlayers = widget.players;
  }

  void _filterPlayers(String query) {
    setState(() {
      _filteredPlayers = widget.players
          .where((p) =>
              p['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Player',
                  style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close))
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search Player',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _filterPlayers,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredPlayers.isEmpty
                ? const Center(child: Text('No players found.'))
                : ListView.builder(
                    itemCount: _filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final p = _filteredPlayers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(p['image_url'] ??
                              "https://lh3.googleusercontent.com/aida-public/AB6AXuBZkQ5E_6hq-vok3PywSsdtdvvAqgp_wT2GE1_Ha121kZrKmDAZrmcejDZ5jhUsF6KFLJpM4Vi4AgAdzPw1MvJddSviZ2zjIIgMLHt_ZDfTA_eByeiUDeCFa5T2_kDfD8yJGi1IOTxvTxd-_HGbiVkfXCd0lZSp-m9Uz16EnNEo87TvHHRlZRM8LERkPAXdfJeobt5cCRvjnNA7JZSj_dkWdGf1X0SkbAx7HuTl5J-0X1DMKjPHN7Ugf3AUy3mjvQOqBmR7p-E9MFNT"),
                        ),
                        title: Text(p['name']),
                        subtitle:
                            Text('${p['role']} - Base: \$${p['base_price']}'),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onPlayerSelected(p['player_id']);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
