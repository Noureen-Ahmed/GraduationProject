import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

enum AppMode { student, professor }

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    required String avatar,
    required String studentId,
    String? major,
    double? gpa,
    int? level,
    String? department,
    @Default([]) List<String> enrolledCourses,
    @Default(AppMode.student) AppMode mode,
    @Default(false) bool isOnboardingComplete,
    String? authToken,
    @Default(false) bool rememberMe,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}