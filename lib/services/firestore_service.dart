import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/diet.dart';
import '../models/goal.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  // ---------------------------------------------------
  // DIETS
  // ---------------------------------------------------

  Future<void> addDiet(Diet diet) async {
    await _db.collection('diets').doc(diet.id).set({
      ...diet.toMap(),
      'uid': uid,
      'date': Timestamp.fromDate(diet.date),
    });
  }

  Stream<List<Diet>> getDiets() {
    return _db
        .collection('diets')
        .where('uid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        final rawDate = data['date'];
        final parsedDate =
            rawDate is Timestamp ? rawDate.toDate() : rawDate as DateTime;

        return Diet.fromMap({
          ...data,
          'date': parsedDate,
        });
      }).toList();
    });
  }

  Future<void> updateDiet(Diet diet) async {
    await _db.collection('diets').doc(diet.id).update({
      ...diet.toMap(),
      'uid': uid,
      'date': Timestamp.fromDate(diet.date),
    });
  }

  Future<void> deleteDiet(String id) async {
    await _db.collection('diets').doc(id).delete();
  }

  // ---------------------------------------------------
  // GOALS
  // ---------------------------------------------------

  Future<void> addGoal(Goal goal) async {
    await _db.collection('goals').doc(goal.id).set({
      ...goal.toMap(),
      'uid': uid,
      'date': Timestamp.fromDate(goal.date),
    });
  }

  Future<void> updateGoal(Goal goal) async {
    await _db.collection('goals').doc(goal.id).update({
      ...goal.toMap(),
      'uid': uid,
      'date': Timestamp.fromDate(goal.date),
    });
  }

  Future<void> deleteGoal(String id) async {
    await _db.collection('goals').doc(id).delete();
  }

  Future<void> toggleGoal(String id, bool status) async {
    await _db.collection('goals').doc(id).update({'completed': status});
  }

  Stream<List<Goal>> getGoals() {
    return _db
        .collection('goals')
        .where('uid', isEqualTo: uid)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        final rawDate = data['date'];
        final parsedDate =
            rawDate is Timestamp ? rawDate.toDate() : rawDate as DateTime;

        return Goal.fromMap({
          ...data,
          'date': parsedDate,
        });
      }).toList();
    });
  }

  // ---------------------------------------------------
  // CALENDAR EVENTS (SELECTED DAY)
  // ---------------------------------------------------

  Stream<List<Map<String, dynamic>>> getEventsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final dietsStream = _db
        .collection('diets')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data();
              final rawDate = data['date'];
              final parsedDate = rawDate is Timestamp
                  ? rawDate.toDate()
                  : rawDate as DateTime;

              return {
                'type': 'diet',
                'name': data['name'],
                'description': data['description'],
                'date': parsedDate,
                'completed': false,
              };
            }).toList());

    final goalsStream = _db
        .collection('goals')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data();
              final rawDate = data['date'];
              final parsedDate = rawDate is Timestamp
                  ? rawDate.toDate()
                  : rawDate as DateTime;

              return {
                'type': 'goal',
                'title': data['title'],
                'description': data['description'],
                'completed': data['completed'],
                'date': parsedDate,
              };
            }).toList());

    return Rx.combineLatest2(dietsStream, goalsStream,
        (diets, goals) => [...diets, ...goals]);
  }

  // ---------------------------------------------------
  // CALENDAR MARKERS (ALL EVENTS)
  // ---------------------------------------------------

  Stream<List<Map<String, dynamic>>> getAllEvents() {
    final dietsStream = _db
        .collection('diets')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        final rawDate = data['date'];
        final parsedDate =
            rawDate is Timestamp ? rawDate.toDate() : rawDate as DateTime;

        return {
          'type': 'diet',
          'name': data['name'],
          'description': data['description'],
          'date': parsedDate,
          'completed': false,
        };
      }).toList();
    });

    final goalsStream = _db
        .collection('goals')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        final rawDate = data['date'];
        final parsedDate =
            rawDate is Timestamp ? rawDate.toDate() : rawDate as DateTime;

        return {
          'type': 'goal',
          'title': data['title'],
          'description': data['description'],
          'completed': data['completed'],
          'date': parsedDate,
        };
      }).toList();
    });

    return Rx.combineLatest2(dietsStream, goalsStream,
        (diets, goals) => [...diets, ...goals]);
  }

  // ---------------------------------------------------
  // DASHBOARD COUNTERS
  // ---------------------------------------------------

  Future<int> countTodayDiets() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await _db
        .collection('diets')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    return snapshot.docs.length;
  }

  Future<int> countActiveGoals() async {
    final snapshot = await _db
        .collection('goals')
        .where('uid', isEqualTo: uid)
        .where('completed', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  Future<int> countCompletedGoals() async {
    final snapshot = await _db
        .collection('goals')
        .where('uid', isEqualTo: uid)
        .where('completed', isEqualTo: true)
        .get();

    return snapshot.docs.length;
  }
}
