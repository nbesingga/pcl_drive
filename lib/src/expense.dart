class Expense {
  final dynamic receiptNo;
  final dynamic chargeValue;
  final dynamic dutyDate;
  final dynamic status;

  Expense({required this.receiptNo, required this.chargeValue, required this.dutyDate, required this.status});

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(receiptNo: json['receipt_no'] ?? '', chargeValue: json['charge_value'] ?? '', dutyDate: json['duty_date'] ?? '', status: json['status'] ?? '');
  }
}
