import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import 'package:therapii/widgets/form_fields.dart';
import 'package:therapii/auth/firebase_auth_manager.dart';
import 'package:therapii/services/user_service.dart';
import 'package:therapii/pages/admin_dashboard_page.dart';
import 'package:therapii/pages/journal_admin_studio_page.dart';
import 'package:therapii/pages/journal_portal_page.dart';
import 'package:therapii/pages/therapist_dashboard_page.dart';
import 'package:therapii/pages/patient_dashboard_page.dart';
import 'package:therapii/pages/patient_onboarding_flow_page.dart';
import 'package:therapii/pages/verify_email_page.dart';
import 'package:therapii/services/invitation_service.dart';
import 'package:therapii/utils/admin_access.dart';
import 'package:therapii/theme_mode_controller.dart';
import 'package:url_launcher/url_launcher.dart';

enum AuthTab { create, login }
enum AccountRole { therapist, patient }

class AuthWelcomePage extends StatefulWidget {
  final AuthTab initialTab;
  final bool openJournalPortalAfterAuth;
  const AuthWelcomePage({
    super.key,
    this.initialTab = AuthTab.create,
    this.openJournalPortalAfterAuth = false,
  });

  @override
  State<AuthWelcomePage> createState() => _AuthWelcomePageState();
}

class _AuthWelcomePageState extends State<AuthWelcomePage> {
  late AuthTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: _AuthCard(
                  tab: _tab,
                  openJournalPortalAfterAuth: widget.openJournalPortalAfterAuth,
                  onTabChanged: (t) => setState(() => _tab = t),
                ),
              ),
            ),
          ),
          // Theme toggle button
          Positioned(
            bottom: 32,
            right: 32,
            child: _ThemeToggleButton(),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (MediaQuery.of(context).size.width > 600)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'Switch Theme',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        Material(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          child: InkWell(
            onTap: () => themeModeController.toggleLightDark(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                size: 24,
                color: isDark ? const Color(0xFFFACC15) : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  final AuthTab tab;
  final bool openJournalPortalAfterAuth;
  final ValueChanged<AuthTab> onTabChanged;
  
  const _AuthCard({
    required this.tab,
    required this.onTabChanged,
    required this.openJournalPortalAfterAuth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.8) : Colors.white;
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(showJournalTag: openJournalPortalAfterAuth),
            const SizedBox(height: 48),
            _TabBar(tab: tab, onChanged: onTabChanged),
            const SizedBox(height: 40),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: tab == AuthTab.create 
                ? _CreateAccountForm(
                    key: const ValueKey('create'),
                    openJournalPortalAfterAuth: openJournalPortalAfterAuth,
                  ) 
                : _LoginForm(
                    key: const ValueKey('login'),
                    openJournalPortalAfterAuth: openJournalPortalAfterAuth,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool showJournalTag;
  const _Header({this.showJournalTag = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset('assets/images/therapii_logo.png', height: 240, fit: BoxFit.contain),
              if (showJournalTag)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E67DD), Color(0xFF1546B9)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1754CF).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Text(
                      'JORNUAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Welcome',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  final AuthTab tab;
  final ValueChanged<AuthTab> onChanged;
  
  const _TabBar({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final unselectedColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final selectedColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    Widget buildTab(String label, AuthTab value) {
      final isSelected = tab == value;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(value),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? selectedColor : unselectedColor,
                  ),
                ),
              ),
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: isSelected ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: Row(
        children: [
          buildTab('Create Account', AuthTab.create),
          buildTab('Log in', AuthTab.login),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final AccountRole? role;
  final ValueChanged<AccountRole> onChanged;
  final bool enabled;

  const _RoleSelector({
    required this.role,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final selectedBg = isDark ? const Color(0xFF475569) : Colors.white;
    final unselectedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final selectedText = isDark ? Colors.white : const Color(0xFF0F172A);

    Widget buildOption(String label, AccountRole value) {
      final isSelected = role == value;
      return Expanded(
        child: GestureDetector(
          onTap: enabled ? () => onChanged(value) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
              border: isSelected && !isDark ? Border.all(
                color: const Color(0xFFE2E8F0),
              ) : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? selectedText : unselectedText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Text(
          'SELECT ACCOUNT TYPE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              buildOption('Therapist', AccountRole.therapist),
              buildOption('Patient', AccountRole.patient),
            ],
          ),
        ),
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;

  const _StyledTextField({
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF334155).withValues(alpha: 0.4) : const Color(0xFFF8FAFC).withValues(alpha: 0.5);
    final borderColor = isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final placeholderColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      style: TextStyle(fontSize: 18, color: textColor),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(fontSize: 18, color: placeholderColor),
        filled: true,
        fillColor: bgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool enabled;

  const _PasswordField({
    required this.controller,
    required this.placeholder,
    this.enabled = true,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return _StyledTextField(
      controller: widget.controller,
      placeholder: widget.placeholder,
      obscureText: _obscured,
      enabled: widget.enabled,
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscured = !_obscured),
        icon: Icon(
          _obscured ? Icons.visibility_off : Icons.visibility,
          size: 24,
          color: iconColor,
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PrimaryActionButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      shadowColor: scheme.primary.withValues(alpha: 0.3),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _CreateAccountForm extends StatefulWidget {
  final bool openJournalPortalAfterAuth;
  const _CreateAccountForm({
    super.key,
    required this.openJournalPortalAfterAuth,
  });

  @override
  State<_CreateAccountForm> createState() => _CreateAccountFormState();
}

class _CreateAccountFormState extends State<_CreateAccountForm> {
  final nameCtl = TextEditingController();
  final emailCtl = TextEditingController();
  final passCtl = TextEditingController();
  final confirmCtl = TextEditingController();
  bool agreeTos = false;
  bool agreePrivacy = false;
  bool _isLoading = false;
  final FirebaseAuthManager _authManager = FirebaseAuthManager();
  AccountRole? _role;

  Uint8List? _avatarBytes;
  String? _avatarFileName;
  String? _avatarPreviewUrl;

  @override
  void dispose() {
    nameCtl.dispose();
    emailCtl.dispose();
    passCtl.dispose();
    confirmCtl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final pending = InvitationService.pendingInvitation;
    if (pending != null) {
      final composedName = pending.patientFullName.trim();
      nameCtl.text = composedName.isNotEmpty ? composedName : pending.patientFirstName;
      emailCtl.text = pending.patientEmail;
      _role = AccountRole.patient;
    }
  }

  Future<void> _pickAvatar() async {
    try {
      debugPrint('[Auth] Avatar tap detected. Opening file picker...');
      final typeGroup = const XTypeGroup(label: 'Images', extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp']);
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) {
        debugPrint('[Auth] File picker canceled.');
        return;
      }
      final bytes = await file.readAsBytes();
      debugPrint('[Auth] Picked file: name=${file.name}, size=${bytes.length}');
      setState(() {
        _avatarBytes = bytes;
        _avatarFileName = file.name;
        _avatarPreviewUrl = null;
      });
    } catch (e, st) {
      debugPrint('[Auth] Error picking image (file_selector): $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not pick image.')));
    }
  }

  Future<String?> _uploadAvatar(String userId) async {
    if (_avatarBytes == null) return null;
    try {
      final ext = (_avatarFileName ?? 'avatar').split('.').last.toLowerCase();
      final ref = FirebaseStorage.instance.ref('user_avatars/$userId/profile.$ext');
      final metadata = SettableMetadata(contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}');
      await ref.putData(_avatarBytes!, metadata);
      final url = await ref.getDownloadURL();
      setState(() => _avatarPreviewUrl = url);
      return url;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload avatar.')));
      return null;
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_role == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Please select account type: Therapist or Patient.')));
      return;
    }
    if (!agreeTos || !agreePrivacy) {
      messenger.showSnackBar(const SnackBar(content: Text('Please agree to Terms of Service and Privacy Policy.')));
      return;
    }
    if (nameCtl.text.isEmpty || emailCtl.text.isEmpty || passCtl.text.isEmpty || confirmCtl.text.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Fill in all fields.')));
      return;
    }
    if (passCtl.text != confirmCtl.text) {
      messenger.showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final isTherapist = _role == AccountRole.therapist;
      final created = await _authManager.createAccountWithEmail(
        context,
        emailCtl.text.trim(),
        passCtl.text,
        isTherapist: isTherapist,
      );
      if (created != null) {
        final pending = InvitationService.pendingInvitation;
        if (pending != null) {
          try {
            await UserService().linkPatientToTherapist(
              userId: created.id,
              therapistId: pending.therapistId,
            );
            await InvitationService().validateAndUseCode(
              code: pending.code,
              patientId: created.id,
            );
            InvitationService.pendingInvitation = null;
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(content: Text('Linked account but failed to finalize code: $e')),
            );
          }
        }
        final storageUrl = await _uploadAvatar(created.id);
        final userService = UserService();
        await userService.updateProfile(
          userId: created.id,
          firstName: nameCtl.text.trim(),
          lastName: '',
          avatarUrl: storageUrl,
          isTherapist: isTherapist,
        );
        final authUser = FirebaseAuth.FirebaseAuth.instance.currentUser;
        if (authUser != null) {
          await authUser.updateDisplayName(nameCtl.text.trim());
          if (storageUrl != null) {
            await authUser.updatePhotoURL(storageUrl);
          }
        }
        final currentUser = FirebaseAuth.FirebaseAuth.instance.currentUser;
        if (currentUser != null && !currentUser.emailVerified) {
          await _authManager.sendEmailVerification(user: currentUser);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => VerifyEmailPage(
                  email: emailCtl.text.trim(),
                  isTherapist: isTherapist,
                  openJournalPortalAfterVerification: widget.openJournalPortalAfterAuth,
                ),
              ),
            );
          }
        } else if (mounted) {
          final email = currentUser?.email;
          if (AdminAccess.isAdminEmail(email)) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => widget.openJournalPortalAfterAuth
                    ? const JournalAdminStudioPage()
                    : const AdminDashboardPage(),
              ),
            );
          } else if (widget.openJournalPortalAfterAuth) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const JournalPortalPage(),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => isTherapist ? const TherapistDashboardPage() : const PatientOnboardingFlowPage(),
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    
    final avatarWidget = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _pickAvatar,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: 44,
          backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
          backgroundImage: _avatarBytes != null
              ? MemoryImage(_avatarBytes!)
              : (_avatarPreviewUrl != null ? NetworkImage(_avatarPreviewUrl!) as ImageProvider : null),
          child: _avatarBytes == null && _avatarPreviewUrl == null
              ? Icon(Icons.person, size: 56, color: isDark ? const Color(0xFF64748B) : Colors.grey.shade600)
              : null,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: avatarWidget),
        const SizedBox(height: 24),
        _RoleSelector(
          role: _role,
          onChanged: (r) => setState(() => _role = r),
          enabled: !_isLoading,
        ),
        const SizedBox(height: 32),
        _StyledTextField(
          controller: nameCtl,
          placeholder: 'User Name',
          enabled: !_isLoading,
        ),
        const SizedBox(height: 20),
        _StyledTextField(
          controller: emailCtl,
          placeholder: 'Email Address',
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 20),
        _PasswordField(
          controller: passCtl,
          placeholder: 'Password',
          enabled: !_isLoading,
        ),
        const SizedBox(height: 20),
        _PasswordField(
          controller: confirmCtl,
          placeholder: 'Confirm Password',
          enabled: !_isLoading,
        ),
        const SizedBox(height: 20),
        TermsCheckbox(
          value: agreeTos,
          onChanged: (v) => setState(() => agreeTos = v ?? false),
          label: 'I agree to the Therapii',
          underlined: 'Terms of Service',
          onLinkTap: () => _openUrl('https://trytherapii.com/?page_id=115'),
        ),
        const SizedBox(height: 8),
        TermsCheckbox(
          value: agreePrivacy,
          onChanged: (v) => setState(() => agreePrivacy = v ?? false),
          label: 'I agree to the Therapii',
          underlined: 'Privacy Policy',
          onLinkTap: () => _openUrl('https://trytherapii.com/?page_id=3'),
        ),
        const SizedBox(height: 24),
        _PrimaryActionButton(
          label: 'SUBMIT',
          onPressed: _submit,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}

class _LoginForm extends StatefulWidget {
  final bool openJournalPortalAfterAuth;
  const _LoginForm({
    super.key,
    required this.openJournalPortalAfterAuth,
  });

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final emailCtl = TextEditingController();
  final passCtl = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  final FirebaseAuthManager _authManager = FirebaseAuthManager();
  AccountRole? _role;

  static const _rememberEmailKey = 'remember_email';
  static const _rememberMeKey = 'remember_me';

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remembered = prefs.getBool(_rememberMeKey) ?? false;
      final email = prefs.getString(_rememberEmailKey) ?? '';
      if (mounted && remembered && email.isNotEmpty) {
        setState(() {
          _rememberMe = true;
          emailCtl.text = email;
        });
      }
    } catch (e) {
      debugPrint('[Auth] Failed to load remembered email: $e');
    }
  }

  Future<void> _saveRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool(_rememberMeKey, true);
        await prefs.setString(_rememberEmailKey, emailCtl.text.trim());
      } else {
        await prefs.remove(_rememberMeKey);
        await prefs.remove(_rememberEmailKey);
      }
    } catch (e) {
      debugPrint('[Auth] Failed to save remembered email: $e');
    }
  }

  @override
  void dispose() {
    emailCtl.dispose();
    passCtl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_role == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Please select account type: Therapist or Patient.')));
      return;
    }
    if (emailCtl.text.isEmpty || passCtl.text.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter email and password.')));
      return;
    }

    setState(() => _isLoading = true);
    await _saveRememberedEmail();
    try {
      final user = await _authManager.signInWithEmail(
        context,
        emailCtl.text.trim(),
        passCtl.text,
      );

      if (user != null) {
        final selectedTherapist = _role == AccountRole.therapist;
        if (user.isTherapist != selectedTherapist) {
          final actualRole = user.isTherapist ? 'Therapist' : 'Patient';
          await _authManager.signOut();
          messenger.showSnackBar(
            SnackBar(content: Text('This account is registered as a $actualRole. Switch to the $actualRole role to continue.')),
          );
          return;
        }
        final pending = InvitationService.pendingInvitation;
        if (pending != null) {
          try {
            await UserService().linkPatientToTherapist(
              userId: user.id,
              therapistId: pending.therapistId,
            );
            await InvitationService().validateAndUseCode(
              code: pending.code,
              patientId: user.id,
            );
            InvitationService.pendingInvitation = null;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to apply invitation: $e')),
            );
          }
        }
        final authUser = FirebaseAuth.FirebaseAuth.instance.currentUser;
        final requiresVerification = authUser != null && !authUser.emailVerified;

        if (requiresVerification) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => VerifyEmailPage(
                  email: emailCtl.text.trim(),
                  isTherapist: user.isTherapist,
                  openJournalPortalAfterVerification: widget.openJournalPortalAfterAuth,
                ),
              ),
            );
          }
          return;
        }

        if (mounted) {
          if (AdminAccess.isAdminEmail(authUser?.email)) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => widget.openJournalPortalAfterAuth
                    ? const JournalAdminStudioPage()
                    : const AdminDashboardPage(),
              ),
            );
          } else if (user.isTherapist) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => widget.openJournalPortalAfterAuth
                    ? const JournalPortalPage()
                    : const TherapistDashboardPage(),
              ),
            );
          } else {
            final destination = widget.openJournalPortalAfterAuth
                ? const JournalPortalPage()
                : (user.patientOnboardingCompleted
                    ? const PatientDashboardPage()
                    : const PatientOnboardingFlowPage());
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => destination),
            );
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = emailCtl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email to reset your password.')),
      );
      return;
    }
    await _authManager.resetPassword(email: email, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final textColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RoleSelector(
          role: _role,
          onChanged: (r) => setState(() => _role = r),
          enabled: !_isLoading,
        ),
        const SizedBox(height: 32),
        _StyledTextField(
          controller: emailCtl,
          placeholder: 'Email Address',
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 20),
        _PasswordField(
          controller: passCtl,
          placeholder: 'Password',
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: _isLoading ? null : (v) => setState(() => _rememberMe = v ?? false),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isLoading ? null : () => setState(() => _rememberMe = !_rememberMe),
              child: Text(
                'Remember Me',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _isLoading ? null : _forgotPassword,
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _PrimaryActionButton(
          label: 'LOG IN',
          onPressed: _login,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
