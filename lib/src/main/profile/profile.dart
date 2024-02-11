import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pcl/src/login/login.dart';
import 'package:pcl/src/main/task/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String plate_no = "";
  Map<String, dynamic> driver = {};
  final DateTime duty = DateTime.now();

  @override
  void initState() {
    super.initState();
    user_info();
  }

  Future<void> user_info() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    // PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (userdata != null) {
      setState(() {
        driver = json.decode(userdata);
        // _appVersion = packageInfo.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.orange.shade900,
            ),
            accountName: Text(
              "Name : ${driver['name']}",
              style: const TextStyle(fontSize: 16.0, color: Colors.white),
            ),
            accountEmail: Text(
              "Trucker : ${driver['trucker_name'].toUpperCase()}",
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
            ),
            currentAccountPicture: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Column(children: [
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/images/driver_avatar.png'),
                      radius: 40.0,
                    ),
                  ]),
                  const SizedBox(width: 8.0),
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                    Text(
                      "${driver['plate_no']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    Text(DateFormat('yyyy/MM/dd').format(duty), style: const TextStyle(color: Colors.white))
                  ])
                ],
              ),
            ),
            // otherAccountsPictures: [
            //   IconButton(
            //     icon: Icon(Icons.edit),
            //     color: Colors.white,
            //     onPressed: () {
            //       // _showDialog(context);
            //     },
            //   ),
            // ],
            margin: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(
              Icons.build,
            ),
            title: const Text('Version', style: TextStyle()),
            trailing: Text(''),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout', style: TextStyle()),
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(fontSize: 16),
                    ),
                    actionsAlignment: MainAxisAlignment.center,
                    actions: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(
                            child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade300,
                                    minimumSize: const Size.fromHeight(40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    )),
                                child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.white),
                                    )))),
                        const SizedBox(width: 8.0),
                        Expanded(
                            child: ElevatedButton.icon(
                                onPressed: () async {
                                  SharedPreferences preferences = await SharedPreferences.getInstance();
                                  await preferences.clear();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                    (Route<dynamic> route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade900,
                                    minimumSize: const Size.fromHeight(40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    )),
                                icon: const Icon(Icons.logout),
                                label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Logout'))))
                      ]),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
