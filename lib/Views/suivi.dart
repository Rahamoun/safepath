import 'package:flutter/material.dart';

class SuiviPage extends StatefulWidget {
  const SuiviPage({Key? key}) : super(key: key);

  @override
  State<SuiviPage> createState() => _SuiviPageState();
}

class _SuiviPageState extends State<SuiviPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour'),
      ),
      body: Center(
        child: Text(
          'Bonjour',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }
}
