import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/multiplayer_models.dart';
import '../../services/chat/chat_service.dart';

/// Provider for chat service
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Provider for chat messages stream
final chatMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  final service = ref.watch(chatServiceProvider);
  return service.messagesStream;
});

/// Provider for new message notifications
final newChatMessageProvider = StreamProvider<ChatMessage>((ref) {
  final service = ref.watch(chatServiceProvider);
  return service.newMessageStream;
});

/// Provider for chat controller
final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(ref);
});

/// Chat state
class ChatState {
  final bool isLoading;
  final bool isConnected;
  final String? error;
  final String? currentRoomId;
  final List<ChatMessage> messages;
  final List<ChatMessage> recentMessages;
  final bool canSendMessage;
  final DateTime? lastMessageTime;

  const ChatState({
    this.isLoading = false,
    this.isConnected = false,
    this.error,
    this.currentRoomId,
    this.messages = const [],
    this.recentMessages = const [],
    this.canSendMessage = true,
    this.lastMessageTime,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isConnected,
    String? error,
    String? currentRoomId,
    List<ChatMessage>? messages,
    List<ChatMessage>? recentMessages,
    bool? canSendMessage,
    DateTime? lastMessageTime,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      error: error,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      messages: messages ?? this.messages,
      recentMessages: recentMessages ?? this.recentMessages,
      canSendMessage: canSendMessage ?? this.canSendMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}

/// Chat controller
class ChatController extends StateNotifier<ChatState> {
  final Ref _ref;
  late final ChatService _service;

  ChatController(this._ref) : super(const ChatState()) {
    _service = _ref.read(chatServiceProvider);
    _initializeListeners();
  }

  /// Initialize listeners
  void _initializeListeners() {
    // Listen to chat messages
    _ref.listen(chatMessagesProvider, (previous, next) {
      next.when(
        data: (messages) {
          state = state.copyWith(
            messages: messages,
            recentMessages: _service.getRecentMessages(5),
            isLoading: false,
            error: null,
          );
        },
        loading: () {
          state = state.copyWith(isLoading: true);
        },
        error: (error, stackTrace) {
          state = state.copyWith(
            error: error.toString(),
            isLoading: false,
          );
        },
      );
    });

    // Listen to new messages for notifications
    _ref.listen(newChatMessageProvider, (previous, next) {
      next.when(
        data: (message) {
          // Handle new message notification
          debugPrint('💬 New message: ${message.message}');
        },
        loading: () {},
        error: (error, stackTrace) {
          debugPrint('❌ Error receiving new message: $error');
        },
      );
    });
  }

  /// Initialize chat for a room
  Future<void> initializeRoom(String roomId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _service.initializeRoom(roomId);
      
      state = state.copyWith(
        currentRoomId: roomId,
        isConnected: true,
        isLoading: false,
      );
      
      debugPrint('💬 Chat initialized for room: $roomId');
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Send a text message
  Future<void> sendMessage(String message) async {
    if (!_canSendMessage()) {
      state = state.copyWith(error: 'Please wait before sending another message');
      return;
    }

    try {
      await _service.sendMessage(message);
      
      state = state.copyWith(
        lastMessageTime: DateTime.now(),
        error: null,
      );
      
      // Update send cooldown
      _updateSendCooldown();
      
      debugPrint('💬 Message sent successfully');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Send an emote
  Future<void> sendEmote(String emote) async {
    if (!_canSendMessage()) {
      state = state.copyWith(error: 'Please wait before sending another emote');
      return;
    }

    try {
      await _service.sendEmote(emote);
      
      state = state.copyWith(
        lastMessageTime: DateTime.now(),
        error: null,
      );
      
      // Update send cooldown
      _updateSendCooldown();
      
      debugPrint('💬 Emote sent successfully');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Send system message (admin only)
  Future<void> sendSystemMessage(String message) async {
    try {
      await _service.sendSystemMessage(message);
      debugPrint('💬 System message sent successfully');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear chat messages
  Future<void> clearMessages() async {
    try {
      state = state.copyWith(isLoading: true);
      
      await _service.clearMessages();
      
      state = state.copyWith(
        messages: [],
        recentMessages: [],
        isLoading: false,
        error: null,
      );
      
      debugPrint('💬 Messages cleared successfully');
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Get messages from a specific player
  List<ChatMessage> getMessagesFromPlayer(String playerId) {
    return _service.getMessagesFromPlayer(playerId);
  }

  /// Get system messages
  List<ChatMessage> getSystemMessages() {
    return _service.getSystemMessages();
  }

  /// Leave current room
  void leaveRoom() {
    _service.leaveRoom();
    
    state = state.copyWith(
      currentRoomId: null,
      isConnected: false,
      messages: [],
      recentMessages: [],
      error: null,
    );
    
    debugPrint('💬 Left chat room');
  }

  /// Check if user can send message (anti-spam)
  bool _canSendMessage() {
    if (state.lastMessageTime == null) return true;
    
    final timeDiff = DateTime.now().difference(state.lastMessageTime!);
    return timeDiff.inSeconds >= 2; // 2 second cooldown
  }

  /// Update send message cooldown
  void _updateSendCooldown() {
    state = state.copyWith(canSendMessage: false);
    
    // Re-enable after cooldown
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        state = state.copyWith(canSendMessage: true);
      }
    });
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for checking if user can send messages
final canSendMessageProvider = Provider<bool>((ref) {
  final state = ref.watch(chatControllerProvider);
  return state.canSendMessage;
});

/// Provider for recent messages count
final recentMessagesCountProvider = Provider<int>((ref) {
  final state = ref.watch(chatControllerProvider);
  return state.recentMessages.length;
});

/// Provider for unread messages (messages received while chat is closed)
final unreadMessagesProvider = StateProvider<int>((ref) => 0);

/// Provider for chat connection status
final chatConnectionStatusProvider = Provider<String>((ref) {
  final state = ref.watch(chatControllerProvider);
  
  if (state.isLoading) return 'Connecting...';
  if (state.isConnected) return 'Connected';
  if (state.error != null) return 'Error';
  return 'Disconnected';
});

/// Provider for filtering messages by type
final messagesByTypeProvider = Provider.family<List<ChatMessage>, ChatMessageType>((ref, type) {
  final state = ref.watch(chatControllerProvider);
  return state.messages.where((message) => message.type == type).toList();
});

/// Provider for player message history
final playerMessageHistoryProvider = Provider.family<List<ChatMessage>, String>((ref, playerId) {
  final controller = ref.watch(chatControllerProvider.notifier);
  return controller.getMessagesFromPlayer(playerId);
});