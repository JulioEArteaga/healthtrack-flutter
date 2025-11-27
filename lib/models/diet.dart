import 'package:cloud_firestore/cloud_firestore.dart';

class Diet {
  final String id;
  final String uid;
  final String name;
  final String description;
  final int calories;
  final DateTime date;

  Diet({
    required this.id,
    required this.uid,
    required this.name,
    required this.description,
    required this.calories,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'description': description,
      'calories': calories,
      'date': date, // se convierte a Timestamp en FirestoreService
    };
  }

  factory Diet.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'];

    return Diet(
      id: map['id'],
      uid: map['uid'],
      name: map['name'],
      description: map['description'],
      calories: map['calories'],
      date: rawDate is Timestamp ? rawDate.toDate() : rawDate as DateTime,
    );
  }
}
