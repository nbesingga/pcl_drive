import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pcl/src/login/login.dart';
import 'package:pcl/src/main/main_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

@override
class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  Map<String, dynamic> driver = {};
  bool isLoggedIn = false;

  final ThemeData kLightTheme = ThemeData(
    appBarTheme: const AppBarTheme(
      color: Colors.red,
    ),
    brightness: Brightness.light,
  );

  final ThemeData kDarkTheme = ThemeData(
    appBarTheme: const AppBarTheme(color: Colors.red),
    brightness: Brightness.dark,
  );
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    checkLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(navigatorKey: navigatorKey, theme: isDarkMode ? kDarkTheme : kLightTheme, home: isLoggedIn ? const MainScreen() : const LoginPage(), debugShowCheckedModeBanner: false);
  }

  void checkLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      setState(() {
        driver = json.decode(userdata!);
      });
    }
  }
}
