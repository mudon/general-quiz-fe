import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/profile_cubit.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../subscription_screen.dart';

const _avatarEmojis = [
  '\u{1F9D1}\u200D\u{1F393}',
  '\u{1F9D1}\u200D\u{1F4BB}',
  '\u{1F9D1}\u200D\u{1F52C}',
  '\u{1F9D1}\u200D\u{1F3A8}',
  '\u{1F9D1}\u200D\u{1F680}',
  '\u{1F9D1}\u200D\u{1F3EB}',
  '\u{1F9D9}',
  '\u{1F9B8}',
  '\u{1F431}',
  '\u{1F436}',
  '\u{1F98A}',
  '\u{1F43C}',
  '\u{1F989}',
  '\u{1F984}',
  '\u{1F31F}',
  '\u{1F525}',
  '\u{1F48E}',
  '\u{1F3AF}',
  '\u{1F3AE}',
  '\u26A1',
];

class ProfileTab extends StatefulWidget {
  final AuthService authService;
  final SubscriptionService subscriptionService;

  const ProfileTab({
    super.key,
    required this.authService,
    required this.subscriptionService,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String _currency = 'myr';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: DeckColors.ink, width: 2)),
                color: DeckColors.paper,
              ),
              child: Row(
                children: [
                  Text('Profile',
                      style: DeckTheme.spaceGrotesk(fontSize: 17)),
                  const Spacer(),
                  if (!state.editing && state.user != null)
                    GestureDetector(
                      onTap: () =>
                          context.read<ProfileCubit>().enterEdit(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: DeckColors.graphiteFaint),
                        ),
                        child: Text('Edit',
                            style: DeckTheme.ibmPlexMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: DeckColors.graphite)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProfileState state) {
    if (state.loading) {
      return const Center(
        child: Text('Loading profile...',
            style: TextStyle(fontSize: 14, color: DeckColors.graphite)),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(state.error!,
                  textAlign: TextAlign.center,
                  style: DeckTheme.ibmPlexMono(color: DeckColors.graphite)),
              const SizedBox(height: 16),
              _btnPrimary('TRY AGAIN',
                  () => context.read<ProfileCubit>().load()),
            ],
          ),
        ),
      );
    }

    if (state.user == null) {
      return Center(
        child: Text('Could not load profile.',
            style: DeckTheme.spaceGrotesk(
                fontSize: 14, color: DeckColors.graphite)),
      );
    }

    final u = state.user!;

    return RefreshIndicator(
      onRefresh: () => context.read<ProfileCubit>().load(),
      color: DeckColors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAvatarSection(context, state, u),
            const SizedBox(height: 16),
            if (state.editing) _buildEditForm(context, state, u),
            _buildTierCard(context, u),
            const SizedBox(height: 16),
            _buildBadgesSection(context, u),
            const SizedBox(height: 16),
            _buildChangePasswordSection(context, state),
            const SizedBox(height: 12),
            _buildChangeEmailSection(context, state),
            const SizedBox(height: 20),
            _buildLogoutButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(
      BuildContext context, ProfileState state, User u) {
    final avatarEmoji = u.avatarValue ?? '\u{1F989}';

    return Column(
      children: [
        GestureDetector(
          onTap: state.editing ? () => _showAvatarPicker(context) : null,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: DeckColors.paperDark,
              shape: BoxShape.circle,
              border: Border.all(color: DeckColors.rule, width: 2),
            ),
            child: Center(
              child: Text(avatarEmoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(u.displayName,
            style: DeckTheme.spaceGrotesk(fontSize: 15)),
        const SizedBox(height: 2),
        Text(
          '${u.tier == 2 ? 'ALL ACCESS' : u.tier == 1 ? 'PREMIUM' : 'FREE'} TIER \u00B7 MEMBER SINCE ${_formatYear(u.createdAt)}',
          style: DeckTheme.ibmPlexMono(fontSize: 9),
        ),
      ],
    );
  }

  void _showAvatarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DeckColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: DeckColors.graphiteFaint,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 16),
            Text('PICK AN AVATAR',
                style: DeckTheme.spaceGrotesk(fontSize: 14)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _avatarEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () async {
                    await context.read<ProfileCubit>().saveProfile(
                          context.read<ProfileCubit>().state.user?.firstName ?? '',
                          context.read<ProfileCubit>().state.user?.lastName ?? '',
                          'icon',
                          emoji,
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: DeckColors.paperDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DeckColors.rule),
                    ),
                    child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(
      BuildContext context, ProfileState state, User u) {
    final fnCtrl = TextEditingController(text: u.firstName);
    final lnCtrl = TextEditingController(text: u.lastName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DeckColors.blueFaint,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: DeckColors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('EDIT PROFILE',
              style: DeckTheme.spaceGrotesk(
                  fontSize: 12, color: DeckColors.blue)),
          const SizedBox(height: 12),
          TextField(
            controller: fnCtrl,
            decoration: const InputDecoration(
              labelText: 'First Name',
            ),
            style: DeckTheme.literata(fontSize: 14),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: lnCtrl,
            decoration: const InputDecoration(
              labelText: 'Last Name',
            ),
            style: DeckTheme.literata(fontSize: 14),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _btnPrimary('SAVE', state.saving
                    ? null
                    : () async {
                        try {
                          await context.read<ProfileCubit>().saveProfile(
                                fnCtrl.text.trim(),
                                lnCtrl.text.trim(),
                                null,
                                null,
                              );
                          if (context.mounted) {
                            context.read<ProfileCubit>().cancelEdit();
                          }
                          fnCtrl.dispose();
                          lnCtrl.dispose();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(e.toString().replaceFirst('Exception: ', ''),
                                      style: DeckTheme.ibmPlexMono(
                                          color: DeckColors.paper, fontSize: 10))),
                            );
                          }
                        }
                      },
                    loading: state.saving),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _btnOutline('CANCEL',
                    () => context.read<ProfileCubit>().cancelEdit()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(BuildContext context, User u) {
    final tierName =
        u.tier == 2 ? 'All Access' : u.tier == 1 ? 'Premium' : 'Free';
    final tierEmoji = u.tier == 2
        ? '\u{1F451}'
        : u.tier == 1
            ? '\u2B50'
            : '\u{1F393}';

    return GestureDetector(
      onTap: () async {
        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => SubscriptionScreen(
              subscriptionService: widget.subscriptionService,
              currentTier: u.tier,
              currency: _currency,
            ),
          ),
        );
        if (context.mounted) {
          context.read<ProfileCubit>().load();
          if (paid == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Plan upgraded!',
                      style: DeckTheme.ibmPlexMono(
                          color: DeckColors.paper, fontSize: 10))),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DeckColors.ink,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Text(tierEmoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tierName,
                      style: DeckTheme.spaceGrotesk(
                          fontSize: 15, color: DeckColors.paper)),
                  const SizedBox(height: 2),
                  Text(
                    u.tier == 2
                        ? 'Unlimited categories'
                        : u.tier == 1
                            ? '10 categories'
                            : '3 categories',
                    style: DeckTheme.ibmPlexMono(
                        fontSize: 9, color: DeckColors.graphiteFaint),
                  ),
                ],
              ),
            ),
            if (u.tier < 2)
              Text('UPGRADE \u279C',
                  style: DeckTheme.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DeckColors.paper)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, User u) {
    if (u.badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DeckColors.paperDark,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: DeckColors.rule),
        ),
        child: Column(
          children: [
            const Text('\u{1F3C5}', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text('NO BADGES YET',
                style: DeckTheme.spaceGrotesk(fontSize: 14)),
            Text('Answer questions to earn badges!',
                style: DeckTheme.ibmPlexMono(fontSize: 9)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Badges earned'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: u.badges.map((b) {
            final name = b['name'] as String? ?? '';
            final slug = b['slug'] as String? ?? '';
            final colorHex = b['color'] as String?;
            final isSelected = u.selectedBadgeSlug == slug;
            final color = _parseColor(colorHex) ?? DeckColors.blue;

            return GestureDetector(
              onTap: () async {
                try {
                  await context.read<ProfileCubit>().selectBadge(slug);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(e.toString().replaceFirst('Exception: ', ''),
                              style: DeckTheme.ibmPlexMono(
                                  color: DeckColors.paper, fontSize: 10))),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DeckColors.yellowBg
                      : DeckColors.paperDark,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: isSelected
                          ? DeckColors.yellow
                          : DeckColors.rule,
                      width: isSelected ? 2 : 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(name,
                        style: DeckTheme.spaceGrotesk(
                            fontSize: 11, color: color)),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Text('\u2713',
                          style: TextStyle(
                              fontSize: 12,
                              color: DeckColors.yellow,
                              fontWeight: FontWeight.w700)),
                    ],
                  ],
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

  Widget _buildChangePasswordSection(
      BuildContext context, ProfileState state) {
    final cpCtrl = TextEditingController();
    final npCtrl = TextEditingController();
    return Column(
      children: [
        GestureDetector(
          onTap: () =>
              context.read<ProfileCubit>().togglePasswordSection(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: DeckColors.paperDark,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: DeckColors.rule),
            ),
            child: Row(
              children: [
                Text('CHANGE PASSWORD',
                    style: DeckTheme.spaceGrotesk(fontSize: 12)),
                const Spacer(),
                Icon(
                  state.showPasswordSection
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: DeckColors.graphite,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (state.showPasswordSection) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DeckColors.paper,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: DeckColors.rule),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: cpCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                  ),
                  style: DeckTheme.literata(fontSize: 14),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: npCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password (min 8 chars)',
                  ),
                  style: DeckTheme.literata(fontSize: 14),
                ),
                const SizedBox(height: 12),
                _btnPrimary('UPDATE PASSWORD',
                    state.changingPassword
                        ? null
                        : () async {
                            if (cpCtrl.text.isEmpty ||
                                npCtrl.text.length < 8) return;
                            try {
                              final msg = await context
                                  .read<ProfileCubit>()
                                  .changePassword(
                                      cpCtrl.text, npCtrl.text);
                              cpCtrl.clear();
                              npCtrl.clear();
                              cpCtrl.dispose();
                              npCtrl.dispose();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(msg as String,
                                          style: DeckTheme.ibmPlexMono(
                                              color: DeckColors.paper, fontSize: 10))),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(e.toString().replaceFirst('Exception: ', ''),
                                          style: DeckTheme.ibmPlexMono(
                                              color: DeckColors.paper, fontSize: 10))),
                                );
                              }
                            }
                          },
                    loading: state.changingPassword),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChangeEmailSection(
      BuildContext context, ProfileState state) {
    final cpCtrl = TextEditingController();
    final neCtrl = TextEditingController();
    return Column(
      children: [
        GestureDetector(
          onTap: () =>
              context.read<ProfileCubit>().toggleEmailSection(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: DeckColors.paperDark,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: DeckColors.rule),
            ),
            child: Row(
              children: [
                Text('CHANGE EMAIL',
                    style: DeckTheme.spaceGrotesk(fontSize: 12)),
                const Spacer(),
                Icon(
                  state.showEmailSection
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: DeckColors.graphite,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (state.showEmailSection) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DeckColors.paper,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: DeckColors.rule),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: cpCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                  ),
                  style: DeckTheme.literata(fontSize: 14),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: neCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'New Email',
                  ),
                  style: DeckTheme.literata(fontSize: 14),
                ),
                const SizedBox(height: 12),
                _btnPrimary('SEND VERIFICATION',
                    state.changingEmail
                        ? null
                        : () async {
                            if (cpCtrl.text.isEmpty ||
                                neCtrl.text.trim().isEmpty) return;
                            try {
                              final data = await context
                                  .read<ProfileCubit>()
                                  .requestEmailChange(
                                      cpCtrl.text, neCtrl.text.trim());
                              cpCtrl.clear();
                              neCtrl.clear();
                              cpCtrl.dispose();
                              neCtrl.dispose();
                              if (context.mounted) {
                                final token = (data as Map<String, dynamic>)[
                                        'debugToken'] as String?;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(data['message'] ?? 'Verification sent',
                                          style: DeckTheme.ibmPlexMono(
                                              color: DeckColors.paper, fontSize: 10))),
                                );
                                if (token != null) {
                                  _showVerifyDialog(context, token);
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(e.toString().replaceFirst('Exception: ', ''),
                                          style: DeckTheme.ibmPlexMono(
                                              color: DeckColors.paper, fontSize: 10))),
                                );
                              }
                            }
                          },
                    loading: state.changingEmail),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showVerifyDialog(BuildContext context, String token) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: DeckColors.paper,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Verify New Email',
                  style: DeckTheme.spaceGrotesk(fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                  'A verification token was generated. Paste it below to confirm.',
                  style: DeckTheme.literata(
                      fontSize: 13, color: DeckColors.graphite)),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: token),
                readOnly: true,
                maxLines: 2,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _btnPrimary('VERIFY', () async {
                      Navigator.pop(ctx);
                      try {
                        final msg = await context
                            .read<ProfileCubit>()
                            .verifyNewEmail(token);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(msg as String,
                                    style: DeckTheme.ibmPlexMono(
                                        color: DeckColors.paper, fontSize: 10))),
                          );
                          await widget.authService.logout();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(
                                context, '/login');
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(e.toString().replaceFirst('Exception: ', ''),
                                    style: DeckTheme.ibmPlexMono(
                                        color: DeckColors.paper, fontSize: 10))),
                          );
                        }
                      }
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _btnOutline('CLOSE',
                        () => Navigator.pop(ctx)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await widget.authService.logout();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: DeckColors.red,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text('LOG OUT',
              style: DeckTheme.spaceGrotesk(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: DeckColors.paper)),
        ),
      ),
    );
  }

  String _formatYear(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const m = [
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
      ];
      return '${m[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: DeckTheme.ibmPlexMono(
              fontSize: 9,
              color: DeckColors.graphite,
              letterSpacing: 0.1)),
    );
  }

  Widget _btnPrimary(String label, VoidCallback? onTap,
      {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: (loading) ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: DeckColors.ink,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: DeckColors.paper),
                  )
                : Text(label,
                    style: DeckTheme.spaceGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: DeckColors.paper)),
          ),
        ),
      ),
    );
  }

  Widget _btnOutline(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: DeckColors.ink, width: 1.5),
          ),
          child: Center(
            child: Text(label,
                style: DeckTheme.spaceGrotesk(
                    fontSize: 13.5, color: DeckColors.ink)),
          ),
        ),
      ),
    );
  }
}
