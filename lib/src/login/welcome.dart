// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:pcl/src/helper/db_helper.dart';
import 'package:pcl/src/main/main_screen.dart';
import 'package:pcl/src/api/api.dart';
import 'package:pcl/src/platelist.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final Api api = Api();
  TextEditingController plate = TextEditingController();
  final helper = TextEditingController();
  final driverName = TextEditingController();
  bool _showClearIcon = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedPlate;
  String plate_no = "";
  // List runsheetList = [];
  // List bookingList = [];
  bool _isLoading = true;
  Map<String, dynamic> driver = {};
  Future<void> user_info() async {
    _isLoading = false;
    await Future.delayed(const Duration(seconds: 1));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    if (userdata != "") {
      setState(() {
        driver = json.decode(userdata!);
        driverName.text = (driver['trans_type'] == 'driver') ? driver['name'] : "";
        helper.text = (driver['trans_type'] == 'helper') ? driver['name'] : "";
        plate.text = driver['plate_no'] ?? '';
      });
      setState(() {
        _isLoading = false;
      });
    } else {
      user_info;
    }
  }

  @override
  void initState() {
    super.initState();
    user_info();
  }

  void _clearPlate() {
    setState(() {
      selectedPlate = null;
      plate_no = "";
      plate.clear();
    });
  }

  void _clearText() {
    setState(() {
      helper.clear();
      _showClearIcon = false;
    });
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
      print("err");
      throw Exception('Failed to load plate no');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: _isLoading
            ? Center(
                child: Lottie.asset(
                  "animations/loading.json",
                  animate: true,
                  alignment: Alignment.center,
                  height: 100,
                  width: 100,
                ),
              )
            : SingleChildScrollView(
                child: Container(
                    child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 80),
                    Text(
                      "${driver['trucker_name']?.toUpperCase()}! \n",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Ready to head out?',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Lottie.asset(
                      "animations/driver.json",
                      animate: true,
                      alignment: Alignment.center,
                      height: 150,
                      width: 150,
                    ),
                    const SizedBox(height: 30),
                    Container(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 4.0,
                          bottom: 16.0,
                        ),
                        width: 300,
                        child: TypeAheadField<PlateList>(
                          // hideKeyboard: true,
                          textFieldConfiguration: TextFieldConfiguration(
                              controller: plate,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18.0),
                                labelText: 'PLATE NO',
                                hintText: 'PLATE NO',
                                labelStyle: const TextStyle(color: Colors.red),
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
                              )),
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
                        )),
                    Container(
                        padding: const EdgeInsets.all(16),
                        width: 300,
                        child: ElevatedButton.icon(
                            icon: const Icon(Icons.keyboard_double_arrow_right),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 248, 51, 2),
                                minimumSize: const Size.fromHeight(45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                )),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('GO ONLINE'),
                            ),
                            onPressed: () async {
                              if (plate.text != '') {
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                final Map<String, dynamic> user = driver;
                                user['driver_name'] = driverName.text.toString();
                                user['helper_name'] = helper.text.toString();
                                user['plate_no'] = plate.text.toString();
                                prefs.setString('user', json.encode(user));
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const MainScreen()));
                              } else {
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
                            })),
                  ],
                ),
              ))));
  }

  void _selectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        plate.text = driver['plate_no'] ?? '';
        return AlertDialog(
          title: Text(driver['trucker']),
          content: Padding(
            padding: const EdgeInsets.all(4.0),
            child: TypeAheadField<PlateList>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: plate,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(2.0),
                  labelText: 'Plate No',
                  hintText: 'Plate No',
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
                  // print(suggestion);
                  plate.text = suggestion.plateNo;
                });
              },
            ),
          ),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.close),
              label: const Text(
                'CANCEL',
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              icon: const Icon(Icons.published_with_changes),
              label: const Text(
                'CHANGE',
              ),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                final Map<String, dynamic> user = driver;
                user['plate_no'] = plate.text.toString();
                prefs.setString('user', json.encode(user));
                setState(() {
                  driver = user;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String? customValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty.';
    }
    return null;
  }
}
