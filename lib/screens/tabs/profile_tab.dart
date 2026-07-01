import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/profile_cubit.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

const _avatarEmojis = [
  '🧑‍🎓', '🧑‍💻', '🧑‍🔬', '🧑‍🎨', '🧑‍🚀', '🧑‍🏫',
  '🧑‍⚕️', '🧑‍🎵', '🧑‍🏋️', '🧑‍🍳', '🦸', '🦹',
  '🐱', '🐶', '🦊', '🐼', '🐨', '🦄',
  '🌟', '🔥', '💎', '🎯', '🎮', '⚡',
];

class ProfileTab extends StatelessWidget {
  final AuthService authService;

  const ProfileTab({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
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
              if (!state.editing && state.user != null)
                IconButton(
                  icon: const Text('✏️', style: TextStyle(fontSize: 20)),
                  onPressed: () => context.read<ProfileCubit>().enterEdit(),
                  tooltip: 'Edit profile',
                ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProfileState state) {
    if (state.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('😎', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text('Loading profile...',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😵', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<ProfileCubit>().load(),
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.user == null) {
      return const Center(
        child: Text('😴 Could not load profile.',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary)),
      );
    }

    final u = state.user!;

    return RefreshIndicator(
      onRefresh: () => context.read<ProfileCubit>().load(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAvatarSection(context, state, u),
            const SizedBox(height: 20),
            if (state.editing) _buildEditForm(context, state, u),
            _buildInfoCard(u),
            const SizedBox(height: 20),
            _buildBadgesSection(context, u),
            const SizedBox(height: 20),
            _buildChangePasswordSection(context, state),
            const SizedBox(height: 20),
            _buildChangeEmailSection(context, state),
            const SizedBox(height: 28),
            _buildLogoutButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, ProfileState state, User u) {
    final selectedBadge = u.selectedBadgeSlug != null
        ? u.badges.firstWhere(
            (b) => b['slug'] == u.selectedBadgeSlug,
            orElse: () => <String, dynamic>{},
          )
        : <String, dynamic>{};
    final hasSelectedBadge = selectedBadge.isNotEmpty;
    final badgeName = hasSelectedBadge ? selectedBadge['name'] as String? : null;
    final avatarEmoji = u.avatarValue;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: state.editing ? () => _showAvatarPicker(context) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: state.editing ? AppColors.secondary : AppColors.outline,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (state.editing ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.4),
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
                    child: state.editing
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(avatarEmoji ?? '🧑‍🎓', style: const TextStyle(fontSize: 40)),
                              const SizedBox(height: 2),
                              const Text('TAP TO CHANGE',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.secondary, letterSpacing: 1)),
                            ],
                          )
                        : Text(avatarEmoji ?? u.firstName[0].toUpperCase(),
                            style: TextStyle(fontSize: avatarEmoji != null ? 42 : 38, fontWeight: FontWeight.w900, color: AppColors.primary)),
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
                      BoxShadow(color: AppColors.gold.withValues(alpha: 0.5), blurRadius: 0, offset: const Offset(2, 2)),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Text('🏅', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(u.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text(u.email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        if (badgeName != null) ...[
          const SizedBox(height: 6),
          Text('🏅 $badgeName', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.gold)),
        ],
      ],
    );
  }

  void _showAvatarPicker(BuildContext context) {
    final pending = ValueNotifier<String?>(null);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ValueListenableBuilder<String?>(
        valueListenable: pending,
        builder: (_, val, _) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: AppColors.outline, width: 3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.outline, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 16),
                const Text('PICK AN AVATAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 2)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _avatarEmojis.map((emoji) {
                    final isSelected = val == emoji;
                    return GestureDetector(
                      onTap: () {
                        context.read<ProfileCubit>().saveProfile(
                          context.read<ProfileCubit>().state.user?.firstName ?? '',
                          context.read<ProfileCubit>().state.user?.lastName ?? '',
                          'icon',
                          emoji,
                        );
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.secondary.withValues(alpha: 0.2) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.secondary : AppColors.outline, width: isSelected ? 3 : 2),
                        ),
                        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditForm(BuildContext context, ProfileState state, User u) {
    final fnCtrl = TextEditingController(text: u.firstName);
    final lnCtrl = TextEditingController(text: u.lastName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.outline, width: 3),
          boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.4), blurRadius: 0, offset: const Offset(4, 4))],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(children: [
                Text('✏️', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('EDIT PROFILE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1.5)),
              ]),
              const SizedBox(height: 14),
              TextField(
                controller: fnCtrl,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  labelStyle: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.outline, width: 2.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.secondary, width: 3)),
                  filled: true,
                  fillColor: Color(0x08FF6D00),
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lnCtrl,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  labelStyle: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.outline, width: 2.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.secondary, width: 3)),
                  filled: true,
                  fillColor: Color(0x08FF6D00),
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: state.saving
                          ? null
                          : () async {
                              try {
                                await context.read<ProfileCubit>().saveProfile(
                                  fnCtrl.text.trim(),
                                  lnCtrl.text.trim(),
                                  null, null,
                                );
                                fnCtrl.dispose();
                                lnCtrl.dispose();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                                  );
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shadowColor: AppColors.secondary.withValues(alpha: 0.5),
                        minimumSize: const Size(0, 48),
                      ),
                      child: state.saving
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                          : const Text('💾 SAVE', style: TextStyle(letterSpacing: 1.5)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.saving ? null : () => context.read<ProfileCubit>().cancelEdit(),
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
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 0, offset: const Offset(4, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow('🔑', 'Role', u.role == 'admin' ? 'ADMIN' : 'USER', u.role == 'admin' ? AppColors.secondary : AppColors.primary),
            const Divider(height: 24, color: AppColors.outline),
            _infoRow(u.emailVerified ? '✅' : '⏳', 'Email', u.emailVerified ? 'Verified' : 'Not verified', u.emailVerified ? AppColors.success : AppColors.secondary),
            const Divider(height: 24, color: AppColors.outline),
            _infoRow('📅', 'Joined', _formatDate(u.createdAt), AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String emoji, String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: valueColor)),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${m[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildBadgesSection(BuildContext context, User u) {
    if (u.badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.outline, width: 3),
          boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.2), blurRadius: 0, offset: const Offset(4, 4))],
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text('🏅', style: TextStyle(fontSize: 40)),
              SizedBox(height: 8),
              Text('NO BADGES YET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1.5)),
              SizedBox(height: 4),
              Text('Answer questions to earn badges!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
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
            boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 0, offset: const Offset(3, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('EARNED BADGES (${u.badges.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1.5)),
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
            final color = _parseColor(colorHex) ?? AppColors.secondary;
            return GestureDetector(
              onTap: () async {
                try {
                  await context.read<ProfileCubit>().selectBadge(slug);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                  }
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.all(isSelected ? 3 : 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppColors.gold : AppColors.outline, width: isSelected ? 3 : 2.5),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.5), blurRadius: 0, offset: const Offset(3, 3))]
                      : [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 0, offset: const Offset(2, 2))],
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: isSelected ? Colors.white : color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isSelected ? AppColors.textPrimary : color)),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Text('✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.gold)),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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

  Widget _buildChangePasswordSection(BuildContext context, ProfileState state) {
    final cpCtrl = TextEditingController();
    final npCtrl = TextEditingController();
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.read<ProfileCubit>().togglePasswordSection(),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: state.showPasswordSection ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.outline, width: 3),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 0, offset: const Offset(4, 4))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('CHANGE PASSWORD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1.5))),
                  Icon(state.showPasswordSection ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
        if (state.showPasswordSection) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.outline, width: 3),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 0, offset: const Offset(4, 4))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: cpCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.outline, width: 2.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.primary, width: 3)),
                      filled: true,
                      fillColor: Color(0x089C27B0),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: npCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password (min 8 chars)',
                      labelStyle: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.outline, width: 2.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.primary, width: 3)),
                      filled: true,
                      fillColor: Color(0x089C27B0),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: state.changingPassword
                        ? null
                        : () async {
                            if (cpCtrl.text.isEmpty || npCtrl.text.length < 8) return;
                            try {
                              final msg = await context.read<ProfileCubit>().changePassword(cpCtrl.text, npCtrl.text);
                              cpCtrl.clear();
                              npCtrl.clear();
                              cpCtrl.dispose();
                              npCtrl.dispose();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg as String)));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                              }
                            }
                          },
                    child: state.changingPassword
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                        : const Text('UPDATE PASSWORD', style: TextStyle(letterSpacing: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChangeEmailSection(BuildContext context, ProfileState state) {
    final cpCtrl = TextEditingController();
    final neCtrl = TextEditingController();
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.read<ProfileCubit>().toggleEmailSection(),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: state.showEmailSection ? AppColors.secondary : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.outline, width: 3),
              boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.15), blurRadius: 0, offset: const Offset(4, 4))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Text('📧', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('CHANGE EMAIL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1.5))),
                  Icon(state.showEmailSection ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
        if (state.showEmailSection) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.outline, width: 3),
              boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.15), blurRadius: 0, offset: const Offset(4, 4))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: cpCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.outline, width: 2.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.secondary, width: 3)),
                      filled: true,
                      fillColor: Color(0x08FF6D00),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: neCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'New Email',
                      labelStyle: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.outline, width: 2.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.secondary, width: 3)),
                      filled: true,
                      fillColor: Color(0x08FF6D00),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: state.changingEmail
                        ? null
                        : () async {
                            if (cpCtrl.text.isEmpty || neCtrl.text.trim().isEmpty) return;
                            try {
                              final data = await context.read<ProfileCubit>().requestEmailChange(cpCtrl.text, neCtrl.text.trim());
                              cpCtrl.clear();
                              neCtrl.clear();
                              cpCtrl.dispose();
                              neCtrl.dispose();
                              if (context.mounted) {
                                final token = (data as Map<String, dynamic>)['debugToken'] as String?;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(data['message'] ?? 'Verification sent')),
                                );
                                if (token != null) _showVerifyDialog(context, token);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                              }
                            }
                          },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.secondary, shadowColor: AppColors.secondary.withValues(alpha: 0.5)),
                    child: state.changingEmail
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                        : const Text('SEND VERIFICATION', style: TextStyle(letterSpacing: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showVerifyDialog(BuildContext context, String token) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify New Email', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('A verification token was generated. Paste it below to confirm your new email.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: token),
              readOnly: true,
              maxLines: 2,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              decoration: const InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))), contentPadding: EdgeInsets.all(10)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final msg = await context.read<ProfileCubit>().verifyNewEmail(token);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg as String)));
                  await authService.logout();
                  if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                }
              }
            },
            child: const Text('CONFIRM & VERIFY', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await authService.logout();
        if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
      },
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline, width: 3),
          boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.4), blurRadius: 0, offset: const Offset(4, 4))],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🚪', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('LOG OUT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }
}
