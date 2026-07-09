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
              content: Text('Payment successful! Pull down to refresh.',
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
              _btnPrimary('TRY AGAIN', () => _load()),
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
              color: DeckColors.ink,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              children: [
                Text('Current: ${_tierName(widget.currentTier)}',
                    style: DeckTheme.spaceGrotesk(
                        fontSize: 14, color: DeckColors.paper)),
                const SizedBox(height: 4),
                Text(_tierDesc(widget.currentTier),
                    style: DeckTheme.ibmPlexMono(
                        fontSize: 9, color: DeckColors.graphiteFaint)),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? DeckColors.ink : DeckColors.paperDark,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: DeckColors.rule),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? DeckColors.paper.withAlpha(30)
                      : DeckColors.paper,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    plan.tier == 2
                        ? '\u{1F451}'
                        : plan.tier == 1
                            ? '\u2B50'
                            : '\u{1F393}',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const Spacer(),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DeckColors.paper.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('CURRENT',
                      style: DeckTheme.ibmPlexMono(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: DeckColors.paper)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name,
                        style: DeckTheme.spaceGrotesk(
                            fontSize: 16,
                            color: isCurrent
                                ? DeckColors.paper
                                : DeckColors.ink)),
                    if (!isFree) ...[
                      const SizedBox(height: 2),
                      Text(_formatPrice(plan),
                          style: DeckTheme.spaceGrotesk(
                              fontSize: 13,
                              color: isCurrent
                                  ? DeckColors.graphiteFaint
                                  : DeckColors.blue)),
                    ],
                    const SizedBox(height: 2),
                    Text(_tierDesc(plan.tier),
                        style: DeckTheme.ibmPlexMono(
                            fontSize: 9,
                            color: isCurrent
                                ? DeckColors.graphiteFaint
                                : DeckColors.graphite)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isCurrent)
            _disabledBtn('YOU ARE HERE')
          else if (isLower)
            _disabledBtn('OWNED')
          else
            _btnPrimary(
              _checkingOut == plan.plan
                  ? 'OPENING STRIPE...'
                  : 'UPGRADE',
              _checkingOut == plan.plan
                  ? null
                  : () => _checkout(plan.plan),
            ),
        ],
      ),
    );
  }

  Widget _disabledBtn(String label) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: DeckColors.graphiteFaint,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(label,
              style: DeckTheme.spaceGrotesk(
                  fontSize: 13.5, color: DeckColors.paper)),
        ),
      ),
    );
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
      return '\$${plan.priceUSD.toStringAsFixed(2)}';
    }
    return 'RM${plan.priceMYR.toStringAsFixed(2)}';
  }

  Widget _btnPrimary(String label, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: onTap != null ? DeckColors.ink : DeckColors.graphiteFaint,
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
