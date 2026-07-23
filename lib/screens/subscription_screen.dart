import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

class SubscriptionScreen extends StatefulWidget {
  final SubscriptionService subscriptionService;
  final int currentTier;
  final String currency;

  const SubscriptionScreen({
    super.key,
    required this.subscriptionService,
    required this.currentTier,
    this.currency = 'myr',
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  List<PlanInfo>? _plans;
  bool _loading = true;
  String? _error;
  String? _checkingOut;
  bool _paymentPending = false;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _paymentPending && mounted) {
      _paymentPending = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Payment successful!',
                style: DeckTheme.ibmPlexMono(
                    color: DeckColors.paper, fontSize: 10))),
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await widget.subscriptionService.getPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _checkout(String plan) async {
    setState(() => _checkingOut = plan);
    try {
      final result =
          await widget.subscriptionService.checkout(plan, widget.currency);
      final url = result['paymentUrl'] as String?;
      if (url != null && mounted) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          _paymentPending = true;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', ''),
                  style: DeckTheme.ibmPlexMono(
                      color: DeckColors.paper, fontSize: 10))),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingOut = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DeckColors.paper,
      appBar: AppBar(
        title: Text('Upgrade Plan'),
        leading: _backButton(context),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Text('Loading plans...',
            style: TextStyle(fontSize: 14, color: DeckColors.graphite)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: DeckTheme.ibmPlexMono(color: DeckColors.graphite)),
              const SizedBox(height: 16),
              _btnFilled('Try again', () => _load()),
            ],
          ),
        ),
      );
    }

    if (_plans == null || _plans!.isEmpty) {
      return Center(
        child: Text('No plans available.',
            style: DeckTheme.spaceGrotesk(
                fontSize: 14, color: DeckColors.graphite)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DeckColors.paperDark,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: DeckColors.rule),
            ),
            child: Row(
              children: [
                Text(_planIcon(widget.currentTier),
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current plan',
                          style: DeckTheme.ibmPlexMono(
                              fontSize: 9,
                              color: DeckColors.graphite,
                              letterSpacing: 0.1)),
                      const SizedBox(height: 2),
                      Text(_tierName(widget.currentTier),
                          style: DeckTheme.spaceGrotesk(fontSize: 15)),
                    ],
                  ),
                ),
                Text(_tierDesc(widget.currentTier),
                    style: DeckTheme.ibmPlexMono(fontSize: 9)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._plans!.map((plan) => _buildPlanCard(plan)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlanCard(PlanInfo plan) {
    final isCurrent = plan.tier == widget.currentTier;
    final isLower = plan.tier < widget.currentTier;
    final isFree = plan.tier == 0;
    final isBest = plan.tier == 3;

    final borderColor = isCurrent
        ? DeckColors.blue
        : isBest
            ? DeckColors.yellow
            : DeckColors.rule;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DeckColors.paper,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
            color: borderColor,
            width: isCurrent || isBest ? 2 : 1),
      ),
      child: Column(
        children: [
          if (isBest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: DeckColors.yellow,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(7)),
              ),
              child: Center(
                child: Text('BEST VALUE',
                    style: DeckTheme.ibmPlexMono(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: DeckColors.ink,
                        letterSpacing: 0.1)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: DeckColors.paperDark,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(_planIcon(plan.tier),
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(plan.name,
                                  style: DeckTheme.spaceGrotesk(
                                      fontSize: 16)),
                              if (isCurrent) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: DeckColors.blueFaint,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text('CURRENT',
                                      style: DeckTheme.ibmPlexMono(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w600,
                                          color: DeckColors.blue)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (!isFree)
                            Text(_formatPrice(plan),
                                style: DeckTheme.spaceGrotesk(
                                    fontSize: 13,
                                    color: DeckColors.blue)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(_tierDesc(plan.tier),
                    style: DeckTheme.ibmPlexMono(fontSize: 9)),
                const SizedBox(height: 12),
                _buildFeatures(plan.tier),
                const SizedBox(height: 14),
                if (isCurrent)
                  _btnDisabled('Current plan')
                else if (isLower)
                  _btnDisabled('Already owned')
                else
                  _btnFilled(
                    _checkingOut == plan.plan
                        ? 'Opening Stripe...'
                        : 'Upgrade',
                    _checkingOut == plan.plan
                        ? null
                        : () => _checkout(plan.plan),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(int tier) {
    final features = <_Feature>[];
    switch (tier) {
      case 3:
        features.addAll([
          _Feature(true, 'All categories unlocked'),
          _Feature(true, 'Unlimited quiz sessions'),
          _Feature(true, 'Priority support'),
          _Feature(true, 'All badges & achievements'),
          _Feature(true, 'Early access to new content'),
        ]);
        break;
      case 2:
        features.addAll([
          _Feature(true, 'All categories unlocked'),
          _Feature(true, 'Unlimited quiz sessions'),
          _Feature(true, 'All badges & achievements'),
          _Feature(false, 'Priority support'),
        ]);
        break;
      case 1:
        features.addAll([
          _Feature(true, 'Up to 10 categories'),
          _Feature(true, 'Unlimited quiz sessions'),
          _Feature(true, 'All badges & achievements'),
          _Feature(false, 'All categories unlocked'),
        ]);
        break;
      default:
        features.addAll([
          _Feature(true, 'Up to 3 categories'),
          _Feature(true, 'Basic quiz sessions'),
          _Feature(false, 'All badges & achievements'),
          _Feature(false, 'All categories unlocked'),
        ]);
    }

    return Column(
      children: features
          .map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      f.included ? Icons.check : Icons.close,
                      size: 14,
                      color: f.included
                          ? DeckColors.green
                          : DeckColors.graphiteFaint,
                    ),
                    const SizedBox(width: 8),
                    Text(f.label,
                        style: DeckTheme.ibmPlexMono(
                            fontSize: 9,
                            color: f.included
                                ? DeckColors.ink
                                : DeckColors.graphiteFaint)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _btnFilled(String label, VoidCallback? onTap, {Color? accent}) {
    final bg = onTap != null
        ? (accent ?? DeckColors.blue)
        : DeckColors.graphiteFaint;
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(label,
                style: DeckTheme.spaceGrotesk(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: DeckColors.paper)),
          ),
        ),
      ),
    );
  }

  Widget _btnDisabled(String label) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: DeckColors.paperDark,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: DeckColors.rule),
        ),
        child: Center(
          child: Text(label,
              style: DeckTheme.spaceGrotesk(
                  fontSize: 13.5, color: DeckColors.graphite)),
        ),
      ),
    );
  }

  String _planIcon(int tier) {
    switch (tier) {
      case 3:
        return '\u{1F3C6}';
      case 2:
        return '\u{1F451}';
      case 1:
        return '\u2B50';
      default:
        return '\u{1F393}';
    }
  }

  String _tierName(int tier) {
    final plan = _plans?.where((p) => p.tier == tier).firstOrNull;
    if (plan == null || tier == 0) return 'Free';
    final price = widget.currency == 'usd'
        ? '\$${plan.priceUSD.toStringAsFixed(2)}'
        : 'RM${plan.priceMYR.toStringAsFixed(2)}';
    return '$price \u2014 ${plan.name}';
  }

  String _tierDesc(int tier) {
    switch (tier) {
      case 3:
        return 'All categories + priority support';
      case 2:
        return 'Unlimited categories';
      case 1:
        return '10 categories';
      default:
        return '3 categories';
    }
  }

  String _formatPrice(PlanInfo plan) {
    if (widget.currency == 'usd') {
      return '\$${plan.priceUSD.toStringAsFixed(2)}/mo';
    }
    return 'RM${plan.priceMYR.toStringAsFixed(2)}/mo';
  }

  Widget _backButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          color: DeckColors.paperDark,
          shape: BoxShape.circle,
          border: Border.all(color: DeckColors.rule),
        ),
        child: const Center(
          child: Text('\u2190',
              style: TextStyle(fontSize: 13, color: DeckColors.ink)),
        ),
      ),
    );
  }
}

class _Feature {
  final bool included;
  final String label;
  const _Feature(this.included, this.label);
}
