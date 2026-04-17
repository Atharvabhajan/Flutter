class EmergencyContact {
  final String? id;
  final String name;
  final String phone;
  final String relation;
  final String? email;
  final int priority;

  EmergencyContact({
    this.id,
    required this.name,
    required this.phone,
    required this.relation,
    this.email,
    this.priority = 1,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relation: json['relation'] ?? 'Other',
      email: json['email'],
      priority: json['priority'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'relation': relation,
      'email': email,
      'priority': priority,
    };
  }
}
