import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

import 'package:pcl/src/api/api.dart';
import 'package:pcl/src/main/task/detail.dart';
import 'package:pcl/src/main/task/history.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reactive_date_time_picker/reactive_date_time_picker.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:connectivity/connectivity.dart';

class BookingPage extends StatefulWidget {
  final item;
  const BookingPage(this.item, {Key? key}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _selectedTabIndex = 0;

  final GlobalKey<SignatureState> _signatureKey = GlobalKey<SignatureState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final scrollController = ScrollController();
  Api api = Api();
  List<String> attachment = [];
  List<Map<String, dynamic>> attach = [];
  late Map<String, dynamic> monitor;
  List<Asset> images = <Asset>[];

  final ImagePicker _picker = ImagePicker();
  File? imageFile;
  List<File>? selectedImages = [];

  int monitor_id = 0;
  bool isSaving = false;
  bool start = false;
  int runsheet_id = 0;
  int page = 1;
  List<dynamic> items = [];
  String signature = "";
  TextEditingController start_remarks = TextEditingController();
  Map<String, dynamic> driver = {};

  Future<List<dynamic>> booking() async {
    final res = await api.getData('getBooking', params: {
      'ticket_id': widget.item['ticket_id'],
    });
    var rows = [];
    if (res.statusCode == 200) {
      var data = jsonDecode(res.body);
      rows = List<dynamic>.from(data['data']);
      items = rows.map((data) {
        int sequenceNo = data['sequence_no'] ?? 3;
        String nextStatus = '';
        int taskId;
        String taskCode = '';
        String task = 'PICKUP';
        int nextSequenceNo;
        String status = data['status'] ?? 'PAT';
        if (status == 'PAT' || status == 'PRE-ASSIGNED TRUCK') {
          nextStatus = 'ARRIVE AT PICKUP ADDRESS';
          taskId = 4;
          taskCode = 'APA';
          nextSequenceNo = 4;
          task = 'PICKUP';
        } else if (status == 'APA' || status == 'ARRIVE AT PICKUP ADDRESS') {
          nextStatus = 'START LOADING';
          taskId = 5;
          taskCode = 'STL';
          nextSequenceNo = sequenceNo + 1;
          task = 'PICKUP';
        } else if (status == 'STL' || status == 'START LOADING') {
          nextStatus = 'FINISH LOADING';
          taskId = 6;
          taskCode = 'FIL';
          nextSequenceNo = sequenceNo + 1;
          task = 'PICKUP';
        } else if (status == 'FIL' || status == 'FINISH LOADING') {
          nextStatus = 'TIME DEPARTURE AT PICKUP ADDR';
          taskId = 7;
          taskCode = 'TDP';
          nextSequenceNo = sequenceNo + 1;
          task = 'PICKUP';
        } else if (status == 'TDP' || status == 'TIME DEPARTURE AT PICKUP ADDR') {
          nextStatus = 'ARRIVE AT DELIVERY ADDRESS';
          taskId = 8;
          taskCode = 'ADA';
          nextSequenceNo = sequenceNo + 1;
          task = 'DELIVERY';
        } else if (status == 'ADA' || status == 'ARRIVE AT DELIVERY ADDRESS') {
          nextStatus = 'START UNLOADING';
          taskId = 9;
          taskCode = 'STU';
          nextSequenceNo = sequenceNo + 1;
          task = 'DELIVERY';
        } else if (status == 'STU' || status == 'START UNLOADING') {
          nextStatus = 'FINISH UNLOADING';
          taskId = 10;
          taskCode = 'FIU';
          nextSequenceNo = sequenceNo + 1;
          task = 'DELIVERY';
        } else if (status == 'FIU' || status == 'FINISH UNLOADING') {
          nextStatus = 'TIME DEPARTURE AT DELIVERY ADDR';
          taskId = 11;
          taskCode = 'TDD';
          nextSequenceNo = sequenceNo + 1;
          task = 'DELIVERY';
        } else if (status == 'TDD' || status == 'TIME DEPARTURE AT DELIVERY ADDR') {
          nextStatus = 'APPROVED TIME OUT';
          taskId = 12;
          taskCode = 'ATO';
          nextSequenceNo = sequenceNo + 1;
          task = 'DELIVERY';
        } else {
          nextStatus = data['status_name'];
          taskId = 2;
          taskCode = 'PAT';
          nextSequenceNo = 4;
        }
        return {
          ...data,
          'task': task,
          'status': status,
          'next_status': nextStatus,
          'task_id': taskId,
          'task_code': taskCode,
          'next_sequence_no': nextSequenceNo
        };
      }).toList();
      return items;
    } else {
      throw Exception('Failed to load plate no');
    }
  }

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }

  void _simulateLoading() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    if (userdata != "") {
      driver = json.decode(userdata!);
    }
  }

  @override
  void dispose() {
    _tabController!.removeListener(_handleTabSelection);
    _tabController?.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      _selectedTabIndex = _tabController!.index;
    });
  }

  @override
  void initState() {
    // booking();
    _simulateLoading();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabSelection);
    super.initState();
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
        title: Text(widget.item['ticket_no'] ?? ''),
        actions: [
          Padding(padding: const EdgeInsets.all(8.0), child: Align(alignment: Alignment.centerRight, child: Text(widget.item['plate_no'] ?? ''))),
        ],
      ),
      body: book(),
    );
  }

  Widget book() {
    return FutureBuilder<List<dynamic>>(
        future: booking(),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: snapshot.data!.length,
                controller: scrollController,
                itemBuilder: (context, int index) {
                  final item = snapshot.data![index];
                  DateTime estPick = DateTime.parse(item['pup_expected_date'] ?? '');
                  final pickupDtime = DateFormat('MMM d,yyyy h:mm a').format(estPick);
                  DateTime estDlv = DateTime.parse(item['dlv_expected_date'] ?? '');
                  final deliverTime = DateFormat('MMM d,yyyy h:mm a').format(estDlv);
                  return Padding(
                      padding: const EdgeInsets.all(4),
                      child: AbsorbPointer(
                        absorbing: false,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => BookingDetailPage(item)));
                          },
                          child: Card(
                            shadowColor: Colors.black,
                            elevation: 8,
                            child: Stack(
                              children: [
                                Container(
                                    padding: EdgeInsets.zero,
                                    child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                                      ListTile(
                                          title: Text(
                                            item['booking_no'] ?? '',
                                            style: TextStyle(color: Colors.red.shade900, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Status : " + (item['status_name'] ?? ''),
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => History(item)));
                                                  },
                                                  child: const Icon(
                                                    Icons.work_history,
                                                    color: Colors.blue,
                                                  )),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                  onTap: () {
                                                    // Navigator.push(context, MaterialPageRoute(builder: (context) => ExceptionPage(_pickup_items[index])));
                                                  },
                                                  child: const Icon(
                                                    Icons.info,
                                                    color: Colors.red,
                                                  )),
                                            ],
                                          )),
                                      const Divider(color: Colors.black, thickness: 1.0),
                                      ListTile(
                                        leading: const Icon(Icons.person_pin, size: 35.0, color: Colors.black),
                                        title: Text(
                                          item['customer'] ?? '',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['order_no'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            Text(
                                              item['booking_date'] ?? '',
                                              style: const TextStyle(fontSize: 11, overflow: TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(left: 5),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade900,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                item['trans_type'].toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      ListTile(
                                          leading: SvgPicture.asset(
                                            'icons/home_pin.svg',
                                            width: 35.0,
                                            height: 35.0,
                                            color: Colors.black,
                                          ),
                                          title: const Text(
                                            'PICK UP',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(
                                              pickupDtime,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red, overflow: TextOverflow.ellipsis),
                                            ),
                                            Text(
                                              item['pup_name'] ?? '',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                                            ),
                                            Text(
                                              item['pup_address'] ?? '',
                                              style: const TextStyle(fontSize: 11, overflow: TextOverflow.ellipsis),
                                            ),
                                          ])),
                                      ListTile(
                                          leading: SvgPicture.asset(
                                            'icons/home_location.svg',
                                            width: 35.0,
                                            height: 35.0,
                                            color: Colors.black,
                                          ),
                                          title: const Text(
                                            'DELIVERY',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(
                                              deliverTime,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red, overflow: TextOverflow.ellipsis),
                                            ),
                                            Text(
                                              item['dlv_name'] ?? '',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                                            ),
                                            Text(
                                              item['dlv_address'] ?? '',
                                              style: const TextStyle(fontSize: 11, overflow: TextOverflow.ellipsis),
                                            ),
                                          ])),
                                      ListTile(
                                          title: (item['status'] == 'TDD' || item['status'] == 'EOT' || item['status'] == 'FTD' || item['status'] == 'FTP')
                                              ? ((item['status'] == 'TDD')
                                                  ? const Center(
                                                      child: Text(
                                                      '*** DELIVERED SUCCESSFULLY ***',
                                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                                                    ))
                                                  : Center(
                                                      child: Text("*** ${item['status_name']} ***",
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.red,
                                                          ))))
                                              : ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                      backgroundColor: (item['task'] == 'DELIVERY') ? Colors.green.shade700 : Colors.blue.shade700,
                                                      minimumSize: const Size.fromHeight(35),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(20),
                                                      )),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Row(mainAxisSize: MainAxisSize.max, children: [
                                                      Text(item['next_status'] ?? ''),
                                                      const SizedBox(width: 8.0),
                                                    ]),
                                                  ),
                                                  onPressed: () {
                                                    _showDialog(context, item);
                                                  }))
                                    ])),
                              ],
                            ),
                          ),
                        ),
                      ));
                });
          } else {
            return const Center(child: Text('No Trip Found!'));
          }
        });
  }

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

  _showDialog(BuildContext context, data) async {
    final TextEditingController note = TextEditingController();
    final TextEditingController receiveBy = TextEditingController();

    DateTime datetime = DateTime.now();
    selectedImages = [];
    attach = [];
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                    return ReactiveFormBuilder(
                        form: buildForm,
                        builder: (context, form, child) {
                          final datetime = form.control('dateTime');
                          return Form(
                              key: _formKey,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                                const SizedBox(height: 8.0),
                                Container(
                                    child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(data['booking_no'] ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    const Divider(),
                                    const Text(
                                      "Please confirm status change to",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      data['next_status'] ?? '',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                    ),
                                  ],
                                )),
                                const SizedBox(height: 16.0),
                                ReactiveDateTimePicker(
                                    formControlName: 'dateTime',
                                    type: ReactiveDatePickerFieldType.dateTime,
                                    decoration: const InputDecoration(
                                      labelText: 'Date & Time',
                                      hintText: 'hintText',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    selectableDayPredicate: (DateTime date) {
                                      final currentDate = DateTime.now();
                                      final twoDaysBefore = currentDate.subtract(const Duration(days: 2));
                                      return date.isAfter(twoDaysBefore) || date.isAtSameMomentAs(currentDate);
                                    }),
                                const SizedBox(height: 4.0),
                                (data['task'] == 'DELIVERY' && data['task_code'] == 'TDD')
                                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                                          child: Signature(
                                            key: _signatureKey,
                                            color: Colors.black,
                                            strokeWidth: 2.0,
                                          ),
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

                                                  final files = {
                                                    'booking_no': data['booking_no'] ?? '',
                                                    'batch_no': data['batch_no'] ?? '',
                                                    'ticket_no': data['ticket_no'] ?? '',
                                                    'task_code': data['task_code'] ?? '',
                                                    'attach': filename
                                                  };
                                                  setState(() {
                                                    attach.add(files);
                                                    selectedImages!.add(File(imagePath));
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
                                                  final files = {
                                                    'booking_no': data['booking_no'] ?? '',
                                                    'batch_no': data['batch_no'] ?? '',
                                                    'ticket_no': data['ticket_no'] ?? '',
                                                    'task_code': data['task_code'] ?? '',
                                                    'attach': filename
                                                  };
                                                  setState(() {
                                                    attach.add(files);
                                                    selectedImages!.add(imagePath);
                                                  });
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
                                          validator: customValidator,
                                          decoration: const InputDecoration(labelText: 'Remarks', border: OutlineInputBorder()),
                                        ),
                                        const SizedBox(height: 16.0)
                                      ])
                                    : Container(),
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
                                            Navigator.of(context).pop();
                                          });
                                        }),
                                    const SizedBox(
                                      width: 2,
                                    ),
                                    FilledButton.icon(
                                      icon: const Icon(Icons.save),
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all<Color>(Colors.red.shade900),
                                      ),
                                      label: const Text('SAVE', overflow: TextOverflow.ellipsis),
                                      onPressed: () {
                                        if (_formKey.currentState!.validate() && form.valid) {
                                          final DateTime date = datetime.value;
                                          final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
                                          data['remarks'] = note.text;
                                          data['receive_by'] = receiveBy.text;
                                          data['datetime'] = dateFormat.format(date);
                                          updateStatus(data);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ]));
                        });
                  })));
        });
  }

  Future<void> errorDialog(BuildContext context, data) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning!', style: TextStyle(color: Colors.red)),
          content: Text("Booking ${data['reference'] ?? ''} is not yet PICK-UP, Unable to change status."),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateStatus(data) async {
    DateTime now = DateTime.now();
    final dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    List<Map<String, dynamic>> logs = [];

    final sign = _signatureKey.currentState;
    if (sign != null && sign.isNull == false) {
      final image = await sign.getData();
      final imageBytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = await getApplicationDocumentsDirectory();
      final dateTimex = DateTime.now();
      final filename = '${dateTimex.microsecondsSinceEpoch}.png';
      final imagePath = path.join(directory.path, filename);
      final buffer = imageBytes!.buffer;
      final file = await File(imagePath).writeAsBytes(buffer.asUint8List(imageBytes.offsetInBytes, imageBytes.lengthInBytes));

      final tempDirectory = await getTemporaryDirectory();
      final tempPath = path.join(tempDirectory.path, filename);
      await file.copy(tempPath);

      setState(() {
        final files = {
          'booking_no': data['booking_no'] ?? '',
          'status_code': data['task_code'] ?? '',
          'attach': filename
        };
        attach.add(files);
      });
    }
    // final book = {
    //   'status': data['task_code'] ?? '',
    //   'status_name': data['next_status'] ?? '',
    //   'sequence_no': data['next_sequence_no'] ?? '',
    //   'task': data[''] ?? ''
    // };
    // setState(() {
    //   // dbHelper.update('booking', book, data['id']);
    // });
    final task = {
      'status_code': data['task_code'] ?? '',
      'receive_by': data['receive_by'] ?? '',
      'status_date': data['datetime'] ?? dateTime,
      'booking_no': data['booking_no'] ?? '',
      'batch_no': data['batch_no'] ?? '',
      'remarks': data['note'] ?? '',
      'inserted_by': driver['id'] ?? 1,
      'type_by': driver['id'] ?? 1,
      'ticket_no': widget.item['ticket_no'],
    };
    print(task);
    try {
      final result = await api.post(task, 'statusUpdate');
      print(result);
      setState(() {
        if (result.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Status Successfully Updated.'),
            behavior: SnackBarBehavior.fixed,
          ));
          Navigator.of(context).pop();
          booking();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(e.toString()),
        behavior: SnackBarBehavior.fixed,
      ));
    }
  }
}
