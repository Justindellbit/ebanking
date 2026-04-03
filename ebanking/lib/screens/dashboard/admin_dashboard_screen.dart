import 'package:ebanking/models/audit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_admin.dart';
import '../../models/account.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {

  final _adminService = AdminService();
  final _authService  = AuthService();

  late TabController _tabController;
  String? _username;

  // Data
  List<UserAdminModel> _users    = [];
  List<Account>        _accounts = [];
  List<AuditLogModel>  _logs     = [];

  bool _loadingUsers    = true;
  bool _loadingAccounts = true;
  bool _loadingLogs     = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInitial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    _username = await _authService.getSavedUsername();
    _loadUsers();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0: if (_users.isEmpty) _loadUsers(); break;
      case 1: if (_accounts.isEmpty) _loadAccounts(); break;
      case 2: if (_logs.isEmpty) _loadLogs(); break;
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    final data = await _adminService.getAllUsers();
    if (!mounted) return;
    setState(() { _users = data; _loadingUsers = false; });
  }

  Future<void> _loadAccounts() async {
    setState(() => _loadingAccounts = true);
    final data = await _adminService.getAllAccounts();
    if (!mounted) return;
    setState(() { _accounts = data; _loadingAccounts = false; });
  }

  Future<void> _loadLogs() async {
    setState(() => _loadingLogs = true);
    final data = await _adminService.getAuditLogs();
    if (!mounted) return;
    setState(() { _logs = data; _loadingLogs = false; });
  }

  Future<void> _toggleBlock(Account account) async {
    HapticFeedback.mediumImpact();
    final isBlocked = account.status == 'BLOCKED';
    final success = isBlocked
        ? await _adminService.unblockAccount(account.id)
        : await _adminService.blockAccount(account.id);

    if (!mounted) return;
    if (success) {
      _showSnack(
        isBlocked
            ? 'Account ${account.number} unblocked'
            : 'Account ${account.number} blocked',
        isBlocked ? const Color(0xFF3DBA7B) : const Color(0xFFE07070),
      );
      _loadAccounts();
    } else {
      _showSnack('Operation failed', const Color(0xFFB03A3A));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUsersTab(),
                  _buildAccountsTab(),
                  _buildLogsTab(),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFC9A84C), Color(0xFFE8C97A)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Admin Panel',
                  style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w700)),
              Text(_username ?? '',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ]),
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.white54, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFC9A84C), Color(0xFFE8C97A)]),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(icon: Icon(Icons.people_rounded, size: 16), text: 'Users'),
          Tab(icon: Icon(Icons.account_balance_rounded, size: 16),
              text: 'Accounts'),
          Tab(icon: Icon(Icons.history_rounded, size: 16), text: 'Audit'),
        ],
      ),
    );
  }

  // ── Tab 1: Users ─────────────────────────────────────────
  Widget _buildUsersTab() {
    if (_loadingUsers) {
      return const Center(child: CircularProgressIndicator(
          color: Color(0xFFC9A84C)));
    }
    if (_users.isEmpty) {
      return _emptyState('No users found', Icons.people_outline_rounded);
    }
    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: const Color(0xFFC9A84C),
      backgroundColor: const Color(0xFF1A2540),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        itemCount: _users.length,
        itemBuilder: (_, i) => _UserCard(user: _users[i]),
      ),
    );
  }

  // ── Tab 2: Accounts ──────────────────────────────────────
  Widget _buildAccountsTab() {
    if (_loadingAccounts) {
      return const Center(child: CircularProgressIndicator(
          color: Color(0xFFC9A84C)));
    }
    if (_accounts.isEmpty) {
      return _emptyState(
          'No accounts found', Icons.account_balance_wallet_outlined);
    }
    return RefreshIndicator(
      onRefresh: _loadAccounts,
      color: const Color(0xFFC9A84C),
      backgroundColor: const Color(0xFF1A2540),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        itemCount: _accounts.length,
        itemBuilder: (_, i) => _AdminAccountCard(
          account: _accounts[i],
          onToggleBlock: () => _toggleBlock(_accounts[i]),
        ),
      ),
    );
  }

  // ── Tab 3: Audit Logs ────────────────────────────────────
  Widget _buildLogsTab() {
    if (_loadingLogs) {
      return const Center(child: CircularProgressIndicator(
          color: Color(0xFFC9A84C)));
    }
    if (_logs.isEmpty) {
      return _emptyState('No audit logs', Icons.history_outlined);
    }
    return RefreshIndicator(
      onRefresh: _loadLogs,
      color: const Color(0xFFC9A84C),
      backgroundColor: const Color(0xFF1A2540),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        itemCount: _logs.length,
        itemBuilder: (_, i) => _AuditLogCard(log: _logs[i]),
      ),
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white12, size: 48),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: Colors.white24)),
      ],
    ));
  }
}

// ─── User Card ────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserAdminModel user;
  const _UserCard({required this.user});

  Color _roleColor(String role) {
    switch (role) {
      case 'ROLE_ADMIN':  return const Color(0xFFC9A84C);
      case 'ROLE_TELLER': return const Color(0xFF4A90D9);
      default:            return const Color(0xFF3DBA7B);
    }
  }

  String _roleLabel(String role) =>
      role.replaceFirst('ROLE_', '');

  @override
  Widget build(BuildContext context) {
    final role = user.primaryRole;
    final color = _roleColor(role);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              user.firstName.isNotEmpty
                  ? user.firstName[0].toUpperCase()
                  : user.username[0].toUpperCase(),
              style: TextStyle(color: color,
                  fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.fullName.isNotEmpty ? user.fullName : user.username,
                style: const TextStyle(color: Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w600)),
            Text(user.email,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_roleLabel(role),
                style: TextStyle(color: color, fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Text('${user.accountCount} account${user.accountCount != 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.white24, fontSize: 10)),
        ]),
      ]),
    );
  }
}

// ─── Admin Account Card ───────────────────────────────────
class _AdminAccountCard extends StatelessWidget {
  final Account      account;
  final VoidCallback onToggleBlock;
  const _AdminAccountCard(
      {required this.account, required this.onToggleBlock});

  @override
  Widget build(BuildContext context) {
    final isBlocked = account.status == 'BLOCKED';
    final last4 = account.number.length > 4
        ? account.number.substring(account.number.length - 4)
        : account.number;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBlocked
              ? const Color(0xFFE07070).withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isBlocked
                ? const Color(0xFFE07070).withOpacity(0.1)
                : const Color(0xFF3DBA7B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.account_balance_rounded,
              color: isBlocked
                  ? const Color(0xFFE07070)
                  : const Color(0xFF3DBA7B),
              size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•••• $last4',
                style: const TextStyle(color: Colors.white,
                    fontSize: 13, fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            Text('${account.accountType}  •  ${account.currency} '
                '${account.balance.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        )),
        GestureDetector(
          onTap: onToggleBlock,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isBlocked
                  ? const Color(0xFF3DBA7B).withOpacity(0.1)
                  : const Color(0xFFE07070).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isBlocked
                    ? const Color(0xFF3DBA7B).withOpacity(0.4)
                    : const Color(0xFFE07070).withOpacity(0.4),
              ),
            ),
            child: Text(
              isBlocked ? 'Unblock' : 'Block',
              style: TextStyle(
                color: isBlocked
                    ? const Color(0xFF3DBA7B)
                    : const Color(0xFFE07070),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Audit Log Card ───────────────────────────────────────
class _AuditLogCard extends StatelessWidget {
  final AuditLogModel log;
  const _AuditLogCard({required this.log});

  Color _actionColor(String action) {
    if (action.contains('BLOCK'))   return const Color(0xFFE07070);
    if (action.contains('DEPOSIT')) return const Color(0xFF3DBA7B);
    if (action.contains('WITHDRAW') ||
        action.contains('TRANSFER')) return const Color(0xFF6B5CE7);
    if (action.contains('LOGIN') ||
        action.contains('REGISTER')) return const Color(0xFF4A90D9);
    return const Color(0xFFC9A84C);
  }

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(log.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 8, height: 8, margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Text(log.action,
                  style: TextStyle(color: color, fontSize: 12,
                      fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              Text(log.createdAt,
                  style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ]),
            const SizedBox(height: 3),
            Text('@${log.username}',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            if (log.description != null && log.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(log.description!,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (log.ipAddress != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    color: Colors.white24, size: 11),
                const SizedBox(width: 3),
                Text(log.ipAddress!,
                    style: const TextStyle(color: Colors.white24, fontSize: 10)),
              ]),
            ],
          ],
        )),
      ]),
    );
  }
}