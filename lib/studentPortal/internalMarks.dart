import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:srm_hope/Utilities/data_saver.dart';

class InternalMarksPage extends StatefulWidget {
  @override
  _InternalMarksPageState createState() => _InternalMarksPageState();
}

class _InternalMarksPageState extends State<InternalMarksPage> {
  late Future<dynamic> internalMarksFuture;

  @override
  void initState() {
    super.initState();
    internalMarksFuture = fetchInternalMarks();
  }

  Future<dynamic> fetchInternalMarks() async {
    try {
      final sid = await UserSession.getSession();
      if (sid == null) {
        throw Exception('No SID found. Please log in again.');
      }

      final response = await http.post(
        Uri.parse('https://api-srm-one.onrender.com/user'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'method': 'getInternalMarkDetails',
          'sid': sid,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Check if the response indicates an error.
        if (data is Map && data["Status"] == "Error") {
          return data;
        }
        // Otherwise, assume data is valid. (Adjust this once the marks data is available.)
        return data;
      } else {
        throw Exception('Failed to retrieve internal marks details.');
      }
    } catch (error) {
      throw Exception('Error fetching internal marks details: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Internal Marks"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                internalMarksFuture = fetchInternalMarks();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<dynamic>(
        future: internalMarksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            final data = snapshot.data;
            // If the API returns an error response, show no marks found.
            if (data is Map && data["Status"] == "Error") {
              return Center(child: Text("No marks details found."));
            }
            // Otherwise, when marks data is available, update the UI accordingly.
            return Center(child: Text("Internal marks details available."));
          } else {
            return Center(child: Text("No data available"));
          }
        },
      ),
    );
  }
}
