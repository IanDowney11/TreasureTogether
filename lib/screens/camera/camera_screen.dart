import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../../services/photo_service.dart';
import '../../services/preferences_service.dart';
import '../../models/group.dart';
import '../groups/groups_screen.dart';
import '../gallery/gallery_screen.dart';
import '../favorites/favorites_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _hasAutoLaunched = false;

  @override
  void initState() {
    super.initState();
    // Fetch photos when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = context.read<PreferencesService>();
      final photoService = context.read<PhotoService>();
      if (prefs.defaultEventId != null) {
        photoService.fetchGroupPhotos(prefs.defaultEventId!);

        // Auto-launch camera on mobile only once
        if (!kIsWeb && !_hasAutoLaunched && prefs.defaultEventId != null) {
          _hasAutoLaunched = true;
          _takePhoto();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<PreferencesService>(
          builder: (context, prefs, _) {
            final defaultEventId = prefs.defaultEventId;
            if (defaultEventId == null) {
              return const Text('Photo Sharing');
            }

            return Consumer<GroupService>(
              builder: (context, groupService, _) {
                final group = groupService.groups
                    .where((g) => g.id == defaultEventId)
                    .firstOrNull;
                return Text(group?.name ?? 'Photo Sharing');
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorites',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
          Consumer<PreferencesService>(
            builder: (context, prefs, _) {
              if (prefs.defaultEventId != null) {
                return IconButton(
                  icon: const Icon(Icons.photo_library),
                  tooltip: 'View Gallery',
                  onPressed: () => _viewGallery(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<PreferencesService>(
              builder: (context, prefs, _) {
                if (prefs.defaultEventId == null) {
                  return Column(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 120,
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No event selected',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select an event to start taking photos',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _selectOrCreateEvent(context),
                        icon: const Icon(Icons.event),
                        label: const Text('Select or Create Event'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Consumer<PhotoService>(
                  builder: (context, photoService, _) {
                    final photos = photoService.getPhotosForGroup(prefs.defaultEventId!);
                    final lastPhoto = photos.isNotEmpty ? photos.first : null;

                    return Column(
                      children: [
                        if (lastPhoto != null) ...[
                          GestureDetector(
                            onTap: () => _viewGallery(context),
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: photoService.getPhotoUrl(lastPhoto),
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
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.3),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Positioned(
                                      bottom: 12,
                                      right: 12,
                                      child: Icon(
                                        Icons.photo_library,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to view gallery',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ] else ...[
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 120,
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 32),
                        ],
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _takePhoto,
                          icon: const Icon(Icons.camera),
                          label: Text(_isUploading ? 'Uploading...' : 'Take Photo'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                        if (_isUploading)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer<AuthService>(
            builder: (context, authService, _) {
              return DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'TreasureTogether',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final version = snapshot.hasData
                            ? 'v${snapshot.data!.version} (${snapshot.data!.buildNumber})${kIsWeb ? ' • Web' : ''}'
                            : 'Loading...';
                        return Text(
                          version,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authService.currentUser?.displayName ??
                          authService.currentUser?.email ??
                          '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Consumer<PreferencesService>(
            builder: (context, prefs, _) {
              final hasEvent = prefs.defaultEventId != null;
              return Column(
                children: [
                  if (hasEvent)
                    ListTile(
                      leading: const Icon(Icons.swap_horiz),
                      title: const Text('Switch Event'),
                      onTap: () {
                        Navigator.pop(context);
                        _selectOrCreateEvent(context);
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.add_circle),
                    title: const Text('Create New Event'),
                    onTap: () {
                      Navigator.pop(context);
                      _createEvent(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Join Event'),
                    onTap: () {
                      Navigator.pop(context);
                      _joinEvent(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('View All Events'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GroupsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.favorite),
                    title: const Text('Favorites'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<AuthService>().signOut();
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      // Request storage permission on Android before saving (only needed for Android 9 and below)
      // On Android 10+ (API 29+), MediaStore doesn't require runtime permissions
      if (!kIsWeb) {
        // Try to request storage permission
        // On Android 10+ this will be granted automatically or not needed
        // On Android 9 and below, this prompts for WRITE_EXTERNAL_STORAGE
        final status = await Permission.storage.request();
        if (!status.isGranted && !status.isLimited) {
          // Permission denied - but we'll continue anyway
          // The photo will still be uploaded to the cloud
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission denied - photo will be uploaded but not saved to device'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Saving and uploading photo...'),
            ],
          ),
        ),
      );

      setState(() => _isUploading = true);

      // Save to device gallery
      final imageBytes = await image.readAsBytes();
      bool savedToGallery = false;
      if (!kIsWeb) {
        try {
          await Gal.putImageBytes(imageBytes);
          savedToGallery = true;
        } catch (e) {
          print('Error saving to gallery: $e');
          savedToGallery = false;
        }
      }

      // Upload to default event
      final prefs = context.read<PreferencesService>();
      final eventId = prefs.defaultEventId;

      if (eventId != null && mounted) {
        final photoService = context.read<PhotoService>();
        final photo = await photoService.uploadPhoto(
          groupId: eventId,
          imageBytes: imageBytes,
          fileName: image.name,
        );

        if (mounted) {
          // Close progress dialog
          Navigator.of(context).pop();

          String message;
          Color backgroundColor;

          if (photo != null && savedToGallery) {
            message = 'Photo saved to gallery and uploaded!';
            backgroundColor = Colors.green;
          } else if (photo != null && !savedToGallery) {
            message = 'Photo uploaded! (Gallery save failed - check permissions)';
            backgroundColor = Colors.orange;
          } else if (photo == null && savedToGallery) {
            message = 'Photo saved to gallery, but upload failed';
            backgroundColor = Colors.orange;
          } else {
            message = 'Failed to save and upload photo';
            backgroundColor = Colors.red;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else if (mounted) {
        // Close progress dialog
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        // Close progress dialog if open
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _selectOrCreateEvent(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GroupsScreen(selectMode: true),
      ),
    );
  }

  void _createEvent(BuildContext context) {
    // Show create event dialog (similar to groups screen)
    _showCreateGroupDialog(context);
  }

  void _joinEvent(BuildContext context) {
    // Show join event dialog (similar to groups screen)
    _showJoinGroupDialog(context);
  }

  void _viewGallery(BuildContext context) {
    final prefs = context.read<PreferencesService>();
    final groupService = context.read<GroupService>();
    final eventId = prefs.defaultEventId;

    if (eventId != null) {
      final group = groupService.groups.where((g) => g.id == eventId).firstOrNull;
      if (group != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GalleryScreen(group: group),
          ),
        );
      }
    }
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Event'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  hintText: 'e.g., Summer Vacation 2024',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an event name';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What is this event for?',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final navigator = Navigator.of(context);
                final groupService = context.read<GroupService>();
                final prefsService = context.read<PreferencesService>();

                navigator.pop();

                final group = await groupService.createGroup(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                if (group != null) {
                  await prefsService.setDefaultEvent(group.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Event "${group.name}" created!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog(BuildContext context) {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Event'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: codeController,
            decoration: const InputDecoration(
              labelText: 'Invite Code',
              hintText: 'Enter 6-character code',
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an invite code';
              }
              if (value.trim().length != 6) {
                return 'Invite code must be 6 characters';
              }
              return null;
            },
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final groupService = context.read<GroupService>();
                final prefsService = context.read<PreferencesService>();

                navigator.pop();

                final success = await groupService.joinGroup(
                  codeController.text.trim().toUpperCase(),
                );

                if (success) {
                  // Set as default event
                  await groupService.fetchUserGroups();
                  final joinedGroup = groupService.groups.firstOrNull;
                  if (joinedGroup != null) {
                    await prefsService.setDefaultEvent(joinedGroup.id);
                  }

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Successfully joined event!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Show error message
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        groupService.error ?? 'Failed to join event',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
