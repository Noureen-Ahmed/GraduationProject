enum AnnouncementType { exam, assignment, general, event }

class Announcement {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final AnnouncementType type;
  final bool isRead;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
  });

  Announcement copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    AnnouncementType? type,
    bool? isRead,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
    };
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      date: DateTime.parse(json['date']),
      type: AnnouncementType.values.firstWhere((e) => e.name == json['type']),
      isRead: json['isRead'] ?? false,
    );
  }
}