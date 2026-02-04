import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:therapii/firebase_options.dart';
import 'package:therapii/theme.dart';
import 'package:therapii/theme_mode_controller.dart';
import 'package:therapii/models/user.dart' as app_user;
import 'package:therapii/pages/admin_dashboard_page.dart';
import 'package:therapii/pages/auth_welcome_page.dart';
import 'package:therapii/pages/landing_page.dart';
import 'package:therapii/pages/patient_dashboard_page.dart';
import 'package:therapii/pages/patient_onboarding_flow_page.dart';
import 'package:therapii/pages/therapist_dashboard_page.dart';
import 'package:therapii/pages/verify_email_page.dart';
import 'package:therapii/utils/admin_access.dart';
import 'package:therapii/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrapFirebase();

  // Make runtime errors visible on web builds instead of a blank screen.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong.\n${details.exception}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeModeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Therapii',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeModeController.mode,
          // Decide the first screen based on auth + role.
          home: const _RootRouter(),
        );
      },
    );
  }
}

/// Stores any initialization error so we can show a fallback UI instead of crashing.
Object? _firebaseInitError;

Future<void> _bootstrapFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    _firebaseInitError = e;
    // ignore: avoid_print
    print('Firebase initialization failed: $e\n$st');
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Simple app-level router that sends users to the right dashboard (or onboarding)
/// as soon as Firebase auth finishes restoring their session.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    // If Firebase failed to initialize, still render the marketing/landing page so
    // the site is never blank.
    if (_firebaseInitError != null) {
      return const LandingPage();
    }

    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // While Firebase hydrates the auth session, show a quick splash.
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final authUser = authSnap.data;
        if (authUser == null) {
          // Not signed in → marketing/entry experience.
          return const LandingPage();
        }

        return FutureBuilder<app_user.User?>(
          future: UserService().getUser(authUser.uid),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If we couldn't load the Firestore profile, bounce to auth so the
            // user can re-auth or create their profile cleanly.
            if (profileSnap.hasError || profileSnap.data == null) {
              return const AuthWelcomePage(initialTab: AuthTab.login);
            }

            final profile = profileSnap.data!;
            final isTherapist = profile.isTherapist;
            final onboardingDone = profile.patientOnboardingCompleted;
            final email = authUser.email ?? '';

            if (!authUser.emailVerified) {
              return VerifyEmailPage(email: email, isTherapist: isTherapist);
            }

            if (AdminAccess.isAdminEmail(email)) {
              return const AdminDashboardPage();
            }

            if (isTherapist) {
              return const TherapistDashboardPage();
            }

            return onboardingDone
                ? const PatientDashboardPage()
                : const PatientOnboardingFlowPage();
          },
        );
      },
    );
  }
}
