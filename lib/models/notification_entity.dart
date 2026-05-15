import 'package:hive/hive.dart';

part 'notification_entity.g.dart';

@HiveType(typeId: 0)
class NotificationEntity extends HiveObject {
  @HiveField(0)
  late String notificationId;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String message;

  @HiveField(3)
  late String type;
  
  @HiveField(4)
  late DateTime timestamp;
  
  @HiveField(5)
  bool isRead = false;
  
  @HiveField(6)
  String? metadata;
}
