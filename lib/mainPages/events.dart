import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<Map<String, dynamic>> events = [];
  String searchQuery = "";
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      final response = await http.get(Uri.parse("https://srm-one-backend.vercel.app/api/events"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['total_events'] == 0) {
          setState(() {
            events = [];
            hasError = true;
          });
          return;
        }

        final now = DateTime.now();
        final dateFormat = DateFormat("dd-MM-yy"); // Define the new date format
        final fetchedEvents = List<Map<String, dynamic>>.from(data['events'].where((event) {
          DateTime endDate = dateFormat.parse(event['end_date']); // Parse the end_date
          return endDate.isAfter(now); // Filter non-expired events
        }).map((event) {
          return {
            "title": event['title'],
            "description": event['desc'],
            "date": event['end_date'],
            "imageUrl": event['image_url'], // Can be null
            "club": event['club'],
            "eventUrl": event['event_url'], // Add the event URL
          };
        }));

        setState(() {
          events = fetchedEvents;
          hasError = fetchedEvents.isEmpty; // Show error if no events are left after filtering
        });
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      setState(() {
        events = [];
        hasError = true;
      });
    }
  }

  List<Map<String, dynamic>> getFilteredEvents() {
    if (searchQuery.isEmpty) return events;
    return events.where((event) {
      return event["title"]!.toString().toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search...",
                  prefixIcon: const Icon(Icons.search),
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

            // Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const Text(
                "Latest Events",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Event List or Error Message
            hasError
                ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  "No events found",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
                : events.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: getFilteredEvents().length,
              itemBuilder: (context, index) {
                final event = getFilteredEvents()[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Image with error handling
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          child: event['imageUrl'] != null && event['imageUrl'] != ''
                              ? Image.network(
                            event['imageUrl']!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                height: 150,
                                width: double.infinity,
                                child: Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 50,
                                ),
                              );
                            },
                          )
                              : const SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event["title"] ?? "No Title",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                event["description"] ?? "No Description",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "End Date: ${event["date"] ?? 'N/A'}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    "By: ${event["club"] ?? 'Unknown'}",
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      final Uri url = Uri.parse(event["event_url"] ?? '');
                                      if (await canLaunch(url.toString())) {
                                        await launch(url.toString());
                                      } else {
                                        // Handle error
                                        print('Could not launch ${event["eventUrl"]}');
                                      }
                                    },
                                    icon: const Icon(Icons.arrow_forward),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/groups');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/directory');
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
