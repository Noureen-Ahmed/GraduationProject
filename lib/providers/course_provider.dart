import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return MockCourseRepository();
});

final courseByIdProvider =
    FutureProvider.family<Course?, String>((ref, courseId) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getCourseById(courseId);
});
final coursesProvider = StreamProvider<List<Course>>((ref) {
  return ref.watch(courseRepositoryProvider).watchCourses();
});

final enrolledCoursesProvider = FutureProvider<List<Course>>((ref) {
  return ref.watch(courseRepositoryProvider).getEnrolledCourses();
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