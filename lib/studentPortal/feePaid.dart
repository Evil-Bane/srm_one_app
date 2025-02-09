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
  double _totalFees = 0.0;

  Future<List<dynamic>> fetchFeePaid() async {
    try {
      final sid = await UserSession.getSession();
      if (sid == null) throw Exception("No SID found. Please log in again.");

      final response = await http.post(
        Uri.parse('https://api-srm-one.vercel.app/user'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'method': 'getFinanceDetails', 'sid': sid},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          _totalFees = data.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount']?.toString() ?? '0') ?? 0));
          return data;
        }
      }
      throw Exception("No Receipts found.");
    } catch (error) {
      throw Exception("Error fetching fee details: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    feePaidFuture = fetchFeePaid();
  }

  Widget _buildTotalCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2A4A), Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Fees Paid",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "₹${_totalFees.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 40),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> receipt) {
    final amount = receipt['amount']?.toString().trim() ?? '';
    final voucherType = receipt['vouchertype']?.toString().trim() ?? '';
    final narration = receipt['narration']?.toString().trim() ?? '';
    final voucherDate = receipt['voucherdate']?.toString().trim() ?? '';
    final voucherNumber = receipt['vouchernumber']?.toString().trim() ?? '';

    return Card(
      color: Color(0xFF1A1A2E),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    voucherType,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[800],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    voucherDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.blueGrey[700], height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Receipt No:",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  voucherNumber,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Amount:",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  "₹$amount",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              "Details:",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              narration,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Fee Receipts"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => setState(() {
              feePaidFuture = fetchFeePaid();
            }),
          )
        ],
        elevation: 0,
      ),

      body: FutureBuilder<List<dynamic>>(
        future: feePaidFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 60, color: Colors.blueGrey),
                  SizedBox(height: 20),
                  Text(
                    "No Receipts Found",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildTotalCard(),
              Expanded(
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => _buildReceiptCard(
                    snapshot.data![index] as Map<String, dynamic>,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}