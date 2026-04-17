import 'package:flutter/material.dart';
import 'package:therapii/models/announcement.dart';
import 'package:therapii/services/announcement_service.dart';

class AnnouncementBanner extends StatelessWidget {
  final AnnouncementTarget target;

  const AnnouncementBanner({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Announcement>>(
      stream: AnnouncementService().getActiveAnnouncements(target),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final announcements = snapshot.data!;
        
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: announcements.map((announcement) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        announcement.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
