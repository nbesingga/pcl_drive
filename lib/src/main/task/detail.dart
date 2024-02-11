import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BookingDetailPage extends StatefulWidget {
  final item;
  const BookingDetailPage(this.item, {Key? key}) : super(key: key);
  @override
  _BookingDetailState createState() => _BookingDetailState();
}

class _BookingDetailState extends State<BookingDetailPage> {
  @override
  void initState() {
    super.initState();
    _initConnectivity();
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
    final String reference = widget.item['booking_no'] ?? '';
    final String orderNo = widget.item['order_no'] ?? '';
    final String pickupAddress = widget.item['pup_address'] ?? '';
    final String deliveryAddress = widget.item['dlv_address'] ?? '';
    final String task = widget.item['task'] ?? '';
    final String customer = widget.item['customer'] ?? '';
    final String remarks = widget.item['remarks'] ?? '';
    final String pickupName = widget.item['pup_name'] ?? '';
    final String deliveryName = widget.item['dlv_name'] ?? '';
    final totalCbm = widget.item['cbm'] ?? '';
    final totalQty = widget.item['quantity'] ?? '';
    final totalWt = widget.item['weight'] ?? '';
    final TextEditingController itemCbm = TextEditingController(text: widget.item['cbm'].toString());
    final TextEditingController itemWeight = TextEditingController(text: widget.item['quantity'].toString());
    final TextEditingController itemQty = TextEditingController(text: widget.item['weight'].toString());
    final String tripType = widget.item['trans_type'] ?? '';

    DateTime estPick = DateTime.parse(widget.item['pup_expected_date'] ?? '');
    final pickupDtime = DateFormat('MMM d,yyyy h:mm a').format(estPick);
    DateTime estDlv = DateTime.parse(widget.item['dlv_expected_date'] ?? '');
    final deliverDtime = DateFormat('MMM d,yyyy h:mm a').format(estDlv);
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.numbers, size: 35.0, color: Colors.black),
                  title: const Text(
                    'Reference',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reference, style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(orderNo, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
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
                          tripType.toUpperCase(),
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
                  leading: const Icon(Icons.person, size: 35.0, color: Colors.black),
                  title: const Text(
                    'CUSTOMER',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  // trailing: Text('May 1, 2023'),
                ),
                ListTile(
                    leading: SvgPicture.asset('icons/home_pin.svg', width: 35.0, height: 35.0, color: Colors.black),
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
                        pickupName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        pickupAddress,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ])),
                ListTile(
                    leading: SvgPicture.asset('icons/home_location.svg', width: 35.0, height: 35.0, color: Colors.black),
                    title: const Text(
                      'DELIVERY',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        deliverDtime,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red, overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        deliveryName,
                        style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        deliveryAddress,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      )
                    ])),
                ListTile(
                    leading: SvgPicture.asset('icons/package.svg', width: 35.0, height: 35.0, color: Colors.black),
                    title: const Text(
                      'ITEM DETAILS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: itemQty,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Qty',
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: itemCbm,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'CBM',
                                  ),
                                  style: const TextStyle(fontSize: 11),
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
                                  controller: itemWeight,
                                  readOnly: true,
                                  keyboardType: TextInputType.text,
                                  decoration: const InputDecoration(
                                    labelText: 'WT',
                                  ),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ],
                    )),
                const Divider(),
                ListTile(
                    leading: const Icon(Icons.description, size: 35.0, color: Colors.black),
                    title: const Text(
                      'Remarks / Special Instruction',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(remarks, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red))),
              ],
            ))
          ],
        ),
      ),
    );
  }
}
