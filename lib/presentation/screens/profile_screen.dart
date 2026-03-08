import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'accelerometer_screen.dart';
import 'gyroscope_screen.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dating_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> _interestSuggestions = <String>[
    'Travel',
    'Music',
    'Food',
    'Hiking',
    'Movies',
    'Fitness',
    'Books',
    'Photography',
  ];

  final ProfileController _profileController = ProfileController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(AuthController authController) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() {
      _selectedImage = File(pickedFile.path);
    });

    await _uploadProfileImage(authController);
  }

  Future<void> _uploadProfileImage(AuthController authController) async {
    if (_selectedImage == null) {
      return;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final url = await _profileController.uploadProfileImage(
        _selectedImage!,
        userEmail: authController.currentUser?.email,
      );
      authController.updateUserProfileImage(url);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      setState(() {
        _selectedImage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  ImageProvider<Object>? _profileImage(AuthController authController) {
    final imageUrl =
        _selectedImage?.path ?? authController.currentUser?.profileImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    }
    return FileImage(File(imageUrl));
  }

  Future<void> _openEditProfileSheet(AuthController authController) async {
    final user = authController.currentUser;
    if (user == null) {
      return;
    }

    final nameController = TextEditingController(text: user.name);
    final bioController = TextEditingController(text: authController.bio);
    final interestsController = TextEditingController(
      text: authController.interests.join(', '),
    );
    var selectedGender = user.gender ?? 'other';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveProfile() async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final name = nameController.text.trim();
              final bio = bioController.text.trim();
              final interests = interestsController.text
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toSet()
                  .toList();

              if (name.length < 2) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Name must be at least 2 characters'),
                  ),
                );
                return;
              }

              if (bio.length < 10) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Bio must be at least 10 characters'),
                  ),
                );
                return;
              }

              final saved = await authController.saveProfile(
                name: name,
                bio: bio,
                gender: selectedGender,
                interests: interests,
                profileImageUrls: authController.profileImageUrls,
              );

              if (!mounted) {
                return;
              }

              if (saved) {
                navigator.pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Profile updated')),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      authController.errorMessage ?? 'Failed to update profile',
                    ),
                  ),
                );
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  mediaQuery.viewInsets.bottom + 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Edit profile',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _sheetField(
                              controller: nameController,
                              label: 'Name',
                              maxLines: 1,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Gender',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children:
                                  <Map<String, String>>[
                                    {'label': 'Male', 'value': 'male'},
                                    {'label': 'Female', 'value': 'female'},
                                    {'label': 'Other', 'value': 'other'},
                                  ].map((option) {
                                    final isSelected =
                                        selectedGender == option['value'];
                                    return ChoiceChip(
                                      label: Text(option['label']!),
                                      selected: isSelected,
                                      onSelected: (_) {
                                        setModalState(() {
                                          selectedGender = option['value']!;
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 14),
                            _sheetField(
                              controller: bioController,
                              label: 'Bio',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 14),
                            _sheetField(
                              controller: interestsController,
                              label: 'Interests',
                              maxLines: 2,
                              hintText: 'Travel, Music, Food',
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _interestSuggestions.map((interest) {
                                final isActive = interestsController.text
                                    .toLowerCase()
                                    .split(',')
                                    .map((item) => item.trim())
                                    .contains(interest.toLowerCase());
                                return FilterChip(
                                  label: Text(interest),
                                  selected: isActive,
                                  onSelected: (_) {
                                    final existing = interestsController.text
                                        .split(',')
                                        .map((item) => item.trim())
                                        .where((item) => item.isNotEmpty)
                                        .toList();
                                    if (isActive) {
                                      existing.removeWhere(
                                        (item) =>
                                            item.toLowerCase() ==
                                            interest.toLowerCase(),
                                      );
                                    } else {
                                      existing.add(interest);
                                    }
                                    setModalState(() {
                                      interestsController.text = existing.join(
                                        ', ',
                                      );
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: authController.isLoading
                                    ? null
                                    : saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE94057),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: authController.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Save changes',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    bioController.dispose();
    interestsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthController, DatingController>(
      builder: (context, authController, datingController, _) {
        final currentUser = authController.currentUser;
        final imageProvider = _profileImage(authController);
        final firstName = currentUser?.name.split(' ').first ?? 'You';

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isCompact = width < 680;
            final isMedium = width >= 680 && width < 1040;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isCompact ? 10 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(
                    authController: authController,
                    datingController: datingController,
                    currentUserName: currentUser?.name ?? 'Your profile',
                    currentUserEmail: currentUser?.email ?? 'Add your email',
                    firstName: firstName,
                    imageProvider: imageProvider,
                    isCompact: isCompact,
                  ),
                  const SizedBox(height: 18),
                  if (isMedium)
                    Column(
                      children: [
                        _buildStatsGrid(datingController, compact: false),
                        const SizedBox(height: 16),
                        _buildMenuCard(authController, compact: false),
                        const SizedBox(height: 16),
                        _buildSettingsCard(),
                      ],
                    )
                  else if (isCompact)
                    Column(
                      children: [
                        _buildStatsGrid(datingController, compact: true),
                        const SizedBox(height: 16),
                        _buildMenuCard(authController, compact: true),
                        const SizedBox(height: 16),
                        _buildSettingsCard(),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildStatsGrid(
                            datingController,
                            compact: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMenuCard(authController, compact: false),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSettingsCard()),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeroCard({
    required AuthController authController,
    required DatingController datingController,
    required String currentUserName,
    required String currentUserEmail,
    required String firstName,
    required ImageProvider<Object>? imageProvider,
    required bool isCompact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 18 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5864), Color(0xFFFD297B), Color(0xFFFF655B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: isCompact ? 42 : 52,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 42,
                          )
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: InkWell(
                      onTap: _isUploadingImage
                          ? null
                          : () => _pickImage(authController),
                      borderRadius: BorderRadius.circular(999),
                      child: Ink(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: _isUploadingImage
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: Color(0xFFE94057),
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUserName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 24 : 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUserEmail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: isCompact ? 13 : 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _heroChip(
                          icon: Icons.verified_user_rounded,
                          label:
                              '${(datingController.profileCompletion * 100).round()}% complete',
                        ),
                        _heroChip(
                          icon: Icons.favorite_rounded,
                          label: '${datingController.matches.length} matches',
                        ),
                        _heroChip(
                          icon: Icons.chat_bubble_rounded,
                          label: '${datingController.threads.length} chats',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            authController.bio.isEmpty
                ? '$firstName, add a stronger bio to improve match quality.'
                : authController.bio,
            style: const TextStyle(color: Colors.white, height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: authController.interests.isEmpty
                ? <Widget>[_heroChip(label: 'Add interests from edit profile')]
                : authController.interests
                      .map((interest) => _heroChip(label: interest))
                      .toList(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => _openEditProfileSheet(authController),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFE94057),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit profile'),
              ),
              OutlinedButton.icon(
                onPressed: _isUploadingImage
                    ? null
                    : () => _pickImage(authController),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.photo_camera_back_rounded),
                label: const Text('Update photo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    DatingController datingController, {
    required bool compact,
  }) {
    final unreadCount = datingController.threads.fold<int>(
      0,
      (sum, thread) => sum + thread.unreadCount,
    );

    return _sectionCard(
      title: 'Profile insights',
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: compact ? 2 : 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: compact ? 1.45 : 1.8,
        children: [
          _metricTile('Likes sent', datingController.likedCount.toString()),
          _metricTile(
            'Super likes',
            datingController.superLikedCount.toString(),
          ),
          _metricTile('Passes', datingController.skippedCount.toString()),
          _metricTile('Matches', datingController.matches.length.toString()),
          _metricTile('Open chats', datingController.threads.length.toString()),
          _metricTile('Unread', unreadCount.toString()),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    AuthController authController, {
    required bool compact,
  }) {
    return _sectionCard(
      title: 'Profile menu',
      child: Column(
        children: [
          _menuTile(
            icon: Icons.edit_note_rounded,
            title: 'Edit profile details',
            subtitle: 'Update your name, bio, interests, and gender',
            onTap: () => _openEditProfileSheet(authController),
          ),
          _menuTile(
            icon: Icons.photo_library_rounded,
            title: 'Manage photos',
            subtitle: 'Upload a new primary photo from your gallery',
            onTap: () => _pickImage(authController),
          ),
          _menuTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: compact
                ? 'Sign out from this device'
                : 'End the current session on this device',
            color: Colors.red,
            onTap: () => _showLogoutDialog(context, authController),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return _sectionCard(
      title: 'Settings',
      child: Column(
        children: [
          _sensorTile(
            title: 'Accelerometer',
            icon: Icons.speed,
            color: Colors.blue,
            screen: const AccelerometerScreen(),
          ),
          _sensorTile(
            title: 'Gyroscope',
            icon: Icons.rotate_right,
            color: Colors.green,
            screen: const GyroscopeScreen(),
          ),
        ],
      ),
    );
  }

  Widget _heroChip({IconData? icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFFE94057),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? const Color(0xFFE94057);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: resolvedColor.withValues(alpha: 0.1),
        child: Icon(icon, color: resolvedColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color ?? theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      onTap: onTap,
    );
  }

  Widget _sensorTile({
    required String title,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    required int maxLines,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE94057), width: 2),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthController authController) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              authController.logout();
              Navigator.pop(dialogContext);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
