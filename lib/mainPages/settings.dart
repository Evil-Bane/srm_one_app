import 'package:flutter/material.dart';
import 'package:srm_hope/Utilities/data_saver.dart';
import 'package:srm_hope/Utilities/gen.dart';
import 'package:srm_hope/login.dart';
import 'dart:convert'; // Import for base64 decoding
import 'package:url_launcher/url_launcher.dart'; // Import for URL launching
import 'package:srm_hope/Utilities/credentials.dart';


class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? userDetails; // Local variable to hold user details
  bool isLoading = true; // To show loading state initially

  @override
  void initState() {
    super.initState();
    _fetchUserDetails(); // Fetch user details on initialization
  }

  Future<void> _fetchUserDetails() async {
    final userDetails1 = await UserDetails.getUserDetails();
    setState(() {
      userDetails = userDetails1;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner if data is still being fetched
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Profile Header
          Row(
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 60,
                backgroundImage: userDetails != null && userDetails!['studentphoto'] != null && userDetails!['studentphoto'].isNotEmpty
                    ? MemoryImage(base64Decode(userDetails!['studentphoto']))
                    : const AssetImage('assets/logo.png') as ImageProvider,
              ),
              const SizedBox(width: 16),
              // Name and Details
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userDetails?['studentname'] ?? 'Fetching Data...', // Display user name
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userDetails?['registerno'] ?? 'Fetching Data...', // Display register number
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userDetails?['program'] ?? 'Fetching Data...', // Display user name
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userDetails?['universityname'] ?? 'Fetching Data...', // Display user name
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // General Section
          const Text(
            'General',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          buildSettingsTile(
            context,
            icon: Icons.settings,
            title: 'Account Settings',
            routeName: '/accountSettings',
          ),
          buildSettingsTile(
            context,
            icon: Icons.support_agent,
            title: 'Support',
            routeName: '/supportPage',
          ),
          buildSettingsTile(
            context,
            icon: Icons.bug_report,
            title: 'Bugs? Report Here',
          ),
          buildSettingsTile(
            context,
            icon: Icons.people,
            title: 'About Us',
            routeName: '/aboutUs',
          ),
          const SizedBox(height: 20),
          // Logout Button
          ElevatedButton(
            onPressed: () async {
              await UserSession.clearSession();
              await UserDetails.deleteUserDetails();
              await UserCredentials.deleteCredentials();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false, // Remove all previous routes
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Background color
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget buildSettingsTile(BuildContext context,
      {required IconData icon, required String title, String? routeName}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        if (routeName != null) {
          Navigator.pushNamed(context, routeName); // Navigate to the specified route
        } else if (title == 'Bugs? Report Here') {
          // Handle Support button click
          _launchSupportURL();
        } else {
          // Handle other actions here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title clicked!')),
          );
        }
      },
    );
  }

  Future<void> _launchSupportURL() async {
    final Uri url = Uri.parse('https://srm-one-beta.vercel.app/');
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }
}