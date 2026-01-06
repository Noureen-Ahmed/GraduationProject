class ScheduleEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String instructor;
  final String? courseId;
  final String? description;

  ScheduleEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.instructor,
    this.courseId,
    this.description,
  });

  ScheduleEvent copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? instructor,
    String? courseId,
    String? description,
  }) {
    return ScheduleEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      instructor: instructor ?? this.instructor,
      courseId: courseId ?? this.courseId,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'instructor': instructor,
      'courseId': courseId,
      'description': description,
    };
  }

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    return ScheduleEvent(
      id: json['id'],
      title: json['title'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      location: json['location'],
      instructor: json['instructor'],
      courseId: json['courseId'],
      description: json['description'],
    );
  }
}