import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:srm_hope/Utilities/data_saver.dart';

class FeePaidPage extends StatefulWidget {
  const FeePaidPage({Key? key}) : super(key: key);

  @override
  _FeePaidPageState createState() => _FeePaidPageState();
}

class _FeePaidPageState extends State<FeePaidPage> {
  late Future<List<dynamic>> feePaidFuture;

  @override
  void initState() {
    super.initState();
    feePaidFuture = fetchFeePaid();
  }

  Future<List<dynamic>> fetchFeePaid() async {
    try {
      final sid = await UserSession.getSession();
      if (sid == null) {
        throw Exception("No SID found. Please log in again.");
      }

      final response = await http.post(
        Uri.parse('https://api-srm-one.onrender.com/user'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'method': 'getFinanceDetails',
          'sid': sid,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Check if the API returns a List; if not, we consider it a failure.
        if (data is List) {
          return data;
        } else {
          throw Exception("No Recipts found.");
        }
      } else {
        throw Exception("No Recipts found.");
      }
    } catch (error) {
      throw Exception("Error fetching fee paid details: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Fee Recipts"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                feePaidFuture = fetchFeePaid();
              });
            },
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: feePaidFuture,
        builder: (context, snapshot) {
          // While waiting for the API response
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          // If an error occurs or data is not in expected format
          if (snapshot.hasError) {
            return Center(child: Text("No Recipts found."));
          }
          // When data is available, but ensure it's a non-empty list
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No Recipts found."));
          }

          final feePaidData = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: feePaidData.length,
            itemBuilder: (context, index) {
              final receipt = feePaidData[index] as Map<String, dynamic>;
              final amount = receipt['amount']?.toString().trim() ?? '';
              final voucherType =
                  receipt['vouchertype']?.toString().trim() ?? '';
              final narration = receipt['narration']?.toString().trim() ?? '';
              final voucherDate =
                  receipt['voucherdate']?.toString().trim() ?? '';
              final voucherNumber =
                  receipt['vouchernumber']?.toString().trim() ?? '';

              return Card(
                color: Color(0xFF1A1A2E),
                margin: EdgeInsets.only(bottom: 16),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Voucher Number and Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Voucher No: $voucherNumber",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            voucherDate,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Voucher Type
                      Text(
                        "Type: $voucherType",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 8),
                      // Amount
                      Text(
                        "Amount: ₹$amount",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      // Narration details
                      Text(
                        "Information:",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        narration,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
