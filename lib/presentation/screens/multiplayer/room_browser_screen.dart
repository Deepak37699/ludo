import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/game_enums.dart';
import '../../../services/multiplayer/multiplayer_service.dart';
import '../../providers/multiplayer_provider.dart';

/// Screen for browsing and joining multiplayer rooms
class MultiplayerRoomBrowserScreen extends ConsumerStatefulWidget {
  const MultiplayerRoomBrowserScreen({super.key});

  @override
  ConsumerState<MultiplayerRoomBrowserScreen> createState() => _MultiplayerRoomBrowserScreenState();
}

class _MultiplayerRoomBrowserScreenState extends ConsumerState<MultiplayerRoomBrowserScreen> {
  GameMode? _selectedGameMode;
  bool _showPrivateRooms = false;
  int? _selectedMaxPlayers;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _loadRooms() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(multiplayerControllerProvider.notifier).findRooms(
        gameMode: _selectedGameMode,
        isPrivate: _showPrivateRooms ? true : null,
        maxPlayers: _selectedMaxPlayers,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final multiplayerState = ref.watch(multiplayerControllerProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer Rooms'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRooms,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateRoomDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConnectionStatus(connectionStatus),
          _buildFilters(),
          Expanded(child: _buildRoomsList(multiplayerState)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _quickMatch,
        icon: const Icon(Icons.flash_on),
        label: const Text('Quick Match'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Build connection status bar
  Widget _buildConnectionStatus(String status) {
    final isConnected = status == 'Connected';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isConnected ? Colors.green.shade100 : Colors.orange.shade100,
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: isConnected ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: isConnected ? Colors.green.shade800 : Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isConnected) ...[
            const Spacer(),
            TextButton(
              onPressed: () => ref.read(multiplayerControllerProvider.notifier).connect(),
              child: const Text('Reconnect'),
            ),
          ],
        ],
      ),
    );
  }

  /// Build filter section
  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Game Mode Filter
            DropdownButtonFormField<GameMode>(
              value: _selectedGameMode,
              decoration: const InputDecoration(
                labelText: 'Game Mode',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Modes'),
                ),
                ...GameMode.values.map((mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(mode.displayName),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGameMode = value;
                });
                _loadRooms();
              },
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Max Players Filter
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMaxPlayers,
                    decoration: const InputDecoration(
                      labelText: 'Max Players',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Any'),
                      ),
                      ...List.generate(4, (index) => DropdownMenuItem(
                        value: index + 2,
                        child: Text('${index + 2} Players'),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMaxPlayers = value;
                      });
                      _loadRooms();
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Private Rooms Filter
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Include Private'),
                    value: _showPrivateRooms,
                    onChanged: (value) {
                      setState(() {
                        _showPrivateRooms = value ?? false;
                      });
                      _loadRooms();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build rooms list
  Widget _buildRoomsList(MultiplayerState state) {
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRooms,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.availableRooms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No rooms found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Create a new room or try adjusting your filters',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.availableRooms.length,
      itemBuilder: (context, index) {
        final room = state.availableRooms[index];
        return _buildRoomCard(room);
      },
    );
  }

  /// Build individual room card
  Widget _buildRoomCard(GameRoom room) {
    final canJoin = room.canJoin;
    final playerCount = room.players.length;
    final maxPlayers = room.maxPlayers;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: InkWell(
        onTap: canJoin ? () => _joinRoom(room) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Host: ${room.hostName}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Room status badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildRoomStatusChip(room.status),
                      const SizedBox(height: 4),
                      if (room.isPrivate)
                        const Chip(
                          label: Text('Private', style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(horizontal: 4),
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '$playerCount/$maxPlayers players',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.gamepad, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    room.gameMode.displayName,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Players list
              if (room.players.isNotEmpty) ...[
                const Text(
                  'Players:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: room.players.map((player) => Chip(
                    label: Text(
                      player.name,
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: _getPlayerColor(player.color).withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  )).toList(),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Join button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canJoin ? () => _joinRoom(room) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canJoin ? Colors.blue : Colors.grey,
                  ),
                  child: Text(
                    canJoin ? 'Join Room' : room.isFull ? 'Room Full' : 'Cannot Join',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build room status chip
  Widget _buildRoomStatusChip(RoomStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case RoomStatus.waiting:
        color = Colors.green;
        text = 'Waiting';
        break;
      case RoomStatus.playing:
        color = Colors.orange;
        text = 'Playing';
        break;
      case RoomStatus.finished:
        color = Colors.blue;
        text = 'Finished';
        break;
      case RoomStatus.closed:
        color = Colors.red;
        text = 'Closed';
        break;
    }
    
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  /// Get player color
  Color _getPlayerColor(PlayerColor playerColor) {
    switch (playerColor) {
      case PlayerColor.red:
        return Colors.red;
      case PlayerColor.blue:
        return Colors.blue;
      case PlayerColor.green:
        return Colors.green;
      case PlayerColor.yellow:
        return Colors.yellow;
    }
  }

  /// Join a room
  void _joinRoom(GameRoom room) {
    if (room.hasPassword) {
      _showPasswordDialog(room);
    } else {
      ref.read(multiplayerControllerProvider.notifier).joinRoom(room.id);
    }
  }

  /// Show password dialog
  void _showPasswordDialog(GameRoom room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join ${room.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This room requires a password:'),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(multiplayerControllerProvider.notifier).joinRoom(
                room.id,
                password: _passwordController.text,
              );
              _passwordController.clear();
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  /// Show create room dialog
  void _showCreateRoomDialog() {
    Navigator.of(context).pushNamed('/create-room');
  }

  /// Quick match
  void _quickMatch() {
    ref.read(multiplayerControllerProvider.notifier).quickMatch(
      gameMode: _selectedGameMode ?? GameMode.onlineMultiplayer,
    );
  }
}