import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/notification_badge.dart';
import '../widgets/glass_card.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;
  final String location;

  const ShellScreen({super.key, required this.child, required this.location});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _getSelectedIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/profile')) return 1;
    if (location.startsWith('/medications')) return 2;
    if (location.startsWith('/documents')) return 3;
    if (location.startsWith('/scanner')) return 4;
    if (location.startsWith('/doctors')) return 5;
    if (location.startsWith('/advisor')) return 6;
    if (location.startsWith('/smartwatch')) return 7;
    if (location.startsWith('/history')) return 8;
    if (location.startsWith('/settings')) return 9;
    return 0;
  }

  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/profile');
        break;
      case 2:
        context.go('/medications');
        break;
      case 3:
        context.go('/documents');
        break;
      case 4:
        context.go('/scanner');
        break;
      case 5:
        context.go('/doctors');
        break;
      case 6:
        context.go('/advisor');
        break;
      case 7:
        context.go('/smartwatch');
        break;
      case 8:
        context.go('/history');
        break;
      case 9:
        context.go('/settings');
        break;
    }
  }

  void _showNotificationsDrawer(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer<NotificationProvider>(
          builder: (context, notifProvider, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notifications', style: AppTypography.displaySmall.copyWith(fontSize: 20)),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => notifProvider.markAllAsRead(userId),
                            child: const Text('Mark all read', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear_all, color: AppColors.danger, size: 20),
                            onPressed: () => notifProvider.clearAll(userId),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: notifProvider.notifications.isEmpty
                        ? Center(
                            child: Text('No new notifications', style: AppTypography.bodyMedium),
                          )
                        : ListView.builder(
                            itemCount: notifProvider.notifications.length,
                            itemBuilder: (context, index) {
                              final item = notifProvider.notifications[index];
                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                backgroundColor: item.isRead ? AppColors.cardBg : AppColors.primary.withValues(alpha: 0.08),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.type == 'medication' ? Icons.medication : Icons.notifications,
                                      color: item.isRead ? AppColors.textMuted : AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.title, style: AppTypography.titleSmall),
                                          Text(item.message, style: AppTypography.bodySmall),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final user = authProvider.currentUser;
    final selectedIndex = _getSelectedIndex(widget.location);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: AppColors.primaryGradient),
              ),
              child: const Icon(Icons.local_hospital_rounded, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            Text('MediCore AI', style: AppTypography.displaySmall.copyWith(fontSize: 20)),
          ],
        ),
        actions: [
          NotificationBadge(
            count: notifProvider.unreadCount,
            onTap: () => _showNotificationsDrawer(context),
          ),
          const SizedBox(width: 8),
          if (user != null) ...[
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: AvatarWidget(name: user.fullName, email: user.email, size: 36),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation Rail
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            extended: isDesktop,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primary.withValues(alpha: 0.2),
            selectedIconTheme: const IconThemeData(color: AppColors.primary, size: 24),
            unselectedIconTheme: const IconThemeData(color: AppColors.textMuted, size: 22),
            selectedLabelTextStyle: AppTypography.labelLarge.copyWith(color: AppColors.primary),
            unselectedLabelTextStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
              NavigationRailDestination(icon: Icon(Icons.medication_outlined), selectedIcon: Icon(Icons.medication), label: Text('Medications')),
              NavigationRailDestination(icon: Icon(Icons.folder_open_outlined), selectedIcon: Icon(Icons.folder), label: Text('Documents')),
              NavigationRailDestination(icon: Icon(Icons.document_scanner_outlined), selectedIcon: Icon(Icons.document_scanner), label: Text('Rx Scanner')),
              NavigationRailDestination(icon: Icon(Icons.local_hospital_outlined), selectedIcon: Icon(Icons.local_hospital), label: Text('Doctors')),
              NavigationRailDestination(icon: Icon(Icons.psychology_outlined), selectedIcon: Icon(Icons.psychology), label: Text('AI Advisor')),
              NavigationRailDestination(icon: Icon(Icons.watch_outlined), selectedIcon: Icon(Icons.watch), label: Text('Smartwatch')),
              NavigationRailDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: Text('Timeline')),
              NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
            ],
          ),

          const VerticalDivider(width: 1, color: AppColors.cardBorder),

          // Main Screen Content
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
