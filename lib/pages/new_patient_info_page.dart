import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/pages/auth_welcome_page.dart';
import 'package:therapii/pages/new_patient_confirm_page.dart';
import 'package:therapii/services/invitation_service.dart';

class NewPatientInfoPage extends StatefulWidget {
  const NewPatientInfoPage({super.key});

  @override
  State<NewPatientInfoPage> createState() => _NewPatientInfoPageState();
}

class _NewPatientInfoPageState extends State<NewPatientInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  final _invitationService = InvitationService();

  bool _offerCredits = true;
  int? _selectedCredits;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint, {Widget? prefix}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outline.withOpacity(0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outline.withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.2),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = FirebaseAuthManager().currentUser;
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      // Force refresh the auth token to ensure it's valid
      await currentUser.getIdToken(true);

      // Extract first name from full name
      final fullName = _nameController.text.trim();
      final parts = fullName.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
      final firstName = parts.isNotEmpty ? parts.first : fullName;
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      // Create invitation and send email
      final createResult = await _invitationService.createInvitationAndSendEmail(
        therapistId: currentUser.uid,
        patientEmail: _emailController.text.trim(),
        patientFirstName: firstName,
        patientLastName: lastName,
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NewPatientConfirmPage(
              patientName: fullName,
              patientEmail: _emailController.text.trim(),
              invitationCode: createResult.invitation.code,
              emailSent: createResult.emailSent,
            ),
          ),
        );
      }
    } on FirebaseAuth.FirebaseAuthException {
      if (mounted) {
        // Auth token issue - prompt user to re-authenticate
        final shouldReauth = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Session Expired'),
            content: const Text('Your session has expired. Please sign in again to continue.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sign In'),
              ),
            ],
          ),
        );

        if (shouldReauth == true && mounted) {
          await FirebaseAuthManager().signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthWelcomePage(initialTab: AuthTab.login)),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Check if error message contains auth-related keywords
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('authorization') || 
            errorMsg.contains('unauthenticated') || 
            errorMsg.contains('expired') ||
            errorMsg.contains('revoked') ||
            errorMsg.contains('invalid')) {
          // Auth issue - prompt to re-authenticate
          final shouldReauth = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Session Expired'),
              content: const Text('Your session has expired. Please sign in again to continue.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          );

          if (shouldReauth == true && mounted) {
            await FirebaseAuthManager().signOut();
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthWelcomePage(initialTab: AuthTab.login)),
                (route) => false,
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send invitation: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = scheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Invite Patient', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: () async {
                await FirebaseAuthManager().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthWelcomePage(initialTab: AuthTab.login)),
                    (route) => false,
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                side: BorderSide(color: scheme.outline.withOpacity(0.35)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.white,
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset('assets/images/therapii_logo.png'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 12)),
                      ],
                      border: Border.all(color: scheme.outline.withOpacity(0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Patient Info',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(
                          'Please enter the information in the form below then hit submit to generate an invitation.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: _fieldDecoration("Patient's Full Name", prefix: const Icon(Icons.person)),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _emailController,
                                decoration: _fieldDecoration('Patient Email', prefix: const Icon(Icons.email_outlined)),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                              ),
                              const SizedBox(height: 18),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Offer free credits',
                                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Each credit is worth one free month',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: scheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _offerCredits,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: primary,
                                    onChanged: (v) => setState(() => _offerCredits = v),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<int>(
                                initialValue: _offerCredits ? _selectedCredits : null,
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('1 Credit (1 Month)')),
                                  DropdownMenuItem(value: 3, child: Text('3 Credits (3 Months)')),
                                  DropdownMenuItem(value: 6, child: Text('6 Credits (6 Months)')),
                                  DropdownMenuItem(value: 12, child: Text('12 Credits (1 Year)')),
                                ],
                                onChanged: _offerCredits ? (v) => setState(() => _selectedCredits = v) : null,
                                decoration: _fieldDecoration('Select number of credits...'),
                                validator: (v) {
                                  if (!_offerCredits) return null;
                                  if (v == null) return 'Select the number of credits';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _notesController,
                                minLines: 4,
                                maxLines: 6,
                                decoration: _fieldDecoration(
                                  "Let's personalize the AI's approach! Please provide some key information about this patient so the AI can tailor its style and make the session feel more personal.",
                                  prefix: const Icon(Icons.note_alt_outlined),
                                ).copyWith(hintMaxLines: 5),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'By clicking Submit, you authorize Therapii to send an email invitation to establish a Therapii account.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: const Color(0xFF3B6CC3),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                    shadowColor: const Color(0x4D3B6CC3),
                                    elevation: 4,
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text('Submit Invite', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
