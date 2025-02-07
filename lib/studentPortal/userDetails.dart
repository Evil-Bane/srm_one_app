import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:srm_hope/Utilities/data_saver.dart';
import 'package:srm_hope/Utilities/gen.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({Key? key}) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> with SingleTickerProviderStateMixin {
  Future<Map<String, dynamic>>? _userDetailsFuture;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  Future<Map<String, dynamic>> fetchUserDetails() async {
    final sid = await UserSession.getSession();
    if (sid == null) {
      throw Exception('No session found');
    }

    final response = await http.post(
      Uri.parse('https://api-srm-one.onrender.com/user'),
      body: {
        'method': 'getPersonalDetails',
        'sid': sid,
      },
    );

    if (response.statusCode == 200) {
      UserDetails.updateUserDetails(json.decode(response.body));
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user details');
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _initializeData();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _userDetailsFuture = fetchUserDetails();
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: Theme.of(context).copyWith(
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isDarkMode ? Colors.grey[850] : Colors.white,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Student Profile'),
          centerTitle: true,
          elevation: 0,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _userDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading profile...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 60,
                        color: Theme.of(context).colorScheme.error
                    ),
                    SizedBox(height: 16),
                    Text(
                      snapshot.error.toString().contains('No session')
                          ? 'Please log in to view profile'
                          : 'Error loading profile data',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _initializeData,
                      icon: Icon(Icons.refresh),
                      label: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasData) {
              final data = snapshot.data!;
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'profile_photo',
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              border: Border.all(color: Colors.grey, width: 2)
                            ),
                            child: Image(
                              height: 150,width: 120,
                              image: data['studentphoto'] != null && data['studentphoto'].isNotEmpty
                                  ? MemoryImage(base64Decode(data['studentphoto']))
                                  : AssetImage('assets/logo.png') as ImageProvider,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Card(
                        color: Color(0xFF1A1A2E),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileHeader(data),
                              Divider(height: 32),
                              _buildDetailsSection(data),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        color: Color(0xFF1A1A2E),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Academic Information'),
                              _buildAcademicDetails(data),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(child: Text('No data available'));
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['studentname'] ?? 'Not Available',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Registration: ${data['registerno'] ?? 'Not Available'}',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(Icons.calendar_today, 'DOB', data['dob'] ?? 'Not Available'),
        _buildDetailRow(Icons.people, 'Parents',
            'Father: ${data['father'] ?? 'Not Available'}\nMother: ${data['mother'] ?? 'Not Available'}'),
        _buildDetailRow(Icons.location_on, 'Address', data['address'] ?? 'Not Available'),
      ],
    );
  }

  Widget _buildAcademicDetails(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(Icons.school, 'Program', data['program'] ?? 'Not Available'),
        _buildDetailRow(Icons.access_time, 'Semester', data['semester'] ?? 'Not Available'),
        _buildDetailRow(Icons.group, 'Section', data['sectiondesc'] ?? 'Not Available'),
        _buildDetailRow(Icons.calendar_today, 'Academic Year', data['academicyear'] ?? 'Not Available'),
        _buildDetailRow(Icons.calendar_month, 'Admitted on', data['admitteddate'] ?? 'Not Available'),
        _buildDetailRow(Icons.business, 'University', data['universityname'] ?? 'Not Available'),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue,),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue
        ),
      ),
    );
  }
}