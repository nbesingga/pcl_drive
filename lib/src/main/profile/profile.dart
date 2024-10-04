import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pcl/src/login/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:pcl/src/platelist.dart';
import 'package:pcl/src/api/api.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Api api = Api();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController plate = TextEditingController();
  String plate_no = "";
  Map<String, dynamic> driver = {};
  final DateTime duty = DateTime.now();
  String _appVersion = "";

  @override
  void initState() {
    user_info();
    super.initState();
  }

  Future<void> user_info() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (userdata != null) {
      setState(() {
        driver = json.decode(userdata);
        _appVersion = packageInfo.version;
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
              "Trucker : ${driver['trucker_name'].toString().toUpperCase()}",
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
                      driver['plate_no'] ?? '',
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
            otherAccountsPictures: [
              IconButton(
                icon: Icon(Icons.edit),
                color: Colors.white,
                onPressed: () {
                  // Add your edit button logic here
                  _showDialog(context);
                },
              ),
            ],
            margin: EdgeInsets.zero,
          ),
          ListTile(
            leading: Icon(
              Icons.build,
            ),
            title: Text('Version', style: TextStyle()),
            trailing: Text(_appVersion),
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
                                  Navigator.of(dialogContext).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    )),
                                child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.red),
                                    )))),
                        const SizedBox(width: 8.0),
                        Expanded(
                            child: ElevatedButton.icon(
                                onPressed: () async {
                                  SharedPreferences preferences = await SharedPreferences.getInstance();
                                  await preferences.clear();
                                  OneSignal.logout();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                    (Route<dynamic> route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
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

  Future<List<PlateList>> plateList(String query) async {
    final res = await api.getData('plateList', params: {
      'trucker_id': driver['trucker_id']
    });
    if (res.statusCode == 200) {
      var data = json.decode(res.body.toString());
      List<dynamic> options = List<dynamic>.from(data['data']);
      List<PlateList> list = options.map((json) => PlateList.fromJson(json)).toList();
      List<PlateList> filteredPlate = list.where((x) => x.plateNo.toString().toLowerCase().contains(query.toLowerCase())).toList();
      return filteredPlate;
    } else {
      return throw Exception('Failed to load plate no');
    }
  }

  void _clearPlate() {
    setState(() {
      plate.text = "";
    });
  }

  _showDialog(BuildContext context) async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          plate.text = driver['plate_no'];
          return AlertDialog(
            contentPadding: EdgeInsets.all(16.0),
            content: Form(
                key: _formKey,
                child: Container(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TypeAheadField<PlateList>(
                          textFieldConfiguration: TextFieldConfiguration(
                            controller: plate,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18.0),
                              labelText: 'PLATE NO',
                              hintText: 'PLATE NO',
                              labelStyle: const TextStyle(color: Colors.red, fontSize: 13.0),
                              border: const OutlineInputBorder(),
                              suffixIcon: plate.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: _clearPlate,
                                    )
                                  : null,
                            ),
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.black,
                            ),
                          ),
                          suggestionsCallback: (String pattern) async {
                            return await plateList(pattern);
                          },
                          itemBuilder: (context, PlateList suggestion) {
                            return ListTile(
                              title: Text("${suggestion.plateNo}"),
                            );
                          },
                          onSuggestionSelected: (PlateList suggestion) {
                            setState(() {
                              plate.text = suggestion.plateNo;
                            });
                          },
                        ),
                        const SizedBox(height: 8.0),
                      ],
                    )))),
            actions: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size.fromHeight(40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            )),
                        child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'CANCEL',
                              style: TextStyle(color: Colors.white),
                            )))),
                const SizedBox(width: 4.0),
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && plate.text != '') {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            final Map<String, dynamic> user = driver;
                            user['plate_no'] = plate.text.toString();
                            prefs.setString('user', json.encode(user));
                            setState(() {
                              driver = user;
                              user_info();
                            });
                            Navigator.of(context).pop();
                          } else if (plate.text == '') {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Validation Error'),
                                    content: const Text('Plate no is required.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('CLOSE'),
                                      ),
                                    ],
                                  );
                                });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size.fromHeight(40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            )),
                        icon: const Icon(Icons.save),
                        label: const FittedBox(fit: BoxFit.scaleDown, child: Text('SAVE')))),
              ])
            ],
          );
        });
  }
}
