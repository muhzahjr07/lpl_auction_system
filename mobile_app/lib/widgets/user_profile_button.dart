import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lpl_auction_app/providers/auth_provider.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:lpl_auction_app/utils/image_helper.dart';

class UserProfileButton extends StatelessWidget {
  final String? userName;
  final String? userRole;
  final String? imageUrl;
  final Color? color;

  const UserProfileButton({
    super.key,
    this.userName,
    this.userRole,
    this.imageUrl,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tooltip: 'Profile',
      itemBuilder: (context) => [
        // Header
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName ?? 'User',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                userRole ?? 'Logged In',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const Divider(),
            ],
          ),
        ),
        // Logout Action
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Log Out', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          Provider.of<AuthProvider>(context, listen: false).logout(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(2), // Border width
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color ?? AppColors.primary,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: (color ?? AppColors.primary).withValues(alpha: 0.1),
          backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
              ? ImageHelper.getTeamLogoProvider(imageUrl)
              : null,
          child: imageUrl == null || imageUrl!.isEmpty
              ? Text(
                  (userName ?? 'U').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: color ?? AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
