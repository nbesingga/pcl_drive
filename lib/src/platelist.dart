class PlateList {
  final dynamic plateNo;
  final dynamic transType;
  final dynamic truckerId;

  PlateList({required this.plateNo, required this.transType, required this.truckerId});

  factory PlateList.fromJson(Map<String, dynamic> json) {
    return PlateList(plateNo: json['plate_no'] ?? '', transType: json['trans_type'] ?? '', truckerId: json['trucker_id'] ?? '');
  }
}
