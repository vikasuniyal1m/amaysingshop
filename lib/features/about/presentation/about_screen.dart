import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'About Us',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          'At Amay Sing Shop, we make online shopping simple with a wide range of products across fashion, electronics, home essentials, beauty, pets, and fitness.',
        ),
        SizedBox(height: 12),
        Text(
          'Our goal is to offer quality products, affordable prices, and a smooth shopping experience in one place.',
        ),
        SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.phone),
          title: Text('(618)731-0065'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.email),
          title: Text('info@amaysingshop.com'),
        ),
      ],
    );
  }
}
