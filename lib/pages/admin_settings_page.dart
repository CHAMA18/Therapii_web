import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _apiKeyController = TextEditingController();
  final _emailFromController = TextEditingController();
  final _emailFromNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  bool _obscureKey = true;
  String? _currentKey;
  String? _currentEmailFrom;
  String? _currentEmailFromName;
  String? _lastUpdatedBy;
  DateTime? _lastUpdatedAt;
  String? _emailLastUpdatedBy;
  DateTime? _emailLastUpdatedAt;
  bool _emailEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _emailFromController.dispose();
    _emailFromNameController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    setState(() => _loading = true);
    try {
      final openaiDoc = await FirebaseFirestore.instance.collection('admin_settings').doc('openai_config').get();
      if (openaiDoc.exists && mounted) {
        final data = openaiDoc.data();
        _currentKey = data?['api_key'] as String?;
        _lastUpdatedBy = data?['updated_by'] as String?;
        final timestamp = data?['updated_at'] as Timestamp?;
        _lastUpdatedAt = timestamp?.toDate();
        if (_currentKey != null) _apiKeyController.text = _currentKey!;
      }

      final emailDoc = await FirebaseFirestore.instance.collection('admin_settings').doc('email_config').get();
      if (emailDoc.exists && mounted) {
        final data = emailDoc.data();
        _currentEmailFrom = data?['from_email'] as String?;
        _currentEmailFromName = data?['from_name'] as String?;
        _emailEnabled = (data?['enabled'] as bool?) ?? true;
        _emailLastUpdatedBy = data?['updated_by'] as String?;
        final timestamp = data?['updated_at'] as Timestamp?;
        _emailLastUpdatedAt = timestamp?.toDate();
        if (_currentEmailFrom != null) _emailFromController.text = _currentEmailFrom!;
        if (_currentEmailFromName != null) _emailFromNameController.text = _currentEmailFromName!;
      }
    } catch (e) {
      if (mounted) _showError('Failed to load configuration: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveApiKey() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuthManager().currentUser;
      if (user == null) {
        _showError('You must be signed in to save settings.');
        return;
      }
      final apiKey = _apiKeyController.text.trim();
      await FirebaseFirestore.instance.collection('admin_settings').doc('openai_config').set({
        'api_key': apiKey,
        'updated_by': user.email ?? user.uid,
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSuccess('OpenAI API key saved successfully!');
        await _loadApiKey();
      }
    } catch (e) {
      if (mounted) _showError('Failed to save API key: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete API Key'),
        content: const Text(
          'Are you sure you want to delete the OpenAI API key? This will disable the AI companion throughout the app.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('admin_settings').doc('openai_config').delete();
      if (mounted) {
        _apiKeyController.clear();
        _currentKey = null;
        _lastUpdatedBy = null;
        _lastUpdatedAt = null;
        _showSuccess('API key deleted successfully.');
      }
    } catch (e) {
      if (mounted) _showError('Failed to delete API key: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveEmailConfig() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuthManager().currentUser;
      if (user == null) {
        _showError('You must be signed in to save settings.');
        return;
      }
      final fromEmail = _emailFromController.text.trim();
      final fromName = _emailFromNameController.text.trim();
      await FirebaseFirestore.instance.collection('admin_settings').doc('email_config').set({
        'from_email': fromEmail,
        'from_name': fromName,
        'enabled': _emailEnabled,
        'updated_by': user.email ?? user.uid,
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSuccess('Email configuration saved successfully!');
        await _loadApiKey();
      }
    } catch (e) {
      if (mounted) _showError('Failed to save email configuration: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteEmailConfig() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Email Config'),
        content: const Text(
          'Are you sure you want to delete the email configuration? This will disable email notifications.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('admin_settings').doc('email_config').delete();
      if (mounted) {
        _emailFromController.clear();
        _emailFromNameController.clear();
        _currentEmailFrom = null;
        _currentEmailFromName = null;
        _emailLastUpdatedBy = null;
        _emailLastUpdatedAt = null;
        _showSuccess('Email configuration deleted successfully.');
      }
    } catch (e) {
      if (mounted) _showError('Failed to delete email configuration: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const maxWidth = 960.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Admin Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _SectionCard(
                          accentColor: const Color(0xFF0EA5E9),
                          icon: Icons.smart_toy_rounded,
                          title: 'OpenAI Configuration',
                          subtitle:
                              'Configure the OpenAI API key for the AI companion chatbot. Changes take effect immediately across the entire app.',
                          headerBadge: 'AI',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('API Key'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _apiKeyController,
                                obscureText: _obscureKey,
                                decoration: _inputDecoration(
                                  hint: 'sk-proj-...',
                                  focusColor: const Color(0xFF0EA5E9),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter an API key';
                                  }
                                  if (!value.startsWith('sk-')) {
                                    return 'API key should start with "sk-"';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              if (_lastUpdatedBy != null || _lastUpdatedAt != null)
                                _MetaInfo(
                                  icon: Icons.info_outline,
                                  text:
                                      'Last updated${_lastUpdatedBy != null ? " by $_lastUpdatedBy" : ""}${_lastUpdatedAt != null ? " on ${_formatDate(_lastUpdatedAt!)}" : ""}',
                                ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _saving ? null : _saveApiKey,
                                      icon: _saving
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.save),
                                      label: Text(_saving ? 'Saving...' : 'Save API Key'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0EA5E9),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: 2,
                                      ),
                                    ),
                                  ),
                                  if (_currentKey != null) ...[
                                    const SizedBox(width: 10),
                                    IconButton(
                                      onPressed: _saving ? null : _deleteApiKey,
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: 'Delete API Key',
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 18),
                              _SubCard(
                                icon: Icons.help_outline,
                                title: 'How to get an OpenAI API Key',
                                steps: const [
                                  'Visit platform.openai.com',
                                  'Sign in or create an account',
                                  'Navigate to API Keys section',
                                  'Click "Create new secret key"',
                                  'Copy and paste the key above',
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SectionCard(
                          accentColor: const Color(0xFF0F172A),
                          icon: Icons.mail_rounded,
                          title: 'Email Configuration',
                          subtitle: 'Configure email settings for invitation notifications via Firebase Extension + Resend.',
                          headerBadge: 'Mail',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('From Email Address'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailFromController,
                                decoration: _inputDecoration(
                                  hint: 'noreply@yourdomain.com',
                                  focusColor: const Color(0xFF0F172A),
                                ),
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) return 'Please enter a sender email';
                                  if (!v.contains('@') || v.startsWith('@') || v.endsWith('@')) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _FieldLabel('From Name'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailFromNameController,
                                decoration: _inputDecoration(
                                  hint: 'Therapii',
                                  focusColor: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (_emailLastUpdatedBy != null || _emailLastUpdatedAt != null)
                                _MetaInfo(
                                  icon: Icons.info_outline,
                                  text:
                                      'Last updated${_emailLastUpdatedBy != null ? " by $_emailLastUpdatedBy" : ""}${_emailLastUpdatedAt != null ? " on ${_formatDate(_emailLastUpdatedAt!)}" : ""}',
                                ),
                              const SizedBox(height: 12),
                              _ToggleRow(
                                label: 'Enable email delivery',
                                value: _emailEnabled,
                                onChanged: (v) => setState(() => _emailEnabled = v),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _saving ? null : _saveEmailConfig,
                                      icon: _saving
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.save),
                                      label: Text(_saving ? 'Saving...' : 'Save Email Config'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0F172A),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: 2,
                                      ),
                                    ),
                                  ),
                                  if (_currentEmailFrom != null) ...[
                                    const SizedBox(width: 10),
                                    IconButton(
                                      onPressed: _saving ? null : _deleteEmailConfig,
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: 'Delete Email Config',
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 18),
                              _SubCard(
                                icon: Icons.extension_rounded,
                                title: 'Setup Firebase Extension + Resend',
                                steps: const [
                                  'Sign up at resend.com and create an API key',
                                  'Go to Firebase Console > Extensions',
                                  'Install "Trigger Email from Firestore"',
                                  'Configure SMTP: Host=smtp.resend.com, Port=465',
                                  'Set Username=resend, Password=your_api_key',
                                  'Set Collection path to "mail"',
                                  'Verify your domain in Resend for production',
                                ],
                                accent: const Color(0xFF0F172A),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required Color focusColor}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: focusColor),
      ),
      suffixIcon: hint.startsWith('sk-')
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
                IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () {
                    final key = _apiKeyController.text;
                    if (key.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: key));
                      _showSuccess('API key copied to clipboard');
                    }
                  },
                ),
              ],
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return 'just now';
        return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
      }
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _SectionCard extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String headerBadge;
  final Widget child;

  const _SectionCard({
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.headerBadge,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.06),
              border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.12))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 6))],
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              headerBadge,
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> steps;
  final Color accent;

  const _SubCard({
    required this.icon,
    required this.title,
    required this.steps,
    this.accent = const Color(0xFF0EA5E9),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          steps[i],
                          style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
        ),
        Switch(
          value: value,
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF0EA5E9);
            }
            return null;
          }),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
