import 'dart:async';
import 'dart:convert';
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
import 'package:pcl/src/main/task/irregularities.dart';
import 'package:pcl/src/main/task/pod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reactive_date_time_picker/reactive_date_time_picker.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
      return rows.map((data) {
        int sequenceNo = data['sequence_no'] ?? 3;
        String nextStatus = '';
        int taskId;
        String taskCode = '';
        String task = 'PICKUP';
        int nextSequenceNo;
        String status = data['status'] ?? 'PAT';
        if (status == 'PAT' || status == 'PRE-ASSIGNED TRUCK') {
          nextStatus = 'ACCEPT BOOKING';
          taskId = 3;
          taskCode = 'APA';
          nextSequenceNo = 3 + 1;
          task = 'PICKUP';
        } else if (status == 'ACPT' || status == 'ACCEPT BOOKING') {
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
    booking();
    _simulateLoading();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabSelection);
    super.initState();
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      booking();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context, true);
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
            return const Center(
                child: SpinKitFadingCircle(
              color: Colors.orange,
              size: 50.0,
            ));
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
                                                    color: Colors.green,
                                                  )),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => IrregularityPage(item)));
                                                  },
                                                  child: const Icon(
                                                    Icons.warning,
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
                                            Text(item['order_type'] + " : " + item['order_no'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red, overflow: TextOverflow.ellipsis)),
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
                                            'assets/icons/home_pin.svg',
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
                                            'assets/icons/home_location.svg',
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
                                              : (item['status'] == 'Assigned' || item['status'] == 'PAT' || item['status'] == 'BTT' || item['status'] == 'ATI')
                                                  ? Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      children: [
                                                        Expanded(
                                                            child: ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color.fromARGB(255, 222, 8, 8),
                                                              minimumSize: const Size.fromHeight(40),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(20),
                                                              )),
                                                          onPressed: () {
                                                            showDialog(
                                                                context: context,
                                                                barrierDismissible: false,
                                                                builder: (BuildContext context) {
                                                                  String reason = 'Mechanical error/ problem / Vehicle breakdown';
                                                                  List<String> options = <String>[
                                                                    "Mechanical error/ problem / Vehicle breakdown",
                                                                    "Trucker's and Contractor Negligence ( ex. Unreachable via cellphone , Late reporting to duty of trucker, Late provision of trips from the coordinator, Budget related concerns)",
                                                                    "Expired permits / Peza / Manila ",
                                                                    "No Available Driver / Helper (due to an Emergency situation that has to attend / Sicked Trucker / Cannot report to work)",
                                                                    "Coding Scheme",
                                                                    "Non Peza Registered ",
                                                                    "No Available truck based on the actual requirement.",
                                                                    "Not updated registration / Insurance policies",
                                                                    "With existing trips / Engaged to other customers",
                                                                    "With current reservations.",
                                                                  ];

                                                                  return AlertDialog(
                                                                    title: Text(item['booking_no'] ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                                                                    content: SizedBox(
                                                                        height: 95,
                                                                        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                                                                          const Text("Are you sure to decline this booking?", textAlign: TextAlign.center, style: TextStyle(color: Colors.black)),
                                                                          const SizedBox(height: 10),
                                                                          DropdownButtonFormField<String>(
                                                                            isExpanded: true,
                                                                            style: const TextStyle(overflow: TextOverflow.clip),
                                                                            value: reason,
                                                                            items: options.map((String value) {
                                                                              return DropdownMenuItem<String>(
                                                                                value: value,
                                                                                child: Text(value, style: const TextStyle(overflow: TextOverflow.clip, color: Colors.black)),
                                                                              );
                                                                            }).toList(),
                                                                            onChanged: (String? newValue) {
                                                                              setState(() {
                                                                                reason = newValue as String;
                                                                              });
                                                                            },
                                                                            decoration: const InputDecoration(
                                                                              labelText: 'Reason',
                                                                              border: OutlineInputBorder(),
                                                                            ),
                                                                          ),
                                                                        ])),
                                                                    actions: [
                                                                      FilledButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: const Color.fromARGB(255, 222, 8, 8),
                                                                        ),
                                                                        child: const Text('CANCEL'),
                                                                        onPressed: () {
                                                                          Navigator.of(context).pop();
                                                                        },
                                                                      ),
                                                                      FilledButton(
                                                                        child: const Text('CONFIRM'),
                                                                        onPressed: isSaving
                                                                            ? null
                                                                            : () async {
                                                                                setState(() {
                                                                                  Navigator.of(context).pop();
                                                                                  isSaving = true;
                                                                                });
                                                                                await updateStatus({
                                                                                  ...item,
                                                                                  'task_code': 'DCLN',
                                                                                  'next_status': 'DECLINED BOOKING',
                                                                                  'remarks': reason
                                                                                });
                                                                                setState(() {
                                                                                  isSaving = false;
                                                                                  booking();
                                                                                });
                                                                              },
                                                                      ),
                                                                    ],
                                                                  );
                                                                });
                                                          },
                                                          icon: const Icon(Icons.close),
                                                          label: const Text('DECLINE'),
                                                        )),
                                                        const SizedBox(width: 3),
                                                        Expanded(
                                                            child: ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.green.shade800,
                                                              minimumSize: const Size.fromHeight(40),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(20),
                                                              )),
                                                          onPressed: () {
                                                            showDialog(
                                                                context: context,
                                                                barrierDismissible: false,
                                                                builder: (BuildContext context) {
                                                                  return AlertDialog(
                                                                    title: Text(item['booking_no'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                                                                    content: const Text("Are you sure to accept this booking?", textAlign: TextAlign.center, style: TextStyle(color: Colors.black)),
                                                                    actions: [
                                                                      FilledButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: const Color.fromARGB(255, 222, 8, 8),
                                                                        ),
                                                                        child: const Text('CANCEL'),
                                                                        onPressed: () {
                                                                          Navigator.of(context).pop();
                                                                        },
                                                                      ),
                                                                      FilledButton(
                                                                        child: const Text('CONFIRM'),
                                                                        onPressed: isSaving
                                                                            ? null
                                                                            : () async {
                                                                                setState(() {
                                                                                  Navigator.of(context).pop();
                                                                                  isSaving = true;
                                                                                });
                                                                                await updateStatus({
                                                                                  ...item,
                                                                                  'task_code': 'ACPT',
                                                                                  'next_status': 'ACCEPT BOOKING'
                                                                                });
                                                                                setState(() {
                                                                                  isSaving = false;
                                                                                  booking();
                                                                                });
                                                                              },
                                                                      ),
                                                                    ],
                                                                  );
                                                                });
                                                          },
                                                          icon: const Icon(Icons.check),
                                                          label: const Text('ACCEPT'),
                                                        )),
                                                      ],
                                                    )
                                                  : item['status'] == 'DCLN'
                                                      ? const Center(
                                                          child: Text(
                                                          '*** BOOKING DECLINED ***',
                                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                                                        ))
                                                      : (item['status'] == 'FIU')
                                                          ? ElevatedButton(
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
                                                                item['inserted_by'] = driver['driver_helper_id'] ?? 0;
                                                                item['type_by'] = driver['driver_helper_id'] ?? 0;
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(builder: (context) => POD(item)),
                                                                ).then((podData) {
                                                                  if (podData != null) {
                                                                    setState(() {
                                                                      booking();
                                                                    });
                                                                  }
                                                                });
                                                              })
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
                                    datePickerEntryMode: DatePickerEntryMode.inputOnly,
                                    timePickerEntryMode: TimePickerEntryMode.inputOnly,
                                    selectableDayPredicate: (DateTime date) {
                                      final currentDate = DateTime.now();
                                      final twoDaysBefore = currentDate.subtract(const Duration(days: 2));
                                      return date.isAfter(twoDaysBefore) || date.isAtSameMomentAs(currentDate);
                                    }),
                                const SizedBox(height: 8.0),
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
                                                  data['datetime'] = dateFormat.format(date);
                                                  await updateStatus(data);
                                                  setState(() {
                                                    isSaving = false;
                                                    booking();
                                                    Navigator.of(context).pop();
                                                  });
                                                }
                                              })
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
    final task = {
      'status_code': data['task_code'] ?? '',
      'receive_by': '',
      'status_date': data['datetime'] ?? dateTime,
      'booking_no': data['booking_no'] ?? '',
      'batch_no': data['batch_no'] ?? '',
      'ticket_no': widget.item['ticket_no'],
      'remarks': '',
      'inserted_by': driver['driver_helper_id'] ?? 0,
      'type_by': driver['driver_helper_id'] ?? 0,
      'source': 'mobile',
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
        });
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(e.toString()),
        behavior: SnackBarBehavior.fixed,
      ));
    }
  }
}
