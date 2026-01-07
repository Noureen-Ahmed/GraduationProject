import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule_event.dart';
import '../repositories/schedule_repository.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ApiScheduleRepository();
});

final scheduleEventsProvider = FutureProvider<List<ScheduleEvent>>((ref) {
  return ref.watch(scheduleRepositoryProvider).getEvents();
});

final upcomingEventsProvider = FutureProvider<List<ScheduleEvent>>((ref) {
  return ref.watch(scheduleRepositoryProvider).getUpcomingEvents();
});

final eventsForDateProvider = FutureProvider.family<List<ScheduleEvent>, DateTime>((ref, date) {
  return ref.watch(scheduleRepositoryProvider).getEventsForDate(date);
});