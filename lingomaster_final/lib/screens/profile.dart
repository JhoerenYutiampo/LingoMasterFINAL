import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lingomaster_final/component/text_box.dart';
import 'package:lingomaster_final/screens/profile_picture.dart';
import 'package:lingomaster_final/screens/signin_screen.dart';
import 'package:lingomaster_final/screens/signin_screen.dart'; // Import the SignInScreen

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // User field
  final currentUser = FirebaseAuth.instance.currentUser!;

  // Edit field
  Future<void> editField(String field) async {}

  // Logout method
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text("P R O F I L E"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              children: [
                // Profile pic
                Center(
                  child: ProfilePicture(),
                ),
                const SizedBox(height: 50),

                // User email
                Text(
                  currentUser.email!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 50),

                // User details
                const Text(
                  'My Details',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                // Bio
                MyTextBox(
                  text: '',
                  sectionName: 'bio',
                  onPressed: () => editField('bio'),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),

          // Logout button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(25.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              gradient: const LinearGradient(
                colors: [Colors.black, Color.fromARGB(255, 87, 121, 64)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(10),
                backgroundColor:
                    Colors.transparent, // This is important for the gradient
                shadowColor: Colors
                    .transparent, // Remove shadow to keep the gradient clean
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
