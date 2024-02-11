import 'dart:async';
import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:timeline_tile/timeline_tile.dart';

class History extends StatefulWidget {
  final item;
  const History(this.item, {Key? key}) : super(key: key);
  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List events = [];
  bool isLoading = false;
  Future<List<dynamic>> logs() async {
    setState(() {
      isLoading = true;
    });
    final log = [];
    // await dbHelper.getAll('booking_logs',
    //     whereCondition: 'booking_id = ?',
    //     whereArgs: [
    //       widget.item['booking_id']
    //     ],
    //     orderBy: 'id DESC');
    events = log;
    setState(() {
      isLoading = false;
    });
    return events;
  }

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _initConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text("Status Logs"),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  widget.item['booking_no'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : FutureBuilder<List<dynamic>>(
                future: logs(),
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  if (events.isNotEmpty) {
                    return ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (context, int index) {
                          final history = events[index];
                          // final signature = history['signature'] ?? '';
                          int flag = history['flag'] ?? 0;
                          return TimelineTile(
                            alignment: TimelineAlign.manual,
                            lineXY: 0.1,
                            endChild: Container(
                              constraints: const BoxConstraints(
                                minHeight: 50,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Text(
                                      history['status_code'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          history['status_name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          history['status_date'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          history['note'],
                                          style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
                                        ),
                                        Text(
                                          (history['task_code'] == 'TDD') ? 'Receive By : ${history['receive_by'] ?? ''}' : '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // ),
                            ),
                            isFirst: false,
                            indicatorStyle: IndicatorStyle(
                              width: 40,
                              color: (flag == 1) ? Colors.green : Colors.blue,
                              padding: const EdgeInsets.all(8),
                              iconStyle: IconStyle(
                                color: Colors.white,
                                iconData: (flag == 1) ? Icons.check : Icons.sync,
                              ),
                            ),
                            beforeLineStyle: const LineStyle(color: Colors.red, thickness: 3),
                            afterLineStyle: const LineStyle(color: Colors.red, thickness: 3),
                          );
                        });
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  } else {
                    return const Center(child: Text('No logs found!'));
                  }
                }));
  }

  Future<void> _showSignature(BuildContext context, sign) async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
                child: sign != 'null'
                    ? Image.memory(
                        base64Decode(sign),
                        key: UniqueKey(),
                      )
                    : const Text('No Signature')),
          );
        });
  }
}
