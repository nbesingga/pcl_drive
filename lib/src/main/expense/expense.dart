import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pcl/src/main/expense/add.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pcl/src/api/api.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  TabController? _tabController;
  int _selectedExpenseTab = 0;
  Map<String, dynamic> driver = {};
  String plateNo = '';
  Api api = Api();
  Size size = Size.zero;
  String status = 'Pending';

  @override
  void initState() {
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _selectedExpenseTab,
    );
    _tabController!.addListener(_handleTabSelection);
    // getExpense();
    super.initState();
  }

  void _handleTabSelection() {
    _selectedExpenseTab = _tabController!.index;
  }

  @override
  void dispose() {
    _tabController!.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<List<dynamic>> getExpense() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    if (userdata != null) {
      var user = json.decode(userdata);
      plateNo = user['plate_no'] ?? '';
    }
    try {
      final res = await api.getData('getTripExpense', params: {
        'plate_no': plateNo,
        'status': status
      });
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        List<dynamic> expense = List<dynamic>.from(data).toList();
        return expense;
      } else {
        return throw Exception('Failed to load plate no');
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> _handleCreateButtonPressed(BuildContext context) async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPage()));
    if (res != null) {
      setState(() {
        getExpense();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text(
              'Expense',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(onPressed: () => _handleCreateButtonPressed(context), child: const Text('CREATE', style: TextStyle(color: Colors.white)))
            ]),
        body: Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              TabBar(
                onTap: (int) {
                  setState(() {
                    switch (int) {
                      case 1:
                        status = 'In-Review';
                        break;
                      case 2:
                        status = 'Approved';
                        break;
                      case 3:
                        status = 'Rejected';
                        break;
                      default:
                        status = 'Pending';
                        break;
                    }
                    _selectedExpenseTab = int;
                  });
                  getExpense();
                },
                indicator: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedExpenseTab > -1
                          ? Colors.red // Color for selected tab
                          : Colors.transparent, // No border for unselected tabs
                      width: 1.0, // Thickness of the bottom border
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
                  Tab(text: "Pending"),
                  Tab(text: "In Review"),
                  Tab(text: "Approved"),
                  Tab(text: "Rejected"),
                ],
              ),
              const SizedBox(height: 2.0),
              Expanded(child: TabBarView(controller: _tabController, children: List.generate(4, (index) => expenseList())))
            ])));
  }

  Widget expenseList() {
    return FutureBuilder<List<dynamic>>(
        future: getExpense(),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: SpinKitFadingCircle(
              color: Colors.orange,
              size: 50.0,
            ));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(4),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  DateTime dateFrom = DateTime.parse(item['duty_date'] ?? '');
                  final ticketDate = DateFormat('MMM d,yyyy').format(dateFrom);
                  final TextEditingController receiptNo = TextEditingController(text: item['receipt_no'] ?? "");
                  final TextEditingController chargeValue = TextEditingController(text: item['charge_value'] ?? "");
                  return Card(
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      shadowColor: Colors.black,
                      elevation: 5,
                      child: ListTile(
                        selectedTileColor: Colors.red.shade100,
                        onTap: () {},
                        // leading: Icon(Icons.currency_ruble, color: Colors.red.shade900),
                        title: Text(
                          item['charge_desc'] ?? '',
                          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            ticketDate,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: receiptNo,
                                    readOnly: true,
                                    decoration: const InputDecoration(labelText: 'RECEIPT NO.', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 10.0,
                              height: 10.0,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: chargeValue,
                                    readOnly: true,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(labelText: 'AMOUNT', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          ]),
                        ]),
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
                                item['status'] ?? 'Pending',
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
        });
  }
}
