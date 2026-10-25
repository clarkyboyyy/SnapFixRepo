import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileui/data/local_account_store.dart';
import 'package:mobileui/data/sample_reports.dart';
import 'package:mobileui/main.dart';
import 'package:mobileui/models/report.dart';
import 'package:mobileui/screen/auth_screen.dart';
import 'package:mobileui/screen/edit_profile.dart';
import 'package:mobileui/screen/home.dart';
import 'package:mobileui/screen/login.dart';
import 'package:mobileui/screen/onboarding_screen.dart';
import 'package:mobileui/screen/profile.dart';
import 'package:mobileui/screen/report.dart';
import 'package:mobileui/screen/report_details.dart';
import 'package:mobileui/screen/report_progress.dart';
import 'package:mobileui/screen/signup.dart';
import 'package:mobileui/screen/submit_report.dart';
import 'package:mobileui/screen/submitted_report.dart';
import 'package:mobileui/screen/update.dart';
import 'package:mobileui/screen/welcome_screen.dart';
import 'package:mobileui/theme/app_theme.dart';
import 'package:mobileui/widget/report_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _skipTour(WidgetTester tester) async {
  await tester.pumpWidget(const SnapFixApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Guest Mode'));
  await tester.pumpAndSettle();
}

BorderSide _cardBorder(WidgetTester tester) {
  final card = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(ReportCard),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (card.decoration! as BoxDecoration).border!.top;
}

LocalAccount _account() => const LocalAccount(
  name: 'Zyra Malik',
  email: 'zyra.malik@example.com',
  salt: 'c2FsdA==',
  passwordHash: 'aGFzaA==',
  mobile: '0917 123 4567',
  address: '12 Rizal Avenue, Purok 3',
);

Future<void> _openProfile(WidgetTester tester) async {
  await _skipTour(tester);
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
}

int _launch = 0;

/// Rebuilds the app the way `main()` does: session read first, then launched.
/// The fresh key drops the old widget state so nothing carries over.
Future<void> _relaunch(WidgetTester tester) async {
  await tester.pumpWidget(
    SnapFixApp(
      key: Key('launch-${_launch++}'),
      initialAccount: await LocalAccountStore().signedInAccount(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Fills the sign-up form; the caller must already be showing [AuthScreen].
Future<void> _submitSignup(
  WidgetTester tester, {
  String name = 'Zyra Malik',
  String email = 'zyra.malik@example.com',
  String password = 'snapfix123',
}) async {
  await tester.tap(find.text('Create Account'));
  await tester.pumpAndSettle();

  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), name);
  await tester.enterText(fields.at(1), email);
  await tester.enterText(fields.at(2), password);
  await tester.enterText(fields.at(3), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
  await tester.pumpAndSettle();
}

/// Registers through the real form so the storage path is exercised too.
Future<void> _register(WidgetTester tester) async {
  await tester.tap(find.text('Connect Account / Log In'));
  await tester.pumpAndSettle();
  await _submitSignup(tester);
}

Future<void> _openLogin(WidgetTester tester) async {
  await tester.tap(find.text('Already have an account? Log In'));
  await tester.pumpAndSettle();
}

Future<void> _submitLogin(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Log In'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LocalAccountStore.defaultPrefs = await SharedPreferences.getInstance();
  });

  testWidgets('welcome screen offers the tour', (tester) async {
    _usePhone(tester);
    await tester.pumpWidget(const SnapFixApp());
    await tester.pumpAndSettle();

    expect(find.text('Report it. Track it. Fixed.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('the tour steps through photo, location and tracking', (
    tester,
  ) async {
    _usePhone(tester);
    await tester.pumpWidget(const SnapFixApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Snap the problem'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Pin the exact spot'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Track it to fixed'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    // The last tour step hands off to the account screen, not Home.
    expect(find.text('Welcome to SnapFix'), findsOneWidget);
  });

  testWidgets('the tour hands a fresh account straight to the profile', (
    tester,
  ) async {
    _usePhone(tester);
    await tester.pumpWidget(const SnapFixApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await _submitSignup(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Zyra Malik'), findsWidgets);
    expect(find.text('zyra.malik@example.com'), findsWidgets);
    expect(find.text('Signed in on this device'), findsOneWidget);
  });

  testWidgets('home shows the report counts from the sample data', (
    tester,
  ) async {
    _usePhone(tester);
    await _skipTour(tester);

    expect(find.text('YOUR REPORT OVERVIEW'), findsOneWidget);
    expect(find.text('Broken Streetlight'), findsOneWidget);
  });

  testWidgets('signing up stores the resident on the profile', (tester) async {
    _usePhone(tester);
    await _openProfile(tester);
    await _register(tester);

    expect(find.text('Zyra Malik'), findsWidgets);
    expect(find.text('zyra.malik@example.com'), findsWidgets);
    expect(find.text('Signed in on this device'), findsOneWidget);
    expect(find.textContaining('snapfix123'), findsNothing);
  });

  testWidgets('the account survives closing and reopening the app', (
    tester,
  ) async {
    _usePhone(tester);
    await _openProfile(tester);
    await _register(tester);

    // A fresh widget tree is a fresh launch reading the same storage.
    await _relaunch(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Zyra Malik'), findsWidgets);
    expect(find.text('zyra.malik@example.com'), findsWidgets);
  });

  testWidgets('logging out ends the session but keeps the account', (
    tester,
  ) async {
    _usePhone(tester);
    await _openProfile(tester);
    await _register(tester);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Not signed in'), findsOneWidget);
    expect(find.text('Connect Account / Log In'), findsOneWidget);

    await tester.tap(find.text('Connect Account / Log In'));
    await tester.pumpAndSettle();
    await _openLogin(tester);
    await _submitLogin(
      tester,
      email: 'zyra.malik@example.com',
      password: 'nope123',
    );

    expect(
      find.text('That password does not match the saved account.'),
      findsOneWidget,
    );
    expect(find.text('Signed in on this device'), findsNothing);

    await _submitLogin(
      tester,
      email: 'Zyra.Malik@example.com',
      password: 'snapfix123',
    );
    expect(find.text('Zyra Malik'), findsWidgets);
    expect(find.text('Signed in on this device'), findsOneWidget);
  });

  testWidgets('logging in with nothing saved explains itself', (tester) async {
    _usePhone(tester);
    await _openProfile(tester);
    await tester.tap(find.text('Connect Account / Log In'));
    await tester.pumpAndSettle();
    await _openLogin(tester);
    await _submitLogin(
      tester,
      email: 'nobody@example.com',
      password: 'snapfix123',
    );

    expect(
      find.text('No account is saved on this device yet. Create one first.'),
      findsOneWidget,
    );
    // A rejected sign-in keeps the resident on the form instead of advancing.
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('edit profile saves the mobile number and address', (
    tester,
  ) async {
    _usePhone(tester);
    await _openProfile(tester);
    await _register(tester);

    expect(find.text('Add it in Edit profile'), findsNWidgets(2));

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), '0917 555 0134');
    await tester.enterText(fields.at(2), '7 Mabini Street');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('0917 555 0134'), findsOneWidget);
    expect(find.text('7 Mabini Street'), findsOneWidget);
    expect(find.text('Add it in Edit profile'), findsNothing);
  });

  testWidgets('every screen renders on a small and large phone', (
    tester,
  ) async {
    final reports = createSampleReports();
    final report = reports.first;

    final screens = <String, Widget>{
      'Welcome': WelcomeScreen(onGetStarted: () {}, onSkip: () {}),
      'Onboarding': OnboardingScreen(onFinished: () {}, onSkip: () {}),
      'Home': Scaffold(
        body: HomePage(reports: reports, onReport: (_) {}, onCreate: () {}),
      ),
      'Reports': Scaffold(
        body: ReportsPage(reports: reports, onReport: (_) {}),
      ),
      'Details': ReportDetailsPage(report: report, onDelete: () {}),
      'Progress': ReportProgressPage(report: report),
      'Updates': Scaffold(
        body: UpdatesPage(reports: reports, onReport: (_) {}),
      ),
      'Profile': Scaffold(
        body: ProfilePage(
          account: _account(),
          onAuth: () {},
          onEdit: () {},
          onLogout: () {},
        ),
      ),
      'Profile guest': Scaffold(
        body: ProfilePage(
          account: null,
          onAuth: () {},
          onEdit: () {},
          onLogout: () {},
        ),
      ),
      'Edit profile': ProfileEditPage(account: _account(), onSaved: (_) {}),
      'Submit': SubmitReportPage(onSubmitted: (_) {}),
      'Submitted': SubmittedReportPage(
        reportId: report.id,
        onViewReports: () {},
        onBackToHome: () {},
      ),
      'Auth': AuthScreen(onSignedIn: (email, name) {}),
      'Login': LoginPage(onSignedIn: (email, name) {}),
      'Signup': SignupPage(onSignedIn: (email, name) {}),
    };

    for (final size in const [Size(320, 568), Size(390, 844)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      for (final entry in screens.entries) {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: entry.value),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${size.width}dp - ${entry.key}',
        );
      }
    }
  });

  testWidgets('submitting an empty report surfaces validation errors', (
    tester,
  ) async {
    _usePhone(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SubmitReportPage(onSubmitted: (_) {}),
      ),
    );

    await tester.tap(find.text('Submit New Report'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('Give the issue a short title'), findsOneWidget);
    expect(find.text('Enter where the issue is'), findsOneWidget);
  });

  testWidgets('a completed form produces a submitted report', (tester) async {
    _usePhone(tester);
    IssueReport? draft;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SubmitReportPage(onSubmitted: (r) => draft = r),
      ),
    );

    await tester.tap(find.text('Street Lighting'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Broken streetlight');
    await tester.enterText(
      fields.at(1),
      'The lamp outside the sari-sari store has been dark for a week.',
    );
    await tester.enterText(fields.at(2), 'Rizal Avenue, Purok 3');
    await tester.tap(find.text('Submit New Report'));
    await tester.pumpAndSettle();

    expect(draft, isNotNull);
    expect(draft!.title, 'Broken streetlight');
    expect(draft!.category, 'Street Lighting');
    expect(draft!.location, 'Rizal Avenue, Purok 3');
    expect(draft!.status, ReportStatus.submitted);
    expect(draft!.photoPath, isNull);
  });

  testWidgets('a report card tints its border under the pointer', (
    tester,
  ) async {
    _usePhone(tester);
    final report = createSampleReports().first;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ReportCard(report: report, onTap: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    addTearDown(pointer.removePointer);

    expect(_cardBorder(tester).color, AppTheme.border);

    await pointer.moveTo(tester.getCenter(find.byType(ReportCard)));
    await tester.pumpAndSettle();
    expect(_cardBorder(tester).color, isNot(AppTheme.border));

    await pointer.moveTo(const Offset(0, 0));
    await tester.pumpAndSettle();
    expect(_cardBorder(tester).color, AppTheme.border);
  });

  group('LocalAccountStore', () {
    test('keeps the password out of storage', () async {
      final store = LocalAccountStore();
      final outcome = await store.register(
        name: 'Zyra Malik',
        email: 'Zyra.Malik@Example.com',
        password: 'snapfix123',
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.account!.email, 'zyra.malik@example.com');

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('snapfix.account')!;
      expect(raw, isNot(contains('snapfix123')));
      expect(LocalAccount.tryParse(raw)!.passwordHash, isNotEmpty);

      expect(
        (await store.signIn(
          email: 'zyra.malik@example.com',
          password: 'snapfix123',
        )).isSuccess,
        isTrue,
      );
      expect(
        (await store.signIn(
          email: 'zyra.malik@example.com',
          password: 'snapfix124',
        )).isSuccess,
        isFalse,
      );
    });

    test('refuses a second registration of the same email', () async {
      final store = LocalAccountStore();
      await store.register(
        name: 'Zyra Malik',
        email: 'zyra@example.com',
        password: 'snapfix123',
      );
      final again = await store.register(
        name: 'Someone Else',
        email: 'ZYRA@example.com',
        password: 'other123',
      );

      expect(again.isSuccess, isFalse);
      expect(again.error, contains('already registered'));
    });

    test('start-up ignores corrupt saved data', () async {
      SharedPreferences.setMockInitialValues({'snapfix.account': 'not json'});

      expect(await LocalAccountStore().readAccount(), isNull);
      expect(await LocalAccountStore().signedInAccount(), isNull);
    });

    test('signing out ends the session but keeps the account', () async {
      final store = LocalAccountStore();
      await store.register(
        name: 'Zyra Malik',
        email: 'zyra@example.com',
        password: 'snapfix123',
      );

      await store.signOut();

      expect(await store.signedInAccount(), isNull);
      expect(await store.readAccount(), isNotNull);
    });

    test('blank edits keep the value already stored', () async {
      final store = LocalAccountStore();
      await store.register(
        name: 'Zyra Malik',
        email: 'zyra@example.com',
        password: 'snapfix123',
      );
      await store.updateProfile(name: 'Zyra M. Malik', mobile: '0917 555 0134');

      final kept = await store.updateProfile(
        name: '',
        address: '7 Mabini Street',
      );

      expect(kept!.name, 'Zyra M. Malik');
      expect(kept.mobile, '0917 555 0134');
      expect(kept.address, '7 Mabini Street');
      expect(kept.email, 'zyra@example.com');
    });
  });
}
