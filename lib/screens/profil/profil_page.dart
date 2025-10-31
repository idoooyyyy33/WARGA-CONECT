import 'package:flutter/material.dart';

class ProfilPage extends StatelessWidget {
  final String userName;
  final String userId;

  const ProfilPage({Key? key, required this.userName, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil - $userName'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Text(
                userName[0].toUpperCase(),
                style: TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            Text(
              userName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('User ID: $userId'),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // TODO: Implementasi edit profile
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit profile akan diimplementasikan')),
                );
              },
              child: Text('Edit Profile'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Logout
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Logout'),
                      content: Text('Apakah Anda yakin ingin logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigasi kembali ke login
                            Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
                          },
                          child: Text('Logout'),
                        ),
                      ],
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
