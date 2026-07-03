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

class _SubscriptionScreenState extends State<SubscriptionScreen> with WidgetsBindingObserver {
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
          content: const Text('Payment successful! Pull down to refresh.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final plans = await widget.subscriptionService.getPlans();
      if (mounted) setState(() { _plans = plans; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _checkout(String plan) async {
    setState(() => _checkingOut = plan);
    try {
      final result = await widget.subscriptionService.checkout(plan, widget.currency);
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
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingOut = null);
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
            Text('💎', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('UPGRADE PLAN',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💎', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text('Loading plans...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
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
                  style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('TRY AGAIN')),
            ],
          ),
        ),
      );
    }

    if (_plans == null || _plans!.isEmpty) {
      return const Center(
        child: Text('😴 No plans available.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.outline, width: 3),
              boxShadow: [
                BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 0, offset: const Offset(5, 5)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('📋', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    'Current: ${_tierName(widget.currentTier)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tierDesc(widget.currentTier),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _plans!.map((plan) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: plan != _plans!.last ? 12 : 0,
                  ),
                  child: _buildPlanCard(plan),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPlanCard(PlanInfo plan) {
    final isCurrent = plan.tier == widget.currentTier;
    final isLower = plan.tier < widget.currentTier;
    final isFree = plan.tier == 0;
    final isPopular = plan.tier == 1;

    final bgColor = isCurrent
        ? AppColors.success
        : isPopular
            ? AppColors.sky
            : Colors.white;

    final accentColor = isCurrent
        ? AppColors.success
        : isPopular
            ? AppColors.primary
            : isLower
                ? AppColors.textSecondary
                : plan.tier == 2
                    ? AppColors.gold
                    : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline, width: 3),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 0, offset: const Offset(5, 5)),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.white.withValues(alpha: 0.2) : accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          _planIcon(plan.tier),
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('CURRENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.success)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900, color: isCurrent ? Colors.white : AppColors.textPrimary, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 4),
                      if (!isFree)
                        Text(
                          _formatPrice(plan),
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800, color: isCurrent ? Colors.white.withValues(alpha: 0.85) : AppColors.primary),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        _tierDesc(plan.tier),
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: isCurrent ? Colors.white70 : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!isFree) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${plan.categoryLimit ?? 'All'} categories',
                        style: TextStyle(fontWeight: FontWeight.w700, color: isCurrent ? Colors.white : AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                if (isCurrent)
                  _buildButton('YOU ARE HERE', accentColor, null, true)
                else if (isLower)
                  _buildButton('OWNED', accentColor, null, true)
                else
                  _buildButton(
                    _checkingOut == plan.plan ? 'OPENING STRIPE...' : 'UPGRADE',
                    accentColor,
                    () => _checkout(plan.plan),
                    false,
                    _checkingOut == plan.plan,
                  ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
                child: const Text('POPULAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback? onTap, bool isCurrent, [bool loading = false]) {
    return SizedBox(
      width: double.infinity,
      child: isCurrent
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
              ),
            )
          : FilledButton(
              onPressed: loading ? null : onTap,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size(double.infinity, 48),
                shadowColor: color.withValues(alpha: 0.4),
              ),
              child: loading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
    );
  }

  String _planIcon(int tier) {
    switch (tier) {
      case 2: return '👑';
      case 1: return '⭐';
      default: return '🎓';
    }
  }

  String _tierName(int tier) {
    final plan = _plans?.where((p) => p.tier == tier).firstOrNull;
    if (plan == null || tier == 0) return 'Free';
    final price = widget.currency == 'usd' ? '\$${plan.priceUSD.toStringAsFixed(2)}' : 'RM${plan.priceMYR.toStringAsFixed(2)}';
    return '$price — ${plan.name}';
  }

  String _tierDesc(int tier) {
    switch (tier) {
      case 2: return 'Unlimited categories';
      case 1: return '10 categories';
      default: return '3 categories';
    }
  }

  String _formatPrice(PlanInfo plan) {
    if (widget.currency == 'usd') {
      return '\$${plan.priceUSD.toStringAsFixed(2)}';
    }
    return 'RM${plan.priceMYR.toStringAsFixed(2)}';
  }
}
