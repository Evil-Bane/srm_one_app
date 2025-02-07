import 'package:flutter/material.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Grade Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _gradeButton(
              context,
              'Exam Results',
              'View your exam details',
              '/exam_details',
              const Icon(Icons.assignment, color: Colors.blue),
            ),
            _gradeButton(
              context,
              'Exam Provisional Results',
              'View your exam provisional details',
              '/provisional_details',
              const Icon(Icons.assignment_ind, color: Colors.blue),
            ),
            _gradeButton(
              context,
              'Internal Marks',
              'Check your internal marks',
              '/internal_marks',
              const Icon(Icons.assessment, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradeButton(BuildContext context, String title, String subtitle, String route, Icon icon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: icon,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}