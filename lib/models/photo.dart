import 'package:json_annotation/json_annotation.dart';

part 'photo.g.dart';

@JsonSerializable()
class Photo {
  final String id;
  @JsonKey(name: 'group_id')
  final String groupId;
  @JsonKey(name: 'uploaded_by')
  final String uploadedBy;
  @JsonKey(name: 'file_name')
  final String fileName;
  @JsonKey(name: 'file_path')
  final String filePath;
  @JsonKey(name: 'file_size')
  final int? fileSize;
  @JsonKey(name: 'mime_type')
  final String? mimeType;
  final String? caption;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'taken_at')
  final DateTime? takenAt;
  @JsonKey(name: 'uploaded_at')
  final DateTime uploadedAt;
  @JsonKey(name: 'is_deleted')
  final bool isDeleted;

  const Photo({
    required this.id,
    required this.groupId,
    required this.uploadedBy,
    required this.fileName,
    required this.filePath,
    this.fileSize,
    this.mimeType,
    this.caption,
    this.metadata,
    this.takenAt,
    required this.uploadedAt,
    this.isDeleted = false,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoToJson(this);

  Photo copyWith({
    String? id,
    String? groupId,
    String? uploadedBy,
    String? fileName,
    String? filePath,
    int? fileSize,
    String? mimeType,
    String? caption,
    Map<String, dynamic>? metadata,
    DateTime? takenAt,
    DateTime? uploadedAt,
    bool? isDeleted,
  }) {
    return Photo(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      caption: caption ?? this.caption,
      metadata: metadata ?? this.metadata,
      takenAt: takenAt ?? this.takenAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Photo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
