import 'dart:async';
import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:pcl/src/api/api.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class History extends StatefulWidget {
  final item;
  const History(this.item, {Key? key}) : super(key: key);
  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List events = [];
  Api api = Api();
  bool isLoading = false;
  Future<List<dynamic>> logs() async {
    setState(() {
      isLoading = true;
    });
    final res = await api.getData('statusHistory', params: {
      'booking_no': widget.item['booking_no'] ?? '',
      'batch_no': widget.item['batch_no'] ?? '',
      'group': 4,
    });
    if (res.statusCode == 200) {
      var data = jsonDecode(res.body);
      return List<dynamic>.from(data['data']);
    } else {
      throw Exception('Failed to load logs');
    }
  }

  @override
  void initState() {
    logs();
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
        body: FutureBuilder<List<dynamic>>(
            future: logs(),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: SpinKitFadingCircle(
                  color: Colors.orange,
                  size: 50.0,
                ));
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, int index) {
                      final history = snapshot.data![index];
                      // final signature = history['signature'] ?? '';
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
                                      history['status_desc'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      history['status_date'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: Colors.red),
                                    ),
                                    Text(
                                      history['remarks'] ?? '',
                                      style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
                                    ),
                                    Text(
                                      (history['status_code'] == 'TDD') ? 'Receive By : ${history['received_by'] ?? ''}' : '',
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
                          color: Colors.green,
                          padding: const EdgeInsets.all(8),
                          iconStyle: IconStyle(color: Colors.white, iconData: Icons.check),
                        ),
                        beforeLineStyle: const LineStyle(color: Colors.grey, thickness: 1),
                        afterLineStyle: const LineStyle(color: Colors.grey, thickness: 1),
                      );
                    });
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              } else {
                return Center(
                    child: Lottie.asset(
                  "assets/animations/noresult.json",
                  animate: true,
                  alignment: Alignment.center,
                  height: 150,
                  width: 150,
                ));
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
