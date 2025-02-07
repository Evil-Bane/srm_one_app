import 'package:flutter/material.dart';

class FeeDetailsPage extends StatelessWidget {
  const FeeDetailsPage({Key? key}) : super(key: key);

  // Helper method to build a button card for fee sections.
  Widget _feeButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required String route,
        required IconData iconData,
      }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(iconData, color: Colors.blue, size: 30),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fee Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _feeButton(
              context,
              title: 'Fee Recipts',
              subtitle: 'View receipts for all fee transactions',
              route: '/fee_paid',
              iconData: Icons.receipt_long,
            ),
          ],
        ),
      ),
    );
  }
}
