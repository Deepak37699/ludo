import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/multiplayer_models.dart';
import '../../../services/chat/chat_service.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/loading_widget.dart';

/// Full-featured chat screen for multiplayer sessions
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  bool _showEmotes = false;
  bool _autoScroll = true;
  
  late AnimationController _emoteAnimationController;
  late Animation<double> _emoteAnimation;

  @override
  void initState() {
    super.initState();
    
    _emoteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _emoteAnimation = CurvedAnimation(
      parent: _emoteAnimationController,
      curve: Curves.easeInOut,
    );
    
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _emoteAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if user is near bottom for auto-scroll
    final isNearBottom = _scrollController.position.maxScrollExtent - 
        _scrollController.position.pixels < 100;
    
    if (_autoScroll != isNearBottom) {
      setState(() {
        _autoScroll = isNearBottom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final messagesAsync = ref.watch(chatMessagesProvider);
    final canSendMessage = ref.watch(canSendMessageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: _showPlayersList,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Messages'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Chat Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status banner
          if (chatState.error != null) _buildErrorBanner(chatState.error!),
          
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessagesList(messages),
              loading: () => const Center(child: LoadingWidget()),
              error: (error, stackTrace) => _buildErrorState(error.toString()),
            ),
          ),
          
          // Emote picker
          if (_showEmotes) _buildEmotePicker(),
          
          // Message input
          _buildMessageInput(canSendMessage),
        ],
      ),
      floatingActionButton: _autoScroll ? null : FloatingActionButton.mini(
        onPressed: _scrollToBottom,
        child: const Icon(Icons.keyboard_arrow_down),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Build error banner
  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => ref.read(chatControllerProvider.notifier).clearError(),
            color: Colors.red.shade700,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  /// Build messages list
  Widget _buildMessagesList(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoScroll && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final previousMessage = index > 0 ? messages[index - 1] : null;
        final showHeader = _shouldShowMessageHeader(message, previousMessage);
        
        return _buildMessageItem(message, showHeader);
      },
    );
  }

  /// Build individual message item
  Widget _buildMessageItem(ChatMessage message, bool showHeader) {
    final isSystem = message.type == ChatMessageType.system;
    final isEmote = message.type == ChatMessageType.emote;
    
    if (isSystem) {
      return _buildSystemMessage(message);
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) _buildMessageHeader(message),
          _buildMessageBubble(message, isEmote),
        ],
      ),
    );
  }

  /// Build message header (sender name and timestamp)
  Widget _buildMessageHeader(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
      child: Row(
        children: [
          Text(
            message.playerName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            ChatUtils.formatTimestamp(message.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build message bubble
  Widget _buildMessageBubble(ChatMessage message, bool isEmote) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isEmote ? Colors.orange.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: isEmote ? Border.all(color: Colors.orange.shade200) : null,
      ),
      child: Text(
        message.message,
        style: TextStyle(
          fontSize: isEmote ? 16 : 14,
          color: isEmote ? Colors.orange.shade700 : Colors.black87,
        ),
      ),
    );
  }

  /// Build system message
  Widget _buildSystemMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message.message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Build emote picker
  Widget _buildEmotePicker() {
    return AnimatedBuilder(
      animation: _emoteAnimation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _emoteAnimation,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(text: 'Emojis'),
                      Tab(text: 'Game'),
                    ],
                    labelColor: Colors.blue.shade700,
                    indicatorColor: Colors.blue.shade700,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildEmoteGrid(ChatEmotes.emotes),
                        _buildEmoteGrid(ChatEmotes.gameEmotes),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build emote grid
  Widget _buildEmoteGrid(List<String> emotes) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: emotes.length,
      itemBuilder: (context, index) {
        final emote = emotes[index];
        return InkWell(
          onTap: () => _sendEmote(emote),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                emote,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build message input
  Widget _buildMessageInput(bool canSendMessage) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Emote button
            IconButton(
              icon: Icon(
                _showEmotes ? Icons.keyboard : Icons.emoji_emotions,
                color: Colors.blue.shade700,
              ),
              onPressed: _toggleEmotes,
            ),
            
            // Message input field
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.blue.shade700),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: canSendMessage ? _sendMessage : null,
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            IconButton(
              icon: Icon(
                Icons.send,
                color: canSendMessage ? Colors.blue.shade700 : Colors.grey,
              ),
              onPressed: canSendMessage ? () => _sendMessage(_messageController.text) : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading chat',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Retry connection
              ref.invalidate(chatMessagesProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Check if message header should be shown
  bool _shouldShowMessageHeader(ChatMessage current, ChatMessage? previous) {
    if (previous == null) return true;
    if (current.playerId != previous.playerId) return true;
    
    final timeDiff = current.timestamp.difference(previous.timestamp);
    return timeDiff.inMinutes > 5; // Show header if messages are 5+ minutes apart
  }

  /// Toggle emote picker
  void _toggleEmotes() {
    setState(() {
      _showEmotes = !_showEmotes;
    });
    
    if (_showEmotes) {
      _emoteAnimationController.forward();
      _focusNode.unfocus();
    } else {
      _emoteAnimationController.reverse();
    }
  }

  /// Send text message
  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;
    
    ref.read(chatControllerProvider.notifier).sendMessage(message.trim());
    _messageController.clear();
    
    // Hide emotes if shown
    if (_showEmotes) {
      _toggleEmotes();
    }
  }

  /// Send emote
  void _sendEmote(String emote) {
    ref.read(chatControllerProvider.notifier).sendEmote(emote);
    
    // Hide emote picker
    _toggleEmotes();
  }

  /// Scroll to bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear':
        _showClearConfirmDialog();
        break;
      case 'settings':
        _showChatSettings();
        break;
    }
  }

  /// Show clear messages confirmation dialog
  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Messages'),
        content: const Text('Are you sure you want to clear all chat messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(chatControllerProvider.notifier).clearMessages();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  /// Show players list
  void _showPlayersList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Players in Chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Show list of players
            const Text('Players list coming soon!'),
          ],
        ),
      ),
    );
  }

  /// Show chat settings
  void _showChatSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chat Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Add chat settings
            const Text('Chat settings coming soon!'),
          ],
        ),
      ),
    );
  }
}