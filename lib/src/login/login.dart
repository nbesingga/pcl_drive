import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pcl/src/login/welcome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info/package_info.dart';
import 'package:pcl/src/api/api.dart';
import 'package:pcl/src/login/forgot_password.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Api api = Api();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  FocusNode textFieldFocusNode = FocusNode();
  bool _obscured = true;
  bool _showClearIcon = false;
  String _appVersion = '';
  String latestVersion = '';
  String url = '';
  bool _isLoading = false;
  String? selectedPlate;
  String? selectedTrucker;
  dynamic plateNo;
  dynamic truckerId;
  @override
  void initState() {
    super.initState();
    app_version();
    textFieldFocusNode.requestFocus();
    _usernameController.addListener(() {
      setState(() {
        _showClearIcon = _usernameController.text.isNotEmpty;
      });
    });
  }

  app_version() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  @override
  void dispose() {
    textFieldFocusNode.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _clearText() {
    setState(() {
      _usernameController.clear();
      _showClearIcon = false;
    });
  }

  void _clearPlate() {
    setState(() {
      selectedPlate = null;
      plateNo = "";
    });
  }

  void _clearTrucker() {
    setState(() {
      selectedTrucker = null;
      truckerId = "";
      selectedPlate = null;
      plateNo = "";
    });
  }

  void showNoInternetDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('No Internet Connection'),
          content: Text('Please check your internet connection and try again.'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _login() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
      setState(() {
        _isLoading = true;
      });
      Future.delayed(const Duration(seconds: 2), () async {
        var data = {
          'username': _usernameController.text,
          'password': _passwordController.text,
        };
        try {
          final response = await api.postData(data, 'login');
          var res = jsonDecode(response.body);
          if (response.statusCode == 200) {
            SharedPreferences preference = await SharedPreferences.getInstance();
            preference.setString('token', res['data']['api_token']);
            preference.setBool('isLoggedIn', true);
            preference.setString('user', json.encode(res['data']));
            await api.getData('appVersion').then((v) async {
              final responseData = json.decode(v.body.toString());
              if (responseData['success'] == true) {
                var data = responseData['data'];
                latestVersion = data['version'] ?? '';
                url = data['link'] ?? '';
                setState(() {
                  if (_appVersion.toString() != latestVersion.toString()) {
                    appUpdate(context, url);
                  } else {
                    _isLoading = false;
                    _usernameController.clear();
                    _passwordController.clear();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const WelcomePage()));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(res['message']),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                });
              }
            });
          } else {
            setState(() {
              _isLoading = false;
              _showLoginError(res['message'] ?? 'Login Failed');
            });
          }
        } catch (e) {
          _isLoading = false;
          _showLoginError(e.toString());
        }
      });
    } else {
      showNoInternetDialog(context);
    }
  }

  Future<void> appUpdate(BuildContext context, url) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Required'),
          content: const Text('A new version of the app is available. Please update to continue using the app.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Update Now'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                setState(() {
                  // launchUrl(Uri.parse(url));
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleObscured() {
    setState(() {
      _obscured = !_obscured;
      if (textFieldFocusNode.hasPrimaryFocus) {
        return;
      }
      textFieldFocusNode.canRequestFocus = false;
    });
  }

  void _showLoginError(message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login Failed'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double logoHeight = constraints.maxHeight * 0.3;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: logoHeight,
                          height: logoHeight,
                          child: Image.asset('assets/images/logo-dark.png'),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          validator: customValidator,
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            labelText: 'Username',
                            labelStyle: const TextStyle(color: Colors.black),
                            prefixIcon: const Icon(Icons.person, size: 24),
                            prefixIconColor: Colors.black,
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.black, width: 1.0),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.red, width: 1.0),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            suffixIcon: _showClearIcon
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.red),
                                    onPressed: _clearText,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          validator: customValidator,
                          controller: _passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          obscureText: _obscured,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.black),
                            prefixIcon: const Icon(Icons.lock_rounded, size: 24),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                              child: GestureDetector(
                                onTap: _toggleObscured,
                                child: Icon(_obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 24, color: Colors.black),
                              ),
                            ),
                            prefixIconColor: Colors.black,
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.black, width: 1.0),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.red, width: 1.0),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPassword()));
                              },
                              child: const Text('Forgot Password?', textAlign: TextAlign.end, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                        ),
                        const SizedBox(height: 20.0),
                        ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(244, 246, 52, 3),
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                )),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      _login();
                                    }
                                  },
                            label: _isLoading ? CircularProgressIndicator(color: Colors.red.shade900) : const Text('SIGN IN'),
                            icon: const Icon(Icons.login)),
                        const SizedBox(height: 24.0),
                        Text(
                          'Version $_appVersion',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],
                    )),
              ),
            );
          },
        ),
      ),
    );
  }

  String? customValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty.';
    }
    return null;
  }
}
