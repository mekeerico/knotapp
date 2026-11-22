import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/knot_image.dart';
import '../../auth/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _enquiries = [];
  List<Map<String, dynamic>> _alerts = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        dio.get(ApiEndpoints.adminUsers),
        dio.get(ApiEndpoints.adminEnquiries),
        dio.get(ApiEndpoints.adminSystemAlerts),
      ]);

      final usersRaw = results[0].data;
      final enquiriesRaw = results[1].data;
      final alertsRaw = results[2].data;

      if (!mounted) return;
      setState(() {
        _users = usersRaw is List
            ? usersRaw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _enquiries = enquiriesRaw is List
            ? enquiriesRaw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _alerts = alertsRaw is List
            ? alertsRaw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load admin data. Ensure you are signed in as Admin.';
        _isLoading = false;
      });
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : const Color(0xFF1F2937),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleSuspendUser(Map<String, dynamic> user) async {
    final id = user['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final nextState = !(user['isSuspended'] == true);

    try {
      final dio = ref.read(dioProvider);
      await dio.patch(
        '${ApiEndpoints.adminUsers}/$id/suspend',
        data: {'isSuspended': nextState},
      );
      _showSnack(nextState ? 'User suspended.' : 'User unsuspended.');
      await _loadAllData();
    } catch (_) {
      _showSnack('Failed to update user status.', isError: true);
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final id = user['id']?.toString() ?? '';
    final email = user['email']?.toString() ?? 'this user';
    if (id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121721),
        title: const Text('Delete User?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Permanently delete $email? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('${ApiEndpoints.adminUsers}/$id');
      _showSnack('User deleted.');
      await _loadAllData();
    } catch (_) {
      _showSnack('Failed to delete user.', isError: true);
    }
  }

  Future<void> _respondToEnquiry(Map<String, dynamic> ticket) async {
    final id = ticket['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final controller = TextEditingController(
      text: ticket['adminResponse']?.toString() ?? '',
    );

    final responseText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121721),
        title: Text(
          'Reply to ${ticket['userName'] ?? ticket['userEmail'] ?? 'User'}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Write your response (also emailed to the user)...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0A0E14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.champagneGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );

    if (responseText == null || responseText.isEmpty) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch(
        '${ApiEndpoints.adminEnquiries}/$id/respond',
        data: {'adminResponse': responseText},
      );
      _showSnack('Response saved and emailed to user.');
      await _loadAllData();
    } catch (_) {
      _showSnack('Failed to send response.', isError: true);
    }
  }

  Future<void> _resolveAlert(String id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('${ApiEndpoints.adminSystemAlerts}/$id/resolve');
      _showSnack('Alert marked as resolved.');
      await _loadAllData();
    } catch (_) {
      _showSnack('Failed to resolve alert.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isAdmin = currentUser?.role.toUpperCase() == 'ADMIN';

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.obsidianBlack,
        appBar: AppBar(
          backgroundColor: AppColors.obsidianBlack,
          title: const Text('Admin Access Required'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: AppColors.champagneGold, size: 48),
                const SizedBox(height: 16),
                Text(
                  'This area is restricted to KNOT administrators.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final verifiedCount = _users.where((u) => u['isVerified'] == true).length;
    final unverifiedCount = _users.length - verifiedCount;
    final openEnquiries = _enquiries.where((e) => e['status'] != 'RESPONDED' && e['status'] != 'RESOLVED').length;
    final unresolvedAlerts = _alerts.where((a) => a['resolved'] != true).length;

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: AppColors.obsidianBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: AppColors.champagneGold, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/discovery');
            }
          },
          tooltip: 'Switch to App View',
        ),
        title: Text(
          'ADMIN COMMAND CENTER',
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.champagneGold,
            letterSpacing: 1.4,
            fontSize: 15,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.champagneGold),
            onPressed: _loadAllData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/auth?mode=login');
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.champagneGold,
          labelColor: AppColors.champagneGold,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: [
            const Tab(text: 'Overview'),
            Tab(text: 'Users (${_users.length})'),
            Tab(text: 'Enquiries ($openEnquiries)'),
            Tab(text: 'Alerts ($unresolvedAlerts)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.champagneGold),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadAllData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(
                      totalUsers: _users.length,
                      verifiedCount: verifiedCount,
                      unverifiedCount: unverifiedCount,
                      openEnquiries: openEnquiries,
                      unresolvedAlerts: unresolvedAlerts,
                    ),
                    _buildUsersTab(),
                    _buildEnquiriesTab(),
                    _buildAlertsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab({
    required int totalUsers,
    required int verifiedCount,
    required int unverifiedCount,
    required int openEnquiries,
    required int unresolvedAlerts,
  }) {
    return RefreshIndicator(
      color: AppColors.champagneGold,
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _statCard('Total Members', '$totalUsers', Icons.people_outline, AppColors.champagneGold),
              _statCard('Verified', '$verifiedCount', Icons.verified_user_outlined, const Color(0xFF34D399)),
              _statCard('Unverified', '$unverifiedCount', Icons.pending_outlined, const Color(0xFFFBBF24)),
              _statCard('Open Enquiries', '$openEnquiries', Icons.support_agent_rounded, const Color(0xFF60A5FA)),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  unresolvedAlerts > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  color: unresolvedAlerts > 0 ? Colors.redAccent : const Color(0xFF34D399),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unresolvedAlerts > 0
                            ? '$unresolvedAlerts Active System Alert(s)'
                            : 'All Systems Operational',
                        style: AppTypography.labelLarge.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Alerts also sent to johnmeke2013@gmail.com',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(3),
                  child: const Text('View', style: TextStyle(color: AppColors.champagneGold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'AUTONOMOUS AUTOMATION (ZERO MANUAL WORK)',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white54,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _autonomousStatusTile(
            icon: Icons.mark_email_unread_outlined,
            title: 'Daily Verification Reminders',
            subtitle: 'Runs automatically every 24h per unverified user via in-app & email.',
          ),
          const SizedBox(height: 10),
          _autonomousStatusTile(
            icon: Icons.system_update_outlined,
            title: 'Play Store Release Monitor',
            subtitle: 'Automatically detects new Google Play publications & notifies all users via in-app & email.',
          ),
          const SizedBox(height: 10),
          _autonomousStatusTile(
            icon: Icons.health_and_safety_outlined,
            title: 'Developer Error & Health Watchdog',
            subtitle: 'Monitors API, database & public endpoints every 5 min and alerts johnmeke2013@gmail.com automatically.',
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accent) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: accent, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _autonomousStatusTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF34D399), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    _badge('AUTO • ACTIVE', const Color(0xFF34D399)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white54,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final filtered = _users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: AppColors.champagneGold, size: 18),
              filled: true,
              fillColor: const Color(0xFF121721),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.champagneGold,
            onRefresh: _loadAllData,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final u = filtered[index];
                final fullName = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
                final email = u['email']?.toString() ?? '';
                final isVerified = u['isVerified'] == true;
                final isSuspended = u['isSuspended'] == true;
                final isPremium = u['isPremium'] == true;
                final images = u['profileImages'] is List ? (u['profileImages'] as List) : [];
                final photoUrl = images.isNotEmpty && images.first is Map
                    ? images.first['url']?.toString()
                    : u['selfieUrl']?.toString();

                return GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF1F2937),
                            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                ? KnotImage.resolveProvider(photoUrl)
                                : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? const Icon(Icons.person, color: Colors.white54, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName.isEmpty ? 'Unnamed Member' : fullName,
                                  style: AppTypography.labelLarge.copyWith(color: Colors.white, fontSize: 13.5),
                                ),
                                Text(
                                  email,
                                  style: AppTypography.bodySmall.copyWith(color: Colors.white54, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _badge(
                            isVerified ? 'VERIFIED' : 'UNVERIFIED',
                            isVerified ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                          ),
                          if (isPremium) _badge('PREMIUM', AppColors.champagneGold),
                          if (isSuspended) _badge('SUSPENDED', Colors.redAccent),
                          if (u['role'] == 'ADMIN') _badge('ADMIN', const Color(0xFF818CF8)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _toggleSuspendUser(u),
                            icon: Icon(
                              isSuspended ? Icons.check_circle_outline : Icons.block,
                              size: 16,
                              color: isSuspended ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                            ),
                            label: Text(
                              isSuspended ? 'Unsuspend' : 'Suspend',
                              style: TextStyle(
                                color: isSuspended ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (u['role'] != 'ADMIN')
                            TextButton.icon(
                              onPressed: () => _deleteUser(u),
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                              label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnquiriesTab() {
    if (_enquiries.isEmpty) {
      return const Center(
        child: Text('No support enquiries yet.', style: TextStyle(color: Colors.white54)),
      );
    }

    return RefreshIndicator(
      color: AppColors.champagneGold,
      onRefresh: _loadAllData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _enquiries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final e = _enquiries[index];
          final status = e['status']?.toString() ?? 'OPEN';
          final isOpen = status == 'OPEN';

          return GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        e['subject']?.toString() ?? 'Support Ticket',
                        style: AppTypography.labelLarge.copyWith(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    _badge(status, isOpen ? const Color(0xFFFBBF24) : const Color(0xFF34D399)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${e['userName'] ?? 'User'} • ${e['userEmail'] ?? ''} • ${e['category'] ?? ''}',
                  style: AppTypography.bodySmall.copyWith(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  e['message']?.toString() ?? '',
                  style: AppTypography.bodySmall.copyWith(color: Colors.white.withOpacity(0.88), height: 1.4),
                ),
                if (e['adminResponse'] != null && e['adminResponse'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.champagneGold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Admin reply: ${e['adminResponse']}',
                      style: const TextStyle(color: AppColors.champagneGold, fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _respondToEnquiry(e),
                    icon: const Icon(Icons.reply_rounded, size: 16, color: AppColors.champagneGold),
                    label: Text(
                      isOpen ? 'Respond' : 'Update Reply',
                      style: const TextStyle(color: AppColors.champagneGold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlertsTab() {
    if (_alerts.isEmpty) {
      return const Center(
        child: Text('No system alerts recorded.', style: TextStyle(color: Colors.white54)),
      );
    }

    return RefreshIndicator(
      color: AppColors.champagneGold,
      onRefresh: _loadAllData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final a = _alerts[index];
          final severity = a['severity']?.toString() ?? 'ERROR';
          final resolved = a['resolved'] == true;
          final color = severity == 'CRITICAL' || severity == 'ERROR'
              ? Colors.redAccent
              : severity == 'WARNING'
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFF38BDF8);

          return GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _badge(severity, color),
                    const SizedBox(width: 8),
                    if (resolved) _badge('RESOLVED', const Color(0xFF34D399)),
                    const Spacer(),
                    Text(
                      a['source']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  a['title']?.toString() ?? 'Alert',
                  style: AppTypography.labelLarge.copyWith(color: Colors.white, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  a['message']?.toString() ?? '',
                  style: AppTypography.bodySmall.copyWith(color: Colors.white70, height: 1.4),
                ),
                if (a['details'] != null && a['details'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      a['details'].toString(),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
                if (!resolved) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _resolveAlert(a['id'].toString()),
                      icon: const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF34D399)),
                      label: const Text(
                        'Mark Resolved',
                        style: TextStyle(color: Color(0xFF34D399), fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
