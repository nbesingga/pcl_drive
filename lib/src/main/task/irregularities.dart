import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pcl/src/api/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IrregularityPage extends StatefulWidget {
  final item;
  const IrregularityPage(this.item, {Key? key}) : super(key: key);
  @override
  State<IrregularityPage> createState() => _IrregularityPageState();
}

class _IrregularityPageState extends State<IrregularityPage> {
  final Api api = Api();
  List data = [];
  String? selectedValue;
  final TextEditingController note = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool isSaving = false;

  final ImagePicker _picker = ImagePicker();
  List<File>? selectedImages = [];
  var attach = [];
  Map<String, dynamic> driver = {};

  @override
  void initState() {
    _simulateLoading();
    super.initState();
  }

  void _simulateLoading() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    if (userdata != "") {
      driver = json.decode(userdata!);
    }
  }

  setSelectedRadioTile(val) {
    setState(() {
      selectedValue = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Irregularities'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  widget.item['reference'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
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
                        Text('Please enter irregularities on your trip.', textAlign: TextAlign.start, style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 40.0),
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      const Text('Add Attachment:', textAlign: TextAlign.start),
                      IconButton(
                          icon: SvgPicture.asset(
                            'assets/icons/gallery_thumbnail.svg',
                            width: 35.0,
                            height: 35.0,
                            color: Colors.green.shade900,
                          ),
                          onPressed: () async {
                            final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                            if (image != null) {
                              final directory = await getApplicationDocumentsDirectory();
                              var imagePath = File(image.path);
                              String filename = path.basename(image.path);
                              final tempPath = path.join(directory.path, filename);

                              // Compress the image before saving
                              var compressedImage = await FlutterImageCompress.compressAndGetFile(
                                imagePath.absolute.path,
                                tempPath,
                                quality: 80, // Adjust quality for compression
                                minWidth: 800, // Adjust minWidth for resizing
                                minHeight: 800, // Adjust minHeight for resizing
                                autoCorrectionAngle: true, // Correct the image angle
                                format: CompressFormat.jpeg, // Set format to jpeg
                              );

                              if (compressedImage != null) {
                                final bytes = await compressedImage.readAsBytes();
                                final base64Image = base64Encode(bytes);
                                String imageExtension = path.extension(tempPath).replaceAll('.', '');
                                String mimeType = 'image/$imageExtension';
                                var base64 = 'data:$mimeType;base64,$base64Image';
                                setState(() {
                                  attach.add(base64);
                                  selectedImages!.add(imagePath);
                                });
                              } else {
                                throw Exception("Error compressing image");
                              }
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

                              // Compress the image before saving
                              var compressedImage = await FlutterImageCompress.compressAndGetFile(
                                imagePath.absolute.path,
                                tempPath,
                                quality: 80, // Adjust quality for compression
                                minWidth: 800, // Adjust minWidth for resizing
                                minHeight: 800, // Adjust minHeight for resizing
                                autoCorrectionAngle: true, // Correct the image angle
                                format: CompressFormat.jpeg, // Set format to jpeg
                              );

                              if (compressedImage != null) {
                                final bytes = await compressedImage.readAsBytes();
                                final base64Image = base64Encode(bytes);
                                String imageExtension = path.extension(tempPath).replaceAll('.', '');
                                String mimeType = 'image/$imageExtension';
                                var base64 = 'data:$mimeType;base64,$base64Image';
                                setState(() {
                                  selectedImages!.add(imagePath);
                                  attach.add(base64);
                                });
                              } else {
                                throw Exception("Error compressing image");
                              }
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
                    const SizedBox(height: 12.0),
                    TextFormField(
                      validator: customValidator,
                      controller: note,
                      decoration: const InputDecoration(labelText: 'Enter Remarks', border: OutlineInputBorder(), hintText: 'Enter Remarks'),
                    ),
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
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    isSaving = true;
                                  });
                                  final remarks = {
                                    'remarks': note.text,
                                    'booking_no': widget.item['booking_no'],
                                    'attachment': attach,
                                    'inserted_by': driver['driver_helper_id']
                                  };
                                  try {
                                    final response = await api.post(remarks, 'transportRemarks');
                                    print(jsonDecode(response.body));
                                    if (response.statusCode == 200) {
                                      setState(() {
                                        isSaving = false;
                                        note.clear();
                                        attach.clear();
                                        selectedImages!.clear();
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                          backgroundColor: Colors.green,
                                          content: Text('Remarks sent successfully'),
                                          behavior: SnackBarBehavior.fixed,
                                        ));
                                      });
                                    } else {
                                      isSaving = false;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        backgroundColor: Colors.red,
                                        content: Text('Remarks not sent.'),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    }
                                  } catch (e) {
                                    isSaving = false;
                                    print(e.toString());
                                  }
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
