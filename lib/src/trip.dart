class Trip {
  final dynamic plateNo;
  final dynamic ticketNo;
  final dynamic truckerId;

  Trip({required this.plateNo, required this.ticketNo, required this.truckerId});

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(plateNo: json['plate_no'] ?? '', ticketNo: json['ticket_no'] ?? '', truckerId: json['trucker_id'] ?? '');
  }
}
