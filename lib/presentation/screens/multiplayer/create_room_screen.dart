import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/game_enums.dart';
import '../../providers/multiplayer_provider.dart';

/// Screen for creating a new multiplayer room
class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  GameMode _selectedGameMode = GameMode.onlineMultiplayer;
  int _maxPlayers = 4;
  bool _isPrivate = false;
  bool _hasPassword = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _roomNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to multiplayer state changes
    ref.listen(multiplayerControllerProvider, (previous, next) {
      if (previous?.isInRoom != next.isInRoom && next.isInRoom) {
        // Room created successfully, navigate to room lobby
        Navigator.of(context).pushReplacementNamed('/room-lobby');
      }
      
      if (next.error != null && previous?.error != next.error) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final multiplayerState = ref.watch(multiplayerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Room'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRoomBasicInfo(),
            const SizedBox(height: 24),
            _buildGameSettings(),
            const SizedBox(height: 24),
            _buildPrivacySettings(),
            const SizedBox(height: 32),
            _buildCreateButton(multiplayerState),
          ],
        ),
      ),
    );
  }

  /// Build room basic information section
  Widget _buildRoomBasicInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Room Name
            TextFormField(
              controller: _roomNameController,
              decoration: const InputDecoration(
                labelText: 'Room Name *',
                hintText: 'Enter a name for your room',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.meeting_room),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Room name is required';
                }
                if (value.trim().length < 3) {
                  return 'Room name must be at least 3 characters';
                }
                if (value.trim().length > 30) {
                  return 'Room name must be less than 30 characters';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Game Mode Selection
            DropdownButtonFormField<GameMode>(
              value: _selectedGameMode,
              decoration: const InputDecoration(
                labelText: 'Game Mode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.gamepad),
              ),
              items: GameMode.values.map((mode) => DropdownMenuItem(
                value: mode,
                child: Row(
                  children: [
                    _getGameModeIcon(mode),
                    const SizedBox(width: 8),
                    Text(mode.displayName),
                  ],
                ),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedGameMode = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build game settings section
  Widget _buildGameSettings() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Max Players
            Row(
              children: [
                const Icon(Icons.people, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Maximum Players',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Currently: $_maxPlayers players',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Slider(
              value: _maxPlayers.toDouble(),
              min: 2,
              max: 4,
              divisions: 2,
              label: '$_maxPlayers players',
              onChanged: (value) {
                setState(() {
                  _maxPlayers = value.round();
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Player slots preview
            _buildPlayerSlotsPreview(),
          ],
        ),
      ),
    );
  }

  /// Build privacy settings section
  Widget _buildPrivacySettings() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Private Room Toggle
            SwitchListTile(
              title: const Text('Private Room'),
              subtitle: Text(
                _isPrivate 
                    ? 'Only players with the room ID can join'
                    : 'Room will appear in public listings',
              ),
              value: _isPrivate,
              onChanged: (value) {
                setState(() {
                  _isPrivate = value;
                });
              },
              secondary: Icon(
                _isPrivate ? Icons.lock : Icons.public,
                color: _isPrivate ? Colors.orange : Colors.blue,
              ),
            ),
            
            const Divider(),
            
            // Password Protection Toggle
            SwitchListTile(
              title: const Text('Password Protection'),
              subtitle: Text(
                _hasPassword 
                    ? 'Players need a password to join'
                    : 'Anyone can join the room',
              ),
              value: _hasPassword,
              onChanged: (value) {
                setState(() {
                  _hasPassword = value;
                });
              },
              secondary: Icon(
                _hasPassword ? Icons.lock_outline : Icons.lock_open,
                color: _hasPassword ? Colors.red : Colors.green,
              ),
            ),
            
            // Password Field
            if (_hasPassword) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Room Password',
                  hintText: 'Enter a password for your room',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
                validator: (value) {
                  if (_hasPassword && (value == null || value.trim().isEmpty)) {
                    return 'Password is required when password protection is enabled';
                  }
                  if (_hasPassword && value!.trim().length < 4) {
                    return 'Password must be at least 4 characters';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build player slots preview
  Widget _buildPlayerSlotsPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Player Slots Preview:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: List.generate(4, (index) {
              final isActive = index < _maxPlayers;
              final isHost = index == 0;
              
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? (isHost ? Colors.blue.shade100 : Colors.green.shade100)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isActive 
                          ? (isHost ? Colors.blue : Colors.green)
                          : Colors.grey,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isHost ? Icons.star : Icons.person,
                        color: isActive 
                            ? (isHost ? Colors.blue : Colors.green)
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHost ? 'Host' : isActive ? 'Player' : 'Empty',
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive 
                              ? (isHost ? Colors.blue : Colors.green)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Build create button
  Widget _buildCreateButton(MultiplayerState state) {
    final isConnected = state.isConnected;
    final isCreating = state.isConnecting || _isCreating;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isConnected && !isCreating ? _createRoom : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isCreating 
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Creating Room...'),
                ],
              )
            : Text(
                isConnected ? 'Create Room' : 'Not Connected',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  /// Get game mode icon
  Widget _getGameModeIcon(GameMode mode) {
    IconData iconData;
    Color color;
    
    switch (mode) {
      case GameMode.singlePlayer:
        iconData = Icons.person;
        color = Colors.blue;
        break;
      case GameMode.localMultiplayer:
        iconData = Icons.people;
        color = Colors.green;
        break;
      case GameMode.onlineMultiplayer:
        iconData = Icons.public;
        color = Colors.orange;
        break;
      case GameMode.quickPlay:
        iconData = Icons.flash_on;
        color = Colors.red;
        break;
    }
    
    return Icon(iconData, color: color, size: 20);
  }

  /// Create room
  void _createRoom() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    ref.read(multiplayerControllerProvider.notifier).createRoom(
      roomName: _roomNameController.text.trim(),
      gameMode: _selectedGameMode,
      maxPlayers: _maxPlayers,
      isPrivate: _isPrivate,
      password: _hasPassword ? _passwordController.text.trim() : null,
    ).then((_) {
      setState(() {
        _isCreating = false;
      });
    }).catchError((error) {
      setState(() {
        _isCreating = false;
      });
    });
  }
}