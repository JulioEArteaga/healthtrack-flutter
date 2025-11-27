import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/firestore_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<DateTime, List<Map<String, dynamic>>> allEvents = {};

  @override
  void initState() {
    super.initState();
    _loadAllEvents();
  }

  void _loadAllEvents() {
    final firestore = FirestoreService();

    firestore.getAllEvents().listen((events) {
      if (!mounted) return;

      final Map<DateTime, List<Map<String, dynamic>>> mapped = {};

      for (final e in events) {
        final day = DateTime(
          e['date'].year,
          e['date'].month,
          e['date'].day,
        );

        mapped.putIfAbsent(day, () => []);
        mapped[day]!.add(e);
      }

      setState(() => allEvents = mapped);
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return allEvents[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// 🔥 OLA SUPERIOR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _TopWaveClipper(),
              child: Container(
                height: 210,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          /// 🔥 TÍTULO
          const Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Calendario',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          /// 🔥 OLA INFERIOR
          Positioned(
            bottom: -40,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _BottomWaveClipper(),
              child: Container(
                height: 160,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          /// 🔥 CONTENIDO
          Padding(
            padding: const EdgeInsets.only(top: 130),
            child: Column(
              children: [
                /// 📅 CALENDARIO
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    focusedDay: _focusedDay,
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    eventLoader: _getEventsForDay,
                    selectedDayPredicate: (day) =>
                        isSameDay(_selectedDay, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Color(0xFFB71C1C),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, rawEvents) {
                        if (rawEvents.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final events =
                            List<Map<String, dynamic>>.from(rawEvents);

                        final hasDiet =
                            events.any((e) => e['type'] == 'diet');
                        final hasGoalPending = events.any(
                          (e) =>
                              e['type'] == 'goal' &&
                              e['completed'] == false,
                        );
                        final hasGoalCompleted = events.any(
                          (e) =>
                              e['type'] == 'goal' &&
                              e['completed'] == true,
                        );

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasDiet) _dot(Colors.purple),
                            if (hasGoalPending) _dot(Colors.blue),
                            if (hasGoalCompleted) _dot(Colors.green),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// 📌 LISTA DE EVENTOS
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: firestore.getEventsForDay(_selectedDay),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFB71C1C),
                          ),
                        );
                      }

                      final events =
                          snapshot.data ?? <Map<String, dynamic>>[];

                      if (events.isEmpty) {
                        return const Center(
                          child: Text('No hay eventos en este día'),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final e = events[index];

                          return _eventTile(
                            icon: e['type'] == 'diet'
                                ? Icons.local_dining
                                : e['completed'] == true
                                    ? Icons.check_circle
                                    : Icons.flag,
                            color: e['type'] == 'diet'
                                ? Colors.purple
                                : e['completed'] == true
                                    ? Colors.green
                                    : Colors.blue,
                            title:
                                e['type'] == 'diet' ? e['name'] : e['title'],
                            subtitle: e['description'] ?? '',
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _eventTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}

/// 🌊 OLA SUPERIOR
class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

/// 🌊 OLA INFERIOR
class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 40);
    path.quadraticBezierTo(size.width / 2, 0, size.width, 60);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}
