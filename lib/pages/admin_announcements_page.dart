import 'package:flutter/material.dart';
import 'package:therapii/models/announcement.dart';
import 'package:therapii/services/announcement_service.dart';
import 'package:therapii/widgets/shimmer_widgets.dart';

class AdminAnnouncementsPage extends StatefulWidget {
  const AdminAnnouncementsPage({super.key});

  @override
  State<AdminAnnouncementsPage> createState() => _AdminAnnouncementsPageState();
}

class _AdminAnnouncementsPageState extends State<AdminAnnouncementsPage> {
  final _messageController = TextEditingController();
  AnnouncementTarget _selectedTarget = AnnouncementTarget.both;
  bool _isCreating = false;

  final AnnouncementService _service = AnnouncementService();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _createAnnouncement() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      await _service.createAnnouncement(text, _selectedTarget);
      if (!mounted) return;
      _messageController.clear();
      setState(() => _selectedTarget = AnnouncementTarget.both);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement created successfully.'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create announcement: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _toggleStatus(Announcement announcement) async {
    try {
      await _service.toggleAnnouncement(announcement.id, !announcement.isActive);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteAnnouncement(announcement.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement deleted.'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete announcement: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manage Announcements'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCreateSection(theme, isDark),
                    const SizedBox(height: 32),
                    Text(
                      'Past Announcements',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAnnouncementsList(theme, isDark),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.campaign_rounded, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Announcement',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This message will appear as a marquee across the selected dashboards.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Message content',
              hintText: 'Enter the announcement text...',
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<AnnouncementTarget>(
                  value: _selectedTarget,
                  decoration: InputDecoration(
                    labelText: 'Target Audience',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: AnnouncementTarget.both, child: Text('Both Therapists and Patients')),
                    DropdownMenuItem(value: AnnouncementTarget.therapist, child: Text('Therapists Only')),
                    DropdownMenuItem(value: AnnouncementTarget.patient, child: Text('Patients Only')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTarget = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isCreating ? null : _createAnnouncement,
                  icon: _isCreating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                  label: const Text('Publish Announcement'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList(ThemeData theme, bool isDark) {
    return StreamBuilder<List<Announcement>>(
      stream: _service.getAllAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AppShimmers.box(context: context, height: 100, width: double.infinity, radius: BorderRadius.circular(24)),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading announcements: ${snapshot.error}', style: TextStyle(color: theme.colorScheme.error)),
          );
        }

        final announcements = snapshot.data ?? [];

        if (announcements.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.3) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.campaign_outlined, size: 48, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  const SizedBox(height: 16),
                  Text(
                    'No announcements yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: announcements.map((announcement) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.3) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.message,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _targetLabel(announcement.target),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatDate(announcement.createdAt),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      Switch(
                        value: announcement.isActive,
                        onChanged: (_) => _toggleStatus(announcement),
                        activeColor: theme.colorScheme.primary,
                      ),
                      Text(
                        announcement.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          color: announcement.isActive ? theme.colorScheme.primary : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: () => _deleteAnnouncement(announcement),
                    tooltip: 'Delete Announcement',
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _targetLabel(AnnouncementTarget target) {
    switch (target) {
      case AnnouncementTarget.both:
        return 'Both';
      case AnnouncementTarget.therapist:
        return 'Therapists';
      case AnnouncementTarget.patient:
        return 'Patients';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
