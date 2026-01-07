import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';
import 'app_session_provider.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return ApiCourseRepository();
});

final courseByIdProvider =
    FutureProvider.family<Course?, String>((ref, courseId) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getCourseById(courseId);
});

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  return ref.watch(courseRepositoryProvider).getCourses();
});

final enrolledCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final allCourses = await ref.watch(coursesProvider.future);
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.maybeWhen(
    data: (user) {
      if (user == null) return [];
      return allCourses.where((c) => user.enrolledCourses.contains(c.id)).toList();
    },
    orElse: () => [],
  );
});

final courseControllerProvider = StateNotifierProvider<CourseController, AsyncValue<void>>((ref) {
  final repository = ref.watch(courseRepositoryProvider);
  return CourseController(repository);
});

class CourseController extends StateNotifier<AsyncValue<void>> {
  final CourseRepository _repository;

  CourseController(this._repository) : super(const AsyncValue.data(null));

  Future<void> enrollInCourse(String courseId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.enrollInCourse(courseId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeFromWishlist(String courseId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeFromWishlist(courseId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final courseFilterProvider = StateProvider<CourseFilter>((ref) {
  return CourseFilter();
});

class CourseFilter {
  final EnrollmentStatus? enrollmentStatus;
  final CourseCategory? category;
  final String searchTerm;

  CourseFilter({
    this.enrollmentStatus,
    this.category,
    this.searchTerm = '',
  });

  CourseFilter copyWith({
    EnrollmentStatus? enrollmentStatus,
    CourseCategory? category,
    String? searchTerm,
  }) {
    return CourseFilter(
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
      category: category ?? this.category,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}