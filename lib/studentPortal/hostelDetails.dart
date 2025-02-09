import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:srm_hope/Utilities/data_saver.dart';

class HostelDetailsPage extends StatefulWidget {
  @override
  _HostelDetailsPageState createState() => _HostelDetailsPageState();
}

class _HostelDetailsPageState extends State<HostelDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? hostelDetails;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchHostelDetails();
  }

  Future<void> _fetchHostelDetails() async {
    try {
      final sid = await UserSession.getSession();
      if (sid != null) {
        final response = await http.post(
          Uri.parse('https://api-srm-one.vercel.app/user'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'sid': sid,
            'method': 'getHostelDetails',
          },
        );

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          // Expecting a list with one map containing hostel details.
          if (responseBody is List &&
              responseBody.isNotEmpty &&
              responseBody[0] is Map) {
            setState(() {
              hostelDetails = responseBody[0];
              errorMsg = null;
              _isLoading = false;
            });
          } else {
            setState(() {
              errorMsg = "Not a Hosteller";
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMsg = "Not a Hosteller";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMsg = "Not a Hosteller";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = "Not a Hosteller";
        _isLoading = false;
      });
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Using a dark background similar to the timetable page.
    return Scaffold(
      appBar: AppBar(
        title: Text("Hostel Details"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchHostelDetails();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMsg != null
          ? Center(
        child: Text(
          errorMsg!,
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: Card(
          color: Color(0xFF1A1A2E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.blueAccent, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    "Hostel Block", hostelDetails!["hostelname"]),
                _buildDetailRow(
                    "Room No.", hostelDetails!["roomname"]),
                _buildDetailRow("Academic Year",
                    hostelDetails!["academicyear"]),
                _buildDetailRow(
                    "Alloted Date", hostelDetails!["alloteddate"]),
                _buildDetailRow(
                    "Room Type", hostelDetails!["roomtype"]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}