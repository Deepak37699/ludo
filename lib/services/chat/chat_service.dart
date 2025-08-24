import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/multiplayer_models.dart';

/// Service for handling chat functionality in multiplayer games
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream controllers
  final StreamController<List<ChatMessage>> _messagesController =
      StreamController<List<ChatMessage>>.broadcast();
  final StreamController<ChatMessage> _newMessageController =
      StreamController<ChatMessage>.broadcast();

  // Current room data
  String? _currentRoomId;
  List<ChatMessage> _messages = [];
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  // Getters
  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;
  Stream<ChatMessage> get newMessageStream => _newMessageController.stream;
  List<ChatMessage> get messages => _messages;

  /// Initialize chat for a room
  Future<void> initializeRoom(String roomId) async {
    _currentRoomId = roomId;
    _messages.clear();
    
    await _loadChatHistory();
    _listenToNewMessages();
    
    debugPrint('💬 Chat initialized for room: $roomId');
  }

  /// Load chat history from Firestore
  Future<void> _loadChatHistory() async {
    if (_currentRoomId == null) return;

    try {
      final snapshot = await _firestore
          .collection('rooms')
          .doc(_currentRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .limit(100) // Load last 100 messages
          .get();

      _messages = snapshot.docs
          .map((doc) => ChatMessage.fromJson(doc.data()))
          .toList();

      _messagesController.add(_messages);
    } catch (e) {
      debugPrint('❌ Error loading chat history: $e');
    }
  }

  /// Listen to new messages in real-time
  void _listenToNewMessages() {
    if (_currentRoomId == null) return;

    _messagesSubscription?.cancel();
    
    _messagesSubscription = _firestore
        .collection('rooms')
        .doc(_currentRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      for (final docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          final message = ChatMessage.fromJson(docChange.doc.data()!);
          
          // Only add if it's a new message (not from history)
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
            _newMessageController.add(message);
          }
        }
      }
      
      // Sort messages by timestamp
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Limit to maximum messages
      if (_messages.length > 200) {
        _messages = _messages.sublist(_messages.length - 200);
      }
      
      _messagesController.add(_messages);
    });
  }

  /// Send a text message
  Future<void> sendMessage(String message) async {
    if (_currentRoomId == null || message.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final chatMessage = ChatMessage(
      id: const Uuid().v4(),
      playerId: user.uid,
      playerName: user.displayName ?? 'Player',
      message: message.trim(),
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
    );

    try {
      await _firestore
          .collection('rooms')
          .doc(_currentRoomId)
          .collection('messages')
          .doc(chatMessage.id)
          .set(chatMessage.toJson());

      debugPrint('💬 Message sent: ${chatMessage.message}');
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      throw Exception('Failed to send message');
    }
  }

  /// Send a system message
  Future<void> sendSystemMessage(String message) async {
    if (_currentRoomId == null || message.trim().isEmpty) return;

    final chatMessage = ChatMessage(
      id: const Uuid().v4(),
      playerId: 'system',
      playerName: 'System',
      message: message.trim(),
      timestamp: DateTime.now(),
      type: ChatMessageType.system,
    );

    try {
      await _firestore
          .collection('rooms')
          .doc(_currentRoomId)
          .collection('messages')
          .doc(chatMessage.id)
          .set(chatMessage.toJson());

      debugPrint('💬 System message sent: ${chatMessage.message}');
    } catch (e) {
      debugPrint('❌ Error sending system message: $e');
    }
  }

  /// Send an emote message
  Future<void> sendEmote(String emote) async {
    if (_currentRoomId == null || emote.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final chatMessage = ChatMessage(
      id: const Uuid().v4(),
      playerId: user.uid,
      playerName: user.displayName ?? 'Player',
      message: emote.trim(),
      timestamp: DateTime.now(),
      type: ChatMessageType.emote,
    );

    try {
      await _firestore
          .collection('rooms')
          .doc(_currentRoomId)
          .collection('messages')
          .doc(chatMessage.id)
          .set(chatMessage.toJson());

      debugPrint('💬 Emote sent: ${chatMessage.message}');
    } catch (e) {
      debugPrint('❌ Error sending emote: $e');
      throw Exception('Failed to send emote');
    }
  }

  /// Clear chat messages
  Future<void> clearMessages() async {
    if (_currentRoomId == null) return;

    try {
      final batch = _firestore.batch();
      final messagesRef = _firestore
          .collection('rooms')
          .doc(_currentRoomId)
          .collection('messages');

      final snapshot = await messagesRef.get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      _messages.clear();
      _messagesController.add(_messages);
      
      debugPrint('💬 Chat messages cleared');
    } catch (e) {
      debugPrint('❌ Error clearing messages: $e');
      throw Exception('Failed to clear messages');
    }
  }

  /// Get recent messages
  List<ChatMessage> getRecentMessages([int count = 10]) {
    if (_messages.length <= count) return _messages;
    return _messages.sublist(_messages.length - count);
  }

  /// Get messages from a specific player
  List<ChatMessage> getMessagesFromPlayer(String playerId) {
    return _messages.where((message) => message.playerId == playerId).toList();
  }

  /// Get system messages
  List<ChatMessage> getSystemMessages() {
    return _messages
        .where((message) => message.type == ChatMessageType.system)
        .toList();
  }

  /// Check if player has sent messages recently (anti-spam)
  bool canSendMessage(String playerId, {Duration cooldown = const Duration(seconds: 2)}) {
    final recentMessages = _messages
        .where((message) => 
            message.playerId == playerId &&
            message.type == ChatMessageType.text &&
            DateTime.now().difference(message.timestamp) < cooldown)
        .toList();
    
    return recentMessages.length < 3; // Max 3 messages per cooldown period
  }

  /// Leave current room
  void leaveRoom() {
    _messagesSubscription?.cancel();
    _currentRoomId = null;
    _messages.clear();
    _messagesController.add(_messages);
    
    debugPrint('💬 Left chat room');
  }

  /// Dispose the service
  void dispose() {
    _messagesSubscription?.cancel();
    _messagesController.close();
    _newMessageController.close();
    
    debugPrint('💬 Chat service disposed');
  }
}

/// Pre-defined emotes for quick access
class ChatEmotes {
  static const List<String> emotes = [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '😊', '😇', '🙂', '😉', '😌', '😍', '🥰', '😘',
    '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪',
    '🤨', '🧐', '🤓', '😎', '🤩', '🥳', '😏', '😒',
    '😞', '😔', '😟', '😕', '🙁', '😣', '😖', '😫',
    '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬',
    '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥',
    '😓', '🤗', '🤔', '🤭', '🤫', '🤥', '😶', '😐',
    '😑', '😬', '🙄', '😯', '😦', '😧', '😮', '😲',
    '🥱', '😴', '🤤', '😪', '😵', '🤐', '🥴', '🤢',
    '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠', '😈',
    '👍', '👎', '👌', '🤞', '✌️', '🤟', '🤘', '🤙',
    '👈', '👉', '👆', '🖕', '👇', '☝️', '👋', '🤚',
    '🖐', '✋', '🖖', '👏', '🙌', '🤲', '🤝', '🙏',
    '💪', '🦾', '🦿', '🦵', '🦶', '👂', '🦻', '👃',
    '🎉', '🎊', '🏆', '🥇', '🥈', '🥉', '🏅', '🎖',
    '⭐', '🌟', '💫', '✨', '🔥', '💯', '💢', '💨',
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
    '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
    '💘', '💝', '💟', '♥️', '💌', '💋', '💍', '💎',
  ];

  static const List<String> gameEmotes = [
    '🎲', '🎯', '🏁', '🚀', '⚡', '🔥', '💥', '✨',
    '🎪', '🎨', '🎭', '🎪', '🎊', '🎉', '🏆', '🥇',
    '😤', '😎', '🤔', '🙄', '😅', '😂', '🤣', '😭',
    '👏', '🙌', '👍', '👎', '🤞', '🤝', '💪', '🔥',
  ];
}

/// Chat message filters and utilities
class ChatUtils {
  /// Filter out inappropriate content (basic implementation)
  static String filterMessage(String message) {
    // Basic profanity filter - in a real app, use a proper service
    const blockedWords = [
      'spam', 'fake', 'cheat', 'hack', 'bot', 'stupid', 'dumb'
    ];
    
    String filtered = message;
    for (final word in blockedWords) {
      filtered = filtered.replaceAll(
        RegExp(word, caseSensitive: false),
        '*' * word.length,
      );
    }
    
    return filtered;
  }

  /// Format timestamp for display
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  /// Get message color based on type
  static String getMessageTypeColor(ChatMessageType type) {
    switch (type) {
      case ChatMessageType.text:
        return '#000000';
      case ChatMessageType.system:
        return '#666666';
      case ChatMessageType.emote:
        return '#FF6B35';
    }
  }
}