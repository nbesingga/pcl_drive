import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

import 'package:pcl/src/api/api.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reactive_date_time_picker/reactive_date_time_picker.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class POD extends StatefulWidget {
  final item;
  const POD(this.item, {super.key});

  @override
  State<POD> createState() => _PODState();
}

class _PODState extends State<POD> with SingleTickerProviderStateMixin {
  final GlobalKey<SignatureState> _signatureKey = GlobalKey<SignatureState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Api api = Api();
  final scrollController = ScrollController();

  List<String> attachment = [];
  List<Map<String, dynamic>> attach = [];
  late Map<String, dynamic> monitor;
  List<Asset> images = <Asset>[];

  final ImagePicker _picker = ImagePicker();
  File? imageFile;
  List<File>? selectedImages = [];

  bool isSaving = false;
  List<Map<String, String>> _items = [];
  List<String> _selectedItems = [];

  initState() {
    super.initState();
    if (widget.item['document'] != null) {
      List<dynamic> documents = widget.item['document'];
      _items = documents.map((doc) => Map<String, String>.from(doc)).toList();
    }
  }

  @override
  FormGroup buildForm() => fb.group({
        'dateTime': FormControl<DateTime>(value: DateTime.now(), validators: [
          Validators.required
        ])
      });
  String? customValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty.';
    }
    return null;
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: false,
            // leading: IconButton(
            //   icon: const Icon(Icons.arrow_back_ios_new),
            //   onPressed: () {
            //     Navigator.of(context).pop();
            //   },
            // ),
            title: const Text('POD'),
            actions: [
              Padding(padding: const EdgeInsets.all(8.0), child: Align(alignment: Alignment.centerRight, child: Text(widget.item['booking_no'] ?? ''))),
            ]),
        body: (isSaving)
            ? const Center(
                child: SpinKitFadingCircle(
                color: Colors.orange,
                size: 50.0,
              ))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                  final TextEditingController note = TextEditingController();
                  final TextEditingController receiveBy = TextEditingController();

                  DateTime datetime = DateTime.now();
                  return ReactiveFormBuilder(
                      form: buildForm,
                      builder: (context, form, child) {
                        final datetime = form.control('dateTime');
                        return Form(
                            key: _formKey,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                              ReactiveDateTimePicker(
                                  formControlName: 'dateTime',
                                  type: ReactiveDatePickerFieldType.dateTime,
                                  decoration: const InputDecoration(
                                    labelText: 'Date & Time',
                                    hintText: 'hintText',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  datePickerEntryMode: DatePickerEntryMode.inputOnly,
                                  timePickerEntryMode: TimePickerEntryMode.inputOnly,
                                  selectableDayPredicate: (DateTime date) {
                                    final currentDate = DateTime.now();
                                    final twoDaysBefore = currentDate.subtract(const Duration(days: 2));
                                    return date.isAfter(twoDaysBefore) || date.isAtSameMomentAs(currentDate);
                                  }),
                              const SizedBox(height: 4.0),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const SizedBox(height: 8.0),
                                const Text('Add Signature', textAlign: TextAlign.start),
                                const SizedBox(height: 8.0),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 1.0,
                                    ),
                                  ),
                                  height: 100.0,
                                  child: Signature(key: _signatureKey, color: Colors.black, strokeWidth: 2.0),
                                ),
                                const SizedBox(height: 2.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    TextButton(
                                        child: const Text(
                                          'Clear Signature',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onPressed: () {
                                          _signatureKey.currentState!.clear();
                                        }),
                                  ],
                                ),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text('Add Attachment:', textAlign: TextAlign.start),
                                  // const SizedBox(width: 70.0),
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
                                            final files = {
                                              'file': base64,
                                            };

                                            setState(() {
                                              attach.add(files);
                                              selectedImages!.add(imagePath);
                                            });
                                          } else {
                                            throw Exception("Error compressing image");
                                          }
                                        }
                                      }),
                                  IconButton(
                                      onPressed: () async {
                                        final image = await _picker.pickImage(
                                          source: ImageSource.camera,
                                          imageQuality: 50, // This quality is used by the ImagePicker package
                                        );

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
                                            final files = {
                                              'file': base64,
                                            };

                                            setState(() {
                                              attach.add(files);
                                              selectedImages!.add(imagePath);
                                            });
                                          } else {
                                            throw Exception("Error compressing image");
                                          }
                                        }
                                      },
                                      icon: Icon(Icons.camera_alt, color: Colors.red.shade900),
                                      iconSize: 28.0),
                                ]),
                                const SizedBox(height: 8.0),
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
                                const SizedBox(height: 8.0),
                                const Text('Document Type'),
                                SingleChildScrollView(
                                    child: Container(
                                        height: 55.0 * _items.length,
                                        child: ListView.builder(
                                          itemCount: _items.length,
                                          itemBuilder: (context, index) {
                                            final item = _items[index];
                                            return CheckboxListTile(
                                              checkColor: Colors.white,
                                              activeColor: Colors.red,
                                              title: Text('${item['name']}'),
                                              value: _selectedItems.contains(item['code']),
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  if (value != null && value) {
                                                    _selectedItems.add(item['code'] ?? '');
                                                  } else {
                                                    _selectedItems.remove(item['code'] ?? '');
                                                  }
                                                });
                                              },
                                            );
                                          },
                                        ))),
                                const SizedBox(height: 8.0),
                                TextFormField(
                                  controller: receiveBy,
                                  validator: customValidator,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    labelText: 'Received By',
                                    suffixIcon: receiveBy.text != ''
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              receiveBy.clear();
                                            },
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                TextFormField(
                                  controller: note,
                                  decoration: const InputDecoration(labelText: 'Remarks', border: OutlineInputBorder()),
                                )
                              ]),
                              const Divider(thickness: 2.0, color: Colors.red),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  FilledButton.icon(
                                      icon: const Icon(Icons.close),
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all<Color>(Colors.orange.shade300),
                                      ),
                                      label: const Text('CANCEL', style: TextStyle(color: Colors.white)),
                                      onPressed: () {
                                        setState(() {
                                          Navigator.pop(context, true);
                                        });
                                      }),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  FilledButton.icon(
                                      icon: const Icon(Icons.update),
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all<Color>(Colors.red.shade900),
                                      ),
                                      label: const Text('UPDATE', overflow: TextOverflow.ellipsis),
                                      onPressed: isSaving
                                          ? null
                                          : () async {
                                              if (_formKey.currentState!.validate() && form.valid) {
                                                setState(() {
                                                  isSaving = true;
                                                });
                                                final DateTime date = datetime.value;
                                                final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
                                                widget.item['remarks'] = note.text;
                                                widget.item['receive_by'] = receiveBy.text;
                                                widget.item['datetime'] = dateFormat.format(date);
                                                widget.item['document'] = _selectedItems;
                                                await updateStatus(widget.item);
                                              }
                                            })
                                ],
                              ),
                            ]));
                      });
                })));
  }

  Future<void> updateStatus(data) async {
    DateTime now = DateTime.now();
    final dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final sign = _signatureKey.currentState;
    if (sign != null) {
      final image = await sign.getData();
      final imageBytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = await getApplicationDocumentsDirectory();
      final dateTimex = DateTime.now();
      final filename = '${dateTimex.microsecondsSinceEpoch}.png';
      final imagePath = path.join(directory.path, filename);
      final buffer = imageBytes!.buffer;
      await File(imagePath).writeAsBytes(buffer.asUint8List(imageBytes.offsetInBytes, imageBytes.lengthInBytes));
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);
      String mimeType = 'image/png';
      var base64 = 'data:$mimeType;base64,$base64Image';

      setState(() {
        final files = {
          'file': base64,
        };
        attach.add(files);
      });
    }
    final task = {
      'status_code': data['task_code'] ?? '',
      'receive_by': data['receive_by'] ?? '',
      'status_date': data['datetime'] ?? dateTime,
      'booking_no': data['booking_no'] ?? '',
      'batch_no': data['batch_no'] ?? '',
      'ticket_no': widget.item['ticket_no'],
      'remarks': data['remarks'] ?? '',
      'inserted_by': data['inserted_by'] ?? 0,
      'type_by': data['type_by'] ?? 0,
      'source': 'mobile',
      'document': _selectedItems,
      'attachment': attach
    };
    try {
      final result = await api.post(task, 'statusUpdate');
      if (result.statusCode == 200) {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Status Successfully Updated.'),
            behavior: SnackBarBehavior.floating,
          ));
          isSaving = false;
          // Navigator.of(context, task).pop();
          Navigator.pop(context, task);
        });
      } else {
        isSaving = false;
        throw Exception('Failed to update status');
      }
    } catch (e) {
      isSaving = false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(e.toString()),
        behavior: SnackBarBehavior.fixed,
      ));
    }
  }
}
