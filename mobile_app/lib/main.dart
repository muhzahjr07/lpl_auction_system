import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lpl_auction_app/providers/auth_provider.dart';
import 'package:lpl_auction_app/screens/login_screen.dart';
import 'package:lpl_auction_app/screens/team_bidding_screen.dart';
import 'package:lpl_auction_app/screens/auctioneer_screen.dart';
import 'package:lpl_auction_app/screens/reports_screen.dart';
import 'package:lpl_auction_app/screens/admin_dashboard_screen.dart';
import 'package:lpl_auction_app/screens/player_management_screen.dart';
import 'package:lpl_auction_app/screens/team_management_screen.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:lpl_auction_app/screens/splash_screen.dart';
import 'package:lpl_auction_app/screens/settings_screen.dart';
import 'package:lpl_auction_app/screens/user_management_screen.dart';
import 'package:lpl_auction_app/screens/auctioneer_dashboard_screen.dart';
import 'package:lpl_auction_app/screens/team_manager_dashboard_screen.dart';
import 'package:lpl_auction_app/screens/my_team_screen.dart';

import 'package:lpl_auction_app/services/api_service.dart';
import 'package:lpl_auction_app/services/socket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  await SocketService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LPL Auction System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Uses system setting
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const LoginScreen(),
        '/auctioneer_home': (context) =>
            const AuctioneerScreen(), // Temporarily mapping to AuctioneerScreen for role
        '/team_home': (context) => const TeamBiddingScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/admin/players': (context) => const PlayerManagementScreen(),
        '/admin/teams': (context) => const TeamManagementScreen(),
        '/admin/users': (context) => const UserManagementScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/auctioneer_view': (context) => const AuctioneerScreen(isViewer: true),
        '/auctioneer_dashboard': (context) => const AuctioneerDashboardScreen(),
        '/team_manager_dashboard': (context) =>
            const TeamManagerDashboardScreen(),
        '/my_team': (context) => const MyTeamScreen(),
      },
    );
  }
}
