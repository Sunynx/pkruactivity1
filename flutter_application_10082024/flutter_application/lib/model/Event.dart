// lib/model/event.dart
class Event {

  final String key;
  final String name;
  final String detail;
  final String Class;
  final String location;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String imageUrl;
  final String activity_People;
  final String activit_Time;
  final String status;

  final String title;

  Event({
    required this.key,
    required this.name,
    required this.detail,
    required this.Class,
    required this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.imageUrl,
    required this.activity_People,
    required this.activit_Time,
    required this.status,

    required this.title,
  });

  get snapshot => null;
}
