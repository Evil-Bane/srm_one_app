import 'package:flutter/material.dart';
import 'package:srm_hope/Utilities/data_saver.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userDetails;

  const ProfilePage({Key? key, this.userDetails}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userDetails;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data during initialization
  }

  Future<void> _fetchUserData() async {
    final fetchedData = await UserSession.getSession();
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SRM IST'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture and Name
            CircleAvatar(
              radius: 100,
              backgroundColor: Colors.black,
              backgroundImage: userDetails != null && userDetails!['Profile Picture'] != null
                  ? NetworkImage(userDetails!['Profile Picture']) as ImageProvider<Object>
                  : null,
              child: userDetails == null || userDetails!['Profile Picture'] == null
                  ? const Icon(
                Icons.person,
                size: 100,
                color: Colors.white,
              )
                  : null,
            ),
            const SizedBox(height: 8),

            // Display user name and email
            if (userDetails != null) ...[
              Text(
                userDetails!['Student Name'] ?? 'Unknown User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                userDetails!['Email ID'] ?? 'No Email',
                style: const TextStyle(
                  fontSize: 14,

                ),
              ),
            ],
            const SizedBox(height: 20),

            // Section: Profile
            buildSection(context, title: 'Profile'),
            const SizedBox(height: 10),
            buildScrollableGridSection(
              cardData: [
                {'title': 'Personal Info', 'route': '/user_details'},
              ],
            ),
            const SizedBox(height: 20),

            // Section: Attendance
            buildSection(context, title: 'Attendance'),
            const SizedBox(height: 10),
            buildScrollableGridSection(
              cardData: [
                {'title': 'Attendance', 'route': '/attendance_details'},

              ],
            ),
            const SizedBox(height: 20),

            // Section: Grades
            buildSection(context, title: 'Grades'),
            const SizedBox(height: 10),
            buildScrollableGridSection(
              cardData: [
                {'title': 'Internal Marks', 'route': '/grades_details'},
                {'title': 'GPA Calculator', 'route': '/announcements'},
              ],
            ),
            const SizedBox(height: 20),
            // Section: Miscellaneous
            buildSection(context, title: 'Miscellaneous'),
            const SizedBox(height: 10),
            buildScrollableGridSection(
              cardData: [
                {'title': 'Fee Dues', 'route': '/fees'},
                {'title': 'Time Table', 'route': '/grades_detailss'},
                {'title': 'Admit Card', 'route': '/admit_cards'},
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Function to build section titles
  Widget buildSection(BuildContext context, {required String title}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Function to build a horizontally scrollable grid of cards for each section
  Widget buildScrollableGridSection({required List<Map<String, String>> cardData}) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cardData.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, cardData[index]['route']!);
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  cardData[index]['title']!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
