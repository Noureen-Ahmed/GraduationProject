import '../models/schedule_event.dart';

abstract class ScheduleRepository {
  Future<List<ScheduleEvent>> getEvents();
  Future<List<ScheduleEvent>> getEventsForDate(DateTime date);
  Future<List<ScheduleEvent>> getUpcomingEvents({int days = 7});
  Future<ScheduleEvent?> getEventById(String id);
  Stream<List<ScheduleEvent>> watchEvents();
}

class MockScheduleRepository implements ScheduleRepository {
  final List<ScheduleEvent> _events = [
    // SATURDAY
    ScheduleEvent(
      id: 'sat-1',
      title: 'Mathematics III',
      startTime: _getRelativeDate(DateTime.saturday, 10),
      endTime: _getRelativeDate(DateTime.saturday, 12),
      location: 'Room 101',
      instructor: 'Dr. Alice',
      courseId: '1',
      description: 'Linear Algebra and Calculus',
    ),
    // SUNDAY
    ScheduleEvent(
      id: 'sun-1',
      title: 'Digital Logic Design',
      startTime: _getRelativeDate(DateTime.sunday, 9),
      endTime: _getRelativeDate(DateTime.sunday, 11),
      location: 'Lab 2',
      instructor: 'Prof. Bob',
      courseId: '2',
      description: 'Boolean Algebra and Gates',
    ),
    // MONDAY: Data Structures
    ScheduleEvent(
      id: 'mon-1',
      title: 'Data Structures Lecture',
      startTime: _getRelativeDate(DateTime.monday, 8, 30),
      endTime: _getRelativeDate(DateTime.monday, 10, 30),
      location: 'Hall A',
      instructor: 'Dr. Smith',
      courseId: '3',
      description: 'Binary Trees and Graph Algorithms',
    ),
    ScheduleEvent(
      id: 'mon-2',
      title: 'web Programming Lecture',
      startTime: _getRelativeDate(DateTime.monday, 13, 0),
      endTime: _getRelativeDate(DateTime.monday, 15, 0),
      location: 'Lab 2',
      instructor: 'Dr. Smith',
      courseId: '4',
      description: 'Web Programming',
    ),
    // TUESDAY: C++ Lab
    ScheduleEvent(
      id: 'tue-1',
      title: 'C++ Programming Lab',
      startTime: _getRelativeDate(DateTime.tuesday, 13, 0),
      endTime: _getRelativeDate(DateTime.tuesday, 15, 0),
      location: 'CS Lab 1',
      instructor: 'Eng. Sarah',
      courseId: '5',
      description: 'Object Oriented Programming in C++',
    ),
    ScheduleEvent(
      id: 'tue-2',
      title: 'Midterm Exam - Physics',
      startTime: _getRelativeDate(DateTime.tuesday, 9, 0),
      endTime: _getRelativeDate(DateTime.tuesday, 11, 0),
      location: 'Main Hall',
      instructor: 'Prof. Johnson',
      courseId: '6',
      description: 'Mechanics and Thermodynamics',
    ),
    // WEDNESDAY
    ScheduleEvent(
      id: 'wed-1',
      title: 'Database Systems',
      startTime: _getRelativeDate(DateTime.wednesday, 11, 0),
      endTime: _getRelativeDate(DateTime.wednesday, 13, 0),
      location: 'Room 302',
      instructor: 'Dr. Miller',
      courseId: '7',
      description: 'SQL and Normalization',
    ),
    // THURSDAY
    ScheduleEvent(
      id: 'thu-1',
      title: 'Algorithms Analysis',
      startTime: _getRelativeDate(DateTime.thursday, 10, 0),
      endTime: _getRelativeDate(DateTime.thursday, 12, 0),
      location: 'Room 205',
      instructor: 'Dr. Wilson',
      courseId: '8',
      description: 'Big O and Greedy Algorithms',
    ),
    ScheduleEvent(
      id: 'thu-2',
      title: 'Final Exam - Ethics',
      startTime: _getRelativeDate(DateTime.thursday, 14, 0),
      endTime: _getRelativeDate(DateTime.thursday, 16, 0),
      location: 'Exam Hall B',
      instructor: 'Dr. Green',
      description: 'Professional Ethics for Engineers',
    ),
    // DATA STRUCTURES EXAMS (Day 16 & 18)
    ScheduleEvent(
      id: 'ds-midterm',
      title: 'Data Structures Midterm Exam',
      startTime: DateTime(DateTime.now().year, DateTime.now().month, 21, 10, 0),
      endTime: DateTime(DateTime.now().year, DateTime.now().month, 21, 12, 0),
      location: 'Exam Hall C',
      instructor: 'Dr. Smith',
      courseId: '4',
      description: 'Midterm covering Trees and Graphs',
    ),
    ScheduleEvent(
      id: 'ds-final',
      title: 'Data Structures Final Exam',
      startTime: DateTime(DateTime.now().year, DateTime.now().month, 28, 14, 0),
      endTime: DateTime(DateTime.now().year, DateTime.now().month, 28, 17, 0),
      location: 'Exam Hall Arena',
      instructor: 'Dr. Smith',
      courseId: '4',
      description: 'Final comprehensive exam',
    ),
  ];

  static DateTime _getRelativeDate(int weekday, int hour, [int minute = 0]) {
    final now = DateTime.now();
    int diff = weekday - now.weekday;
    // We want the one in the current 7-day window
    final date = now.add(Duration(days: diff));
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  @override
  Future<List<ScheduleEvent>> getEvents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_events);
  }

  @override
  Future<List<ScheduleEvent>> getEventsForDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _events.where((event) {
      final eventDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return eventDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  @override
  Future<List<ScheduleEvent>> getUpcomingEvents({int days = 7}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));
    
    return _events.where((event) {
      return event.startTime.isAfter(now) && event.startTime.isBefore(endDate);
    }).toList();
  }

  @override
  Future<ScheduleEvent?> getEventById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _events.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<List<ScheduleEvent>> watchEvents() {
    return Stream.value(List.from(_events));
  }
}