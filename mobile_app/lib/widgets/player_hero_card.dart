import 'package:flutter/material.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:lpl_auction_app/services/api_service.dart';
import 'package:lpl_auction_app/widgets/custom_network_image.dart';

class PlayerHeroCard extends StatelessWidget {
  final String name;
  final String role;
  final String imageUrl;
  final String country;
  final String basePrice;
  final String? lotNumber;
  final String? totalRuns;
  final String? strikeRate;
  final String? wickets;
  final String? economyRate;

  const PlayerHeroCard({
    super.key,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.country,
    required this.basePrice,
    this.lotNumber,
    this.totalRuns,
    this.strikeRate,
    this.wickets,
    this.economyRate,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder image logic
    String displayUrl = imageUrl;
    if (imageUrl.isNotEmpty && !Uri.parse(imageUrl).isAbsolute) {
      final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
      displayUrl = '$baseUrl$imageUrl';
    }

    final hasValidImage = displayUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: hasValidImage
                      ? CustomNetworkImage(
                          imageUrl: displayUrl,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.person,
                                size: 80, color: Colors.white54),
                          ),
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.person,
                              size: 80, color: Colors.white54),
                        ),
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),
              // Lot Number Badge (Top Right)
              if (lotNumber != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'LOT #$lotNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Country Badge (Top Left)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        country,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              // Name & Role (Bottom Left)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.sports_cricket,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          role,
                          style: TextStyle(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Info Grid
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'BASE PRICE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        basePrice,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context).dividerColor),

                // Stats Columns based on data
                if (totalRuns != null || strikeRate != null) ...[
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'BAT STATS', // Runs / SR
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalRuns != null
                              ? '$totalRuns Runs'
                              : 'SR: $strikeRate',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (totalRuns != null && strikeRate != null)
                          Text(
                            'SR: $strikeRate',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context).dividerColor),
                ],

                if (wickets != null || economyRate != null) ...[
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'BOWL STATS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          wickets != null
                              ? '$wickets Wkts'
                              : 'Econ: $economyRate',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (wickets != null && economyRate != null)
                          Text(
                            'Econ: $economyRate',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
