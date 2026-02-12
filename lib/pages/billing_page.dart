
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Clean, web-friendly billing hub with modern card design.
class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  List<_Invoice> _invoices = [];
  bool _isLoadingInvoices = true;
  bool _isLoadingBilling = true;
  
  // Billing data from Stripe
  bool _isPaidUser = false;
  String _planName = 'Free Plan';
  double _creditBalance = 0;
  _PaymentMethodData? _paymentMethod;
  String? _nextBillingDate;
  _AppliedCoupon? _appliedCoupon;
  
  // Redeem code controller
  final _redeemCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBillingDetails();
    _fetchInvoices();
  }

  @override
  void dispose() {
    _redeemCodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchBillingDetails() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getStripeBillingDetails');
      final result = await callable.call();
      
      final data = result.data as Map<String, dynamic>;
      
      if (mounted) {
        setState(() {
          _isPaidUser = data['isPaidUser'] == true;
          _planName = data['planName'] as String? ?? 'Free Plan';
          _creditBalance = (data['creditBalance'] as num?)?.toDouble() ?? 0;
          _nextBillingDate = data['nextBillingDate'] as String?;
          
          if (data['paymentMethod'] != null) {
            final pm = data['paymentMethod'] as Map<String, dynamic>;
            _paymentMethod = _PaymentMethodData(
              brand: pm['brand'] as String? ?? 'card',
              last4: pm['last4'] as String? ?? '****',
              expMonth: pm['expMonth'] as int? ?? 1,
              expYear: pm['expYear'] as int? ?? 2030,
            );
          }
          
          if (data['appliedCoupon'] != null) {
            final coupon = data['appliedCoupon'] as Map<String, dynamic>;
            _appliedCoupon = _AppliedCoupon(
              code: coupon['code'] as String? ?? '',
              name: coupon['name'] as String? ?? '',
              percentOff: (coupon['percentOff'] as num?)?.toDouble(),
              amountOff: (coupon['amountOff'] as num?)?.toDouble(),
            );
          }
          
          _isLoadingBilling = false;
        });
      }
    } catch (error) {
      debugPrint('Error fetching billing details: $error');
      if (mounted) {
        setState(() => _isLoadingBilling = false);
      }
    }
  }

  Future<void> _fetchInvoices() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getStripeInvoices');
      final result = await callable.call();
      
      final invoicesData = result.data['invoices'] as List<dynamic>? ?? [];
      final fetchedInvoices = invoicesData.map((invoice) {
        return _Invoice(
          id: invoice['id'] as String? ?? '',
          amount: (invoice['amount'] as num?)?.toDouble() ?? 0.0,
          issuedAt: DateTime.tryParse(invoice['issuedAt'] as String? ?? '') ?? DateTime.now(),
          status: _InvoiceStatus.paid,
          invoiceUrl: invoice['invoiceUrl'] as String?,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _invoices = fetchedInvoices;
          _isLoadingInvoices = false;
        });
      }
    } catch (error) {
      debugPrint('Error fetching invoices: $error');
      if (mounted) {
        setState(() {
          _invoices = [];
          _isLoadingInvoices = false;
        });
      }
    }
  }

  Future<void> _redeemCode() async {
    final code = _redeemCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a code to redeem.')),
      );
      return;
    }
    
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('redeemStripeCode');
      final response = await callable.call({'code': code});
      final data = response.data as Map<String, dynamic>;

      if (!mounted) return;
      _redeemCodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] as String? ?? 'Code redeemed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchBillingDetails();
    } catch (e) {
      debugPrint('Error redeeming code: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to redeem code: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleChangePlan(BuildContext context) async {
    try {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening Stripe Checkout...')),
      );

      final callable = FirebaseFunctions.instance.httpsCallable('createStripeCheckoutSession');
      final baseUrl = kIsWeb ? Uri.base.toString().replaceAll(RegExp(r'[?#].*'), '') : 'https://therapii.app';
      
      final result = await callable.call({
        'priceId': 'price_1SOt2aL9fA3Th1kO32maIqxk',
        'successUrl': '$baseUrl/billing?success=true',
        'cancelUrl': '$baseUrl/billing?cancelled=true',
      });

      final checkoutUrl = result.data['url'] as String?;
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('No checkout URL returned');
      }

      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch checkout URL');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Firebase Functions error: ${e.code} - ${e.message}');
      debugPrint('Details: ${e.details}');
      
      if (!context.mounted) return;
      
      String errorMessage;
      if (e.code == 'not-found' || e.code == 'internal') {
        errorMessage = 'Cloud Functions not deployed yet.\n\nPlease deploy functions first:\n1. Download project code\n2. Run: firebase deploy --only functions';
      } else {
        errorMessage = 'Error: ${e.message ?? e.code}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (error) {
      debugPrint('Error creating checkout session: $error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open checkout: ${error.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E69FF),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
          label: const Text('Back', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        leadingWidth: 100,
        title: const Text(
          'Billing & Plans',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Plan Card
                _isLoadingBilling
                    ? const _HeroCardShimmer()
                    : _HeroCard(
                        planName: _planName,
                        isPaidUser: _isPaidUser,
                        highlights: _isPaidUser 
                          ? const ['Unlimited chat', 'AI voice concierge', 'Analytics vault']
                          : const ['Basic chat', 'Session summaries'],
                        onUpgrade: () => _handleChangePlan(context),
                      ),
                const SizedBox(height: 24),
                
                // Metrics Grid
                _MetricsGrid(
                  isPaidUser: _isPaidUser,
                  creditBalance: _creditBalance,
                ),
                const SizedBox(height: 24),
                
                // Gift/Credit Code Section
                _CreditCodeCard(
                  controller: _redeemCodeController,
                  appliedCoupon: _appliedCoupon,
                  onRedeem: _redeemCode,
                ),
                const SizedBox(height: 24),
                
                // Invoices Section
                _InvoicesCard(
                  invoices: _invoices,
                  isLoading: _isLoadingInvoices,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Data classes
class _PaymentMethodData {
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;

  const _PaymentMethodData({
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
  });
}

class _AppliedCoupon {
  final String code;
  final String name;
  final double? percentOff;
  final double? amountOff;

  const _AppliedCoupon({
    required this.code,
    required this.name,
    this.percentOff,
    this.amountOff,
  });
}

class _Invoice {
  final String id;
  final double amount;
  final DateTime issuedAt;
  final _InvoiceStatus status;
  final String? invoiceUrl;

  const _Invoice({
    required this.id,
    required this.amount,
    required this.issuedAt,
    required this.status,
    this.invoiceUrl,
  });
}

enum _InvoiceStatus { paid, dueSoon, overdue }

// Hero Card Shimmer
class _HeroCardShimmer extends StatelessWidget {
  const _HeroCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 80, height: 24, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 16),
          Container(width: 140, height: 32, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 20, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 24),
          Container(width: double.infinity, height: 52, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12))),
        ],
      ),
    );
  }
}

// Hero Plan Card
class _HeroCard extends StatelessWidget {
  final String planName;
  final bool isPaidUser;
  final List<String> highlights;
  final VoidCallback onUpgrade;

  const _HeroCard({
    required this.planName,
    required this.isPaidUser,
    required this.highlights,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final badgeLabel = isPaidUser ? 'Premium care' : 'Free tier';
    final description = isPaidUser
      ? 'AI-enhanced therapist partnership with voice journaling, session analytics, and concierge escalation.'
      : 'Get started with basic chat support and session summaries. Upgrade for unlimited AI access.';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPaidUser ? Icons.workspace_premium : Icons.star_outline,
                  size: 12,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  badgeLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Plan Name
          Text(
            planName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          
          // Feature Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: highlights.map((highlight) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text(
                    highlight,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 32),
          
          // Upgrade Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUpgrade,
              icon: Icon(isPaidUser ? Icons.settings : Icons.upgrade, size: 18),
              label: Text(isPaidUser ? 'Manage plan' : 'Upgrade now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Metrics Grid
class _MetricsGrid extends StatelessWidget {
  final bool isPaidUser;
  final double creditBalance;

  const _MetricsGrid({
    required this.isPaidUser,
    required this.creditBalance,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        
        final metrics = [
          _MetricItem(
            icon: Icons.auto_awesome,
            value: isPaidUser ? 'Unlimited' : '0%',
            label: 'AI minutes used',
            detail: isPaidUser ? 'Unlimited usage' : 'Upgrade for unlimited',
          ),
          _MetricItem(
            icon: Icons.schedule,
            value: '4',
            label: 'Therapist sessions',
            detail: 'completed this month',
          ),
          _MetricItem(
            icon: Icons.account_balance_wallet,
            value: '\$${creditBalance.toStringAsFixed(0)}',
            label: 'Credit balance',
            detail: creditBalance > 0 ? 'applied to next invoice' : 'No credits yet',
          ),
        ];
        
        if (isWide) {
          return Row(
            children: metrics.map((m) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: m == metrics.last ? 0 : 24,
                ),
                child: _MetricCard(metric: m),
              ),
            )).toList(),
          );
        }
        
        return Column(
          children: metrics.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _MetricCard(metric: m),
          )).toList(),
        );
      },
    );
  }
}

class _MetricItem {
  final IconData icon;
  final String value;
  final String label;
  final String detail;

  const _MetricItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricItem metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(metric.icon, color: const Color(0xFF3B82F6), size: 20),
          ),
          const SizedBox(height: 24),
          Text(
            metric.value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.detail,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// Credit Code Card
class _CreditCodeCard extends StatelessWidget {
  final TextEditingController controller;
  final _AppliedCoupon? appliedCoupon;
  final VoidCallback onRedeem;

  const _CreditCodeCard({
    required this.controller,
    this.appliedCoupon,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.redeem, color: Color(0xFF94A3B8), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gift or credit code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appliedCoupon != null
                          ? 'Active coupon: ${appliedCoupon!.name}'
                          : 'Apply concierge credits or corporate stipends to reduce upcoming invoices.',
                      style: TextStyle(
                        fontSize: 14,
                        color: appliedCoupon != null ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF8FAFC), height: 1),
          const SizedBox(height: 24),
          
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              
              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: _RedeemInput(controller: controller, onRedeem: onRedeem),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share credits from your therapist portal.')),
                        );
                      },
                      icon: const Icon(Icons.share, size: 18, color: Color(0xFF2563EB)),
                      label: const Text(
                        'Share credits',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                );
              }
              
              return Column(
                children: [
                  _RedeemInput(controller: controller, onRedeem: onRedeem),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share credits from your therapist portal.')),
                      );
                    },
                    icon: const Icon(Icons.share, size: 18, color: Color(0xFF2563EB)),
                    label: const Text(
                      'Share credits',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RedeemInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onRedeem;

  const _RedeemInput({required this.controller, required this.onRedeem});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 448),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          hintText: 'Redeem code',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.qr_code_2, color: Color(0xFF94A3B8), size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
        ),
        onSubmitted: (_) => onRedeem(),
      ),
    );
  }
}

// Invoices Card
class _InvoicesCard extends StatelessWidget {
  final List<_Invoice> invoices;
  final bool isLoading;

  const _InvoicesCard({required this.invoices, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description, color: Color(0xFF3B82F6), size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Download detailed receipts or share them with your care team.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          if (isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 64),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading invoices...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else if (invoices.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 64),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Color(0xFFCBD5E1),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No invoices yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your past payments and receipts will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            )
          else
            ...invoices.map((invoice) => _InvoiceRow(
              invoice: invoice,
              localizations: localizations,
            )),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final _Invoice invoice;
  final MaterialLocalizations localizations;

  const _InvoiceRow({required this.invoice, required this.localizations});

  Color _statusColor(_InvoiceStatus status) {
    switch (status) {
      case _InvoiceStatus.paid: return const Color(0xFF2563EB);
      case _InvoiceStatus.dueSoon: return const Color(0xFFF59E0B);
      case _InvoiceStatus.overdue: return const Color(0xFFEF4444);
    }
  }

  String _statusLabel(_InvoiceStatus status) {
    switch (status) {
      case _InvoiceStatus.paid: return 'Paid';
      case _InvoiceStatus.dueSoon: return 'Due soon';
      case _InvoiceStatus.overdue: return 'Overdue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (invoice.invoiceUrl != null && invoice.invoiceUrl!.isNotEmpty) {
              try {
                final uri = Uri.parse(invoice.invoiceUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open invoice PDF.')),
                    );
                  }
                }
              } catch (error) {
                debugPrint('Error opening invoice: $error');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${error.toString()}')),
                  );
                }
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice PDF not available.')),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor(invoice.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: _statusColor(invoice.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              invoice.id,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(invoice.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusLabel(invoice.status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(invoice.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.formatMediumDate(invoice.issuedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${invoice.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap to download',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
