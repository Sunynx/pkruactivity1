import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application/screen/import.dart';
import 'package:flutter_application/screen/update_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/screen/home.dart';
import 'package:flutter_application/user/edit_user.dart';

class ProfileScreen extends StatefulWidget {
  final String userIdStudent;

  ProfileScreen({required this.userIdStudent});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Future<Map<String, dynamic>?>? _studentDataFuture;

  @override
  void initState() {
    super.initState();
    _studentDataFuture = _fetchUserData();
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    try {
      DatabaseReference dbRef = _database.child('user');
      Query query =
          dbRef.orderByChild('user_id_student').equalTo(widget.userIdStudent);

      DatabaseEvent event = await query.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        Map<dynamic, dynamic> userData =
            snapshot.value as Map<dynamic, dynamic>;
        return userData.isNotEmpty
            ? Map<String, dynamic>.from(
                userData.values.first as Map<dynamic, dynamic>)
            : null;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9;

    return Scaffold(
      appBar: AppBar(
        title: Text('ข้อมูลส่วนตัว', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _studentDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: Colors.orange));
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red)));
          } else if (snapshot.hasData) {
            final data = snapshot.data;
            List<Widget> infoRows = [
              _buildInfoRow(
                  'ชื่อ - นามสกุล', data?['user_name'] ?? 'N/A', Icons.person),
            ];

            if (data?['status'] == 's') {
              infoRows.addAll([
                _buildInfoRow('สถานะ', 'นักศึกษา', Icons.school),
                _buildInfoRow('รหัสนักศึกษา', data?['user_id_student'] ?? 'N/A',
                    Icons.badge),
                _buildInfoRow(
                    'สาขา', data?['user_class'] ?? 'N/A', Icons.business),
                _buildInfoRow('ชั่วโมงที่เก็บได้', data?['minTime'] ?? 'N/A',
                    Icons.timer),
                //_buildInfoRow('ชั่วโมงที่ขาดอีก', data?['minTime'] ?? 'N/A',
                // Icons.hourglass_empty),
              ]);
            } else if (data?['status'] == 'a') {
              infoRows.add(_buildInfoRow(
                  'สถานะ', 'ADMIN - แอดมิน', Icons.admin_panel_settings));
            } else if (data?['status'] == 't') {
              infoRows.add(
                  _buildInfoRow('สถานะ', 'PROFESSOR - อาจารย์', Icons.school));
            }

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: cardWidth,
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: infoRows,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    if (data?['status'] != 's')
                      _buildButton('อัพเดตฐานข้อมูล', Icons.update, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ImportExcelPage()),
                        );
                      }),
                    if (data?['status'] != 's') SizedBox(height: 20),
                    if (data?['status'] != 's')
                      _buildButton('กำหนดสิทธิสถานะ', Icons.security, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditUser()));
                      }),
                    SizedBox(height: 20),
                    _buildButton('ออกระบบ', Icons.exit_to_app, () {
                      _showLogoutDialog(context);
                    }),
                  ],
                ),
              ),
            );
          } else {
            return Center(
                child: Text('No data found',
                    style: TextStyle(color: Colors.black)));
          }
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    if (label == 'ชั่วโมงที่เก็บได้') {
      int minTime = int.parse(value);
      int hours = minTime ~/ 60;
      int minutes = minTime % 60;
      value = '$hours ชั่วโมง $minutes นาที';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                Text(value,
                    style: TextStyle(fontSize: 16.0, color: Colors.orange)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onPressed,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการออกระบบ'),
          content: Text('คุณต้องการออกระบบหรือไม่?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                await AuthService.signOutAndClearLocalStorage(context);
              },
              child: Text('Yes', style: TextStyle(color: Colors.orange)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }
}

class AuthService {
  static Future<void> signOutAndClearLocalStorage(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Error during sign out: $e');
    }
  }
}
