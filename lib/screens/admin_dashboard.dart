import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../utils/database_helper.dart';
import '../utils/bilingual_text_styles.dart';
import '../utils/responsive_utils.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/update_user_dialog.dart';
import '../widgets/responsive_app_bar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  // Brand palette (greens only)
  static const Color background = Color(0xFFF0FFF0); // Honeydew
  static const Color deepGreen = Color(0xFF0B5D3B);  // Premium deep green
  static const Color midGreen = Color(0xFF2E7D32);   // Medium green
  static const Color lightGreenFill = Color(0xFFE8F5E9); // Very light green fill
  static const Color borderGreen = Color(0xFF66BB6A); // For borders/focus

  late final TabController _tabController;
  late final AnimationController _cardAnimationController;
  late final Animation<double> _cardScaleAnimation;
  
  List<User> _allUsers = [];
  List<User> _adminUsers = [];
  List<User> _regularUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cardScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeOutBack),
    );
    
    
    _loadUsers();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final allUsers = await DatabaseHelper.instance.getAllUsers();
      final adminUsers = await DatabaseHelper.instance.getUsersByRole(UserRole.admin);
      final regularUsers = await DatabaseHelper.instance.getUsersByRole(UserRole.user);

      setState(() {
        _allUsers = allUsers;
        _adminUsers = adminUsers;
        _regularUsers = regularUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        onUserAdded: () {
          _loadUsers(); // Refresh the user list
        },
      ),
    );
  }

  Future<void> _toggleUserRole(User user) async {
    final newRole = user.role == UserRole.admin ? UserRole.user : UserRole.admin;
    
    final success = await DatabaseHelper.instance.updateUserRole(user.id!, newRole);
    
    if (success) {
      _loadUsers(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} role updated to ${newRole.displayName}'),
            backgroundColor: deepGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update user role'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete User',
          style: TextStyle(color: deepGreen, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to permanently delete ${user.fullName}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await DatabaseHelper.instance.deleteUser(user.id!);
        if (success) {
          _loadUsers();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${user.fullName} has been deleted'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete user'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showUpdateUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => UpdateUserDialog(
        user: user,
        onUserUpdated: () {
          _loadUsers(); // Refresh the user list
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().currentUser;

    return ResponsiveBuilder(
      builder: (context, screenType) {
        return Scaffold(
          backgroundColor: background,
          appBar: ResponsiveAppBar(
            title: 'Admin Dashboard',
            backgroundColor: background,
            foregroundColor: deepGreen,
            elevation: 2,
            actions: [
              Padding(
                padding: ResponsiveUtils.getResponsiveMargin(context),
                child: Chip(
                  label: ResponsiveText(
                    currentUser?.fullName ?? 'Admin',
                    baseFontSize: 12,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: deepGreen,
                ),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: deepGreen))
              : Column(
                  children: [
                    Container(
                      color: background,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: deepGreen,
                        unselectedLabelColor: midGreen,
                        indicatorColor: deepGreen,
                        labelStyle: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                        ),
                        tabs: [
                          Tab(
                            text: screenType == ScreenType.mobile
                                ? 'All (${_allUsers.length})'
                                : 'All Users (${_allUsers.length})',
                            icon: const Icon(Icons.people),
                          ),
                          Tab(
                            text: screenType == ScreenType.mobile
                                ? 'Admin (${_adminUsers.length})'
                                : 'Admins (${_adminUsers.length})',
                            icon: const Icon(Icons.admin_panel_settings),
                          ),
                          Tab(
                            text: screenType == ScreenType.mobile
                                ? 'User (${_regularUsers.length})'
                                : 'Users (${_regularUsers.length})',
                            icon: const Icon(Icons.person),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildUserList(_allUsers, showRole: true, screenType: screenType),
                          _buildUserList(_adminUsers, screenType: screenType),
                          _buildUserList(_regularUsers, screenType: screenType),
                        ],
                      ),
                    ),
                  ],
                ),
          floatingActionButton: screenType == ScreenType.mobile
              ? FloatingActionButton(
                  onPressed: _showAddUserDialog,
                  backgroundColor: deepGreen,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.person_add),
                )
              : FloatingActionButton.extended(
                  onPressed: _showAddUserDialog,
                  backgroundColor: deepGreen,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.person_add),
                  label: ResponsiveText(
                    'Add User',
                    baseFontSize: 14,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildUserList(List<User> users, {bool showRole = false, ScreenType? screenType}) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: ResponsiveUtils.getResponsiveSpacing(context, 64),
              color: Colors.grey[400],
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
            ResponsiveText(
              'No users found',
              baseFontSize: 18,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: deepGreen,
      child: screenType == ScreenType.mobile
          ? ListView.builder(
              padding: ResponsiveUtils.getResponsivePadding(context),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildAnimatedUserCard(user, index, showRole: showRole, screenType: screenType);
              },
            )
          : GridView.builder(
              padding: ResponsiveUtils.getResponsivePadding(context),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveUtils.getResponsiveColumns(context),
                childAspectRatio: screenType == ScreenType.tablet ? 1.8 : 2.2,
                crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
                mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
              ),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildAnimatedUserCard(user, index, showRole: showRole, screenType: screenType);
              },
            ),
    );
  }

  Widget _buildAnimatedUserCard(User user, int index, {bool showRole = false, ScreenType? screenType}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: _buildUserCard(user, showRole: showRole, screenType: screenType),
          ),
        );
      },
    );
  }

  Widget _buildUserCard(User user, {bool showRole = false, ScreenType? screenType}) {
    final currentUser = context.read<UserProvider>().currentUser;
    final isCurrentUser = currentUser?.id == user.id;

    return MouseRegion(
      onEnter: (_) => _cardAnimationController.forward(),
      onExit: (_) => _cardAnimationController.reverse(),
      child: AnimatedBuilder(
        animation: _cardAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_cardScaleAnimation.value - 1.0) * 0.02,
            child: Card(
              margin: EdgeInsets.only(bottom: ResponsiveUtils.getResponsiveSpacing(context, 12)),
              elevation: 2 + (_cardScaleAnimation.value * 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: user.isActive ? borderGreen.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Padding(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: ResponsiveUtils.getResponsiveSpacing(context, 20),
                  backgroundColor: user.isActive ? deepGreen : Colors.grey,
                  foregroundColor: Colors.white,
                  child: ResponsiveText(
                    user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                    baseFontSize: 16,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ResponsiveText(
                            user.fullName,
                            baseFontSize: 16,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: deepGreen,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.getResponsiveSpacing(context, 6),
                                vertical: ResponsiveUtils.getResponsiveSpacing(context, 2),
                              ),
                              decoration: BoxDecoration(
                                color: deepGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ResponsiveText(
                                'YOU',
                                baseFontSize: 10,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      ResponsiveText(
                        user.email,
                        baseFontSize: 14,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (showRole) ...[
                        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 4)),
                        Chip(
                          label: ResponsiveText(
                            user.role.displayName,
                            baseFontSize: 12,
                          ),
                          backgroundColor: user.isAdmin 
                              ? deepGreen.withValues(alpha: 0.1)
                              : lightGreenFill,
                          side: BorderSide(
                            color: user.isAdmin ? deepGreen : borderGreen,
                            width: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!user.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'INACTIVE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                BilingualText.bilingual(
                  'Created: ${_formatDate(user.createdAt)}',
                  style: BilingualTextStyles.bodySmall(
                    'Created: ${_formatDate(user.createdAt)}',
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (!isCurrentUser) ...[
                  TextButton.icon(
                    onPressed: () => _showUpdateUserDialog(user),
                    icon: const Icon(
                      Icons.edit,
                      size: 16,
                      color: midGreen,
                    ),
                    label: const Text(
                      'Edit',
                      style: TextStyle(color: midGreen, fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _toggleUserRole(user),
                    icon: Icon(
                      user.isAdmin ? Icons.person : Icons.admin_panel_settings,
                      size: 16,
                      color: midGreen,
                    ),
                    label: Text(
                      user.isAdmin ? 'Make User' : 'Make Admin',
                      style: const TextStyle(color: midGreen, fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteUser(user),
                    icon: const Icon(
                      Icons.delete,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}