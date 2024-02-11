import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pcl/src/api/api.dart';
import 'package:pcl/src/chargeslist.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AddPage extends StatefulWidget {
  const AddPage({Key? key}) : super(key: key);
  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final Api api = Api();
  List data = [];
  String? selectedValue;
  final TextEditingController note = TextEditingController();
  final TextEditingController charge = TextEditingController();
  final TextEditingController amount = TextEditingController();
  final TextEditingController receipt = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? selectedCharge;
  String chargeCode = "";
  bool _isLoading = true;

  final ImagePicker _picker = ImagePicker();
  List<File>? selectedImages = [];
  var attach = [];
  Future<void> exception() async {
    _isLoading = true;
    final List<Map<String, dynamic>> rows = [];
    if (mounted) {
      setState(() {
        data = rows;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  setSelectedRadioTile(val) {
    setState(() {
      selectedValue = val;
    });
  }

  void _clearCharges() {
    setState(() {
      selectedCharge = null;
      chargeCode = "";
      charge.clear();
    });
  }

  Future<List<ChargesList>> charges(String query) async {
    final res = await api.getData('charges', params: {
      'group': 1
    });
    if (res.statusCode == 200) {
      var data = json.decode(res.body.toString());
      List<dynamic> options = List<dynamic>.from(data['data']);
      List<ChargesList> list = options.map((json) => ChargesList.fromJson(json)).toList();
      List<ChargesList> filteredPlate = list.where((x) => x.chargeDesc.toString().toLowerCase().contains(query.toLowerCase())).toList();
      return filteredPlate;
    } else {
      print("err");
      throw Exception('Failed to load plate no');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text('Create Expense'),
        ),
        body: SingleChildScrollView(
            child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(height: 40.0),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('Please enter expense on your trip.', textAlign: TextAlign.start, style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 30.0),
                    TypeAheadField<ChargesList>(
                      hideKeyboard: true,
                      textFieldConfiguration: TextFieldConfiguration(
                          controller: charge,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
                            labelText: 'Charge Name',
                            hintText: 'Charge Name',
                            labelStyle: const TextStyle(color: Colors.grey),
                            border: const OutlineInputBorder(),
                            suffixIcon: charge.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _clearCharges,
                                  )
                                : null,
                          ),
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: Colors.black,
                          )),
                      suggestionsCallback: (String pattern) async {
                        return await charges(pattern);
                      },
                      itemBuilder: (context, ChargesList suggestion) {
                        return ListTile(
                          title: Text("${suggestion.chargeDesc}"),
                        );
                      },
                      onSuggestionSelected: (ChargesList suggestion) {
                        setState(() {
                          charge.text = suggestion.chargeDesc;
                        });
                      },
                    ),
                    const SizedBox(height: 10.0),
                    TextFormField(
                      validator: customValidator,
                      controller: amount,
                      decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder(), hintText: 'Amount'),
                    ),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      validator: customValidator,
                      controller: receipt,
                      decoration: const InputDecoration(labelText: 'Receipt No', border: OutlineInputBorder(), hintText: 'Receipt No'),
                    ),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      validator: customValidator,
                      controller: note,
                      decoration: const InputDecoration(labelText: 'Remarks', border: OutlineInputBorder(), hintText: 'Remarks'),
                    ),
                    const SizedBox(height: 12.0),
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      const Text('Add Receipt:', textAlign: TextAlign.start),
                      IconButton(
                          icon: SvgPicture.asset(
                            'icons/gallery_thumbnail.svg',
                            width: 35.0,
                            height: 35.0,
                            color: Colors.green.shade900,
                          ),
                          onPressed: () async {
                            final image = await _picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              final directory = await getApplicationDocumentsDirectory();
                              String imagePath = image.path;
                              String filename = path.basename(imagePath);
                              final tempPath = path.join(directory.path, filename);
                              final imageFile = File(image.path);
                              await imageFile.copy(tempPath);
                              String imageExtension = path.extension(tempPath).replaceAll('.', '');
                              final bytes = await imageFile.readAsBytes();
                              final base64Image = base64Encode(bytes);
                              String mimeType = 'application/$imageExtension';
                              var base64 = 'data:$mimeType;base64,$base64Image';
                              setState(() {
                                selectedImages!.add(File(imagePath));
                                attach.add(base64);
                              });
                            }
                          }),
                      IconButton(
                          onPressed: () async {
                            final image = await _picker.pickImage(source: ImageSource.camera);
                            if (image != null) {
                              final directory = await getApplicationDocumentsDirectory();
                              var imagePath = File(image.path);
                              String filename = path.basename(image.path);
                              final tempPath = path.join(directory.path, filename);
                              await imagePath.copy(tempPath);
                              String imageExtension = path.extension(tempPath).replaceAll('.', '');
                              final bytes = await imagePath.readAsBytes();
                              final base64Image = base64Encode(bytes);
                              String mimeType = 'application/$imageExtension';
                              var base64 = 'data:$mimeType;base64,$base64Image';
                              setState(() {
                                selectedImages!.add(imagePath);
                                attach.add(base64);
                              });
                            }
                          },
                          icon: Icon(Icons.camera_alt, color: Colors.red.shade900),
                          iconSize: 28.0),
                    ]),
                    selectedImages!.isNotEmpty
                        ? SizedBox(
                            height: 100,
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemCount: selectedImages!.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Image.file(selectedImages![index], fit: BoxFit.cover, width: 300, height: 300, alignment: Alignment.center),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Checkbox(
                                        value: true,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == false) {
                                              selectedImages!.removeAt(index);
                                              attach.removeAt(index);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          )
                        : const Align(
                            alignment: Alignment.center,
                            child: Text(
                              '',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            )),
                    const SizedBox(height: 20.0),
                    ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 222, 8, 8),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            )),
                        label: const Text('SUBMIT'),
                        icon: const Icon(Icons.save),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final remarks = {
                              'remarks': note.text,
                              // 'booking_id': widget.item['booking_id'],
                              // 'runsheet_id': widget.item['runsheet_id'],
                              'attachment': attach
                            };
                            await api.post(remarks, 'bookingRemarks').then((response) {
                              if (response['success'] == true) {
                                setState(() {
                                  note.clear();
                                  attach.clear();
                                  selectedImages!.clear();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    backgroundColor: Colors.green,
                                    content: Text('Created successfully'),
                                    behavior: SnackBarBehavior.fixed,
                                  ));
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text('Error on saving.'),
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                            });
                          }
                        }),
                  ]),
                ))));
  }

  String? customValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty.';
    }
    return null;
  }
}
