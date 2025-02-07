import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:srm_hope/Utilities/data_saver.dart';
import 'dart:convert';


class DirectoryPage extends StatefulWidget {
  const DirectoryPage({Key? key}) : super(key: key);

  @override
  _DirectoryPageState createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  String selectedCategory = "All";
  String studentSection = "";
  String studentBatch = "";
  String studentProgram = "";
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  // A method to get the current student section, batch, and program from local storage.
  Future<void> getStudentSection() async {
    final userData = await UserSession.getSession(); // Reading data from local storage
    if (userData != null) {
      setState(() {
        studentSection = ("");
        studentBatch = ("");
        studentProgram = ("");
      });
    }
  }

  // Fetch students data from the API.
  Future<List<Map<String, dynamic>>> fetchStudents() async {
    try {
      final response = await http.get(Uri.parse('https://srm-one-backend.vercel.app/api/directories'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final students = data['students']; // Corrected parsing for students array

        if (students != null && students.isNotEmpty) {
          // Now return the list of students from the response
          return students.map<Map<String, dynamic>>((student) {
            return {
              'name': student['sname'] ?? "Unknown", // Default value for name if it's null
              'section': (student['section'] ?? "Unknown"),
              'batch': (student['batch'] ?? "Unknown"),
              'program': (student['program'] ?? "Unknown"),
              'profilePic': student['pfp_link'] ?? "", // Default empty string for profilePic if null
            };
          }).toList();
        } else {
          throw Exception('No students found in the response.');
        }
      } else {
        throw Exception('Failed to load students. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to fetch students: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    getStudentSection(); // Get student section on page load.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Directory"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings'); // Navigate to Settings Page
            },
          ),
        ],
      ),
      body: Column(
        children: [

          // Category Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: ["All", "My Class"]
                .map((category) => Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Chip(
                    label: Text(category),
                    backgroundColor: selectedCategory == category ? Colors.blue : Colors.white,
                    labelStyle: TextStyle(
                      color: selectedCategory == category ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ))
                .toList(),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),


          // Fetch and display student list based on the section
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("NOT FUNCTIONAL NOW"));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No students found"));
                }

                // Filter students based on selected category and search query
                List<Map<String, dynamic>> filteredStudents = snapshot.data!;

                if (selectedCategory == "My Class") {
                  filteredStudents = filteredStudents.where((student) {
                    bool match = student['section'] == studentSection &&
                        student['batch'] == studentBatch &&
                        student['program'] == studentProgram;
                    return match;
                  }).toList();
                }

                if (searchQuery.isNotEmpty) {
                  filteredStudents = filteredStudents.where((student) {
                    return student['name']!.toLowerCase().contains(searchQuery);
                  }).toList();
                }

                return ListView(
                  children: filteredStudents.map((student) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: student['profilePic'] != ""
                              ? NetworkImage(student['profilePic']!)
                              : null,
                          child: student['profilePic'] == "" ? Text(student['name']![0]) : null,
                        ),
                        title: Text(student['name']!),
                        subtitle: Text(
                          "${student['section']} - ${student['batch']} \n${student['program']}",
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        currentIndex: 3, // Set to Directory page index
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home'); // Navigate to Home Page
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/events'); // Navigate to Events Page
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/groups'); // Navigate to Groups Page
              break;
            case 3:
            // Already on Directory Page
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Groups"),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: "Directory"),
        ],
      ),
    );
  }
}
