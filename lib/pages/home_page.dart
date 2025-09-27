import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../widgets/custom_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首頁', style: AppText.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('歡迎回來！', style: AppText.title),
                const SizedBox(height: 16),
                const Text('這裡是你的主頁。你可以前往各功能頁面。'),
                const SizedBox(height: 24),
                CustomButton(
                  text: '查看溫室資訊',
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
