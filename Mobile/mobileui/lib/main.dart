import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/local_account_store.dart';
import 'data/sample_reports.dart';
import 'models/report.dart';
import 'screen/auth_screen.dart';
import 'screen/edit_profile.dart';
import 'screen/home.dart';
import 'screen/onboarding_screen.dart';
import 'screen/profile.dart';
import 'screen/report.dart';
import 'screen/report_details.dart';
import 'screen/submit_report.dart';
import 'screen/submitted_report.dart';
import 'screen/update.dart';
import 'screen/welcome_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocalAccountStore.defaultPrefs = await SharedPreferences.getInstance();
  runApp(
    SnapFixApp(initialAccount: await LocalAccountStore().signedInAccount()),
  );
}

class SnapFixApp extends StatelessWidget {
  const SnapFixApp({super.key, this.initialAccount});

  /// The account still signed in from an earlier launch, if any.
  final LocalAccount? initialAccount;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SnapFix',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: AppEntry(initialAccount: initialAccount),
  );
}

/// Chooses between the first-run tour and the main app.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key, this.initialAccount});

  final LocalAccount? initialAccount;

  @override
  State<AppEntry> createState() => _AppEntryState();
}

enum _Stage { welcome, onboarding, app, auth }

class _AppEntryState extends State<AppEntry> {
  late _Stage _stage = widget.initialAccount == null
      ? _Stage.welcome
      : _Stage.app;

  /// `initialAccount` is only what an earlier launch left behind, so the
  /// resident registered in this session has to be carried to the shell here.
  late LocalAccount? _account = widget.initialAccount;

  void _advance(_Stage stage) {
    setState(() => _stage = stage);
  }

  Future<void> _finishAuth(String email, String? name) async {
    final account = await LocalAccountStore().signedInAccount();
    if (!mounted) return;
    setState(() {
      _account = account;
      _stage = _Stage.app;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.welcome:
        return WelcomeScreen(
          onGetStarted: () => _advance(_Stage.onboarding),
          onSkip: () => _advance(_Stage.app),
        );

      case _Stage.onboarding:
        return OnboardingScreen(
          onFinished: () => _advance(_Stage.auth),
          onSkip: () => _advance(_Stage.app),
        );

      case _Stage.auth:
        return AuthScreen(onSignedIn: _finishAuth);

      case _Stage.app:
        return SnapFixShell(initialAccount: _account);
    }
  }
}

/// Bottom-navigation shell that owns the in-memory report list and the
/// signed-in account.
class SnapFixShell extends StatefulWidget {
  const SnapFixShell({super.key, this.initialAccount});

  final LocalAccount? initialAccount;

  @override
  State<SnapFixShell> createState() => _SnapFixShellState();
}

class _SnapFixShellState extends State<SnapFixShell> {
  final List<IssueReport> _reports = createSampleReports();
  final LocalAccountStore _store = LocalAccountStore();
  int _tab = 0;
  int _serial = 14;
  late LocalAccount? _account = widget.initialAccount;

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        reports: _reports,
        onReport: _showDetails,
        onCreate: () => _open(SubmitReportPage(onSubmitted: _addReport)),
      ),
      ReportsPage(reports: _reports, onReport: _showDetails),
      const SizedBox.shrink(),
      UpdatesPage(reports: _reports, onReport: _showDetails),
      ProfilePage(
        account: _account,
        onAuth: _openAuth,
        onEdit: _editProfile,
        onLogout: _signOut,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          if (i == 2) {
            _open(SubmitReportPage(onSubmitted: _addReport));
          } else {
            setState(() => _tab = i);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle, size: 38, color: AppTheme.pink),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Updates',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _addReport(IssueReport draft) {
    final saved = draft.copyWith(id: 'SF-LOCAL-${_serial++}');
    setState(() {
      _reports.insert(0, saved);
      _tab = 1;
    });
    _open(
      SubmittedReportPage(
        reportId: saved.id,
        onViewReports: () => Navigator.pop(context),
        onBackToHome: () {
          setState(() => _tab = 0);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openAuth() =>
      _open(AuthScreen(onSignedIn: (email, name) => _onSignedIn(email, name)));

  /// The auth pages pop themselves and persist the session, so the shell only
  /// has to re-read what storage holds.
  void _onSignedIn(String email, String? name) {
    _refreshAccount();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          name == null || name.trim().isEmpty
              ? 'Signed in as $email.'
              : 'Welcome back, ${name.trim()}!',
        ),
      ),
    );
  }

  Future<void> _refreshAccount() async {
    final account = await _store.signedInAccount();
    if (mounted) setState(() => _account = account);
  }

  void _editProfile() {
    final account = _account;
    if (account == null) {
      _openAuth();
      return;
    }
    _open(
      ProfileEditPage(
        account: account,
        onSaved: (updated) => setState(() => _account = updated),
      ),
    );
  }

  Future<void> _signOut() async {
    // Ends the session but keeps the account registered on this device.
    await _store.signOut();
    if (mounted) setState(() => _account = null);
  }

  void _showDetails(IssueReport report) => _open(
    ReportDetailsPage(report: report, onDelete: () => _confirmDelete(report)),
  );

  Future<void> _confirmDelete(IssueReport report) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: AppTheme.pink, size: 35),
        title: const Text('Delete report?'),
        content: const Text(
          'Are you sure you want to delete this report? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep report'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete report'),
          ),
        ],
      ),
    );

    if (yes != true) return;
    setState(() => _reports.removeWhere((r) => r.id == report.id));
    if (mounted) Navigator.pop(context);
  }
}
