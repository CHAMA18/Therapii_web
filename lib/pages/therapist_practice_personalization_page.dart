import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:therapii/data/universities.dart';
import 'package:therapii/pages/therapist_inspiration_page.dart';
import 'package:therapii/theme.dart';

class TherapistPracticePersonalizationPage extends StatefulWidget {
  const TherapistPracticePersonalizationPage({super.key});

  @override
  State<TherapistPracticePersonalizationPage> createState() => _TherapistPracticePersonalizationPageState();
}

class _TherapistPracticePersonalizationPageState extends State<TherapistPracticePersonalizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _practiceNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedState;
  bool _loading = true;
  bool _saving = false;

  // File upload states
  Uint8List? _profilePhotoBytes;
  String? _profilePhotoName;
  Uint8List? _certificateBytes;
  String? _certificateName;
  Uint8List? _governmentIdBytes;
  String? _governmentIdName;

  // Licensure entries
  final List<LicensureEntry> _licensureEntries = [];

  // Education entries
  final List<EducationEntry> _educationEntries = [];

  final List<String> _usStates = [
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut',
    'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa',
    'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan',
    'Minnesota', 'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire',
    'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio',
    'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
    'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington', 'West Virginia',
    'Wisconsin', 'Wyoming',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _practiceNameController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('therapists').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        _fullNameController.text = data['full_name'] ?? '';
        _practiceNameController.text = data['practice_name'] ?? '';
        _cityController.text = data['city'] ?? '';
        _selectedState = data['state'];
        _zipCodeController.text = data['zip_code'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? user.email ?? '';

        // Load licensure entries
        final licensures = data['licensures'] as List<dynamic>?;
        if (licensures != null) {
          for (final lic in licensures) {
            _licensureEntries.add(LicensureEntry(
              state: lic['state'],
              licenseNumber: lic['license_number'],
              expirationDate: lic['expiration_date'],
            ));
          }
        }

        // Load education entries
        final educations = data['educations'] as List<dynamic>?;
        if (educations != null) {
          for (final edu in educations) {
            _educationEntries.add(EducationEntry(
              institution: edu['institution'],
              degree: edu['degree'],
              graduationYear: edu['graduation_year'],
            ));
          }
        }
      } else {
        _emailController.text = user.email ?? '';
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickFile(String type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          switch (type) {
            case 'profile':
              _profilePhotoBytes = file.bytes;
              _profilePhotoName = file.name;
              break;
            case 'certificate':
              _certificateBytes = file.bytes;
              _certificateName = file.name;
              break;
            case 'government_id':
              _governmentIdBytes = file.bytes;
              _governmentIdName = file.name;
              break;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be signed in to continue.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('therapists').doc(user.uid).set(
        {
          'full_name': _fullNameController.text.trim(),
          'practice_name': _practiceNameController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _selectedState,
          'zip_code': _zipCodeController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'licensures': _licensureEntries.map((e) => e.toMap()).toList(),
          'educations': _educationEntries.map((e) => e.toMap()).toList(),
          'contact_info_completed_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TherapistInspirationPage()),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save. ${e.message ?? e.code}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _addLicensure() {
    showDialog(
      context: context,
      builder: (ctx) => _LicensureDialog(
        states: _usStates,
        onSave: (entry) {
          setState(() => _licensureEntries.add(entry));
        },
      ),
    );
  }

  void _addEducation() {
    showDialog(
      context: context,
      builder: (ctx) => _EducationDialog(
        onSave: (entry) {
          setState(() => _educationEntries.add(entry));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 768;

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? DarkModeColors.surface : const Color(0xFFF9FAFB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? DarkModeColors.surface : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Sticky Header
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(
                bottom: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                      ),
                      const Spacer(),
                      Text(
                        'Practice Setup',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 48 : 24,
                  vertical: 40,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header row with logo and logout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompactHeader = constraints.maxWidth < 520;
                          return Flex(
                            direction: isCompactHeader ? Axis.vertical : Axis.horizontal,
                            mainAxisAlignment: isCompactHeader ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: isCompactHeader ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Therapii',
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (isCompactHeader) const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await firebase_auth.FirebaseAuth.instance.signOut();
                                  if (mounted) {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  }
                                },
                                icon: Icon(Icons.logout, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                label: Text(
                                  'Logout',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: isDark ? Colors.grey[700]! : const Color(0xFFE2E8F0)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Page title
                      Text(
                        'PRACTICE SETUP',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Contact and Licensure Information',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete your professional profile to begin practicing on the platform.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Contact Information Section
                      _buildContactSection(context, isWide),
                      const SizedBox(height: 48),

                      // Professional Verification Section
                      _buildVerificationSection(context, isWide),
                      const SizedBox(height: 48),

                      // Licensure Section
                      _buildLicensureSection(context),
                      const SizedBox(height: 24),

                      // Education Section
                      _buildEducationSection(context),
                      const SizedBox(height: 48),

                      // Footer buttons
                      Container(
                        padding: const EdgeInsets.only(top: 32),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            FilledButton(
                              onPressed: _saving ? null : _saveAndContinue,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                elevation: 4,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      'Continue',
                                      style: textTheme.labelLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            TextButton(
                              onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                              child: Text(
                                'Go Back',
                                style: textTheme.labelLarge?.copyWith(
                                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full Name
        _buildFormField(
          context,
          label: 'Full Name',
          child: TextFormField(
            controller: _fullNameController,
            decoration: _inputDecoration(context, 'John Doe'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
        ),
        const SizedBox(height: 20),

        // Practice Name
        _buildFormField(
          context,
          label: 'Practice / Office Name',
          child: TextFormField(
            controller: _practiceNameController,
            decoration: _inputDecoration(context, 'Healing Minds Wellness'),
          ),
        ),
        const SizedBox(height: 20),

        // City and State row
        isWide
            ? Row(
                children: [
                  Expanded(
                    child: _buildFormField(
                      context,
                      label: 'City',
                      child: TextFormField(
                        controller: _cityController,
                        decoration: _inputDecoration(context, 'New York'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildFormField(
                      context,
                      label: 'State',
                      child: DropdownButtonFormField<String>(
                        value: _selectedState,
                        decoration: _inputDecoration(context, 'Select State'),
                        items: _usStates
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedState = v),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildFormField(
                    context,
                    label: 'City',
                    child: TextFormField(
                      controller: _cityController,
                      decoration: _inputDecoration(context, 'New York'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    context,
                    label: 'State',
                    child: DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: _inputDecoration(context, 'Select State'),
                      items: _usStates
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedState = v),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 20),

        // Zip Code and Phone row
        isWide
            ? Row(
                children: [
                  Expanded(
                    child: _buildFormField(
                      context,
                      label: 'Zip Code',
                      child: TextFormField(
                        controller: _zipCodeController,
                        decoration: _inputDecoration(context, '10001'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildFormField(
                      context,
                      label: 'Phone Number',
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: _inputDecoration(context, '+1 (555) 000-0000'),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildFormField(
                    context,
                    label: 'Zip Code',
                    child: TextFormField(
                      controller: _zipCodeController,
                      decoration: _inputDecoration(context, '10001'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    context,
                    label: 'Phone Number',
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration(context, '+1 (555) 000-0000'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 20),

        // Email
        _buildFormField(
          context,
          label: 'Email Address',
          child: TextFormField(
            controller: _emailController,
            decoration: _inputDecoration(context, 'john.doe@example.com'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationSection(BuildContext context, bool isWide) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Professional Verification',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        isWide
            ? Row(
                children: [
                  Expanded(child: _buildUploadCard(context, 'profile', Icons.person, 'Profile Photo', 'Clear headshot for your public profile', _profilePhotoName)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUploadCard(context, 'certificate', Icons.school, 'Certificates', 'Copy of your degree or certification', _certificateName)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUploadCard(context, 'government_id', Icons.badge, 'Government ID', 'Passport, License, or State ID', _governmentIdName)),
                ],
              )
            : Column(
                children: [
                  _buildUploadCard(context, 'profile', Icons.person, 'Profile Photo', 'Clear headshot for your public profile', _profilePhotoName),
                  const SizedBox(height: 16),
                  _buildUploadCard(context, 'certificate', Icons.school, 'Certificates', 'Copy of your degree or certification', _certificateName),
                  const SizedBox(height: 16),
                  _buildUploadCard(context, 'government_id', Icons.badge, 'Government ID', 'Passport, License, or State ID', _governmentIdName),
                ],
              ),
      ],
    );
  }

  Widget _buildUploadCard(BuildContext context, String type, IconData icon, String title, String description, String? fileName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _pickFile(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: fileName != null
                ? colorScheme.primary.withValues(alpha: 0.5)
                : (isDark ? Colors.grey[700]! : const Color(0xFFE2E8F0)),
            width: fileName != null ? 2 : 2,
            style: fileName != null ? BorderStyle.solid : BorderStyle.none,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: DashedBorder(
          color: isDark ? Colors.grey[600]! : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (fileName != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          fileName,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Tap to upload',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLicensureSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : const Color(0xFFE2E8F0)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _addLicensure,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'State Licensure',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Provide details for each state you are licensed to practice in.',
                          style: textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.add_circle_outline, color: isDark ? Colors.grey[400] : Colors.grey[400]),
                ],
              ),
            ),
          ),
          if (_licensureEntries.isNotEmpty) ...[
            Divider(height: 1, color: isDark ? Colors.grey[700] : const Color(0xFFE2E8F0)),
            ..._licensureEntries.asMap().entries.map((entry) {
              final idx = entry.key;
              final lic = entry.value;
              return ListTile(
                title: Text('${lic.state} - ${lic.licenseNumber}'),
                subtitle: Text('Expires: ${lic.expirationDate ?? 'N/A'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => setState(() => _licensureEntries.removeAt(idx)),
                ),
              );
            }),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: InkWell(
              onTap: _addLicensure,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Add another State Licensure',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : const Color(0xFFE2E8F0)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _addEducation,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Education',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add your academic qualifications so patients can see your expertise at a glance.',
                          style: textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.add_circle_outline, color: isDark ? Colors.grey[400] : Colors.grey[400]),
                ],
              ),
            ),
          ),
          if (_educationEntries.isNotEmpty) ...[
            Divider(height: 1, color: isDark ? Colors.grey[700] : const Color(0xFFE2E8F0)),
            ..._educationEntries.asMap().entries.map((entry) {
              final idx = entry.key;
              final edu = entry.value;
              return ListTile(
                title: Text('${edu.degree} - ${edu.institution}'),
                subtitle: Text('Graduated: ${edu.graduationYear ?? 'N/A'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => setState(() => _educationEntries.removeAt(idx)),
                ),
              );
            }),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: InkWell(
              onTap: _addEducation,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Add another Education',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(BuildContext context, {required String label, required Widget child}) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? Colors.grey[700]! : const Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? Colors.grey[700]! : const Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}

// Helper classes
class LicensureEntry {
  final String? state;
  final String? licenseNumber;
  final String? expirationDate;

  LicensureEntry({this.state, this.licenseNumber, this.expirationDate});

  Map<String, dynamic> toMap() => {
        'state': state,
        'license_number': licenseNumber,
        'expiration_date': expirationDate,
      };
}

class EducationEntry {
  final String? institution;
  final String? degree;
  final String? graduationYear;

  EducationEntry({this.institution, this.degree, this.graduationYear});

  Map<String, dynamic> toMap() => {
        'institution': institution,
        'degree': degree,
        'graduation_year': graduationYear,
      };
}

// Licensure Dialog
class _LicensureDialog extends StatefulWidget {
  final List<String> states;
  final Function(LicensureEntry) onSave;

  const _LicensureDialog({required this.states, required this.onSave});

  @override
  State<_LicensureDialog> createState() => _LicensureDialogState();
}

class _LicensureDialogState extends State<_LicensureDialog> {
  String? _state;
  final _licenseNumberController = TextEditingController();
  final _expirationController = TextEditingController();

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _expirationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add State Licensure'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _state,
              decoration: const InputDecoration(labelText: 'State'),
              items: widget.states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _state = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _licenseNumberController,
              decoration: const InputDecoration(labelText: 'License Number'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _expirationController,
              decoration: const InputDecoration(labelText: 'Expiration Date (MM/YYYY)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            widget.onSave(LicensureEntry(
              state: _state,
              licenseNumber: _licenseNumberController.text.trim(),
              expirationDate: _expirationController.text.trim(),
            ));
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Education Dialog
class _EducationDialog extends StatefulWidget {
  final Function(EducationEntry) onSave;

  const _EducationDialog({required this.onSave});

  @override
  State<_EducationDialog> createState() => _EducationDialogState();
}

class _EducationDialogState extends State<_EducationDialog> {
  final _institutionController = TextEditingController();
  final _degreeController = TextEditingController();
  final _yearController = TextEditingController();
  String? _selectedInstitution;

  @override
  void dispose() {
    _institutionController.dispose();
    _degreeController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Education'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                return kUniversities.where((u) => u.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (selection) {
                _selectedInstitution = selection;
                _institutionController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Institution'),
                  onChanged: (v) {
                    _institutionController.text = v;
                    _selectedInstitution = v;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _degreeController,
              decoration: const InputDecoration(labelText: 'Degree (e.g., Ph.D., Psy.D.)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(labelText: 'Graduation Year'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            widget.onSave(EducationEntry(
              institution: _selectedInstitution ?? _institutionController.text.trim(),
              degree: _degreeController.text.trim(),
              graduationYear: _yearController.text.trim(),
            ));
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Dashed Border Widget
class DashedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final BorderRadius borderRadius;

  const DashedBorder({
    super.key,
    required this.child,
    this.color = Colors.grey,
    this.strokeWidth = 1.5,
    this.dashWidth = 6,
    this.dashSpace = 4,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final BorderRadius borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(borderRadius.toRRect(Rect.fromLTWH(0, 0, size.width, size.height)));

    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + length), Offset.zero);
        }
        distance += length;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
