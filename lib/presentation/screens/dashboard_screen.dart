import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/dating_controller.dart';
import '../controllers/theme_controller.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();
  int _selectedIndex = 0;
  Offset _dragOffset = Offset.zero;
  bool _isAnimatingOut = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleMessageChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleMessageChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _handleMessageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 1) {
      final controller = context.read<DatingController>();
      if (controller.selectedThreadId == null &&
          controller.threads.isNotEmpty) {
        controller.selectThread(controller.threads.first.id);
      }
    }

    setState(() => _selectedIndex = index);
  }

  ImageProvider? _getProfileImage(AuthController authController) {
    final imageUrl = authController.currentUser?.profileImageUrl;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return NetworkImage(imageUrl);
      }
      return FileImage(File(imageUrl));
    }

    return null;
  }

  void _onPanUpdate(DragUpdateDetails details, DatingController controller) {
    if (_isAnimatingOut || controller.profiles.isEmpty) {
      return;
    }

    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details, DatingController controller) {
    if (_isAnimatingOut || controller.profiles.isEmpty) {
      return;
    }

    const threshold = 110.0;
    if (_dragOffset.dx > threshold) {
      _animateSwipe(true, controller);
      return;
    }

    if (_dragOffset.dx < -threshold) {
      _animateSwipe(false, controller);
      return;
    }

    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  void _animateSwipe(bool liked, DatingController controller) {
    if (controller.profiles.isEmpty || _isAnimatingOut) {
      return;
    }

    final profile = controller.profiles.first;

    setState(() {
      _isAnimatingOut = true;
      _dragOffset = Offset(liked ? 760 : -760, _dragOffset.dy);
    });

    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) {
        return;
      }

      controller.swipeCurrentProfile(liked);
      setState(() {
        _dragOffset = Offset.zero;
        _isAnimatingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            liked
                ? "It's a match-ready like for ${profile.name}"
                : 'Passed on ${profile.name}',
          ),
          duration: const Duration(milliseconds: 900),
          backgroundColor: liked ? const Color(0xFFE94057) : Colors.blueGrey,
        ),
      );
    });
  }

  void _sendMessage(DatingController controller) {
    FocusScope.of(context).unfocus();
    controller.sendMessage(_messageController.text);
    _messageController.clear();
  }

  void _superLikeCurrentProfile(DatingController controller) {
    final profile = controller.superLikeCurrentProfile();
    if (profile == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Super liked ${profile.name}. Chat opened in Messages.'),
        duration: const Duration(milliseconds: 1200),
        backgroundColor: Colors.blue,
      ),
    );

    setState(() {
      _selectedIndex = 1;
      _dragOffset = Offset.zero;
      _isAnimatingOut = false;
    });
  }

  int _unreadCount(DatingController controller) {
    return controller.threads.fold<int>(
      0,
      (sum, thread) => sum + thread.unreadCount,
    );
  }

  Widget _buildDiscoverScreen(
    BuildContext context,
    AuthController authController,
    DatingController controller,
    bool isMobile,
    bool isTablet,
  ) {
    final userName =
        authController.currentUser?.name.split(' ').first ?? 'Friend';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroStrip(authController, controller, isMobile, userName),
        SizedBox(height: isMobile ? 16 : 24),
        Expanded(
          child: controller.profiles.isEmpty
              ? _buildEmptyDiscover(controller)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = math.min<double>(
                      constraints.maxWidth,
                      isMobile ? 420 : 520,
                    );
                    final cardHeight = math.min<double>(
                      constraints.maxHeight,
                      isTablet ? 640 : 720,
                    );

                    return Center(
                      child: SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (controller.profiles.length > 2)
                              _buildStackCard(
                                controller.profiles[2],
                                scale: 0.92,
                                topPadding: 18,
                              ),
                            if (controller.profiles.length > 1)
                              _buildStackCard(
                                controller.profiles[1],
                                scale: 0.96,
                                topPadding: 10,
                              ),
                            _buildTopCard(
                              controller.profiles.first,
                              controller,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        SizedBox(height: isMobile ? 14 : 20),
        _buildActionButtons(controller),
      ],
    );
  }

  Widget _buildHeroStrip(
    AuthController authController,
    DatingController controller,
    bool isMobile,
    String userName,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5864), Color(0xFFFD297B), Color(0xFFFF655B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE94057).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 26 : 32,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: _getProfileImage(authController),
                child: _getProfileImage(authController) == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good evening, $userName',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${controller.matches.length} active matches and ${controller.threads.length} conversations',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${controller.likedCount} likes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Profile strength',
                  '${(controller.profileCompletion * 100).round()}%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Matches',
                  '${controller.matches.length}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Unread',
                  _unreadCount(controller).toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackCard(
    DatingProfile profile, {
    required double scale,
    required double topPadding,
  }) {
    return Positioned.fill(
      top: topPadding,
      child: Transform.scale(
        scale: scale,
        child: _buildProfileCard(profile, interactive: false),
      ),
    );
  }

  Widget _buildTopCard(DatingProfile profile, DatingController controller) {
    final angle = (_dragOffset.dx / 320) * 0.18;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      transform: Matrix4.identity()
        ..translate(_dragOffset.dx, _dragOffset.dy)
        ..rotateZ(angle),
      child: GestureDetector(
        onPanUpdate: (details) => _onPanUpdate(details, controller),
        onPanEnd: (details) => _onPanEnd(details, controller),
        child: _buildProfileCard(profile, interactive: true),
      ),
    );
  }

  Widget _buildProfileCard(DatingProfile profile, {required bool interactive}) {
    final showLikeLabel = _dragOffset.dx > 28;
    final showNopeLabel = _dragOffset.dx < -28;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(profile.imageUrl, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(25, 0, 0, 0),
                  Color.fromARGB(70, 0, 0, 0),
                  Color.fromARGB(200, 0, 0, 0),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.28),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.24)),
              ),
              child: Text(
                '${profile.compatibility}% match',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (interactive && showLikeLabel)
            Positioned(
              left: 22,
              top: 72,
              child: _buildTag('LIKE', Colors.greenAccent),
            ),
          if (interactive && showNopeLabel)
            Positioned(
              right: 22,
              top: 72,
              child: _buildTag('NOPE', Colors.orangeAccent),
            ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.name}, ${profile.age}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.tagline,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${profile.location} - ${profile.distanceKm} km away',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  profile.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.interests
                      .map(
                        (interest) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.16),
                            ),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Transform.rotate(
      angle: label == 'LIKE' ? -0.18 : 0.18,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(DatingController controller) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRoundAction(
          icon: Icons.close_rounded,
          color: Colors.orange,
          onTap: controller.profiles.isEmpty
              ? null
              : () => _animateSwipe(false, controller),
        ),
        const SizedBox(width: 20),
        _buildRoundAction(
          icon: Icons.star_rounded,
          color: theme.colorScheme.secondary,
          onTap: controller.profiles.isEmpty
              ? null
              : () => _superLikeCurrentProfile(controller),
        ),
        const SizedBox(width: 20),
        _buildRoundAction(
          icon: Icons.favorite_rounded,
          color: const Color(0xFFE94057),
          onTap: controller.profiles.isEmpty
              ? null
              : () => _animateSwipe(true, controller),
        ),
      ],
    );
  }

  Widget _buildRoundAction({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.22),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  Widget _buildEmptyDiscover(DatingController controller) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, size: 54, color: Color(0xFFE94057)),
            const SizedBox(height: 14),
            const Text(
              'You reached the end of the stack',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You liked ${controller.likedCount} profiles and skipped ${controller.skippedCount}. Open Matches to start chatting.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesScreen(DatingController controller, bool isMobile) {
    final selectedThread = controller.selectedThread;

    if (isMobile && selectedThread != null) {
      return _buildConversationPanel(
        controller,
        isMobile: true,
        showBackButton: true,
      );
    }

    if (controller.threads.isEmpty) {
      return _buildConversationEmptyState(
        title: 'No conversations yet',
        subtitle: 'Like a profile or open a match to start chatting.',
      );
    }

    return Row(
      children: [
        Expanded(
          flex: isMobile ? 1 : 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Messages',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Start with your newest match and keep the chat moving.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: controller.threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final thread = controller.threads[index];
                    final isSelected = selectedThread?.id == thread.id;

                    return InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        controller.selectThread(thread.id);
                        if (isMobile) {
                          setState(() {});
                        }
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF0F3)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE94057).withOpacity(0.24)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(
                                    thread.imageUrl,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: thread.isOnline
                                          ? Colors.green
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    thread.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    thread.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  thread.timeLabel,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                if (thread.unreadCount > 0) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE94057),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${thread.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 18),
          Expanded(
            flex: 5,
            child: _buildConversationPanel(
              controller,
              isMobile: false,
              showBackButton: false,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConversationPanel(
    DatingController controller, {
    required bool isMobile,
    required bool showBackButton,
  }) {
    final theme = Theme.of(context);
    final thread = controller.selectedThread;
    if (thread == null) {
      final fallbackThread = controller.threads.isNotEmpty
          ? controller.threads.first
          : null;
      return _buildConversationEmptyState(
        title: fallbackThread == null
            ? 'Select a conversation'
            : 'Open a chat to start messaging',
        subtitle: fallbackThread == null
            ? 'Choose a match from the list to open the chat.'
            : 'Tap below to continue chatting with ${fallbackThread.name}.',
        actionLabel: fallbackThread == null
            ? null
            : 'Open ${fallbackThread.name}',
        onAction: fallbackThread == null
            ? null
            : () {
                controller.selectThread(fallbackThread.id);
                setState(() {});
              },
      );
    }

    final messages = controller.selectedMessages;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              children: [
                if (showBackButton)
                  IconButton(
                    onPressed: () {
                      controller.clearSelectedThread();
                      setState(() {});
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                CircleAvatar(backgroundImage: NetworkImage(thread.imageUrl)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        thread.isOnline ? 'Active now' : 'Recently active',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Conversation with ${thread.name} is active',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
          ),
          Divider(color: theme.dividerColor, height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxBubbleWidth =
                    constraints.maxWidth * (isMobile ? 0.82 : 0.62);
                return ListView.builder(
                  padding: EdgeInsets.all(isMobile ? 14 : 18),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final alignment = message.isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start;
                    final bubbleColor = message.isMine
                        ? const Color(0xFFE94057)
                        : theme.colorScheme.surfaceContainerHighest;
                    final textColor = message.isMine
                        ? Colors.white
                        : theme.colorScheme.onSurface;

                    return Column(
                      crossAxisAlignment: alignment,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(color: textColor, height: 1.3),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _sendMessage(controller),
                    decoration: InputDecoration(
                      hintText: 'Write a message',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _messageController.text.trim().isEmpty
                      ? null
                      : () => _sendMessage(controller),
                  borderRadius: BorderRadius.circular(999),
                  child: Ink(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _messageController.text.trim().isEmpty
                          ? theme.disabledColor.withOpacity(0.3)
                          : const Color(0xFFE94057),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationEmptyState({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 42,
                color: Color(0xFFE94057),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.chat_bubble_rounded),
                  label: Text(actionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94057),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesScreen(
    DatingController controller,
    bool isMobile,
    bool isTablet,
  ) {
    final crossAxisCount = isMobile
        ? 2
        : isTablet
        ? 3
        : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Matches',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'People who already matched with you. Open a chat while the momentum is fresh.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            itemCount: controller.matches.length,
            itemBuilder: (context, index) {
              final match = controller.matches[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(match.imageUrl, fit: BoxFit.cover),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromARGB(20, 0, 0, 0),
                            Color.fromARGB(190, 0, 0, 0),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: match.isOnline
                              ? Colors.greenAccent
                              : Colors.white54,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${match.distanceLabel} - ${match.lastActiveLabel}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                controller.openMatchChat(match);
                                setState(() => _selectedIndex = 1);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFE94057),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Message',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentScreen(
    BuildContext context,
    AuthController authController,
    DatingController controller,
    bool isMobile,
    bool isTablet,
  ) {
    switch (_selectedIndex) {
      case 0:
        return _buildDiscoverScreen(
          context,
          authController,
          controller,
          isMobile,
          isTablet,
        );
      case 1:
        return _buildMessagesScreen(controller, isMobile);
      case 2:
        return _buildMatchesScreen(controller, isMobile, isTablet);
      case 3:
        return const ProfileScreen();
      default:
        return _buildDiscoverScreen(
          context,
          authController,
          controller,
          isMobile,
          isTablet,
        );
    }
  }

  Widget _buildDesktopRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onBottomNavTap,
      labelType: NavigationRailLabelType.all,
      leading: const SizedBox(height: 12),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.local_fire_department_outlined),
          selectedIcon: Icon(Icons.local_fire_department),
          label: Text('Discover'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_bubble_rounded),
          label: Text('Messages'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.favorite_border_rounded),
          selectedIcon: Icon(Icons.favorite_rounded),
          label: Text('Matches'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: Text('Profile'),
        ),
      ],
    );
  }

  Widget _buildMobileDrawer(AuthController authController) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: _getProfileImage(authController),
                child: _getProfileImage(authController) == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(authController.currentUser?.name ?? 'User'),
              subtitle: Text(
                authController.currentUser?.email ?? 'user@example.com',
              ),
            ),
            Divider(color: theme.dividerColor),
            _drawerItem(Icons.local_fire_department_rounded, 'Discover', 0),
            _drawerItem(Icons.chat_bubble_rounded, 'Messages', 1),
            _drawerItem(Icons.favorite_rounded, 'Matches', 2),
            _drawerItem(Icons.person_rounded, 'Profile', 3),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    authController.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        _onBottomNavTap(index);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;
    final isTablet = width >= 760 && width < 1180;

    return Consumer3<AuthController, DatingController, ThemeController>(
      builder: (context, authController, datingController, themeController, _) {
        final showRail = !isMobile;
        final theme = Theme.of(context);

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            leading: isMobile
                ? IconButton(
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(Icons.menu_rounded),
                  )
                : null,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF5864), Color(0xFFFD297B)],
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'BhetGhat',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => setState(() => _selectedIndex = 3),
                icon: CircleAvatar(
                  radius: 16,
                  backgroundImage: _getProfileImage(authController),
                  child: _getProfileImage(authController) == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
              ),
              IconButton(
                onPressed: themeController.toggleTheme,
                icon: Icon(
                  themeController.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          drawer: isMobile ? _buildMobileDrawer(authController) : null,
          body: SafeArea(
            child: Row(
              children: [
                if (showRail) ...[
                  _buildDesktopRail(),
                  VerticalDivider(color: theme.dividerColor, width: 1),
                ],
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 22),
                    child: _buildCurrentScreen(
                      context,
                      authController,
                      datingController,
                      isMobile,
                      isTablet,
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isMobile
              ? BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: _onBottomNavTap,
                  selectedItemColor: const Color(0xFFE94057),
                  unselectedItemColor: Colors.grey.shade600,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.local_fire_department_outlined),
                      activeIcon: Icon(Icons.local_fire_department),
                      label: 'Discover',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat_bubble_outline_rounded),
                      activeIcon: Icon(Icons.chat_bubble_rounded),
                      label: 'Messages',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.favorite_border_rounded),
                      activeIcon: Icon(Icons.favorite_rounded),
                      label: 'Matches',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline_rounded),
                      activeIcon: Icon(Icons.person_rounded),
                      label: 'Profile',
                    ),
                  ],
                  type: BottomNavigationBarType.fixed,
                )
              : null,
        );
      },
    );
  }
}
