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
              height: 60,
            ),
            const SizedBox(width: 15),
            const Text(
              'SRM One',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
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
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.blue,
                        blurRadius: 10,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.black,
                        backgroundImage: _decodeBase64Image(
                          userDetails?['studentphoto'],
                        ),
                        child: userDetails == null ||
                            userDetails!['studentphoto'] == null ||
                            userDetails!['studentphoto']!.isEmpty
                            ? const Icon(
                          Icons.person,
                          size: 100,
                        )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      // Profile Name
                      Text(
                        userDetails?['studentname'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Registration No.
                      Text(
                        userDetails?['registerno'] ?? 'No Info',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              const Icon(
                                Icons.cake,
                                size: 30,
                                color: Colors.blue,
                              ),
                              Text(userDetails?['dob'] ?? 'N/A')
                            ],
                          ),
                          const SizedBox(width: 35),
                          Column(
                            children: [
                              const Icon(
                                Icons.school,
                                size: 30,
                                color: Colors.blue,
                              ),
                              Text(userDetails?['semester'] ?? 'N/A')
                            ],
                          ),
                          const SizedBox(width: 35),
                          Column(
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                size: 30,
                                color: Colors.blue,
                              ),
                              Text(
                                  'Section: ${userDetails?['sectiondesc'] ?? 'N/A'}'),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            // Heading
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Menu",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Menu Items
            _menuItem('Attendance', 'View your attendance', '/attendance_details',
                const Icon(Icons.data_thresholding_outlined, color: Colors.blue)),
            _menuItem('Grades', 'Check your grades', '/grades_details',
                const Icon(Icons.grade, color: Colors.blue)),
            _menuItem('Time Table', 'View class schedule', '/time_table',
                const Icon(Icons.table_view, color: Colors.blue)),
            _menuItem('GPA Calculator', 'Calculate your GPA', '/gpa_calc',
                const Icon(Icons.question_mark_sharp, color: Colors.blue)),
            _menuItem('Fees', 'Check pending dues', '/fee_details',
                const Icon(Icons.attach_money, color: Colors.blue)),
            _menuItem('Hostel', 'All your hostel needs', '/no_rec',
                const Icon(Icons.credit_card, color: Colors.blue)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: _navigateToPage, // Use the function to navigate
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
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
