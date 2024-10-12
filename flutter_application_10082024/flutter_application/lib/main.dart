import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_application/screen/home.dart';
import 'package:flutter_application/screen/showdata.dart';
import 'package:flutter_application/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate();
  FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PKRU Activity',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Colors.orange,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 255, 174, 43),
        ),
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('th', 'TH'),
      ],
      home: SplashScreen(), // ตั้งค่า SplashScreen เป็นหน้าแรก
    ),
  );
}
