// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Photo _$PhotoFromJson(Map<String, dynamic> json) => Photo(
  id: json['id'] as String,
  groupId: json['group_id'] as String,
  uploadedBy: json['uploaded_by'] as String,
  fileName: json['file_name'] as String,
  filePath: json['file_path'] as String,
  fileSize: (json['file_size'] as num?)?.toInt(),
  mimeType: json['mime_type'] as String?,
  caption: json['caption'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  takenAt: json['taken_at'] == null
      ? null
      : DateTime.parse(json['taken_at'] as String),
  uploadedAt: DateTime.parse(json['uploaded_at'] as String),
  isDeleted: json['is_deleted'] as bool? ?? false,
);

Map<String, dynamic> _$PhotoToJson(Photo instance) => <String, dynamic>{
  'id': instance.id,
  'group_id': instance.groupId,
  'uploaded_by': instance.uploadedBy,
  'file_name': instance.fileName,
  'file_path': instance.filePath,
  'file_size': instance.fileSize,
  'mime_type': instance.mimeType,
  'caption': instance.caption,
  'metadata': instance.metadata,
  'taken_at': instance.takenAt?.toIso8601String(),
  'uploaded_at': instance.uploadedAt.toIso8601String(),
  'is_deleted': instance.isDeleted,
};
