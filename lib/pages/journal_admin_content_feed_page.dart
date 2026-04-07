import 'package:flutter/material.dart';
import 'package:therapii/pages/journal_admin_analytics_page.dart';
import 'package:therapii/pages/journal_admin_dashboard_page.dart';
import 'package:therapii/pages/journal_admin_patients_hub_page.dart';
import 'package:therapii/pages/journal_admin_settings_page.dart';
import 'package:therapii/pages/journal_admin_studio_page.dart';
import 'package:therapii/pages/journal_admin_team_hub_page.dart';
import 'package:therapii/pages/journal_portal_page.dart';
import 'package:therapii/services/app_page_state_service.dart';
import 'package:therapii/widgets/journal_admin_sidebar.dart';

class JournalAdminContentFeedPage extends StatelessWidget {
  const JournalAdminContentFeedPage({super.key});

  void _onSidebarNavigate(BuildContext context, JournalAdminSidebarItem item) {
    switch (item) {
      case JournalAdminSidebarItem.dashboard:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminDashboardPage()),
        );
        break;
      case JournalAdminSidebarItem.articles:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminStudioPage()),
        );
        break;
      case JournalAdminSidebarItem.contentFeed:
        return;
      case JournalAdminSidebarItem.team:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminTeamHubPage()),
        );
        break;
      case JournalAdminSidebarItem.patients:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => const JournalAdminPatientsHubPage()),
        );
        break;
      case JournalAdminSidebarItem.analytics:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminAnalyticsPage()),
        );
        break;
      case JournalAdminSidebarItem.settings:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JournalAdminSettingsPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RememberAppPage(
      pageId: AppPageId.journalAdminDashboard, // Using the same page ID to maintain continuity
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F8),
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JournalAdminSidebar(
                activeItem: JournalAdminSidebarItem.contentFeed,
                onNavigate: (item) => _onSidebarNavigate(context, item),
              ),
              const Expanded(
                child: JournalPortalPage(hidePortalSidebar: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
