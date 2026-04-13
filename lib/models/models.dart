// lib/models/models.dart
import 'package:hive/hive.dart';

class UserModel {
  String id;
  String username;
  String passwordHash;

  UserModel({required this.id, required this.username, required this.passwordHash});
}

class PhotoModel {
  String id;
  String path;
  double latitude;
  double longitude;
  String name;
  String description;
  DateTime timestamp;
  String ownerId;
  bool isPublic;

  PhotoModel({
    required this.id,
    required this.path,
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.description,
    required this.timestamp,
    required this.ownerId,
    required this.isPublic,
  });
}

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final id = reader.readString();
    final username = reader.readString();
    final passwordHash = reader.readString();
    return UserModel(id: id, username: username, passwordHash: passwordHash);
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.username);
    writer.writeString(obj.passwordHash);
  }
}

class PhotoModelAdapter extends TypeAdapter<PhotoModel> {
  @override
  final int typeId = 1;

  @override
  PhotoModel read(BinaryReader reader) {
    final id = reader.readString();
    final path = reader.readString();
    final latitude = reader.readDouble();
    final longitude = reader.readDouble();
    final name = reader.readString();
    final description = reader.readString();
    final timestamp = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final ownerId = reader.readString();
    final isPublic = reader.readBool();
    return PhotoModel(
      id: id,
      path: path,
      latitude: latitude,
      longitude: longitude,
      name: name,
      description: description,
      timestamp: timestamp,
      ownerId: ownerId,
      isPublic: isPublic,
    );
  }

  @override
  void write(BinaryWriter writer, PhotoModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.path);
    writer.writeDouble(obj.latitude);
    writer.writeDouble(obj.longitude);
    writer.writeString(obj.name);
    writer.writeString(obj.description);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeString(obj.ownerId);
    writer.writeBool(obj.isPublic);
  }
}