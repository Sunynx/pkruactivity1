import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/screen/home.dart';
import 'package:flutter_application/screen/showdata.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _navigateToHome();
        }
      });

    _controller.forward();
  }

  _navigateToHome() async {
    await Future.delayed(Duration(seconds: 3), () {});
    Widget homeScreen = await getUserDataAndDecideScreen();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => homeScreen),
    );
  }

  Future<Widget> getUserDataAndDecideScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id_student');

    if (userId != null && userId.isNotEmpty) {
      Map<String, dynamic> userData = {
        'user_id_student': prefs.getString('user_id_student') ?? '',
        'user_password': prefs.getString('user_password') ?? '',
        'user_name': prefs.getString('user_name') ?? '',
        'user_class': prefs.getString('user_class') ?? '',
        'status': prefs.getString('status') ?? '',
        'minTime': prefs.getString('minTime') ?? '',
      };

      return showdata(userData: userData);
    } else {
      return HomeScreen();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset(
            'assets/images/Logo2.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
