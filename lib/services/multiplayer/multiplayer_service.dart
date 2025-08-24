import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/game_state.dart';
import '../../data/models/player.dart';
import '../../data/models/token.dart';
import '../../data/models/position.dart';
import '../../data/models/multiplayer_models.dart';
import '../../core/enums/game_enums.dart';

/// Comprehensive multiplayer service for real-time Ludo gameplay
class MultiplayerService {
  static final MultiplayerService _instance = MultiplayerService._internal();
  factory MultiplayerService() => _instance;
  MultiplayerService._internal();

  // Socket.IO connection
  IO.Socket? _socket;
  String? _serverUrl;
  
  // Firebase references
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Game room management
  String? _currentRoomId;
  GameRoom? _currentRoom;
  
  // Stream controllers for real-time updates
  final StreamController<GameState> _gameStateController = StreamController<GameState>.broadcast();
  final StreamController<List<Player>> _playersController = StreamController<List<Player>>.broadcast();
  final StreamController<ConnectionState> _connectionController = StreamController<ConnectionState>.broadcast();
  final StreamController<MultiplayerEvent> _eventController = StreamController<MultiplayerEvent>.broadcast();
  
  // Connection state
  bool _isConnected = false;
  bool _isInRoom = false;
  
  // Reconnection settings
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Getters for streams
  Stream<GameState> get gameStateStream => _gameStateController.stream;
  Stream<List<Player>> get playersStream => _playersController.stream;
  Stream<ConnectionState> get connectionStream => _connectionController.stream;
  Stream<MultiplayerEvent> get eventStream => _eventController.stream;
  
  // Getters for state
  bool get isConnected => _isConnected;
  bool get isInRoom => _isInRoom;
  String? get currentRoomId => _currentRoomId;
  GameRoom? get currentRoom => _currentRoom;

  /// Initialize multiplayer service
  Future<void> initialize({String? serverUrl}) async {
    _serverUrl = serverUrl ?? 'https://ludo-server.herokuapp.com'; // Replace with actual server URL
    
    await _initializeSocket();
    await _setupFirebaseListeners();
    
    debugPrint('🌐 Multiplayer service initialized');
  }

  /// Initialize Socket.IO connection
  Future<void> _initializeSocket() async {
    try {
      _socket = IO.io(_serverUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer ${await _getAuthToken()}'})
          .build());

      _setupSocketListeners();
      
    } catch (e) {
      debugPrint('❌ Failed to initialize socket: $e');
      throw MultiplayerException('Failed to initialize connection', e.toString());
    }
  }

  /// Setup Socket.IO event listeners
  void _setupSocketListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.on('connect', (_) {
      debugPrint('🔗 Connected to multiplayer server');
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add(ConnectionState.connected);
    });

    _socket!.on('disconnect', (_) {
      debugPrint('🔌 Disconnected from multiplayer server');
      _isConnected = false;
      _connectionController.add(ConnectionState.disconnected);
      _attemptReconnection();
    });

    _socket!.on('connect_error', (error) {
      debugPrint('❌ Connection error: $error');
      _connectionController.add(ConnectionState.error);
      _attemptReconnection();
    });

    // Room events
    _socket!.on('room_joined', (data) => _handleRoomJoined(data));
    _socket!.on('room_left', (data) => _handleRoomLeft(data));
    _socket!.on('player_joined', (data) => _handlePlayerJoined(data));
    _socket!.on('player_left', (data) => _handlePlayerLeft(data));
    _socket!.on('room_full', (data) => _handleRoomFull(data));
    
    // Game events
    _socket!.on('game_started', (data) => _handleGameStarted(data));
    _socket!.on('game_state_updated', (data) => _handleGameStateUpdated(data));
    _socket!.on('move_made', (data) => _handleMoveMade(data));
    _socket!.on('dice_rolled', (data) => _handleDiceRolled(data));
    _socket!.on('turn_changed', (data) => _handleTurnChanged(data));
    _socket!.on('game_ended', (data) => _handleGameEnded(data));
    
    // Error events
    _socket!.on('error', (error) => _handleSocketError(error));
    _socket!.on('invalid_move', (data) => _handleInvalidMove(data));
  }

  /// Setup Firebase real-time listeners
  Future<void> _setupFirebaseListeners() async {
    // Listen to room document changes for backup sync
    // This provides redundancy in case Socket.IO fails
  }

  /// Get authentication token
  Future<String?> _getAuthToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  /// Connect to multiplayer server
  Future<void> connect() async {
    if (_socket == null) {
      await initialize();
    }
    
    if (!_isConnected) {
      _connectionController.add(ConnectionState.connecting);
      _socket!.connect();
    }
  }

  /// Disconnect from multiplayer server
  Future<void> disconnect() async {
    if (_socket != null && _isConnected) {
      await leaveRoom();
      _socket!.disconnect();
      _isConnected = false;
      _connectionController.add(ConnectionState.disconnected);
    }
  }

  /// Create a new game room
  Future<GameRoom> createRoom({
    required String roomName,
    required GameMode gameMode,
    int maxPlayers = 4,
    bool isPrivate = false,
    String? password,
  }) async {
    if (!_isConnected) {
      throw MultiplayerException('Not connected to server', 'CONNECTION_ERROR');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw MultiplayerException('User not authenticated', 'AUTH_ERROR');
    }

    final roomData = {
      'roomName': roomName,
      'gameMode': gameMode.name,
      'maxPlayers': maxPlayers,
      'isPrivate': isPrivate,
      'password': password,
      'hostId': user.uid,
      'hostName': user.displayName ?? 'Host',
    };

    final completer = Completer<GameRoom>();
    
    _socket!.emit('create_room', roomData);
    
    _socket!.once('room_created', (data) {
      final room = GameRoom.fromJson(data);
      _currentRoom = room;
      _currentRoomId = room.id;
      _isInRoom = true;
      completer.complete(room);
    });

    _socket!.once('room_creation_failed', (error) {
      completer.completeError(MultiplayerException('Failed to create room', error.toString()));
    });

    return completer.future;
  }

  /// Join an existing game room
  Future<GameRoom> joinRoom(String roomId, {String? password}) async {
    if (!_isConnected) {
      throw MultiplayerException('Not connected to server', 'CONNECTION_ERROR');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw MultiplayerException('User not authenticated', 'AUTH_ERROR');
    }

    final joinData = {
      'roomId': roomId,
      'playerId': user.uid,
      'playerName': user.displayName ?? 'Player',
      'password': password,
    };

    final completer = Completer<GameRoom>();
    
    _socket!.emit('join_room', joinData);
    
    _socket!.once('room_joined', (data) {
      final room = GameRoom.fromJson(data);
      _currentRoom = room;
      _currentRoomId = room.id;
      _isInRoom = true;
      completer.complete(room);
    });

    _socket!.once('join_failed', (error) {
      completer.completeError(MultiplayerException('Failed to join room', error.toString()));
    });

    return completer.future;
  }

  /// Leave current room
  Future<void> leaveRoom() async {
    if (_isInRoom && _currentRoomId != null) {
      _socket!.emit('leave_room', {'roomId': _currentRoomId});
      _currentRoom = null;
      _currentRoomId = null;
      _isInRoom = false;
    }
  }

  /// Start the game (host only)
  Future<void> startGame() async {
    if (!_isInRoom || _currentRoomId == null) {
      throw MultiplayerException('Not in a room', 'ROOM_ERROR');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw MultiplayerException('User not authenticated', 'AUTH_ERROR');
    }

    if (_currentRoom?.hostId != user.uid) {
      throw MultiplayerException('Only host can start the game', 'PERMISSION_ERROR');
    }

    _socket!.emit('start_game', {'roomId': _currentRoomId});
  }

  /// Make a move in the game
  Future<void> makeMove({
    required String tokenId,
    required Position fromPosition,
    required Position toPosition,
    required int diceValue,
  }) async {
    if (!_isInRoom || _currentRoomId == null) {
      throw MultiplayerException('Not in a room', 'ROOM_ERROR');
    }

    final moveData = {
      'roomId': _currentRoomId,
      'tokenId': tokenId,
      'fromPosition': fromPosition.toJson(),
      'toPosition': toPosition.toJson(),
      'diceValue': diceValue,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _socket!.emit('make_move', moveData);
  }

  /// Roll dice
  Future<void> rollDice() async {
    if (!_isInRoom || _currentRoomId == null) {
      throw MultiplayerException('Not in a room', 'ROOM_ERROR');
    }

    _socket!.emit('roll_dice', {
      'roomId': _currentRoomId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send game state update
  Future<void> updateGameState(GameState gameState) async {
    if (!_isInRoom || _currentRoomId == null) {
      throw MultiplayerException('Not in a room', 'ROOM_ERROR');
    }

    final updateData = {
      'roomId': _currentRoomId,
      'gameState': gameState.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    _socket!.emit('update_game_state', updateData);
  }

  /// Find available rooms
  Future<List<GameRoom>> findRooms({
    GameMode? gameMode,
    bool? isPrivate,
    int? maxPlayers,
  }) async {
    if (!_isConnected) {
      throw MultiplayerException('Not connected to server', 'CONNECTION_ERROR');
    }

    final filters = {
      'gameMode': gameMode?.name,
      'isPrivate': isPrivate,
      'maxPlayers': maxPlayers,
    };

    final completer = Completer<List<GameRoom>>();
    
    _socket!.emit('find_rooms', filters);
    
    _socket!.once('rooms_found', (data) {
      final rooms = (data as List).map((roomData) => GameRoom.fromJson(roomData)).toList();
      completer.complete(rooms);
    });

    _socket!.once('find_rooms_failed', (error) {
      completer.completeError(MultiplayerException('Failed to find rooms', error.toString()));
    });

    return completer.future;
  }

  /// Quick match - join any available room
  Future<GameRoom> quickMatch({GameMode gameMode = GameMode.onlineMultiplayer}) async {
    if (!_isConnected) {
      throw MultiplayerException('Not connected to server', 'CONNECTION_ERROR');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw MultiplayerException('User not authenticated', 'AUTH_ERROR');
    }

    final matchData = {
      'playerId': user.uid,
      'playerName': user.displayName ?? 'Player',
      'gameMode': gameMode.name,
    };

    final completer = Completer<GameRoom>();
    
    _socket!.emit('quick_match', matchData);
    
    _socket!.once('match_found', (data) {
      final room = GameRoom.fromJson(data);
      _currentRoom = room;
      _currentRoomId = room.id;
      _isInRoom = true;
      completer.complete(room);
    });

    _socket!.once('match_failed', (error) {
      completer.completeError(MultiplayerException('Failed to find match', error.toString()));
    });

    return completer.future;
  }

  // Event handlers

  void _handleRoomJoined(dynamic data) {
    final room = GameRoom.fromJson(data);
    _currentRoom = room;
    _playersController.add(room.players);
    _eventController.add(MultiplayerEvent(
      type: MultiplayerEventType.roomJoined,
      data: room,
    ));
  }

  void _handleRoomLeft(dynamic data) {
    _currentRoom = null;
    _currentRoomId = null;
    _isInRoom = false;
    _eventController.add(MultiplayerEvent(
      type: MultiplayerEventType.roomLeft,
      data: data,
    ));
  }

  void _handlePlayerJoined(dynamic data) {
    final player = Player.fromJson(data['player']);
    _currentRoom = _currentRoom?.copyWith(
      players: [..._currentRoom!.players, player],
    );
    _playersController.add(_currentRoom!.players);
    _eventController.add(MultiplayerEvent(
      type: MultiplayerEventType.playerJoined,
      data: player,
    ));
  }

  void _handlePlayerLeft(dynamic data) {
    final playerId = data['playerId'];
    _currentRoom = _currentRoom?.copyWith(
      players: _currentRoom!.players.where((p) => p.id != playerId).toList(),
    );
    _playersController.add(_currentRoom!.players);
    _eventController.add(MultiplayerEvent(
      type: MultiplayerEventType.playerLeft,
      data: data,
    ));
  }

  void _handleRoomFull(dynamic data) {
    _eventController.add(MultiplayerEvent(
      type: MultiplayerEventType.roomFull,
      data: data,
    ));
  }

  void _handleGameStarted(dynamic data) {
    final gameState = GameState.fromJson(data['gameState']);
    _gameStateController.add(gameState);
    _eventController.add(MultiplayerEvent(
      type: MultiplayerEventType.gameStarted,
      data: gameState,
    ));
  }

  void _handleGameStateUpdated(dynamic data) {
    final gameState = GameState.fromJson(data['gameState']);
    _gameStateController.add(gameState);
    _eventController.add(MultiplayerEvent(
      type: MultiplayerEventType.gameStateUpdated,
      data: gameState,
    ));
  }

  void _handleMoveMade(dynamic data) {
    final move = GameMove.fromJson(data);
    _eventController.add(MultiplayerEvent(
      type: MultiplayerEventType.moveMade,
      data: move,
    ));
  }

  void _handleDiceRolled(dynamic data) {
    final diceResult = DiceResult.fromJson(data);
    _eventController.add(MultiplayerEvent(
      type: MultiplayerEventType.diceRolled,
      data: diceResult,
    ));
  }

  void _handleTurnChanged(dynamic data) {
    _eventController.add(MultiplayerEvent(
      type: MultiplayerEventType.turnChanged,
      data: data,
    ));
  }

  void _handleGameEnded(dynamic data) {
    final gameResult = GameResult.fromJson(data);
    _eventController.add(MultiplayerEvent(
      type: MultiplayerEventType.gameEnded,
      data: gameResult,
    ));
  }

  void _handleSocketError(dynamic error) {
    debugPrint('❌ Socket error: $error');
    _eventController.add(MultiplayerEvent(
      type: MultiplayerEventType.error,
      data: error,
    ));
  }

  void _handleInvalidMove(dynamic data) {
    _eventController.add(MultiplayerEvent(
      type: MultiplayerEventType.invalidMove,
      data: data,
    ));
  }

  /// Update game state
  Future<void> updateGameState(GameState gameState) async {
    if (!_isConnected || !_isInRoom) {
      throw MultiplayerException('Not connected or not in room', 'CONNECTION_ERROR');
    }

    _socket!.emit('update_game_state', {
      'roomId': _currentRoomId,
      'gameState': gameState.toJson(),
    });
  }

  /// Update player ready state
  Future<void> updatePlayerReady(bool isReady) async {
    if (!_isConnected || !_isInRoom) {
      throw MultiplayerException('Not connected or not in room', 'CONNECTION_ERROR');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw MultiplayerException('User not authenticated', 'AUTH_ERROR');
    }

    _socket!.emit('update_player_ready', {
      'roomId': _currentRoomId,
      'playerId': user.uid,
      'isReady': isReady,
    });
  }

  /// Attempt reconnection
  void _attemptReconnection() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    debugPrint('🔄 Attempting reconnection $_reconnectAttempts/$_maxReconnectAttempts');

    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isConnected && _socket != null) {
        _socket!.connect();
      }
    });
  }

  /// Dispose the service
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _reconnectTimer?.cancel();
    
    _gameStateController.close();
    _playersController.close();
    _connectionController.close();
    _eventController.close();
    
    debugPrint('🔄 Multiplayer service disposed');
  }
}

/// Connection states
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Multiplayer event types
enum MultiplayerEventType {
  roomJoined,
  roomLeft,
  playerJoined,
  playerLeft,
  roomFull,
  gameStarted,
  gameStateUpdated,
  moveMade,
  diceRolled,
  turnChanged,
  gameEnded,
  error,
  invalidMove,
}

/// Multiplayer event
class MultiplayerEvent {
  final MultiplayerEventType type;
  final dynamic data;
  final DateTime timestamp;

  MultiplayerEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Game room model
class GameRoom {
  final String id;
  final String name;
  final String hostId;
  final String hostName;
  final List<Player> players;
  final int maxPlayers;
  final GameMode gameMode;
  final bool isPrivate;
  final bool hasPassword;
  final RoomStatus status;
  final DateTime createdAt;
  final GameState? gameState;

  const GameRoom({
    required this.id,
    required this.name,
    required this.hostId,
    required this.hostName,
    required this.players,
    required this.maxPlayers,
    required this.gameMode,
    required this.isPrivate,
    required this.hasPassword,
    required this.status,
    required this.createdAt,
    this.gameState,
  });

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      id: json['id'],
      name: json['name'],
      hostId: json['hostId'],
      hostName: json['hostName'],
      players: (json['players'] as List).map((p) => Player.fromJson(p)).toList(),
      maxPlayers: json['maxPlayers'],
      gameMode: GameMode.values.firstWhere((mode) => mode.name == json['gameMode']),
      isPrivate: json['isPrivate'],
      hasPassword: json['hasPassword'],
      status: RoomStatus.values.firstWhere((status) => status.name == json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      gameState: json['gameState'] != null ? GameState.fromJson(json['gameState']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hostId': hostId,
      'hostName': hostName,
      'players': players.map((p) => p.toJson()).toList(),
      'maxPlayers': maxPlayers,
      'gameMode': gameMode.name,
      'isPrivate': isPrivate,
      'hasPassword': hasPassword,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'gameState': gameState?.toJson(),
    };
  }

  GameRoom copyWith({
    String? id,
    String? name,
    String? hostId,
    String? hostName,
    List<Player>? players,
    int? maxPlayers,
    GameMode? gameMode,
    bool? isPrivate,
    bool? hasPassword,
    RoomStatus? status,
    DateTime? createdAt,
    GameState? gameState,
  }) {
    return GameRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      players: players ?? this.players,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      gameMode: gameMode ?? this.gameMode,
      isPrivate: isPrivate ?? this.isPrivate,
      hasPassword: hasPassword ?? this.hasPassword,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      gameState: gameState ?? this.gameState,
    );
  }

  bool get isFull => players.length >= maxPlayers;
  bool get canJoin => !isFull && status == RoomStatus.waiting;
  bool get isHost => hostId == FirebaseAuth.instance.currentUser?.uid;
}

/// Room status
enum RoomStatus {
  waiting,
  playing,
  finished,
  closed,
}

/// Dice result model
class DiceResult {
  final int value;
  final String playerId;
  final DateTime timestamp;

  const DiceResult({
    required this.value,
    required this.playerId,
    required this.timestamp,
  });

  factory DiceResult.fromJson(Map<String, dynamic> json) {
    return DiceResult(
      value: json['value'],
      playerId: json['playerId'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'playerId': playerId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Game result model
class GameResult {
  final String gameId;
  final Player? winner;
  final List<Player> players;
  final Duration gameDuration;
  final DateTime endedAt;
  final Map<String, dynamic> statistics;

  const GameResult({
    required this.gameId,
    this.winner,
    required this.players,
    required this.gameDuration,
    required this.endedAt,
    required this.statistics,
  });

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      gameId: json['gameId'],
      winner: json['winner'] != null ? Player.fromJson(json['winner']) : null,
      players: (json['players'] as List).map((p) => Player.fromJson(p)).toList(),
      gameDuration: Duration(milliseconds: json['gameDuration']),
      endedAt: DateTime.parse(json['endedAt']),
      statistics: json['statistics'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'winner': winner?.toJson(),
      'players': players.map((p) => p.toJson()).toList(),
      'gameDuration': gameDuration.inMilliseconds,
      'endedAt': endedAt.toIso8601String(),
      'statistics': statistics,
    };
  }
}

/// Multiplayer exception
class MultiplayerException implements Exception {
  final String message;
  final String code;

  const MultiplayerException(this.message, this.code);

  @override
  String toString() => 'MultiplayerException: $message ($code)';
}