// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../widgets/custom_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home', style: AppText.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Welcome back!', style: AppText.title),
                const SizedBox(height: 16),
                const Text('This is your dashboard. Navigate to features below.'),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'View Greenhouse',
                  onPressed: () => Navigator.pushNamed(context, '/greenhouse'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
