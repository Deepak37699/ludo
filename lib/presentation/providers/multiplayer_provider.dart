import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/game_state.dart';
import '../../data/models/player.dart';
import '../../data/models/position.dart';
import '../../data/models/multiplayer_models.dart';
import '../../core/enums/game_enums.dart';
import '../../services/multiplayer/multiplayer_service.dart';

/// Provider for multiplayer service
final multiplayerServiceProvider = Provider<MultiplayerService>((ref) {
  return MultiplayerService();
});

/// Provider for connection state
final connectionStateProvider = StreamProvider<ConnectionState>((ref) {
  final service = ref.watch(multiplayerServiceProvider);
  return service.connectionStream;
});

/// Provider for current room
final currentRoomProvider = StateProvider<GameRoom?>((ref) => null);

/// Provider for room players
final roomPlayersProvider = StreamProvider<List<Player>>((ref) {
  final service = ref.watch(multiplayerServiceProvider);
  return service.playersStream;
});

/// Provider for multiplayer game state
final multiplayerGameStateProvider = StreamProvider<GameState>((ref) {
  final service = ref.watch(multiplayerServiceProvider);
  return service.gameStateStream;
});

/// Provider for multiplayer events
final multiplayerEventsProvider = StreamProvider<MultiplayerEvent>((ref) {
  final service = ref.watch(multiplayerServiceProvider);
  return service.eventStream;
});

/// Provider for multiplayer controller
final multiplayerControllerProvider = StateNotifierProvider<MultiplayerController, MultiplayerState>((ref) {
  return MultiplayerController(ref);
});

/// Multiplayer state
class MultiplayerState {
  final bool isConnected;
  final bool isConnecting;
  final bool isInRoom;
  final GameRoom? currentRoom;
  final List<GameRoom> availableRooms;
  final String? error;
  final bool isSearchingForMatch;
  final ConnectionState connectionState;

  const MultiplayerState({
    this.isConnected = false,
    this.isConnecting = false,
    this.isInRoom = false,
    this.currentRoom,
    this.availableRooms = const [],
    this.error,
    this.isSearchingForMatch = false,
    this.connectionState = ConnectionState.disconnected,
  });

  MultiplayerState copyWith({
    bool? isConnected,
    bool? isConnecting,
    bool? isInRoom,
    GameRoom? currentRoom,
    List<GameRoom>? availableRooms,
    String? error,
    bool? isSearchingForMatch,
    ConnectionState? connectionState,
  }) {
    return MultiplayerState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      isInRoom: isInRoom ?? this.isInRoom,
      currentRoom: currentRoom ?? this.currentRoom,
      availableRooms: availableRooms ?? this.availableRooms,
      error: error,
      isSearchingForMatch: isSearchingForMatch ?? this.isSearchingForMatch,
      connectionState: connectionState ?? this.connectionState,
    );
  }
}

/// Multiplayer controller
class MultiplayerController extends StateNotifier<MultiplayerState> {
  final Ref _ref;
  late final MultiplayerService _service;

  MultiplayerController(this._ref) : super(const MultiplayerState()) {
    _service = _ref.read(multiplayerServiceProvider);
    _initializeListeners();
  }

  /// Initialize listeners
  void _initializeListeners() {
    // Listen to connection state changes
    _ref.listen(connectionStateProvider, (previous, next) {
      next.when(
        data: (connectionState) {
          state = state.copyWith(
            connectionState: connectionState,
            isConnected: connectionState == ConnectionState.connected,
            isConnecting: connectionState == ConnectionState.connecting,
          );
        },
        loading: () {
          state = state.copyWith(isConnecting: true);
        },
        error: (error, stackTrace) {
          state = state.copyWith(
            error: error.toString(),
            isConnecting: false,
            isConnected: false,
          );
        },
      );
    });

    // Listen to multiplayer events
    _ref.listen(multiplayerEventsProvider, (previous, next) {
      next.when(
        data: (event) => _handleMultiplayerEvent(event),
        loading: () {},
        error: (error, stackTrace) {
          state = state.copyWith(error: error.toString());
        },
      );
    });
  }

  /// Handle multiplayer events
  void _handleMultiplayerEvent(MultiplayerEvent event) {
    switch (event.type) {
      case MultiplayerEventType.roomJoined:
        final room = event.data as GameRoom;
        state = state.copyWith(
          currentRoom: room,
          isInRoom: true,
          error: null,
        );
        _ref.read(currentRoomProvider.notifier).state = room;
        break;

      case MultiplayerEventType.roomLeft:
        state = state.copyWith(
          currentRoom: null,
          isInRoom: false,
        );
        _ref.read(currentRoomProvider.notifier).state = null;
        break;

      case MultiplayerEventType.playerJoined:
        final player = event.data as Player;
        debugPrint('👤 Player joined: ${player.name}');
        break;

      case MultiplayerEventType.playerLeft:
        debugPrint('👤 Player left room');
        break;

      case MultiplayerEventType.roomFull:
        state = state.copyWith(
          error: 'Room is full',
          isSearchingForMatch: false,
        );
        break;

      case MultiplayerEventType.gameStarted:
        debugPrint('🎮 Game started!');
        break;

      case MultiplayerEventType.error:
        state = state.copyWith(
          error: event.data.toString(),
          isSearchingForMatch: false,
        );
        break;

      default:
        break;
    }
  }

  /// Connect to multiplayer server
  Future<void> connect() async {
    try {
      state = state.copyWith(isConnecting: true, error: null);
      await _service.connect();
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        error: e.toString(),
      );
    }
  }

  /// Disconnect from multiplayer server
  Future<void> disconnect() async {
    try {
      await _service.disconnect();
      state = state.copyWith(
        isConnected: false,
        isInRoom: false,
        currentRoom: null,
        isSearchingForMatch: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Create a new room
  Future<void> createRoom({
    required String roomName,
    required GameMode gameMode,
    int maxPlayers = 4,
    bool isPrivate = false,
    String? password,
  }) async {
    try {
      state = state.copyWith(error: null);
      
      final room = await _service.createRoom(
        roomName: roomName,
        gameMode: gameMode,
        maxPlayers: maxPlayers,
        isPrivate: isPrivate,
        password: password,
      );

      state = state.copyWith(
        currentRoom: room,
        isInRoom: true,
      );
      
      _ref.read(currentRoomProvider.notifier).state = room;
      
      debugPrint('🏠 Room created: ${room.name}');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Join a room
  Future<void> joinRoom(String roomId, {String? password}) async {
    try {
      state = state.copyWith(error: null);
      
      final room = await _service.joinRoom(roomId, password: password);
      
      state = state.copyWith(
        currentRoom: room,
        isInRoom: true,
      );
      
      _ref.read(currentRoomProvider.notifier).state = room;
      
      debugPrint('🚪 Joined room: ${room.name}');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Leave current room
  Future<void> leaveRoom() async {
    try {
      await _service.leaveRoom();
      
      state = state.copyWith(
        currentRoom: null,
        isInRoom: false,
      );
      
      _ref.read(currentRoomProvider.notifier).state = null;
      
      debugPrint('🚪 Left room');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Start game (host only)
  Future<void> startGame() async {
    try {
      await _service.startGame();
      debugPrint('🎮 Starting game...');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Find available rooms
  Future<void> findRooms({
    GameMode? gameMode,
    bool? isPrivate,
    int? maxPlayers,
  }) async {
    try {
      state = state.copyWith(error: null);
      
      final rooms = await _service.findRooms(
        gameMode: gameMode,
        isPrivate: isPrivate,
        maxPlayers: maxPlayers,
      );
      
      state = state.copyWith(availableRooms: rooms);
      
      debugPrint('🔍 Found ${rooms.length} rooms');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Quick match
  Future<void> quickMatch({GameMode gameMode = GameMode.onlineMultiplayer}) async {
    try {
      state = state.copyWith(
        error: null,
        isSearchingForMatch: true,
      );
      
      final room = await _service.quickMatch(gameMode: gameMode);
      
      state = state.copyWith(
        currentRoom: room,
        isInRoom: true,
        isSearchingForMatch: false,
      );
      
      _ref.read(currentRoomProvider.notifier).state = room;
      
      debugPrint('⚡ Quick match found: ${room.name}');
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isSearchingForMatch: false,
      );
    }
  }

  /// Make a move
  Future<void> makeMove({
    required String tokenId,
    required Position fromPosition,
    required Position toPosition,
    required int diceValue,
  }) async {
    try {
      await _service.makeMove(
        tokenId: tokenId,
        fromPosition: fromPosition,
        toPosition: toPosition,
        diceValue: diceValue,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Roll dice
  Future<void> rollDice() async {
    try {
      await _service.rollDice();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update game state
  Future<void> updateGameState(GameState gameState) async {
    try {
      await _service.updateGameState(gameState);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update player ready state
  Future<void> updatePlayerReady(bool isReady) async {
    try {
      await _service.updatePlayerReady(isReady);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Cancel search
  void cancelSearch() {
    state = state.copyWith(isSearchingForMatch: false);
  }
}

/// Provider for checking if user is connected
final isConnectedProvider = Provider<bool>((ref) {
  final state = ref.watch(multiplayerControllerProvider);
  return state.isConnected;
});

/// Provider for checking if user is in room
final isInRoomProvider = Provider<bool>((ref) {
  final state = ref.watch(multiplayerControllerProvider);
  return state.isInRoom;
});

/// Provider for checking if user is host
final isHostProvider = Provider<bool>((ref) {
  final room = ref.watch(currentRoomProvider);
  return room?.isHost ?? false;
});

/// Provider for room capacity status
final roomCapacityProvider = Provider<String>((ref) {
  final room = ref.watch(currentRoomProvider);
  if (room == null) return '';
  
  return '${room.players.length}/${room.maxPlayers}';
});

/// Provider for available rooms count
final availableRoomsCountProvider = Provider<int>((ref) {
  final state = ref.watch(multiplayerControllerProvider);
  return state.availableRooms.length;
});

/// Provider for connection status text
final connectionStatusProvider = Provider<String>((ref) {
  final connectionState = ref.watch(connectionStateProvider);
  
  return connectionState.when(
    data: (state) {
      switch (state) {
        case ConnectionState.disconnected:
          return 'Disconnected';
        case ConnectionState.connecting:
          return 'Connecting...';
        case ConnectionState.connected:
          return 'Connected';
        case ConnectionState.error:
          return 'Connection Error';
      }
    },
    loading: () => 'Connecting...',
    error: (_, __) => 'Connection Error',
  );
});

/// Provider for network game moves
final networkGameMovesProvider = StreamProvider<GameMove>((ref) async* {
  final eventsStream = ref.watch(multiplayerEventsProvider);
  
  await for (final eventAsync in eventsStream) {
    eventAsync.when(
      data: (event) {
        if (event.type == MultiplayerEventType.moveMade) {
          // Yield the move data
          // This would need proper GameMove implementation
        }
      },
      loading: () {},
      error: (error, stackTrace) {},
    );
  }
});

/// Provider for dice roll events
final networkDiceRollsProvider = StreamProvider<DiceResult>((ref) async* {
  final eventsStream = ref.watch(multiplayerEventsProvider);
  
  await for (final eventAsync in eventsStream) {
    eventAsync.when(
      data: (event) {
        if (event.type == MultiplayerEventType.diceRolled) {
          final diceResult = event.data as DiceResult;
          yield diceResult;
        }
      },
      loading: () {},
      error: (error, stackTrace) {},
    );
  }
});

/// Provider for game end events
final gameEndEventsProvider = StreamProvider<GameResult>((ref) async* {
  final eventsStream = ref.watch(multiplayerEventsProvider);
  
  await for (final eventAsync in eventsStream) {
    eventAsync.when(
      data: (event) {
        if (event.type == MultiplayerEventType.gameEnded) {
          final gameResult = event.data as GameResult;
          yield gameResult;
        }
      },
      loading: () {},
      error: (error, stackTrace) {},
    );
  }
});