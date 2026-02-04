import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lpl_auction_app/providers/auth_provider.dart';
import 'package:lpl_auction_app/services/api_service.dart';
import 'package:lpl_auction_app/services/socket_service.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  final List<Map<String, String>> _demoUsers = [
    {'name': 'Admin', 'email': 'admin@lpl.com', 'role': 'Admin'},
    {'name': 'Auctioneer', 'email': 'auctioneer@lpl.com', 'role': 'Auctioneer'},
    {'name': 'Jaffna Kings', 'email': 'jaffna@lpl.com', 'role': 'Manager'},
    {'name': 'Colombo Strikers', 'email': 'colombo@lpl.com', 'role': 'Manager'},
    {'name': 'Galle Titans', 'email': 'galle@lpl.com', 'role': 'Manager'},
    {'name': 'Dambulla Aura', 'email': 'dambulla@lpl.com', 'role': 'Manager'},
    {'name': 'B-Love Kandy', 'email': 'kandy@lpl.com', 'role': 'Manager'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Decorative Background Blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 100)
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 100)
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo Section
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.cardColor,
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10))
                            ],
                            image: const DecorationImage(
                              image: AssetImage(
                                'assets/logo.jpg',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: theme.scaffoldBackgroundColor, width: 2),
                          ),
                          child: const Icon(Icons.check,
                              size: 14, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'LPL Auction System',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PLAYER AUCTIONING PORTAL',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLabel('Username or Email', theme),
                          Autocomplete<Map<String, String>>(
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<
                                    Map<String, String>>.empty();
                              }
                              return _demoUsers.where((user) => user['name']!
                                  .toLowerCase()
                                  .contains(
                                      textEditingValue.text.toLowerCase()));
                            },
                            displayStringForOption:
                                (Map<String, String> option) =>
                                    option['email']!,
                            onSelected: (Map<String, String> selection) {
                              _emailController.text = selection['email']!;
                            },
                            fieldViewBuilder: (context, textEditingController,
                                focusNode, onFieldSubmitted) {
                              // Sync controllers if needed, or just use the one from Autocomplete
                              _emailController.text =
                                  textEditingController.text;
                              textEditingController.addListener(() {
                                _emailController.text =
                                    textEditingController.text;
                              });

                              return _buildInputField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                hint: 'team@lpl.com',
                                icon: Icons.person_outline,
                                theme: theme,
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 300, // Match field width roughly
                                    color: theme.cardColor,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(8.0),
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          title: Text(option['name']!),
                                          subtitle: Text(option['role']!,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600])),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildLabel('Password', theme),
                          _buildInputField(
                            controller: _passwordController,
                            hint: '••••••••',
                            icon: _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            obscureText: !_isPasswordVisible,
                            onIconPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            theme: theme,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) =>
                                          setState(() => _rememberMe = v!),
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Remember me',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              color: AppColors.textMuted)),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: theme.cardColor,
                                      title: Text('Forgot Password?',
                                          style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface)),
                                      content: Text(
                                          'Please contact admin@lpl.com to reset your password.',
                                          style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface)),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('OK',
                                              style: TextStyle(
                                                  color: AppColors.primary)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('Forgot Password?',
                                    style: TextStyle(color: AppColors.primary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed:
                                authProvider.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                              shadowColor:
                                  AppColors.primary.withValues(alpha: 0.4),
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Log In',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(width: 8),
                                      Icon(Icons.login),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('AUTHORIZED ACCESS',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                  letterSpacing: 1.2)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildRoleBadge('Admin',
                            Icons.admin_panel_settings_outlined, theme),
                        _buildRoleBadge(
                            'Auctioneer', Icons.gavel_outlined, theme),
                        _buildRoleBadge(
                            'Manager', Icons.groups_outlined, theme),
                      ],
                    ),

                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/reports'),
                      child: const Text('View Public Reports',
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Settings Button (Moved to top layer)
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: AppColors.primary),
                  onPressed: _showServerSettingsDialog,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? onIconPressed,
    required ThemeData theme,
    FocusNode? focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        style: TextStyle(
            fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? Colors.white10
                    : const Color(0xFFCFE7DF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? Colors.white10
                    : const Color(0xFFCFE7DF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: onIconPressed != null
              ? IconButton(
                  icon: Icon(icon, color: AppColors.textMuted),
                  onPressed: onIconPressed,
                )
              : Icon(icon, color: AppColors.textMuted),
        ),
        validator: (value) => value!.isEmpty
            ? 'Please enter ${hint.contains('••••') ? 'password' : 'email'}'
            : null,
      ),
    );
  }

  Widget _buildRoleBadge(String label, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showServerSettingsDialog() {
    final controller =
        TextEditingController(text: ApiService.baseUrl.replaceAll('/api', ''));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Settings'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText:
                'https://fritz-diminishable-disenchantedly.ngrok-free.dev',
            hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
            labelText: 'Server URL',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await ApiService().updateUrl(controller.text);
              await SocketService().init();
              if (mounted) {
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Server URL Updated!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await Provider.of<AuthProvider>(context, listen: false)
          .login(_emailController.text, _passwordController.text);

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setBool('remember_me', true);
          await prefs.setString('saved_email', _emailController.text);
        } else {
          await prefs.remove('remember_me');
          await prefs.remove('saved_email');
        }

        if (mounted) {
          final role =
              Provider.of<AuthProvider>(context, listen: false).userRole;
          if (role == 'TEAM_MANAGER') {
            Navigator.pushReplacementNamed(context, '/team_manager_dashboard');
          } else if (role == 'ADMIN') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else if (role == 'AUCTIONEER') {
            Navigator.pushReplacementNamed(context, '/auctioneer_dashboard');
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Login Failed. Check server connection or credentials.')),
        );
      }
    }
  }
}
