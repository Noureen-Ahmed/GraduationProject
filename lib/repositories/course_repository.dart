import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/course.dart';

abstract class CourseRepository {
  Future<List<Course>> getCourses();
  Future<Course?> getCourseById(String id);
  // These are user-centric, ideally handled by user provider + data manipulation, 
  // keeping them here for compatibility but implementation might vary.
  Future<void> enrollInCourse(String courseId);
  Future<void> removeFromWishlist(String courseId);
}

class MockCourseRepository implements CourseRepository {
  final List<Course> _courses = [
    Course(
      id: '1',
      code: 'COMP101',
      name: 'Introduction to Computer Science',
      category: CourseCategory.comp,
      creditHours: 4,
      professors: ['Dr. Smith'],
      description: 'An introductory course to computer science concepts including programming fundamentals, data structures, and algorithms.',
      schedule: [
        CourseSchedule(day: 'Monday', time: '10:00 AM - 11:30 AM', location: 'Room 204'),
        CourseSchedule(day: 'Wednesday', time: '10:00 AM - 11:30 AM', location: 'Room 204'),
        CourseSchedule(day: 'Friday', time: '10:00 AM - 11:30 AM', location: 'Lab 101'),
      ],
      content: [
        CourseContent(week: 1, topic: 'Introduction to Programming', description: 'Basic concepts of programming and problem-solving'),
        CourseContent(week: 2, topic: 'Variables and Data Types', description: 'Understanding variables, data types, and memory management'),
      ],
      assignments: [
        Assignment(
          id: '1',
          title: 'Hello World Program',
          dueDate: DateTime.now().add(const Duration(days: 7)),
          maxScore: 100,
          description: 'Write a simple program that displays "Hello, World!"',
        ),
      ],
      exams: [
        Exam(
          id: '1',
          title: 'Midterm Exam',
          date: DateTime.now().add(const Duration(days: 30)),
          format: 'Written and Practical',
          gradingBreakdown: 'Theory: 60%, Practical: 40%',
        ),
      ],
      enrollmentStatus: EnrollmentStatus.enrolled,
    ),
    Course(
      id: '2',
      code: 'MATH101',
      name: 'Calculus I',
      category: CourseCategory.math,
      creditHours: 4,
      professors: ['Dr. Brown'],
      description: 'An introductory course to calculus covering limits, derivatives, and integrals.',
      schedule: [
        CourseSchedule(day: 'Tuesday', time: '2:00 PM - 3:30 PM', location: 'Room 305'),
        CourseSchedule(day: 'Thursday', time: '2:00 PM - 3:30 PM', location: 'Room 305'),
      ],
      content: [
        CourseContent(week: 1, topic: 'Limits and Continuity', description: 'Understanding limits and continuity of functions'),
        CourseContent(week: 2, topic: 'Derivatives', description: 'Introduction to derivatives and differentiation rules'),
      ],
      assignments: [
        Assignment(
          id: '2',
          title: 'Derivative Problems Set',
          dueDate: DateTime.now().add(const Duration(days: 5)),
          maxScore: 50,
          description: 'Solve problems on differentiation',
        ),
      ],
      exams: [
        Exam(
          id: '2',
          title: 'Calculus Midterm',
          date: DateTime.now().add(const Duration(days: 28)),
          format: 'Written Exam',
          gradingBreakdown: 'Problem Solving: 70%, Theory: 30%',
        ),
      ],
      enrollmentStatus: EnrollmentStatus.enrolled,
    ),
    Course(
      id: '3',
      code: 'PHYS101',
      name: 'Physics I',
      category: CourseCategory.phys,
      creditHours: 4,
      professors: ['Prof. Johnson'],
      description: 'Mechanics and Thermodynamics covering motion, forces, energy, and heat.',
      schedule: [
        CourseSchedule(day: 'Monday', time: '2:00 PM - 3:30 PM', location: 'Room 201'),
        CourseSchedule(day: 'Wednesday', time: '2:00 PM - 3:30 PM', location: 'Room 201'),
        CourseSchedule(day: 'Friday', time: '2:00 PM - 4:00 PM', location: 'Lab 102'),
      ],
      content: [
        CourseContent(week: 1, topic: 'Kinematics', description: 'Study of motion without considering forces'),
        CourseContent(week: 2, topic: 'Newton\'s Laws', description: 'Forces and their effects on motion'),
      ],
      assignments: [
        Assignment(
          id: '3',
          title: 'Force Analysis Problems',
          dueDate: DateTime.now().add(const Duration(days: 6)),
          maxScore: 75,
          description: 'Analyze forces in various scenarios',
        ),
      ],
      exams: [
        Exam(
          id: '3',
          title: 'Physics Midterm',
          date: DateTime.now().add(const Duration(days: 32)),
          format: 'Written + Lab Practical',
          gradingBreakdown: 'Theory: 50%, Practical: 50%',
        ),
      ],
      enrollmentStatus: EnrollmentStatus.enrolled,
    ),
    Course(
      id: '4',
      code: 'COMP201',
      name: 'Data Structures',
      category: CourseCategory.comp,
      creditHours: 4,
      professors: ['Dr. Smith'],
      description: 'Advanced data structures including trees, graphs, and hash tables.',
      schedule: [
        CourseSchedule(day: 'Tuesday', time: '10:00 AM - 11:30 AM', location: 'Room 203'),
        CourseSchedule(day: 'Thursday', time: '10:00 AM - 11:30 AM', location: 'Room 203'),
      ],
      content: [
        CourseContent(week: 1, topic: 'Arrays and Linked Lists', description: 'Linear data structures'),
        CourseContent(week: 2, topic: 'Stacks and Queues', description: 'LIFO and FIFO data structures'),
      ],
      assignments: [
        Assignment(
          id: '4',
          title: 'Binary Tree Implementation',
          dueDate: DateTime.now().add(const Duration(days: 8)),
          maxScore: 100,
          description: 'Implement binary search tree with insert, delete, and search operations',
        ),
      ],
      exams: [
        Exam(
          id: '4',
          title: 'Data Structures Exam',
          date: DateTime.now().add(const Duration(days: 35)),
          format: 'Written + Coding',
          gradingBreakdown: 'Theory: 40%, Coding: 60%',
        ),
      ],
      enrollmentStatus: EnrollmentStatus.enrolled,
    ),
    Course(
      id: '5',
      code: 'SOFT302',
      name: 'Software Engineering',
      category: CourseCategory.comp,
      creditHours: 3,
      professors: ['Dr. Ahmed'],
      description: 'Principles of software development, modeling, and project management.',
      schedule: [
        CourseSchedule(day: 'Sunday', time: '12:00 PM - 1:30 PM', location: 'Hall A'),
      ],
      content: [],
      assignments: [],
      exams: [],
      enrollmentStatus: EnrollmentStatus.enrolled,
    ),
    Course(
      id: '6',
      code: 'AI101',
      name: 'Artificial Intelligence',
      category: CourseCategory.comp,
      creditHours: 3,
      professors: ['Dr. Noureen'],
      description: 'Introduction to AI, search algorithms, and machine learning basics.',
      schedule: [
        CourseSchedule(day: 'Wednesday', time: '1:00 PM - 2:30 PM', location: 'Lab 2'),
      ],
      content: [],
      assignments: [],
      exams: [],
      enrollmentStatus: EnrollmentStatus.enrolled,
    ),
  ];

  @override
  Future<List<Course>> getCourses() async {
    return _courses;
  }

  @override
  Future<Course?> getCourseById(String id) async {
    return _courses.firstWhere((c) => c.id == id, orElse: () => _courses.first);
  }

  @override
  Future<void> enrollInCourse(String courseId) async {}

  @override
  Future<void> removeFromWishlist(String courseId) async {}
}

class ApiCourseRepository implements CourseRepository {
  static const String _baseUrl = 'http://localhost:3000/api';

  @override
  Future<List<Course>> getCourses() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/courses'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['courses'];
        return list.map((json) {
           // Ensure enum names match
           return Course.fromJson(json);
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting courses: $e');
      return [];
    }
  }

  @override
  Future<Course?> getCourseById(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/courses/$id'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Course.fromJson(data['course']);
      }
      return null;
    } catch (e) {
      print('Error getting course by id: $e');
      return null;
    }
  }

  @override
  Future<void> enrollInCourse(String courseId) async {
    // This requires user context or an endpoint that knows the current user via token/session.
    // Since we don't have global auth header injection setup in a simple way here yet,
    // we might need to handle this in the provider or assume a specific endpoint.
    // For now, this is a placeholder or could throw.
    // But to avoid breaking the app, we'll do nothing.
    print('ApiCourseRepository.enrollInCourse: Not implemented at repo level, use UserProvider');
  }

  @override
  Future<void> removeFromWishlist(String courseId) async {
    print('ApiCourseRepository.removeFromWishlist: Not implemented at repo level');
  }
  
  Future<List<Course>> getEnrolledCourses() async {
      return []; // Logic moved to provider
  }

  Future<List<Course>> getWishlistCourses() async {
      return []; // Logic moved to provider
  }
    
  Stream<List<Course>> watchCourses() {
    // Fallback for stream providers if we don't switch to future provider immediately
    return Stream.fromFuture(getCourses()); 
  }
}