import 'dart:async';
import '../models/announcement.dart';

abstract class AnnouncementRepository {
  Future<List<Announcement>> getAnnouncements();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> addAnnouncement(Announcement announcement);
  Stream<List<Announcement>> watchAnnouncements();
}

class MockAnnouncementRepository implements AnnouncementRepository {
  final List<Announcement> _announcements = [
    Announcement(
      id: '1',
      title: 'Mid-term Exam Schedule',
      message: 'Mid-term exam schedule has been released. Please check your student portal for specific dates and times.',
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: AnnouncementType.exam,
    ),
    Announcement(
      id: '2',
      title: 'Library Hours Extended',
      message: 'The library will be open 24/7 during exam week to support students.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: AnnouncementType.general,
    ),
    Announcement(
      id: '3',
      title: 'New Assignment Posted',
      message: 'A new assignment has been posted for Computer Graphics course.',
      date: DateTime.now().subtract(const Duration(days: 3)),
      type: AnnouncementType.assignment,
    ),
    Announcement(
      id: '4',
      title: 'Guest Lecture on AI',
      message: 'Join us for a special guest lecture on Artificial Intelligence in Education.',
      date: DateTime.now().subtract(const Duration(days: 4)),
      type: AnnouncementType.event,
    ),
  ];

  final StreamController<List<Announcement>> _controller = StreamController<List<Announcement>>.broadcast();

  void _emit() {
    _controller.add(List.from(_announcements));
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_announcements);
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _announcements.indexWhere((announcement) => announcement.id == id);
    if (index != -1) {
      _announcements[index] = _announcements[index].copyWith(isRead: true);
      _emit();
    }
  }

  @override
  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (int i = 0; i < _announcements.length; i++) {
      _announcements[i] = _announcements[i].copyWith(isRead: true);
    }
    _emit();
  }

  @override
  Future<void> addAnnouncement(Announcement announcement) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _announcements.insert(0, announcement); // Add to beginning of list
    _emit();
  }

  @override
  Stream<List<Announcement>> watchAnnouncements() async* {
    yield List.from(_announcements);
    yield* _controller.stream;
  }
}