import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:pcl/src/main/task/booking.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pcl/src/api/api.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({Key? key}) : super(key: key);

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  TabController? _tabController;
  Api api = Api();
  int _selectedTabIndex = 1;
  String plateNo = '';
  TextEditingController search = TextEditingController();
  String searchQuery = '';
  Size size = Size.zero;

  @override
  void initState() {
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _selectedTabIndex,
    );
    _tabController!.addListener(_handleTabSelection);
    getTrips();
    super.initState();
  }

  @override
  void dispose() {
    _tabController!.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    _selectedTabIndex = _tabController!.index;
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      search.clear();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    size = MediaQuery.of(context).size;
    if (size.width < 600) {
      _addScrollListener();
    }
  }

  void handleScroll() {
    if (size.width > 600) return;
  }

  void _addScrollListener() {
    _scrollController.addListener(handleScroll);
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
      return [];
    }
  }

  _refreshTrips() {
    setState(() {
      getTrips();
    });
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
          IconButton(
            onPressed: () => _refreshTrips(),
            icon: const Icon(Icons.refresh),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TabBar(
              onTap: (int) {
                setState(() {
                  _selectedTabIndex = int;
                });
              },
              indicator: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _selectedTabIndex > -1 ? Colors.red : Colors.transparent,
                    width: 1.0,
                  ),
                ),
              ),
              indicatorColor: Colors.black87,
              indicatorWeight: 1.0,
              controller: _tabController,
              labelColor: const Color.fromARGB(221, 233, 34, 34),
              dividerColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: "Previous", icon: Icon(Icons.history)),
                Tab(text: "Today", icon: Icon(Icons.calendar_today)),
              ],
            ),
            const SizedBox(height: 2.0),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  previousTab(),
                  todayTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleButtonPressed(BuildContext context, item) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPage(item),
      ),
    );
    if (res != null) {
      setState(() {
        getTrips();
      });
    }
  }

  Widget previousTab() {
    return FutureBuilder<List<dynamic>>(
      future: getTrips(),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitFadingCircle(
              color: Colors.orange,
              size: 50.0,
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return ListView.builder(
            controller: _scrollController,
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
                  onTap: () => _handleButtonPressed(context, item),
                  leading: SvgPicture.asset(
                    'assets/icons/transportation.svg',
                    width: 35.0,
                    height: 35.0,
                    color: Colors.orange.shade900,
                  ),
                  title: Text(
                    item['ticket_no'] ?? '',
                    style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticketDate,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return Center(
            child: Lottie.asset(
              "assets/animations/noresult.json",
              animate: true,
              alignment: Alignment.center,
              height: 150,
              width: 150,
            ),
          );
        }
      },
    );
  }

  Widget todayTab() {
    return FutureBuilder<List<dynamic>>(
      future: getTrips(),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitFadingCircle(
              color: Colors.orange,
              size: 50.0,
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return ListView.builder(
            controller: _scrollController,
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
                  onTap: () => _handleButtonPressed(context, item),
                  leading: SvgPicture.asset(
                    'assets/icons/transportation.svg',
                    width: 35.0,
                    height: 35.0,
                    color: Colors.orange.shade900,
                  ),
                  title: Text(
                    item['ticket_no'] ?? '',
                    style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticketDate,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return Center(
            child: Lottie.asset(
              "assets/animations/noresult.json",
              animate: true,
              alignment: Alignment.center,
              height: 150,
              width: 150,
            ),
          );
        }
      },
    );
  }
}
