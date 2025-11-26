import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MasterAboutUsScreen extends StatelessWidget {
  const MasterAboutUsScreen({super.key});

  Future<void> _launch(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('About Us', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/logologo.jpg',
                width: 250,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: ListTile(
                leading: const Icon(Icons.call),
                title: const Text("Support"),
                onTap: () {
                  _launch('tel:+998901120444');
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.telegram_outlined),
                title: const Text('Contact via Telegram'),
                onTap: () {
                  _launch('https://t.me/axrarovich');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
