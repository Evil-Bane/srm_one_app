import 'package:flutter/material.dart';
import 'studentPortal/attendanceDetails.dart';
import 'studentPortal/gradeDetails.dart';
import 'settingsPages/changePass.dart';
import 'studentPortal/userDetails.dart';
import 'login.dart';
import 'mainPages/home.dart';
import 'mainPages/events.dart'; // Import your Events Page
import 'mainPages/groups.dart'; // Import your Groups Page
import 'mainPages/directory.dart'; // Import your Directory Page
import 'mainPages/settings.dart'; // Settings Page
import 'settingsPages/accountSettings.dart';
import 'Utilities/data_saver.dart'; // For checking login state
import 'studentPortal/timeTable.dart';
import 'Utilities/GPAcalculator.dart';
import 'studentPortal/examDetails.dart';
import 'studentPortal/internalMarks.dart';
import 'studentPortal/feeDetails.dart';
import 'studentPortal/feePaid.dart';
import 'studentPortal/provisionalResults.dart';
import 'settingsPages/aboutUS.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = false;
  String? userDetails; // Updated to nullable
  bool isInitializing = true; // Track if initialization is done

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Method to check the login status
  Future<void> _checkLoginStatus() async {
    // Check if user session exists
    final user = await UserSession.getSession();

    // If user is logged in, fetch user details
    if (user != null) {
      userDetails = await UserSession.getSession();
      if (userDetails == null) {
        // If no user details are found, clear the session and redirect to login
        await UserSession.clearSession();
      }
    }

    setState(() {
      isLoggedIn = user != null && userDetails != null;
      isInitializing = false; // Set to false after initialization
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.purple,  // Light theme app bar color
          titleTextStyle: TextStyle(color: Colors.black),
        ),
        scaffoldBackgroundColor: Colors.white,  // Light theme background color
        primaryColor: Colors.purple,  // Primary color for buttons, etc.
      ),
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],  // Dark theme app bar color
          titleTextStyle: TextStyle(color: Colors.white),
        ),
        scaffoldBackgroundColor: Colors.black,  // Dark theme background color
        primaryColor: Color(0xFF1A1A2E), // Primary color for buttons, etc.
      ),
      themeMode: ThemeMode.dark,  // Use system theme (light/dark mode)
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => isInitializing
            ? SplashScreen() // Show splash screen during initialization
            : (isLoggedIn
            ? HomePage() // If logged in, show HomePage
            : LoginPage()), // If not logged in, show LoginPage
        '/login': (context) => LoginPage(), // Login Page
        '/home': (context) => HomePage(),
        '/events': (context) => EventsPage(), // Events Page
        '/groups': (context) => GroupsPage(), // Groups Page
        '/directory': (context) => DirectoryPage(), // Directory Page
        '/settings': (context) => SettingsPage(), // Settings Page
        '/accountSettings': (context) => AccountSettings(),
        '/user_details': (context) => UserDetailsPage(),
        '/attendance_details': (context) => AttendancePage(),
        '/time_table': (context) => TimetablePage(),
        '/gpa_calc': (context) => GpaCalculatorPage(),
        '/change_Pass': (context) => ChangePasswordScreen(),
        '/grades_details': (context) => GradesPage(),
        '/exam_details': (context) => ExamDetailsPage(),
        '/internal_marks': (context) => InternalMarksPage(),
        '/fee_details': (context) => FeeDetailsPage(),
        '/fee_paid': (context) => FeePaidPage(),
        '/provisional_details': (context) => ProvisionalResultsPage(),
        '/aboutUs': (context) => AboutUsPage(),
      },
    );
  }
}

// Splash Screen Widget
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Show loading animation
      ),
    );
  }
}
