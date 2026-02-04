import 'package:flutter/material.dart';
import 'package:lpl_auction_app/app_theme.dart';
import 'package:lpl_auction_app/services/api_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return Colors.red;
      case 'AUCTIONEER':
        return Colors.blue;
      case 'TEAM_MANAGER':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['showAddDialog'] == true) {
        _showAddUserDialog();
      }
    });
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await _apiService.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
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
      final success = await _apiService.deleteUser(id);
      if (success) {
        _fetchUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete user')),
          );
        }
      }
    }
  }

  void _showAddUserDialog({Map<String, dynamic>? user}) {
    final isEditing = user != null;
    final nameController = TextEditingController(text: user?['name']);
    final emailController = TextEditingController(text: user?['email']);
    final passwordController = TextEditingController();
    String role = user?['role'] ?? 'AUCTIONEER';
    final roles = ['ADMIN', 'AUCTIONEER', 'TEAM_MANAGER'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit User' : 'Add User'),
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
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                    labelText: isEditing
                        ? 'Password (Leave blank to keep current)'
                        : 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: role,
                items: roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => role = val!,
                decoration: const InputDecoration(labelText: 'Role'),
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
              if (nameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  (!isEditing && passwordController.text.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All fields are required')),
                );
                return;
              }

              final userData = {
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'role': role
              };

              if (passwordController.text.isNotEmpty) {
                userData['password'] = passwordController.text.trim();
              }

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              bool success;
              if (isEditing) {
                success =
                    await _apiService.updateUser(user['user_id'], userData);
              } else {
                userData['password'] = passwordController.text.trim();
                success = await _apiService.createUser(userData);
              }

              if (success && mounted) {
                navigator.pop();
                _fetchUsers();
                messenger.showSnackBar(
                  SnackBar(
                      content: Text(isEditing ? 'User updated' : 'User added')),
                );
              } else if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                      content: Text(isEditing
                          ? 'Failed to update user'
                          : 'Failed to add user')),
                );
              }
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _getRoleColor(user['role']).withValues(alpha: 0.2),
                      child: Text(
                        user['name'][0].toUpperCase(),
                        style: TextStyle(
                            color: _getRoleColor(user['role']),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(user['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['email']),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            user['role'],
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: _getRoleColor(user['role']),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddUserDialog(user: user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(user['user_id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textDark,
      ),
    );
  }
}
