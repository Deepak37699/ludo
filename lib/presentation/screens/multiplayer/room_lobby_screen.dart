import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/game_enums.dart';
import '../../../data/models/multiplayer_models.dart';
import '../../../data/models/player.dart';
import '../../providers/multiplayer_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../chat/chat_screen.dart';

/// Screen for room lobby where players wait before starting the game
class RoomLobbyScreen extends ConsumerStatefulWidget {
  const RoomLobbyScreen({super.key});

  @override
  ConsumerState<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends ConsumerState<RoomLobbyScreen> {
  bool _isReady = false;
  final TextEditingController _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize chat when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRoom = ref.read(currentRoomProvider);
      if (currentRoom != null) {
        ref.read(chatControllerProvider.notifier).initializeRoom(currentRoom.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final multiplayerState = ref.watch(multiplayerControllerProvider);
    final currentRoom = ref.watch(currentRoomProvider);
    final roomPlayers = ref.watch(roomPlayersProvider);
    final isHost = ref.watch(isHostProvider);

    // Listen to multiplayer events
    ref.listen(multiplayerEventsProvider, (previous, next) {
      next.when(
        data: (event) => _handleMultiplayerEvent(event),
        loading: () {},
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    if (currentRoom == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Room Lobby'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Room not found',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Please return to the room browser',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentRoom.name),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: isHost ? _showRoomSettings : null,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _showLeaveRoomDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Room information banner
          _buildRoomInfoBanner(currentRoom),
          
          // Players list
          Expanded(
            flex: 2,
            child: _buildPlayersList(roomPlayers),
          ),
          
          // Chat section
          Expanded(
            flex: 1,
            child: _buildChatSection(),
          ),
          
          // Control buttons
          _buildControlButtons(currentRoom, isHost),
        ],
      ),
    );
  }

  /// Handle multiplayer events
  void _handleMultiplayerEvent(MultiplayerEvent event) {
    switch (event.type) {
      case MultiplayerEventType.gameStarted:
        // Navigate to game screen
        Navigator.of(context).pushReplacementNamed('/game');
        break;
        
      case MultiplayerEventType.playerJoined:
        final player = event.data as Player;
        _showSnackBar('${player.name} joined the room', Colors.green);
        break;
        
      case MultiplayerEventType.playerLeft:
        _showSnackBar('A player left the room', Colors.orange);
        break;
        
      case MultiplayerEventType.roomFull:
        _showSnackBar('Room is now full!', Colors.blue);
        break;
        
      case MultiplayerEventType.error:
        _showSnackBar('Error: ${event.data}', Colors.red);
        break;
        
      default:
        break;
    }
  }

  /// Build room information banner
  Widget _buildRoomInfoBanner(GameRoom room) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.meeting_room, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                room.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (room.isPrivate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Private',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.gamepad, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                room.gameMode.displayName,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                '${room.players.length}/${room.maxPlayers} players',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build players list
  Widget _buildPlayersList(AsyncValue<List<Player>> roomPlayersAsync) {
    return roomPlayersAsync.when(
      data: (players) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Players',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${players.length} / 4',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: 4, // Always show 4 slots
                  itemBuilder: (context, index) {
                    if (index < players.length) {
                      return _buildPlayerCard(players[index], index);
                    } else {
                      return _buildEmptyPlayerSlot(index);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: LoadingWidget()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading players: $error'),
          ],
        ),
      ),
    );
  }

  /// Build individual player card
  Widget _buildPlayerCard(Player player, int index) {
    final playerColors = [Colors.red, Colors.blue, Colors.green, Colors.yellow];
    final color = playerColors[index % playerColors.length];
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(
          Icons.person,
          color: color,
        ),
      ),
      title: Text(
        player.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          if (player.isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Host',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (player.isReady && !player.isHost) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Ready',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: player.isHost
          ? const Icon(Icons.star, color: Colors.orange)
          : player.isReady
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.schedule, color: Colors.grey),
    );
  }

  /// Build empty player slot
  Widget _buildEmptyPlayerSlot(int index) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey.withOpacity(0.2),
        child: Icon(
          Icons.person_add,
          color: Colors.grey.shade400,
        ),
      ),
      title: Text(
        'Waiting for player...',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      ),
      subtitle: Text(
        'Slot ${index + 1}',
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Build chat section
  Widget _buildChatSection() {
    final chatState = ref.watch(chatControllerProvider);
    final recentMessages = chatState.recentMessages;
    
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.chat, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ChatScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: recentMessages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: recentMessages.length,
                      itemBuilder: (context, index) {
                        final message = recentMessages[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black87, fontSize: 12),
                              children: [
                                TextSpan(
                                  text: '${message.playerName}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                TextSpan(text: message.message),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 1,
                    onSubmitted: _sendChatMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _sendChatMessage(_chatController.text),
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build control buttons
  Widget _buildControlButtons(GameRoom room, bool isHost) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          if (!isHost) ...[
            // Ready button for non-host players
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleReady,
                icon: Icon(_isReady ? Icons.check_circle : Icons.schedule),
                label: Text(_isReady ? 'Ready!' : 'Ready?'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isReady ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            // Start game button for host
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canStartGame(room) ? _startGame : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (!_canStartGame(room))
              Text(
                'Need at least 2 players to start',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
          ],
          const SizedBox(height: 8),
          // Leave room button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showLeaveRoomDialog,
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Leave Room'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if game can be started
  bool _canStartGame(GameRoom room) {
    return room.players.length >= 2 && 
           room.players.where((p) => !p.isHost).every((p) => p.isReady);
  }

  /// Toggle ready state
  void _toggleReady() {
    setState(() {
      _isReady = !_isReady;
    });
    
    // Send ready state to server
    ref.read(multiplayerControllerProvider.notifier).updatePlayerReady(_isReady);
  }

  /// Start the game
  void _startGame() {
    ref.read(multiplayerControllerProvider.notifier).startGame();
  }

  /// Send chat message
  void _sendChatMessage(String message) {
    if (message.trim().isEmpty) return;
    
    ref.read(chatControllerProvider.notifier).sendMessage(message.trim());
    _chatController.clear();
  }

  /// Show room settings dialog
  void _showRoomSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Room Settings'),
        content: const Text('Room settings functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show leave room confirmation dialog
  void _showLeaveRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room'),
        content: const Text('Are you sure you want to leave this room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveRoom();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  /// Leave the room
  void _leaveRoom() {
    ref.read(multiplayerControllerProvider.notifier).leaveRoom();
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/multiplayer',
      (route) => false,
    );
  }

  /// Show snack bar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}