import 'package:flutter/material.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Language',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 50.0,
          top: 20.0,
          right: 50.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.4),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              _buildLanguageItem(context, 'assets/images/ru.jpg', 'Русский'),
              const Divider(height: 1),
              _buildLanguageItem(context, 'assets/images/uz.jpg', "O'zbek"),
              const Divider(height: 1),
              _buildLanguageItem(context, 'assets/images/en.jpg', 'English'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context, String flagAsset, String language) {
    return ListTile(
      leading: Image.asset(flagAsset, width: 32, height: 24, fit: BoxFit.cover),
      title: Text(language),
      onTap: () {
        // Til tanlash logikasi
      },
    );
  }
}
