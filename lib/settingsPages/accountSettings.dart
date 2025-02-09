import 'package:flutter/material.dart';

class AccountSettings extends StatefulWidget {
  const AccountSettings({super.key});

  @override
  _AccountSettingsState createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildListItem(context, 'Change Password', '/change_Pass1'),
        ],
      ),
    );
  }


  Widget _buildListItem(BuildContext context, String title, String routeName) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 18)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        await Navigator.pushNamed(context, routeName);
      },
    );
  }
}
