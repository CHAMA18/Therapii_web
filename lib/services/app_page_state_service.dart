import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPageId {
  static const landing = 'landing';
  static const authWelcome = 'auth_welcome';
  static const verifyEmail = 'verify_email';
  static const adminDashboard = 'admin_dashboard';
  static const myPatients = 'my_patients';
  static const patientDashboard = 'patient_dashboard';
  static const patientOnboarding = 'patient_onboarding';
  static const journalPortal = 'journal_portal';
  static const journalAdminDashboard = 'journal_admin_dashboard';
  static const journalAdminStudio = 'journal_admin_studio';
  static const journalAdminTeamHub = 'journal_admin_team_hub';
  static const journalAdminPatientsHub = 'journal_admin_patients_hub';
  static const journalAdminAnalytics = 'journal_admin_analytics';
  static const journalAdminSettings = 'journal_admin_settings';
}

class AppPageStateService {
  static const _lastPageKey = 'app.last_page_id';
  static String? _lastSavedPageId;

  static Future<void> rememberPage(String pageId) async {
    if (_lastSavedPageId == pageId) return;
    _lastSavedPageId = pageId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPageKey, pageId);
  }

  static Future<String?> loadRememberedPage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPageId = prefs.getString(_lastPageKey);
    _lastSavedPageId = savedPageId;
    return savedPageId;
  }

  static Future<void> resetToLanding() async {
    await rememberPage(AppPageId.landing);
  }
}

class RememberAppPage extends StatefulWidget {
  final String pageId;
  final Widget child;

  const RememberAppPage({
    super.key,
    required this.pageId,
    required this.child,
  });

  @override
  State<RememberAppPage> createState() => _RememberAppPageState();
}

class _RememberAppPageState extends State<RememberAppPage> {
  @override
  void initState() {
    super.initState();
    _remember();
  }

  @override
  void didUpdateWidget(covariant RememberAppPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageId != widget.pageId) {
      _remember();
    }
  }

  void _remember() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppPageStateService.rememberPage(widget.pageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
