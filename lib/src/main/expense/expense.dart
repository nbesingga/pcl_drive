import 'package:flutter/material.dart';
import 'package:pcl/src/main/expense/add.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Expense',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          )),
      body: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(
          leading: Icon(Icons.sell, size: 30.0, color: Colors.grey),
          title: Text(
            'Expense No : ',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Date :',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        Divider(
          height: 2.0,
        )
      ]),
      floatingActionButton: Container(
          margin: const EdgeInsets.only(bottom: 10.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
            FloatingActionButton(
                hoverColor: Colors.green,
                backgroundColor: const Color.fromARGB(255, 248, 51, 2),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AddPage()));
                },
                child: const Icon(Icons.add, size: 30.0))
          ])),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
