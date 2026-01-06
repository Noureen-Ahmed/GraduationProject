import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement.dart';
import '../repositories/announcement_repository.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return MockAnnouncementRepository();
});

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  return ref.watch(announcementRepositoryProvider).watchAnnouncements();
});

final announcementControllerProvider = StateNotifierProvider<AnnouncementController, AsyncValue<void>>((ref) {
  final repository = ref.watch(announcementRepositoryProvider);
  return AnnouncementController(repository);
});

class AnnouncementController extends StateNotifier<AsyncValue<void>> {
  final AnnouncementRepository _repository;

  AnnouncementController(this._repository) : super(const AsyncValue.data(null));

  Future<void> markAsRead(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAsRead(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAllAsRead();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createAnnouncement(Announcement announcement) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addAnnouncement(announcement);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}