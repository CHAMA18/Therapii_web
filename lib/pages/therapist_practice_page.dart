import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:therapii/pages/therapist_therapeutic_models_page.dart';
import 'package:therapii/widgets/primary_button.dart';

class TherapistPracticePage extends StatefulWidget {
  const TherapistPracticePage({super.key});

  @override
  State<TherapistPracticePage> createState() => _TherapistPracticePageState();
}

class _TherapistPracticePageState extends State<TherapistPracticePage> {
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
  String? _profilePhotoName;
  String? _certificateName;
  String? _governmentIdName;

  // Licensure entries
  final List<LicensureEntry> _licensureEntries = [];

  // Education entries
  final List<EducationEntry> _educationEntries = [];

  static const List<String> _usStates = [
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
    'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
    'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
    'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
    'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
    'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
    'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
    'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
    'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
    'West Virginia', 'Wisconsin', 'Wyoming', 'District of Columbia',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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

  Future<void> _loadInitialData() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('therapists').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        _fullNameController.text = data['full_name'] ?? user.displayName ?? '';
        _practiceNameController.text = data['practice_name'] ?? '';
        _cityController.text = data['city'] ?? '';
        _selectedState = data['state'];
        _zipCodeController.text = data['zip_code'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? user.email ?? '';

        // Load existing file names if available
        _profilePhotoName = data['profile_photo_name'];
        _certificateName = data['certificate_name'];
        _governmentIdName = data['government_id_name'];

        // Load licensure entries
        final licensures = data['licensures'] as List<dynamic>?;
        if (licensures != null) {
          for (final entry in licensures) {
            _licensureEntries.add(LicensureEntry.fromMap(entry as Map<String, dynamic>));
          }
        }

        // Load education entries
        final educations = data['educations'] as List<dynamic>?;
        if (educations != null) {
          for (final entry in educations) {
            _educationEntries.add(EducationEntry.fromMap(entry as Map<String, dynamic>));
          }
        }
      } else {
        _emailController.text = user.email ?? '';
        _fullNameController.text = user.displayName ?? '';
      }
    } catch (e) {
      debugPrint('Error loading therapist data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFile(String type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type == 'photo' ? FileType.image : FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final fileName = result.files.first.name;
        setState(() {
          switch (type) {
            case 'photo':
              _profilePhotoName = fileName;
              break;
            case 'certificate':
              _certificateName = fileName;
              break;
            case 'id':
              _governmentIdName = fileName;
              break;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to pick file. Please try again.')),
        );
      }
    }
  }

  void _addLicensureEntry() {
    showDialog(
      context: context,
      builder: (ctx) => LicensureDialog(
        states: _usStates,
        onSave: (entry) {
          setState(() => _licensureEntries.add(entry));
        },
      ),
    );
  }

  void _addEducationEntry() {
    showDialog(
      context: context,
      builder: (ctx) => EducationDialog(
        onSave: (entry) {
          setState(() => _educationEntries.add(entry));
        },
      ),
    );
  }

  void _removeLicensure(int index) {
    setState(() => _licensureEntries.removeAt(index));
  }

  void _removeEducation(int index) {
    setState(() => _educationEntries.removeAt(index));
  }

  Future<void> _logout() async {
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out right now. Please try again.')),
      );
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
      final data = <String, dynamic>{
        'full_name': _fullNameController.text.trim(),
        'practice_name': _practiceNameController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _selectedState,
        'zip_code': _zipCodeController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'profile_photo_name': _profilePhotoName,
        'certificate_name': _certificateName,
        'government_id_name': _governmentIdName,
        'licensures': _licensureEntries.map((e) => e.toMap()).toList(),
        'educations': _educationEntries.map((e) => e.toMap()).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('therapists').doc(user.uid).set(
            data,
            SetOptions(merge: true),
          );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TherapistTherapeuticModelsPage()),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDark ? scheme.surface : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(context, scheme, isDark),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleSection(context, scheme),
                          const SizedBox(height: 40),
                          _buildContactSection(context, scheme, isDark),
                          const SizedBox(height: 48),
                          _buildVerificationSection(context, scheme, isDark),
                          const SizedBox(height: 48),
                          _buildLicensureSection(context, scheme, isDark),
                          const SizedBox(height: 24),
                          _buildEducationSection(context, scheme, isDark),
                          const SizedBox(height: 48),
                          _buildFooter(context, scheme),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? scheme.surface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? scheme.outline.withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/Therapii_image.png',
                  height: 32,
                  fit: BoxFit.contain,
                ),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: Icon(Icons.logout_rounded, size: 18, color: isDark ? scheme.onSurface : const Color(0xFF64748B)),
                  label: Text(
                    'Logout',
                    style: TextStyle(color: isDark ? scheme.onSurface : const Color(0xFF64748B)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: isDark ? scheme.outline.withValues(alpha: 0.4) : const Color(0xFFE2E8F0)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRACTICE SETUP',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Contact and Licensure Information',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Complete your professional profile to begin practicing on the platform.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context, ColorScheme scheme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return Column(
          children: [
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name',
              placeholder: 'John Doe',
              isDark: isDark,
              scheme: scheme,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _practiceNameController,
              label: 'Practice / Office Name',
              placeholder: 'Healing Minds Wellness',
              isDark: isDark,
              scheme: scheme,
            ),
            const SizedBox(height: 20),
            if (isWide)
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      placeholder: 'New York',
                      isDark: isDark,
                      scheme: scheme,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildDropdown(
                      label: 'State',
                      value: _selectedState,
                      items: _usStates,
                      onChanged: (val) => setState(() => _selectedState = val),
                      isDark: isDark,
                      scheme: scheme,
                    ),
                  ),
                ],
              )
            else ...[
              _buildTextField(
                controller: _cityController,
                label: 'City',
                placeholder: 'New York',
                isDark: isDark,
                scheme: scheme,
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'State',
                value: _selectedState,
                items: _usStates,
                onChanged: (val) => setState(() => _selectedState = val),
                isDark: isDark,
                scheme: scheme,
              ),
            ],
            const SizedBox(height: 20),
            if (isWide)
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _zipCodeController,
                      label: 'Zip Code',
                      placeholder: '10001',
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                      scheme: scheme,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      placeholder: '+1 (555) 000-0000',
                      keyboardType: TextInputType.phone,
                      isDark: isDark,
                      scheme: scheme,
                    ),
                  ),
                ],
              )
            else ...[
              _buildTextField(
                controller: _zipCodeController,
                label: 'Zip Code',
                placeholder: '10001',
                keyboardType: TextInputType.number,
                isDark: isDark,
                scheme: scheme,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                placeholder: '+1 (555) 000-0000',
                keyboardType: TextInputType.phone,
                isDark: isDark,
                scheme: scheme,
              ),
            ],
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              placeholder: 'john.doe@example.com',
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
              scheme: scheme,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required bool isDark,
    required ColorScheme scheme,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark ? scheme.onSurface.withValues(alpha: 0.8) : const Color(0xFF475569),
              ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.4)),
            filled: true,
            fillColor: isDark ? scheme.surface : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? scheme.outline.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? scheme.outline.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
    required ColorScheme scheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark ? scheme.onSurface.withValues(alpha: 0.8) : const Color(0xFF475569),
              ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text('Select State', style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.4))),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? scheme.surface : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? scheme.outline.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? scheme.outline.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildVerificationSection(BuildContext context, ColorScheme scheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Professional Verification',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            if (isWide) {
              return Row(
                children: [
                  Expanded(child: _buildUploadCard(
                    icon: Icons.person_rounded,
                    title: 'Profile Photo',
                    description: 'Clear headshot for your public profile',
                    fileName: _profilePhotoName,
                    onTap: () => _pickFile('photo'),
                    isDark: isDark,
                    scheme: scheme,
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUploadCard(
                    icon: Icons.school_rounded,
                    title: 'Certificates',
                    description: 'Copy of your degree or certification',
                    fileName: _certificateName,
                    onTap: () => _pickFile('certificate'),
                    isDark: isDark,
                    scheme: scheme,
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUploadCard(
                    icon: Icons.badge_rounded,
                    title: 'Government ID',
                    description: 'Passport, License, or State ID',
                    fileName: _governmentIdName,
                    onTap: () => _pickFile('id'),
                    isDark: isDark,
                    scheme: scheme,
                  )),
                ],
              );
            }
            return Column(
              children: [
                _buildUploadCard(
                  icon: Icons.person_rounded,
                  title: 'Profile Photo',
                  description: 'Clear headshot for your public profile',
                  fileName: _profilePhotoName,
                  onTap: () => _pickFile('photo'),
                  isDark: isDark,
                  scheme: scheme,
                ),
                const SizedBox(height: 16),
                _buildUploadCard(
                  icon: Icons.school_rounded,
                  title: 'Certificates',
                  description: 'Copy of your degree or certification',
                  fileName: _certificateName,
                  onTap: () => _pickFile('certificate'),
                  isDark: isDark,
                  scheme: scheme,
                ),
                const SizedBox(height: 16),
                _buildUploadCard(
                  icon: Icons.badge_rounded,
                  title: 'Government ID',
                  description: 'Passport, License, or State ID',
                  fileName: _governmentIdName,
                  onTap: () => _pickFile('id'),
                  isDark: isDark,
                  scheme: scheme,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildUploadCard({
    required IconData icon,
    required String title,
    required String description,
    required String? fileName,
    required VoidCallback onTap,
    required bool isDark,
    required ColorScheme scheme,
  }) {
    final hasFile = fileName != null && fileName.isNotEmpty;
    final borderColor = hasFile
        ? scheme.primary
        : (isDark ? scheme.outline.withValues(alpha: 0.3) : const Color(0xFFE2E8F0));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: scheme.primary.withValues(alpha: 0.04),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: borderColor,
            strokeWidth: hasFile ? 2 : 2,
            radius: 12,
            dashWidth: 6,
            dashSpace: 4,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? scheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? scheme.primary.withValues(alpha: 0.15)
                        : const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: scheme.primary, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (hasFile)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: scheme.primary, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          fileName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.primary,
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
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

  Widget _buildLicensureSection(BuildContext context, ColorScheme scheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? scheme.outline.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'State Licensure',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Provide details for each state you are licensed to practice in.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _addLicensureEntry,
                  icon: Icon(Icons.add_circle_outline_rounded, color: scheme.outline),
                ),
              ],
            ),
          ),
          if (_licensureEntries.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _licensureEntries.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: scheme.outline.withValues(alpha: 0.2)),
              itemBuilder: (context, index) {
                final entry = _licensureEntries[index];
                return ListTile(
                  title: Text('${entry.state} - ${entry.licenseNumber}'),
                  subtitle: Text('Expires: ${entry.expirationDate ?? 'N/A'}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                    onPressed: () => _removeLicensure(index),
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: TextButton.icon(
              onPressed: _addLicensureEntry,
              icon: Icon(Icons.add_rounded, size: 18, color: scheme.primary),
              label: Text('Add State Licensure', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection(BuildContext context, ColorScheme scheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? scheme.outline.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Education',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add your academic qualifications so patients can see your expertise at a glance.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _addEducationEntry,
                  icon: Icon(Icons.add_circle_outline_rounded, color: scheme.outline),
                ),
              ],
            ),
          ),
          if (_educationEntries.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _educationEntries.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: scheme.outline.withValues(alpha: 0.2)),
              itemBuilder: (context, index) {
                final entry = _educationEntries[index];
                return ListTile(
                  title: Text('${entry.degree} - ${entry.institution}'),
                  subtitle: Text('Year: ${entry.graduationYear ?? 'N/A'}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                    onPressed: () => _removeEducation(index),
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: TextButton.icon(
              onPressed: _addEducationEntry,
              icon: Icon(Icons.add_rounded, size: 18, color: scheme.primary),
              label: Text('Add Education', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme scheme) {
    return Column(
      children: [
        Divider(color: scheme.outline.withValues(alpha: 0.2)),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: 'Continue',
                onPressed: _saving ? null : _saveAndContinue,
                isLoading: _saving,
                uppercase: false,
              ),
            ),
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
              child: Text(
                'Go Back',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Data models
class LicensureEntry {
  final String state;
  final String licenseNumber;
  final String? expirationDate;

  LicensureEntry({required this.state, required this.licenseNumber, this.expirationDate});

  Map<String, dynamic> toMap() => {
        'state': state,
        'license_number': licenseNumber,
        'expiration_date': expirationDate,
      };

  factory LicensureEntry.fromMap(Map<String, dynamic> map) => LicensureEntry(
        state: map['state'] ?? '',
        licenseNumber: map['license_number'] ?? '',
        expirationDate: map['expiration_date'],
      );
}

class EducationEntry {
  final String degree;
  final String institution;
  final String? graduationYear;

  EducationEntry({required this.degree, required this.institution, this.graduationYear});

  Map<String, dynamic> toMap() => {
        'degree': degree,
        'institution': institution,
        'graduation_year': graduationYear,
      };

  factory EducationEntry.fromMap(Map<String, dynamic> map) => EducationEntry(
        degree: map['degree'] ?? '',
        institution: map['institution'] ?? '',
        graduationYear: map['graduation_year'],
      );
}

// Dialogs
class LicensureDialog extends StatefulWidget {
  final List<String> states;
  final void Function(LicensureEntry entry) onSave;

  const LicensureDialog({super.key, required this.states, required this.onSave});

  @override
  State<LicensureDialog> createState() => _LicensureDialogState();
}

class _LicensureDialogState extends State<LicensureDialog> {
  String? _selectedState;
  final _licenseController = TextEditingController();
  final _expirationController = TextEditingController();

  @override
  void dispose() {
    _licenseController.dispose();
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
              value: _selectedState,
              decoration: const InputDecoration(labelText: 'State'),
              items: widget.states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _selectedState = val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _licenseController,
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
            if (_selectedState != null && _licenseController.text.trim().isNotEmpty) {
              widget.onSave(LicensureEntry(
                state: _selectedState!,
                licenseNumber: _licenseController.text.trim(),
                expirationDate: _expirationController.text.trim().isEmpty ? null : _expirationController.text.trim(),
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class EducationDialog extends StatefulWidget {
  final void Function(EducationEntry entry) onSave;

  const EducationDialog({super.key, required this.onSave});

  @override
  State<EducationDialog> createState() => _EducationDialogState();
}

class _EducationDialogState extends State<EducationDialog> {
  final _degreeController = TextEditingController();
  final _institutionController = TextEditingController();
  final _yearController = TextEditingController();

  @override
  void dispose() {
    _degreeController.dispose();
    _institutionController.dispose();
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
            TextField(
              controller: _degreeController,
              decoration: const InputDecoration(labelText: 'Degree (e.g., Ph.D., M.A.)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _institutionController,
              decoration: const InputDecoration(labelText: 'Institution'),
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
            if (_degreeController.text.trim().isNotEmpty && _institutionController.text.trim().isNotEmpty) {
              widget.onSave(EducationEntry(
                degree: _degreeController.text.trim(),
                institution: _institutionController.text.trim(),
                graduationYear: _yearController.text.trim().isEmpty ? null : _yearController.text.trim(),
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Custom painter for dashed border effect
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        dashPath.addPath(
          metric.extractPath(distance, nextDistance > metric.length ? metric.length : nextDistance),
          Offset.zero,
        );
        distance = nextDistance + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      radius != oldDelegate.radius ||
      dashWidth != oldDelegate.dashWidth ||
      dashSpace != oldDelegate.dashSpace;
}
