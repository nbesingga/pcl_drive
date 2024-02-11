class Trucker {
  final dynamic truckerName;
  final dynamic truckerId;

  Trucker({required this.truckerName, required this.truckerId});

  factory Trucker.fromJson(Map<String, dynamic> json) {
    return Trucker(truckerName: json['trucker_name'] ?? '', truckerId: json['trucker_id'] ?? '');
  }
}
