import 'package:flutter/material.dart';
import 'package:srm_hope/Utilities/gen.dart';
import 'package:srm_hope/Utilities/data_saver.dart';
import 'dart:convert'; // Import for base64 decoding
import 'dart:typed_data'; // Import for Uint8List to handle the image data

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true; // Flag to show loading spinner while fetching data
  bool isInitialLoad = true; // To track if it's the first load
  int _currentIndex = 0; // Current index for BottomNavigationBar

  @override
  void initState() {
    super.initState();
    _checkAndFetchUserDetails(); // Check for local data and fetch if necessary
  }

  Future<void> _checkAndFetchUserDetails() async {
    setState(() {
      isLoading = true; // Show loading while fetching
    });

    try {
      final storedDetails = await UserDetails.getUserDetails();

      if (storedDetails != null && storedDetails.isNotEmpty) {
        // If details exist and are not empty, use them
        setState(() {
          userDetails = storedDetails;
        });
      } else {
        // If no details are stored or data is empty, fetch them from API and store locally
        final String? sid = await UserSession.getSession();
        if (sid != null) {
          final fetchedDetails = await UserDetails.fetchAndSaveUserDetails(sid);
          setState(() {
            userDetails = fetchedDetails;
          });
        }
      }
    } catch (e) {
      // Handle any errors
      debugPrint("Error fetching user details: $e");
    } finally {
      setState(() {
        isLoading = false; // Stop loading spinner after data is fetched
        isInitialLoad = false; // It's no longer the first load
      });
    }
  }

  // Decode the base64 image data into an ImageProvider
  ImageProvider<Object>? _decodeBase64Image(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    try {
      final decodedBytes = base64Decode(base64Str);
      return MemoryImage(Uint8List.fromList(decodedBytes));
    } catch (e) {
      debugPrint("Error decoding base64 image: $e");
      return null;
    }
  }

  // Navigate to specific pages based on index
  void _navigateToPage(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Use pushReplacementNamed to prevent stacking the same page
    switch (index) {
      case 0:
        break; // Already on Home
      case 1:
        Navigator.pushReplacementNamed(context, '/events');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/groups');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/directory');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive scaling
    final double screenWidth = MediaQuery.of(context).size.width;
    // Use 400 as the base width for scaling; adjust as needed
    final double scale = screenWidth / 400;

    // Show loading screen if data is loading or null
    if (isLoading && isInitialLoad) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // Show loading spinner initially
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              height: 60 * scale,
            ),
            SizedBox(width: 15 * scale),
            Text(
              'SRM One',
              style: TextStyle(fontSize: 20 * scale),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings'); // Navigate to settings page
            },
          ),
        ],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Card
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/user_details');
              },
              child: Card(
                elevation: 16,
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(16.0 * scale),
                  padding: EdgeInsets.all(16.0 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(16.0 * scale),
                    border: Border.all(color: Colors.black, width: 2 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue,
                        blurRadius: 10 * scale,
                        spreadRadius: 10 * scale,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 50 * scale,
                        backgroundColor: Colors.black,
                        backgroundImage: _decodeBase64Image(
                          userDetails?['studentphoto'],
                        ),
                        child: (userDetails == null ||
                            userDetails!['studentphoto'] == null ||
                            userDetails!['studentphoto']!.isEmpty)
                            ? Icon(
                          Icons.person,
                          size: 100 * scale,
                        )
                            : null,
                      ),
                      SizedBox(height: 10 * scale),
                      // Profile Name
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          userDetails?['studentname'] ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 5 * scale),
                      // Registration No.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          userDetails?['registerno'] ?? 'No Info',
                          style: TextStyle(
                            fontSize: 14 * scale,
                          ),
                        ),
                      ),
                      SizedBox(height: 10 * scale),
                      // Using a Row to ensure the info stays in one line.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.cake,
                                  size: 30 * scale,
                                  color: Colors.blue,
                                ),
                                SizedBox(height: 4 * scale),
                                Text(
                                  userDetails?['dob'] ?? 'N/A',
                                  style: TextStyle(fontSize: 14 * scale),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.school,
                                  size: 30 * scale,
                                  color: Colors.blue,
                                ),
                                SizedBox(height: 4 * scale),
                                Text(
                                  userDetails?['semester'] ?? 'N/A',
                                  style: TextStyle(fontSize: 14 * scale),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 30 * scale,
                                  color: Colors.blue,
                                ),
                                SizedBox(height: 4 * scale),
                                Text(
                                  'Section: ${userDetails?['sectiondesc'] ?? 'N/A'}',
                                  style: TextStyle(fontSize: 14 * scale),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Heading
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 8.0 * scale),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Menu",
                  style: TextStyle(fontSize: 18 * scale, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Menu Items
            _menuItem(
              'Attendance',
              'View your attendance',
              '/attendance_details',
              Icon(Icons.data_thresholding_outlined, color: Colors.blue, size: 24 * scale),
            ),
            _menuItem(
              'Grades',
              'Check your grades',
              '/grades_details',
              Icon(Icons.grade, color: Colors.blue, size: 24 * scale),
            ),
            _menuItem(
              'Time Table',
              'View class schedule',
              '/time_table',
              Icon(Icons.table_view, color: Colors.blue, size: 24 * scale),
            ),
            _menuItem(
              'GPA Calculator',
              'Calculate your GPA',
              '/gpa_calc',
              Icon(Icons.question_mark_sharp, color: Colors.blue, size: 24 * scale),
            ),
            _menuItem(
              'Fees',
              'Check pending dues',
              '/fee_details',
              Icon(Icons.attach_money, color: Colors.blue, size: 24 * scale),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: _navigateToPage, // Use the function to navigate
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 24 * scale),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event, size: 24 * scale),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups, size: 24 * scale),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts, size: 24 * scale),
            label: 'Directory',
          ),
        ],
      ),
    );
  }

  Widget _menuItem(String title, String subtitle, String route, Icon icon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: icon,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
