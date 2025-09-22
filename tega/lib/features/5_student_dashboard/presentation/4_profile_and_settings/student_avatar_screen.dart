import 'package:flutter/material.dart';

class AvatarScreen extends StatelessWidget {
  const AvatarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Center avatar
          Center(
            child: Hero(
              tag: 'avatarHero',
              child: CircleAvatar(
                radius: 140,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person, size: 120, color: Colors.grey[600]),
                // Or backgroundImage: NetworkImage("https://example.com/avatar.png"),
              ),
            ),
          ),

          // Back arrow button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                Navigator.pop(context); // closes and returns to student home
              },
            ),
          ),
        ],
      ),
    );
  }
}
