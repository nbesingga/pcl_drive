import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage('assets/images/flutter_logo.png'),
              ),
              title: Text(
                'Driver Name',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Driver ID: ABC123',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Delivery Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ongoing Delivery',
                    style: TextStyle(fontSize: 16),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle button press (e.g., mark delivery as completed)
                    },
                    child: const Text('Mark Completed'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // List of Upcoming Deliveries
            const Text(
              'Upcoming Deliveries',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 3, // Replace with the actual number of upcoming deliveries
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Delivery #$index'),
                    subtitle: const Text('Scheduled for 2:00 PM'),
                    onTap: () {
                      // Navigate to delivery details page
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => DeliveryDetailsPage()));
                      // Replace 'DeliveryDetailsPage()' with the actual page for delivery details
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
