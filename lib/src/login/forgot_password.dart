import 'package:flutter/material.dart';
import 'package:pcl/src/api/api.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  Api api = Api();
  final TextEditingController _emailController = TextEditingController();
  bool _showClearIcon = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      setState(() {
        _showClearIcon = _emailController.text.isNotEmpty;
      });
    });
  }

  void _submitForm(BuildContext context) async {
    final String email = _emailController.text.trim();

    if (!_isValidEmail(email)) {
      _showErrorDialog(context, 'Invalid email');
      return;
    }
    await api.postData({
      'email': email
    }, 'forgot-password');
    _resetPassword(email).then((_) => _showSuccessDialog(context)).catchError((error) => _showErrorDialog(context, error.toString()));
  }

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _resetPassword(String email) async {
    // Simulate password reset request delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate password reset success
    const bool success = true;

    if (success) {
      // Password reset successful
      return;
    } else {
      // Password reset failed
      throw 'Failed to reset password';
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const SizedBox(
              child: Row(children: [
            Icon(Icons.check, color: Colors.green),
            SizedBox(
              width: 3,
            ),
            Text(
              "Success",
              style: TextStyle(color: Colors.green),
            )
          ])),
          content: const Text('Reset instructions have been sent to your email.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const SizedBox(
              child: Row(children: [
            Icon(Icons.warning),
            SizedBox(
              width: 3,
            ),
            Text("Error")
          ])),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Please enter email address to reset your password.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40.0),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(90.0),
                ),
                labelText: 'Enter email address',
                prefixIcon: const Icon(Icons.mail, size: 24),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(70.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red, width: 2.0),
                  borderRadius: BorderRadius.circular(70.0),
                ),
                suffixIcon: _showClearIcon
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          _emailController.clear();
                        })
                    : null,
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 222, 8, 8),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    )),
                onPressed: () => _submitForm(context),
                label: const Text('SEND EMAIL'),
                icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}
