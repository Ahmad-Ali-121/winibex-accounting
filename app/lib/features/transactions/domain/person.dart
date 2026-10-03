/// Someone who can be named on an entry: who paid a cost personally, who
/// received money, who is being reimbursed.
class Person {
  const Person({required this.id, required this.name, required this.role});

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as int,
        name: json['name'] as String,
        role: json['role'] as String,
      );

  final int id;
  final String name;
  final String role;
}
