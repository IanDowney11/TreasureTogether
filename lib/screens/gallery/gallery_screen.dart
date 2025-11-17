import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import '../../models/group.dart';
import '../../models/photo.dart';
import '../../services/auth_service.dart';
import '../../services/photo_service.dart';
import '../../services/group_service.dart';
import '../../services/preferences_service.dart';

class GalleryScreen extends StatefulWidget {
  final Group group;

  const GalleryScreen({super.key, required this.group});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Fetch photos when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotoService>().fetchGroupPhotos(widget.group.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showGroupInfo,
            tooltip: 'Share invite code',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'info') {
                _showGroupInfo();
              } else if (value == 'members') {
                _showGroupMembers();
              } else if (value == 'leave') {
                _showLeaveEventDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 12),
                    Text('Group Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    Icon(Icons.people_outline),
                    SizedBox(width: 12),
                    Text('View Members'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Leave Event', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<PhotoService>(
        builder: (context, photoService, _) {
          if (photoService.isLoading &&
              photoService.getPhotosForGroup(widget.group.id).isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (photoService.error != null &&
              photoService.getPhotosForGroup(widget.group.id).isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(photoService.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => photoService.fetchGroupPhotos(widget.group.id),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final photos = photoService.getPhotosForGroup(widget.group.id);

          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined,
                       size: 120,
                       color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  const SizedBox(height: 24),
                  Text(
                    'No photos yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start capturing memories!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showUploadOptions(),
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Upload Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => photoService.fetchGroupPhotos(widget.group.id),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap any photo to view • Edit or delete your own photos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return _PhotoThumbnail(
                        photo: photo,
                        onTap: () => _showPhotoViewer(photos, index),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadOptions,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;

      // Show upload dialog
      _showUploadDialog(image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showUploadDialog(XFile imageFile) {
    final captionController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FutureBuilder<Uint8List>(
        future: imageFile.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          final imageBytes = snapshot.data!;

          return AlertDialog(
            title: const Text('Upload Photo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            TextField(
              controller: captionController,
              decoration: const InputDecoration(
                labelText: 'Caption (optional)',
                hintText: 'Add a caption...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Get PhotoService reference BEFORE popping the dialog
              final photoService = context.read<PhotoService>();
              final navigator = Navigator.of(context);

              navigator.pop();

              final photo = await photoService.uploadPhoto(
                groupId: widget.group.id,
                imageBytes: imageBytes,
                fileName: imageFile.name,
                caption: captionController.text.trim().isEmpty
                    ? null
                    : captionController.text.trim(),
              );

              // Only show snackbar if widget is still mounted
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      photo != null
                          ? 'Photo uploaded successfully!'
                          : photoService.error ?? 'Failed to upload photo',
                    ),
                    backgroundColor: photo != null ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Upload'),
          ),
        ],
      );
        },
      ),
    );
  }

  void _showPhotoViewer(List<Photo> photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _showGroupInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.group.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.group.description != null) ...[
              const Text('Description:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.group.description!),
              const SizedBox(height: 16),
            ],
            const Text('Invite Code:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.group.inviteCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.group.inviteCode),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invite code copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy code',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Share this code with others to invite them',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showGroupMembers() {
    final groupService = context.read<GroupService>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.group.name} Members'),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: groupService.getGroupMembersWithProfiles(widget.group.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Text('Failed to load members'),
                ),
              );
            }

            final members = snapshot.data!;

            if (members.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Text('No members found'),
                ),
              );
            }

            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final profile = member['profiles'] as Map<String, dynamic>?;
                  final displayName = profile?['display_name'] as String?;
                  final email = profile?['email'] as String? ?? 'Unknown';
                  final role = member['role'] as String? ?? 'member';

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (displayName ?? email).substring(0, 1).toUpperCase(),
                      ),
                    ),
                    title: Text(displayName ?? email),
                    subtitle: Text(displayName != null ? email : null ?? ''),
                    trailing: role == 'admin'
                        ? Chip(
                            label: const Text('Admin'),
                            backgroundColor: Colors.blue.shade100,
                          )
                        : null,
                  );
                },
              ),
            );
          },
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLeaveEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Event'),
        content: Text(
          'Are you sure you want to leave "${widget.group.name}"? You will need a new invite code to rejoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final groupService = context.read<GroupService>();
              final prefsService = context.read<PreferencesService>();
              final navigator = Navigator.of(context);

              // Close dialog
              navigator.pop();

              final success = await groupService.leaveGroup(widget.group.id);

              if (context.mounted) {
                if (success) {
                  // If this was the default event, clear it
                  if (prefsService.defaultEventId == widget.group.id) {
                    await prefsService.clearDefaultEvent();
                  }

                  // Go back to previous screen
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Left event successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        groupService.error ?? 'Failed to leave event',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;

  const _PhotoThumbnail({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photoService = context.read<PhotoService>();
    final url = photoService.getPhotoUrl(photo);

    return GestureDetector(
      onTap: onTap,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      ),
    );
  }
}

class PhotoViewerScreen extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  Map<String, bool> _favoritesCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final photoService = context.read<PhotoService>();
    for (var photo in widget.photos) {
      final isFav = await photoService.isFavorited(photo.id);
      _favoritesCache[photo.id] = isFav;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];
    final photoService = context.read<PhotoService>();
    final authService = context.read<AuthService>();
    final currentUserId = authService.currentUser?.id;
    final isOwner = currentUserId != null && photo.uploadedBy == currentUserId;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadPhoto(context, photo),
            tooltip: 'Download photo',
          ),
          IconButton(
            icon: Icon(
              _favoritesCache[photo.id] == true
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
            color: _favoritesCache[photo.id] == true ? Colors.red : null,
            onPressed: () => _toggleFavorite(photo),
            tooltip: _favoritesCache[photo.id] == true
                ? 'Remove from favorites'
                : 'Add to favorites',
          ),
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editCaption(context, photo),
              tooltip: 'Edit caption',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deletePhoto(context, photo),
              tooltip: 'Delete photo',
            ),
          ],
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          final url = photoService.getPhotoUrl(photo);

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error, color: Colors.white),
                    ),
                  ),
                ),
              ),
              if (photo.caption != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.black87,
                  child: Text(
                    photo.caption!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _editCaption(BuildContext context, Photo photo) {
    final captionController = TextEditingController(text: photo.caption ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: captionController,
          decoration: const InputDecoration(
            labelText: 'Caption',
            hintText: 'Add a caption...',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final photoService = context.read<PhotoService>();
              final navigator = Navigator.of(context);

              navigator.pop();

              final success = await photoService.updateCaption(
                photo.id,
                captionController.text.trim(),
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Caption updated successfully!'
                          : photoService.error ?? 'Failed to update caption',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );

                if (success) {
                  // Update the local photo object
                  setState(() {
                    // The photo list will be updated by the service
                  });
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(Photo photo) async {
    final photoService = context.read<PhotoService>();
    final isFavorited = _favoritesCache[photo.id] == true;

    bool success;
    if (isFavorited) {
      success = await photoService.removeFromFavorites(photo.id);
    } else {
      success = await photoService.addToFavorites(photo.id);
    }

    if (success) {
      setState(() {
        _favoritesCache[photo.id] = !isFavorited;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorited
                  ? 'Removed from favorites'
                  : 'Added to favorites',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            photoService.error ?? 'Failed to update favorites',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadPhoto(BuildContext context, Photo photo) async {
    try {
      final photoService = context.read<PhotoService>();
      final url = photoService.getPhotoUrl(photo);

      if (kIsWeb) {
        // For web, copy URL to clipboard (dart:html causes build issues on mobile)
        await Clipboard.setData(ClipboardData(text: url));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo URL copied! Open in new tab to download.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        // For mobile, download and save to gallery
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloading...'),
            duration: Duration(seconds: 2),
          ),
        );

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await Gal.putImageBytes(response.bodyBytes);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo saved to gallery!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to download photo'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deletePhoto(BuildContext context, Photo photo) {
    // Capture the outer navigator context before showing dialogs
    final outerNavigator = Navigator.of(context);
    final photoService = context.read<PhotoService>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text(
          'This photo will be permanently deleted and cannot be recovered. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close confirmation dialog using dialog context
              Navigator.of(dialogContext).pop();

              // Show deleting progress using outer context
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (progressContext) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text('Deleting photo...'),
                    ],
                  ),
                ),
              );

              final success = await photoService.deletePhoto(photo.id);

              // Use outer navigator to dismiss dialogs and navigate
              if (context.mounted) {
                // Close progress dialog
                outerNavigator.pop();

                if (success) {
                  // Return to gallery view
                  outerNavigator.pop();

                  // Show success message
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Photo deleted successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        photoService.error ?? 'Failed to delete photo',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}
