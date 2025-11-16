import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../models/photo.dart';

class PhotoService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String bucketName = 'photos';

  Map<String, List<Photo>> _photosByGroup = {};
  bool _isLoading = false;
  String? _error;
  double _uploadProgress = 0.0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  /// Get photos for a specific group
  List<Photo> getPhotosForGroup(String groupId) {
    return _photosByGroup[groupId] ?? [];
  }

  /// Upload a photo to a group
  Future<Photo?> uploadPhoto({
    required String groupId,
    required Uint8List imageBytes,
    required String fileName,
    String? caption,
    DateTime? takenAt,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      _uploadProgress = 0.0;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique file name
      final fileExtension = path.extension(fileName);
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$userId$fileExtension';
      final filePath = '$groupId/$uniqueFileName';

      // Get file size
      final fileSize = imageBytes.length;

      // Upload to Supabase storage
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              contentType: _getMimeType(fileExtension),
              upsert: false,
            ),
          );

      _uploadProgress = 1.0;
      notifyListeners();

      // Create photo metadata record
      // Store the relative path (without bucket name) for use with getPublicUrl
      final photoData = await _supabase.from('photos').insert({
        'group_id': groupId,
        'uploaded_by': userId,
        'file_name': uniqueFileName,
        'file_path': filePath,  // Use filePath, not storagePath
        'file_size': fileSize,
        'mime_type': _getMimeType(fileExtension),
        'caption': caption,
        'taken_at': takenAt?.toIso8601String(),
      }).select().single();

      final photo = Photo.fromJson(photoData);

      // Add to local cache
      if (_photosByGroup[groupId] == null) {
        _photosByGroup[groupId] = [];
      }
      _photosByGroup[groupId]!.insert(0, photo);

      return photo;
    } catch (e) {
      _error = 'Failed to upload photo: $e';
      return null;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Fetch photos for a specific group
  Future<void> fetchGroupPhotos(String groupId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('photos')
          .select()
          .eq('group_id', groupId)
          .eq('is_deleted', false)
          .order('uploaded_at', ascending: false);

      _photosByGroup[groupId] = (response as List)
          .map((json) => Photo.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'Failed to fetch photos: $e';
      _photosByGroup[groupId] = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get public URL for a photo
  String getPhotoUrl(Photo photo) {
    try {
      return _supabase.storage.from(bucketName).getPublicUrl(photo.filePath);
    } catch (e) {
      return '';
    }
  }

  /// Download photo to local device
  Future<Uint8List?> downloadPhoto(Photo photo) async {
    try {
      final bytes = await _supabase.storage
          .from(bucketName)
          .download(photo.filePath);
      return bytes;
    } catch (e) {
      _error = 'Failed to download photo: $e';
      notifyListeners();
      return null;
    }
  }

  /// Delete a photo (soft delete)
  Future<bool> deletePhoto(String photoId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabase
          .from('photos')
          .update({'is_deleted': true})
          .eq('id', photoId);

      // Remove from local cache
      for (var groupPhotos in _photosByGroup.values) {
        groupPhotos.removeWhere((p) => p.id == photoId);
      }

      return true;
    } catch (e) {
      _error = 'Failed to delete photo: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update photo caption
  Future<bool> updateCaption(String photoId, String caption) async {
    try {
      await _supabase
          .from('photos')
          .update({'caption': caption})
          .eq('id', photoId);

      // Update in local cache
      for (var groupPhotos in _photosByGroup.values) {
        final index = groupPhotos.indexWhere((p) => p.id == photoId);
        if (index != -1) {
          groupPhotos[index] = groupPhotos[index].copyWith(caption: caption);
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update caption: $e';
      return false;
    }
  }

  /// Helper to get MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear cached photos for a group
  void clearGroupPhotos(String groupId) {
    _photosByGroup.remove(groupId);
    notifyListeners();
  }
}
