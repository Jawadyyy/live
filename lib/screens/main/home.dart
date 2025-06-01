import 'package:flutter/material.dart';
import 'package:live/auth/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //get auth service
  final authService = AuthService();

  //logout button pressed
  void logout() async {
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          //logout button
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: const Center(child: Text('Home', style: TextStyle(fontSize: 24))),
    );
  }
}
