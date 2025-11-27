import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String id;
  final String uid;
  final String title;
  final String description;
  final DateTime date;
  final bool completed;

  Goal({
    required this.id,
    required this.uid,
    required this.title,
    required this.description,
    required this.date,
    required this.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'title': title,
      'description': description,
      'completed': completed,
      'date': date, // FirestoreService lo convierte a Timestamp
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'];

    return Goal(
      id: map['id'],
      uid: map['uid'],
      title: map['title'],
      description: map['description'],
      completed: map['completed'] ?? false,
      date: rawDate is Timestamp ? rawDate.toDate() : rawDate as DateTime,
    );
  }
}
