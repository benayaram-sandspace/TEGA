import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // counter removed — this HomePage shows a static confirmation message.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(widget.title),
      ),
      body: const Center(
        child: Text(
          'Home Page - Tega ',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      ),
  // no FAB on this simplified home page
    );
  }
}