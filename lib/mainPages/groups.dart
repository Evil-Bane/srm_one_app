import 'package:flutter/material.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({Key? key}) : super(key: key);

  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  // List of all groups
  final List<Map<String, String>> groups = [
    {"name": "Flutter Developers", "description": "A group for Flutter enthusiasts."},
    {"name": "Tech Innovators", "description": "Discuss the latest in technology."},
    {"name": "AI Enthusiasts", "description": "Share ideas about Artificial Intelligence."},
    {"name": "Open Source Contributors", "description": "Collaborate on open-source projects."},
  ];

  // List of joined groups
  final List<Map<String, String>> yourGroups = [];

  String searchQuery = "";

  // Get filtered groups (excluding already joined groups)
  List<Map<String, String>> getFilteredGroups() {
    if (searchQuery.isEmpty) {
      return groups
          .where((group) => !yourGroups.contains(group))
          .toList();
    }
    return groups
        .where((group) =>
    !yourGroups.contains(group) &&
        (group['name']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
            group['description']!.toLowerCase().contains(searchQuery.toLowerCase())))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Groups"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings'); // Navigate to Profile Page
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search Groups...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // "Your Groups" Section
          if (yourGroups.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Your Groups",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                children: yourGroups.map((group) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(group['name']![0]), // First letter of the group name
                      ),
                      title: Text(group['name']!),
                      subtitle: Text(group['description']!),
                      trailing: TextButton(
                        onPressed: () {
                          setState(() {
                            yourGroups.remove(group); // Leave the group
                          });
                        },
                        child: const Text("Leave", style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // "More Groups" Section
          if (getFilteredGroups().isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "More Groups",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                children: getFilteredGroups().map((group) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(group['name']![0]), // First letter of the group name
                      ),
                      title: Text(group['name']!),
                      subtitle: Text(group['description']!),
                      trailing: TextButton(
                        onPressed: () {
                          setState(() {
                            yourGroups.add(group); // Add to joined groups
                          });
                        },
                        child: const Text("Join"),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        currentIndex: 2, // Set to Groups page index
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home'); // Navigate to Home Page
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/events'); // Navigate to Events Page
              break;
            case 2:
            // Already on Groups Page
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/directory'); // Navigate to Directory Page
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
