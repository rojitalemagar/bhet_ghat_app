import 'package:flutter/material.dart';

class DatingController extends ChangeNotifier {
  DatingController() {
    _seedProfiles();
  }

  final List<DatingProfile> _profiles = [];
  final List<MatchProfile> _matches = [];
  final List<MessageThread> _threads = [];
  final Map<String, List<ChatMessage>> _messagesByThread = {};
  int _likedCount = 0;
  int _superLikedCount = 0;
  int _skippedCount = 0;
  String? _selectedThreadId;

  List<DatingProfile> get profiles => List.unmodifiable(_profiles);
  List<MatchProfile> get matches => List.unmodifiable(_matches);
  List<MessageThread> get threads => List.unmodifiable(_threads);
  int get likedCount => _likedCount;
  int get superLikedCount => _superLikedCount;
  int get skippedCount => _skippedCount;
  String? get selectedThreadId => _selectedThreadId;

  MessageThread? get selectedThread {
    if (_selectedThreadId == null) {
      return null;
    }
    return _threads.cast<MessageThread?>().firstWhere(
      (thread) => thread?.id == _selectedThreadId,
      orElse: () => null,
    );
  }

  List<ChatMessage> get selectedMessages {
    if (_selectedThreadId == null) {
      return const [];
    }
    return List.unmodifiable(_messagesByThread[_selectedThreadId] ?? const []);
  }

  void swipeCurrentProfile(bool liked) {
    if (_profiles.isEmpty) {
      return;
    }

    final profile = _profiles.removeAt(0);
    if (liked) {
      _likedCount += 1;
      _createMatch(profile);
    } else {
      _skippedCount += 1;
    }
    notifyListeners();
  }

  DatingProfile? superLikeCurrentProfile() {
    if (_profiles.isEmpty) {
      return null;
    }

    final profile = _profiles.removeAt(0);
    _likedCount += 1;
    _superLikedCount += 1;
    _createMatch(profile, isSuperLike: true);
    notifyListeners();
    return profile;
  }

  void selectThread(String threadId) {
    _selectedThreadId = threadId;
    _markThreadRead(threadId);
    notifyListeners();
  }

  void clearSelectedThread() {
    if (_selectedThreadId == null) {
      return;
    }
    _selectedThreadId = null;
    notifyListeners();
  }

  void openMatchChat(MatchProfile match) {
    final existingThread = _threads.cast<MessageThread?>().firstWhere(
      (thread) => thread?.matchId == match.id,
      orElse: () => null,
    );

    if (existingThread != null) {
      selectThread(existingThread.id);
      return;
    }

    final thread = MessageThread(
      id: 'thread_${match.id}',
      matchId: match.id,
      name: match.name,
      imageUrl: match.imageUrl,
      lastMessage: 'You matched with ${match.name}. Say hi.',
      timeLabel: 'now',
      unreadCount: 0,
      isOnline: match.isOnline,
    );

    _threads.insert(0, thread);
    _messagesByThread[thread.id] = [
      ChatMessage(
        id: 'msg_${thread.id}_system',
        threadId: thread.id,
        text: 'You matched with ${match.name}. Start the conversation.',
        isMine: false,
        timestamp: DateTime.now(),
      ),
    ];
    selectThread(thread.id);
  }

  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _selectedThreadId == null) {
      return;
    }

    final thread = selectedThread;
    if (thread == null) {
      return;
    }

    final messages = _messagesByThread[_selectedThreadId!] ?? <ChatMessage>[];
    messages.add(
      ChatMessage(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
        threadId: thread.id,
        text: trimmed,
        isMine: true,
        timestamp: DateTime.now(),
      ),
    );
    _messagesByThread[_selectedThreadId!] = messages;
    _replaceThread(
      thread.copyWith(lastMessage: trimmed, timeLabel: 'now', unreadCount: 0),
    );

    Future<void>.delayed(const Duration(milliseconds: 650), () {
      final reply = _generateReply(thread.name);
      final updatedMessages = _messagesByThread[thread.id] ?? <ChatMessage>[];
      updatedMessages.add(
        ChatMessage(
          id: 'msg_${DateTime.now().microsecondsSinceEpoch}_reply',
          threadId: thread.id,
          text: reply,
          isMine: false,
          timestamp: DateTime.now(),
        ),
      );
      _messagesByThread[thread.id] = updatedMessages;
      final isActiveThread = _selectedThreadId == thread.id;
      _replaceThread(
        thread.copyWith(
          lastMessage: reply,
          timeLabel: 'now',
          unreadCount: isActiveThread ? 0 : thread.unreadCount + 1,
        ),
      );
      notifyListeners();
    });

    notifyListeners();
  }

  double get profileCompletion {
    final stats = <bool>[
      true,
      _likedCount > 0,
      _superLikedCount > 0,
      _matches.isNotEmpty,
      _threads.isNotEmpty,
    ];
    final completed = stats.where((value) => value).length;
    return completed / stats.length;
  }

  void _seedProfiles() {
    _profiles
      ..clear()
      ..addAll([
        DatingProfile(
          id: 'aarohi',
          name: 'Aarohi Gurung',
          age: 24,
          location: 'Kathmandu',
          distanceKm: 1,
          bio:
              'Coffee lover, trekking partner, and movie night fan. Looking for honest conversation.',
          interests: const ['Hiking', 'Photography', 'Nepali Music'],
          imageUrl:
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=1200',
          compatibility: 94,
          tagline: 'Slow mornings, good coffee, long walks.',
        ),
        DatingProfile(
          id: 'ritesh',
          name: 'Ritesh Thapa',
          age: 27,
          location: 'Pokhara',
          distanceKm: 5,
          bio:
              'Weekend traveler and foodie. Let us plan a mountain sunrise together.',
          interests: const ['Travel', 'Food', 'Guitar'],
          imageUrl:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=1200',
          compatibility: 89,
          tagline: 'Road trips, playlists, and ramen.',
        ),
        DatingProfile(
          id: 'nisha',
          name: 'Nisha Karki',
          age: 23,
          location: 'Lalitpur',
          distanceKm: 2,
          bio:
              'Bookstore dates and deep chats. I value kindness and consistency.',
          interests: const ['Books', 'Art', 'Yoga'],
          imageUrl:
              'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=1200',
          compatibility: 92,
          tagline: 'Art galleries and calm evenings.',
        ),
        DatingProfile(
          id: 'sujan',
          name: 'Sujan Bhandari',
          age: 29,
          location: 'Bhaktapur',
          distanceKm: 3,
          bio: 'Tech by day, futsal by evening. Looking for someone genuine.',
          interests: const ['Futsal', 'Tech', 'Cooking'],
          imageUrl:
              'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=1200',
          compatibility: 86,
          tagline: 'Competitive on the court, easygoing off it.',
        ),
      ]);

    _matches
      ..clear()
      ..addAll([
        MatchProfile(
          id: 'maya',
          name: 'Maya Shrestha',
          distanceLabel: '2 km away',
          imageUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
          isOnline: true,
          lastActiveLabel: 'Active now',
        ),
        MatchProfile(
          id: 'anish',
          name: 'Anish Rai',
          distanceLabel: '4 km away',
          imageUrl:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
          isOnline: false,
          lastActiveLabel: 'Active 12m ago',
        ),
      ]);

    _threads
      ..clear()
      ..addAll([
        MessageThread(
          id: 'thread_maya',
          matchId: 'maya',
          name: 'Maya Shrestha',
          imageUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
          lastMessage: 'I know a rooftop cafe with great momo.',
          timeLabel: '2m',
          unreadCount: 1,
          isOnline: true,
        ),
        MessageThread(
          id: 'thread_anish',
          matchId: 'anish',
          name: 'Anish Rai',
          imageUrl:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
          lastMessage: 'Saturday works for me.',
          timeLabel: '1h',
          unreadCount: 0,
          isOnline: false,
        ),
      ]);

    _messagesByThread
      ..clear()
      ..addAll({
        'thread_maya': [
          ChatMessage(
            id: 'msg_m1',
            threadId: 'thread_maya',
            text: 'Hey, your hiking pictures look amazing.',
            isMine: true,
            timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
          ),
          ChatMessage(
            id: 'msg_m2',
            threadId: 'thread_maya',
            text:
                'Thanks. You seem like someone who would enjoy an early trek.',
            isMine: false,
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ),
          ChatMessage(
            id: 'msg_m3',
            threadId: 'thread_maya',
            text: 'I know a rooftop cafe with great momo.',
            isMine: false,
            timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          ),
        ],
        'thread_anish': [
          ChatMessage(
            id: 'msg_a1',
            threadId: 'thread_anish',
            text: 'Are you more into road trips or staying local?',
            isMine: false,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          ChatMessage(
            id: 'msg_a2',
            threadId: 'thread_anish',
            text: 'Road trips if there is good food involved.',
            isMine: true,
            timestamp: DateTime.now().subtract(
              const Duration(hours: 1, minutes: 50),
            ),
          ),
          ChatMessage(
            id: 'msg_a3',
            threadId: 'thread_anish',
            text: 'Saturday works for me.',
            isMine: false,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      });

    _selectedThreadId = _threads.isNotEmpty ? _threads.first.id : null;
  }

  void _createMatch(DatingProfile profile, {bool isSuperLike = false}) {
    final matchId = profile.id;
    final alreadyMatched = _matches.any((item) => item.id == matchId);
    if (alreadyMatched) {
      return;
    }

    final match = MatchProfile(
      id: matchId,
      name: profile.name,
      distanceLabel: '${profile.distanceKm} km away',
      imageUrl: profile.imageUrl,
      isOnline: profile.distanceKm <= 2,
      lastActiveLabel: isSuperLike
          ? 'Super like'
          : profile.distanceKm <= 2
          ? 'Active now'
          : 'Active 18m ago',
    );

    _matches.insert(0, match);
    openMatchChat(match);
  }

  String _generateReply(String name) {
    const replies = [
      'That sounds fun. What are you doing this weekend?',
      'I am into that. Tell me more.',
      'Nice. I would definitely reply to that on Tinder too.',
      'You seem easy to talk to already.',
    ];
    final index = DateTime.now().millisecond % replies.length;
    return '$name: ${replies[index]}';
  }

  void _markThreadRead(String threadId) {
    final thread = _threads.cast<MessageThread?>().firstWhere(
      (item) => item?.id == threadId,
      orElse: () => null,
    );
    if (thread == null || thread.unreadCount == 0) {
      return;
    }
    _replaceThread(thread.copyWith(unreadCount: 0));
  }

  void _replaceThread(MessageThread updated) {
    final index = _threads.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      return;
    }
    _threads.removeAt(index);
    _threads.insert(0, updated);
  }
}

class DatingProfile {
  const DatingProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.distanceKm,
    required this.bio,
    required this.interests,
    required this.imageUrl,
    required this.compatibility,
    required this.tagline,
  });

  final String id;
  final String name;
  final int age;
  final String location;
  final int distanceKm;
  final String bio;
  final List<String> interests;
  final String imageUrl;
  final int compatibility;
  final String tagline;
}

class MatchProfile {
  const MatchProfile({
    required this.id,
    required this.name,
    required this.distanceLabel,
    required this.imageUrl,
    required this.isOnline,
    required this.lastActiveLabel,
  });

  final String id;
  final String name;
  final String distanceLabel;
  final String imageUrl;
  final bool isOnline;
  final String lastActiveLabel;
}

class MessageThread {
  const MessageThread({
    required this.id,
    required this.matchId,
    required this.name,
    required this.imageUrl,
    required this.lastMessage,
    required this.timeLabel,
    required this.unreadCount,
    required this.isOnline,
  });

  final String id;
  final String matchId;
  final String name;
  final String imageUrl;
  final String lastMessage;
  final String timeLabel;
  final int unreadCount;
  final bool isOnline;

  MessageThread copyWith({
    String? lastMessage,
    String? timeLabel,
    int? unreadCount,
  }) {
    return MessageThread(
      id: id,
      matchId: matchId,
      name: name,
      imageUrl: imageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      timeLabel: timeLabel ?? this.timeLabel,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.text,
    required this.isMine,
    required this.timestamp,
  });

  final String id;
  final String threadId;
  final String text;
  final bool isMine;
  final DateTime timestamp;
}
