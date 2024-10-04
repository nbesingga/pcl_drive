import 'package:flutter/material.dart';
import 'package:pcl/src/main/expense/expense.dart';
import 'package:pcl/src/main/profile/profile.dart';
import 'package:pcl/src/main/task/task.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final List<Widget> _pages = [
    const TaskPage(),
    const ExpensePage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageView(
          controller: _pageController,
          children: _pages,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
        bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(width: 1.0, color: Colors.red),
              ),
            ),
            child: SalomonBottomBar(
              selectedItemColor: Colors.red,
              unselectedItemColor: Colors.grey,
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  _pageController.animateToPage(
                    index,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.ease,
                  );
                });
              },
              items: [
                SalomonBottomBarItem(
                  icon: const Icon(Icons.assignment),
                  title: const Text('TASK'),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.receipt_long),
                  title: const Text('EXPENSE'),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.person),
                  title: const Text('ACCOUNT'),
                ),
              ],
            )));
  }
}
