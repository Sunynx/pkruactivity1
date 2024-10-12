import 'package:flutter/material.dart';
import 'package:flutter_application/screen/showdata.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _obscureText = true;
  void _togglePasswordView() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  double screenHeight = 0.0;
  double screenWidth = 0.0;

  TextEditingController idStudentController = TextEditingController();
  TextEditingController passwordStudentController = TextEditingController();

  late DatabaseReference dbRef;

  Future<void> signInWithFirebase() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: LoadingAnimationWidget.inkDrop(
              color: Colors.white,
              size: 100,
            ),
          );
        },
      );

      String id_student = idStudentController.text;
      String password_student = passwordStudentController.text;

      DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('user');

      Query query = dbRef.orderByChild('user_id_student').equalTo(id_student);

      // ดึงข้อมูลที่ตรงกับ Query ที่สร้างขึ้นมา
      DatabaseEvent event = await query.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        Map<dynamic, dynamic> userData =
            snapshot.value as Map<dynamic, dynamic>;

        // สร้างฟังก์ชันเพื่อแปลง Map<dynamic, dynamic> เป็น Map<String, dynamic>
        Map<String, dynamic> _transformMap(Map<dynamic, dynamic> map) {
          Map<String, dynamic> transformedMap = {};
          map.forEach((key, value) {
            transformedMap[key.toString()] = value;
          });
          return transformedMap;
        }

        userData.forEach((key, value) {
          String user_id_student = value['user_id_student'];
          String user_password = value['user_password'];
          String user_name = value['user_name'];
          String user_class = value['user_class'];
          String status = value['status'];
          String minTime = value['minTime'];

          if (user_id_student == id_student &&
              user_password == password_student) {
            saveUserDataToLocal(value);

            Future.delayed(const Duration(seconds: 2), () {
              final snackBar = SnackBar(
                elevation: 0,
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.transparent,
                content: AwesomeSnackbarContent(
                  title: 'Success!',
                  message: 'ล็อคอินสำเร็จ!',
                  contentType: ContentType.success,
                ),
              );

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(snackBar);
            });

            Future.delayed(const Duration(seconds: 2), () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      showdata(userData: _transformMap(value)),
                ),
              ); // ปิด showDialog หลังจาก 2 วินาที
            });
          } else {
            Future.delayed(const Duration(seconds: 2), () {
              final snackBar = SnackBar(
                elevation: 0,
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.transparent,
                content: AwesomeSnackbarContent(
                  title: 'Error!',
                  message: 'รหัสนักศึกษาหรือรหัสผ่านไม่ถูกต้อง!',
                  contentType: ContentType.failure,
                ),
              );

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(snackBar)
                    .closed // เมื่อ SnackBar ปิด
                    .then((reason) {
                  
                });
            });

            Future.delayed(const Duration(seconds: 2), () {
              Navigator.pop(context); // ปิด showDialog หลังจาก 2 วินาที
            });
          }
        });
      } else {
        Future.delayed(const Duration(seconds: 2), () {
          final snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Error!',
              message: 'ไม่พบบัญชี!',
              contentType: ContentType.failure,
            ),
          );

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
        });

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context); // ปิด showDialog หลังจาก 2 วินาที
        });
        //print('ไม่พบบัญชี');
      }
    } catch (e) {
      Future.delayed(const Duration(seconds: 2), () {
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Error!',
            message: 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ!',
            contentType: ContentType.failure,
          ),
        );

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      });

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context); // ปิด showDialog หลังจาก 2 วินาที
      });

      //print("เกิดข้อผิดพลาดในการเข้าสู่ระบบ: $e");
    }
  }

  Future<void> saveUserDataToLocal(Map<dynamic, dynamic> userData) async {
    if (userData == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();

    // ดึงข้อมูลจาก userData
    String user_id_student = userData['user_id_student'];
    String user_password = userData['user_password'];
    String user_name = userData['user_name'];
    String user_class = userData['user_class'];
    String status = userData['status'];
    String minTime = userData['minTime'];

    await prefs.setString('user_id_student', user_id_student);
    await prefs.setString('user_password', user_password);
    await prefs.setString('user_name', user_name);
    await prefs.setString('user_class', user_class);
    await prefs.setString('status', status);
    await prefs.setString('minTime', minTime);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  screenHeight = MediaQuery.of(context).size.height;
  screenWidth = MediaQuery.of(context).size.width;

  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFA07A), Color(0xFFFF7F50)],
        ),
      ),
      child: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circles
            Positioned(
              top: screenHeight * -0.05,
              left: -40,
              child: _buildCircle(150, Colors.white.withOpacity(0.3)),
            ),
            Positioned(
              top: screenHeight * 0.22,
              left: 290,
              child: _buildCircle(100, Colors.white.withOpacity(0.2)),
            ),
            Positioned(
              top: screenHeight * 0.39,
              left: 4,
              child: _buildCircle(120, Colors.white.withOpacity(0.2), isOval: true),
            ),

            // Welcome text
            Positioned(
              top: screenHeight * 0.15,
              child: Text(
                "Welcome",
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
            ),

            // Logo
            Positioned(
              top: screenHeight * 0.2,
              child: Image.asset(
                "assets/images/logo_home.png",
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.2,
              ),
            ),

            // ID Student input
            Positioned(
              top: screenHeight * 0.4,
              left: 0,
              right: 0,
              child: _buildInputField(
                hintText: 'ID STUDENT',
                controller: idStudentController,
                icon: Icons.person_2_outlined,
              ),
            ),

            // Password input
            Positioned(
              top: screenHeight * 0.5,
              left: 0,
              right: 0,
              child: _buildInputField(
                hintText: 'PASSWORD',
                controller: passwordStudentController,
                icon: Icons.lock,
                isPassword: true,
              ),
            ),

            // Login button
            Positioned(
              top: screenHeight * 0.7,
              child: _buildLoginButton(context),
            ),

            // Bottom decoration
            // Positioned(
            //   bottom: 0,
            //   child: Container(
            //     width: MediaQuery.of(context).size.width,
            //     height: screenHeight * 0.2,
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.only(
            //         topLeft: Radius.circular(100),
            //         topRight: Radius.circular(100),
            //       ),
            //       color: Color(0xFFe8e4e4),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildCircle(double size, Color color, {bool isOval = false}) {
  return Container(
    width: size,
    height: isOval ? size * 0.6 : size,
    decoration: BoxDecoration(
      shape: isOval ? BoxShape.rectangle : BoxShape.circle,
      color: color,
      borderRadius: isOval ? BorderRadius.circular(size / 2) : null,
    ),
  );
}

Widget _buildInputField({
  required String hintText,
  required TextEditingController controller,
  required IconData icon,
  bool isPassword = false,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 60),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscureText : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 10),
            child: Icon(icon, color: Color(0xFF778899)),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 70),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Color(0xFF778899),
                  ),
                  onPressed: _togglePasswordView,
                )
              : null,
          contentPadding: EdgeInsets.symmetric(vertical: 15.0),
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(20),
        ],
      ),
    ),
  );
}

Widget _buildLoginButton(BuildContext context) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 50,
    padding: EdgeInsets.symmetric(horizontal: 60),
    child: ElevatedButton(
      onPressed: () {
        signInWithFirebase();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(color: Colors.white, width: 2), // เพิ่มขอบสีขาว
        ),
        elevation: 5,
      ),
      child: Text(
        'LOGIN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

}
