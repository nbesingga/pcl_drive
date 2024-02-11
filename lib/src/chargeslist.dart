class ChargesList {
  final dynamic chargeCode;
  final dynamic chargeDesc;

  ChargesList({required this.chargeCode, required this.chargeDesc});

  factory ChargesList.fromJson(Map<String, dynamic> json) {
    return ChargesList(chargeCode: json['charge_code'] ?? '', chargeDesc: json['charge_desc'] ?? '');
  }
}
