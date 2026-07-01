import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';

const _avatarEmojis = [
  '🧑‍🎓', '🧑‍💻', '🧑‍🔬', '🧑‍🎨', '🧑‍🚀', '🧑‍🏫',
  '🧑‍⚕️', '🧑‍🎵', '🧑‍🏋️', '🧑‍🍳', '🦸', '🦹',
  '🐱', '🐶', '🦊', '🐼', '🐨', '🦄',
  '🌟', '🔥', '💎', '🎯', '🎮', '⚡',
];

class ProfileTab extends StatefulWidget {
  final AuthService authService;
  final ProfileService profileService;

  const ProfileTab({
    super.key,
    required this.authService,
    required this.profileService,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  User? _user;
  bool _loading = true;
  String? _error;

  bool _editing = false;
  bool _saving = false;
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  String? _pendingAvatar;

  bool _showPasswordSection = false;
  bool _changingPassword = false;
  late TextEditingController _currentPwCtrl;
  late TextEditingController _newPwCtrl;

  bool _showEmailSection = false;
  bool _changingEmail = false;
  late TextEditingController _currentPwForEmailCtrl;
  late TextEditingController _newEmailCtrl;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _currentPwCtrl = TextEditingController();
    _newPwCtrl = TextEditingController();
    _currentPwForEmailCtrl = TextEditingController();
    _newEmailCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _currentPwForEmailCtrl.dispose();
    _newEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _editing = false;
    });
    try {
      final user = await widget.profileService.getProfile();
      if (mounted) {
        setState(() { _user = user; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  void _enterEdit() {
    _firstNameCtrl.text = _user?.firstName ?? '';
    _lastNameCtrl.text = _user?.lastName ?? '';
    _pendingAvatar = _user?.avatarValue;
    setState(() => _editing = true);
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _pendingAvatar = null;
    });
  }

  Future<void> _saveProfile() async {
    final fn = _firstNameCtrl.text.trim();
    final ln = _lastNameCtrl.text.trim();
    if (fn.isEmpty || ln.isEmpty) return;

    setState(() => _saving = true);
    try {
      await widget.profileService.updateProfile(
        firstName: fn,
        lastName: ln,
        avatarType: _pendingAvatar != null ? 'icon' : null,
        avatarValue: _pendingAvatar,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final cp = _currentPwCtrl.text;
    final np = _newPwCtrl.text;
    if (cp.isEmpty || np.length < 8) return;

    setState(() => _changingPassword = true);
    try {
      final msg = await widget.profileService.changePassword(
        currentPassword: cp,
        newPassword: np,
      );
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  Future<void> _requestEmailChange() async {
    final cp = _currentPwForEmailCtrl.text;
    final ne = _newEmailCtrl.text.trim();
    if (cp.isEmpty || ne.isEmpty) return;

    setState(() => _changingEmail = true);
    try {
      final data = await widget.profileService.requestEmailChange(
        currentPassword: cp,
        newEmail: ne,
      );
      _currentPwForEmailCtrl.clear();
      _newEmailCtrl.clear();
      if (mounted) {
        final debugToken = data['debugToken'] as String?;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Verification sent')),
        );
        if (debugToken != null) {
          _showVerifyDialog(debugToken);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _changingEmail = false);
    }
  }

  void _showVerifyDialog(String token) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify New Email',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A verification token was generated. Paste it below to confirm your new email.',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: token),
              readOnly: true,
              maxLines: 2,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _verifyEmail(token);
            },
            child: const Text('CONFIRM & VERIFY',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyEmail(String token) async {
    try {
      final msg = await widget.profileService.verifyNewEmail(token: token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        await widget.authService.logout();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _onBadgeTap(String slug) async {
    try {
      await widget.profileService.selectBadge(slug);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('😎', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('MY PROFILE',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
        actions: [
          if (!_editing && _user != null)
            IconButton(
              icon: const Text('✏️', style: TextStyle(fontSize: 20)),
              onPressed: _enterEdit,
              tooltip: 'Edit profile',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😎', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Loading profile...',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😵', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return const Center(
        child: Text('😴 Could not load profile.',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary)),
      );
    }

    final u = _user!;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAvatarSection(u),
            const SizedBox(height: 20),
            if (_editing) _buildEditForm(u),
            _buildInfoCard(u),
            const SizedBox(height: 20),
            _buildBadgesSection(u),
            const SizedBox(height: 20),
            _buildChangePasswordSection(),
            const SizedBox(height: 20),
            _buildChangeEmailSection(),
            const SizedBox(height: 28),
            _buildLogoutButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(User u) {
    final selectedBadge = u.selectedBadgeSlug != null
        ? u.badges.firstWhere(
            (b) => b['slug'] == u.selectedBadgeSlug,
            orElse: () => <String, dynamic>{},
          )
        : <String, dynamic>{};

    final hasSelectedBadge = selectedBadge.isNotEmpty;
    final badgeName = hasSelectedBadge ? selectedBadge['name'] as String? : null;
    final avatarEmoji = _pendingAvatar ?? u.avatarValue;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: _editing ? _showAvatarPicker : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: _editing ? AppColors.secondary : AppColors.outline,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_editing ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.4),
                      blurRadius: 0,
                      offset: const Offset(6, 6),
                    ),
                  ],
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: _editing
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                avatarEmoji ?? '🧑‍🎓',
                                style: const TextStyle(fontSize: 40),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'TAP TO CHANGE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.secondary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            avatarEmoji ?? u.firstName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: avatarEmoji != null ? 42 : 38,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            if (hasSelectedBadge)
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outline, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.5),
                        blurRadius: 0,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('🏅', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          u.displayName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          u.email,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        if (badgeName != null) ...[
          const SizedBox(height: 6),
          Text(
            '🏅 $badgeName',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
            ),
          ),
        ],
      ],
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.outline, width: 3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'PICK AN AVATAR',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _avatarEmojis.map((emoji) {
                final isSelected = _pendingAvatar == emoji;
                return GestureDetector(
                  onTap: () {
                    setState(() => _pendingAvatar = emoji);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.secondary.withValues(alpha: 0.2) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.secondary : AppColors.outline,
                        width: isSelected ? 3 : 2,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(User u) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.outline, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.4),
              blurRadius: 0,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Text('✏️', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'EDIT PROFILE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _firstNameCtrl,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.outline, width: 2.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.secondary, width: 3),
                  ),
                  filled: true,
                  fillColor: AppColors.secondary.withValues(alpha: 0.03),
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lastNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.outline, width: 2.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.secondary, width: 3),
                  ),
                  filled: true,
                  fillColor: AppColors.secondary.withValues(alpha: 0.03),
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _saveProfile,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shadowColor: AppColors.secondary.withValues(alpha: 0.5),
                        minimumSize: const Size(0, 48),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: Colors.white),
                            )
                          : const Text('💾 SAVE',
                              style: TextStyle(letterSpacing: 1.5)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _cancelEdit,
                      child: const Text('CANCEL'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(User u) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              '🔑', 'Role',
              u.role == 'admin' ? 'ADMIN' : 'USER',
              u.role == 'admin' ? AppColors.secondary : AppColors.primary,
            ),
            const Divider(height: 24, color: AppColors.outline),
            _buildInfoRow(
              u.emailVerified ? '✅' : '⏳',
              'Email',
              u.emailVerified ? 'Verified' : 'Not verified',
              u.emailVerified ? AppColors.success : AppColors.secondary,
            ),
            const Divider(height: 24, color: AppColors.outline),
            _buildInfoRow(
              '📅', 'Joined',
              _formatDate(u.createdAt),
              AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final m = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${m[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildBadgesSection(User u) {
    if (u.badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.outline, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.2),
              blurRadius: 0,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              const Text(
                'NO BADGES YET',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Answer questions to earn badges!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outline, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.3),
                blurRadius: 0,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'EARNED BADGES (${u.badges.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: u.badges.map((b) {
            final name = b['name'] as String? ?? '';
            final slug = b['slug'] as String? ?? '';
            final colorHex = b['color'] as String?;
            final isSelected = u.selectedBadgeSlug == slug;
            return _buildBadgeChip(name, slug, colorHex, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBadgeChip(String name, String slug, String? colorHex, bool isSelected) {
    final color = _parseColor(colorHex) ?? AppColors.secondary;

    return GestureDetector(
      onTap: () => _onBadgeTap(slug),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(isSelected ? 3 : 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.outline,
            width: isSelected ? 3 : 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.5),
                    blurRadius: 0,
                    offset: const Offset(3, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 0,
                    offset: const Offset(2, 2),
                  ),
                ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppColors.textPrimary : color,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                const Text('✓', style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      final h = hex.replaceFirst('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return null;
  }

  Widget _buildChangePasswordSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showPasswordSection = !_showPasswordSection),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _showPasswordSection ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.outline, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 0,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'CHANGE PASSWORD',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Icon(
                    _showPasswordSection ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showPasswordSection) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.outline, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 0,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _currentPwCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.outline, width: 2.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 3),
                      ),
                      filled: true,
                      fillColor: AppColors.primary.withValues(alpha: 0.03),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPwCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password (min 8 chars)',
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.outline, width: 2.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 3),
                      ),
                      filled: true,
                      fillColor: AppColors.primary.withValues(alpha: 0.03),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _changingPassword ? null : _changePassword,
                    child: _changingPassword
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 3, color: Colors.white),
                          )
                        : const Text('UPDATE PASSWORD',
                            style: TextStyle(letterSpacing: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChangeEmailSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showEmailSection = !_showEmailSection),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _showEmailSection ? AppColors.secondary : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.outline, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  blurRadius: 0,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Text('📧', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'CHANGE EMAIL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Icon(
                    _showEmailSection ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showEmailSection) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.outline, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  blurRadius: 0,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _currentPwForEmailCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.outline, width: 2.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.secondary, width: 3),
                      ),
                      filled: true,
                      fillColor: AppColors.secondary.withValues(alpha: 0.03),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'New Email',
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.outline, width: 2.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.secondary, width: 3),
                      ),
                      filled: true,
                      fillColor: AppColors.secondary.withValues(alpha: 0.03),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _changingEmail ? null : _requestEmailChange,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shadowColor: AppColors.secondary.withValues(alpha: 0.5),
                    ),
                    child: _changingEmail
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 3, color: Colors.white),
                          )
                        : const Text('SEND VERIFICATION',
                            style: TextStyle(letterSpacing: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        await widget.authService.logout();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      },
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.4),
              blurRadius: 0,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🚪', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'LOG OUT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
