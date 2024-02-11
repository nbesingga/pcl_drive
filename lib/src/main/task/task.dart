import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:pcl/src/main/task/booking.dart';
import 'package:pcl/src/trip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pcl/src/api/api.dart';
import 'package:intl/intl.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  Api api = Api();
  int _selectedTabIndex = 1;
  String plateNo = '';
  TextEditingController search = TextEditingController();
  String searchQuery = '';
  @override
  void initState() {
    getTrips();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _selectedTabIndex,
    );
    _tabController!.addListener(_handleTabSelection);
    super.initState();
  }

  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      _selectedTabIndex = _tabController!.index;
    });
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      search.clear();
    });
  }

  Future<List<dynamic>> getTrips() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    if (userdata != null) {
      var user = json.decode(userdata);
      plateNo = user['plate_no'] ?? '';
    }
    final res = await api.getData('getTrip', params: {
      'plate_no': plateNo,
      'type': _selectedTabIndex
    });
    if (res.statusCode == 200) {
      var data = jsonDecode(res.body);
      List<dynamic> trip = List<dynamic>.from(data['data']);
      return trip;
    } else {
      throw Exception('Failed to load plate no');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'Tasks',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(padding: const EdgeInsets.all(8.0), child: Align(alignment: Alignment.centerRight, child: Text(plateNo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          ],
          automaticallyImplyLeading: false),
      body: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              controller: search,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(4.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(70.0),
                ),
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          _clearSearch();
                        })
                    : null,
              ),
            ),
            const SizedBox(height: 2.0),
            Expanded(
                child: TabBarView(controller: _tabController, children: [
              previousTab(),
              todayTab()
            ]))
          ])),
      bottomNavigationBar: BottomAppBar(
        elevation: 5.0,
        color: Colors.white,
        child: TabBar(
          onTap: (int) {
            setState(() {
              _selectedTabIndex = int;
            });
          },
          indicator: BoxDecoration(
            color: Colors.white30,
            borderRadius: BorderRadius.circular(10.0),
          ),
          indicatorColor: Colors.white10,
          indicatorWeight: 1.0,
          controller: _tabController,
          labelColor: Colors.red.shade900,
          dividerColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.event_repeat)),
            Tab(icon: Icon(Icons.today)),
          ],
        ),
      ),
      floatingActionButton: Container(
          margin: const EdgeInsets.only(bottom: 10.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
            FloatingActionButton(
                hoverColor: Colors.red,
                backgroundColor: const Color.fromARGB(255, 248, 51, 2),
                onPressed: () {
                  getTrips();
                },
                child: const Icon(Icons.refresh, size: 30.0))
          ])),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget previousTab() {
    return FutureBuilder<List<dynamic>>(
        future: getTrips(),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  DateTime dateFrom = DateTime.parse(item['ticket_date'] ?? '');
                  final ticketDate = DateFormat('MMM d,yyyy h:mm a').format(dateFrom);
                  return Card(
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      shadowColor: Colors.black,
                      elevation: 5,
                      child: ListTile(
                        selectedTileColor: Colors.red.shade100,
                        onTap: () {
                          setState(() {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => BookingPage(item)));
                          });
                        },
                        leading: SvgPicture.asset(
                          'icons/transportation.svg',
                          width: 35.0,
                          height: 35.0,
                          color: Colors.orange.shade900,
                        ),
                        title: Text(
                          item['ticket_no'] ?? '',
                          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            ticketDate,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(left: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (item['ticket_status'] == 'In-Progress') ? Colors.orange.shade200 : Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item['ticket_status'].toUpperCase() ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ));
                });
          } else {
            return const Center(
              child: Text('No Trip Found!'),
              //  Lottie.asset(
              //   "animations/noresult.json",
              //   animate: true,
              //   alignment: Alignment.center,
              //   height: 300,
              //   width: 300,
              // ),
            );
          }
        });
  }

  Widget todayTab() {
    return FutureBuilder<List<dynamic>>(
      future: getTrips(),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              DateTime dateFrom = DateTime.parse(item['ticket_date'] ?? '');
              final ticketDate = DateFormat('MMM d,yyyy').format(dateFrom);
              return Card(
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  shadowColor: Colors.black,
                  elevation: 5,
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => BookingPage(item)));
                      });
                    },
                    leading: SvgPicture.asset(
                      'icons/transportation.svg',
                      width: 35.0,
                      height: 35.0,
                      color: Colors.orange.shade900,
                    ),
                    title: Text(
                      item['ticket_no'] ?? '',
                      style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        ticketDate,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(left: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (item['ticket_status'] == 'In-Progress') ? Colors.orange.shade200 : Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['ticket_status'].toUpperCase() ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      ],
                    ),
                  ));
            },
          );
        } else {
          return const Center(
            child: Text('No Trip Found!'),
            //     Lottie.asset(
            //   "animations/noresult.json",
            //   animate: true,
            //   alignment: Alignment.center,
            //   height: 300,
            //   width: 300,
            // )
          );
        }
      },
    );
  }
}
