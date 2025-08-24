import 'package:flutter/material.dart';
import '../../core/enums/game_enums.dart';

/// Service for managing game themes and customization
class ThemeService {
  static final Map<String, GameThemeData> _themes = {};
  static final Map<String, BoardThemeData> _boardThemes = {};

  /// Initialize all available themes
  static void initialize() {
    _initializeGameThemes();
    _initializeBoardThemes();
  }

  /// Initialize game UI themes
  static void _initializeGameThemes() {
    _themes.clear();
    
    // Classic Theme
    _themes['classic'] = GameThemeData(
      id: 'classic',
      name: 'Classic',
      description: 'Traditional Ludo colors and design',
      isPremium: false,
      primaryColor: Colors.blue.shade600,
      secondaryColor: Colors.blue.shade100,
      backgroundColor: Colors.grey.shade50,
      surfaceColor: Colors.white,
      cardColor: Colors.white,
      textColor: Colors.black87,
      subtitleColor: Colors.grey.shade600,
      successColor: Colors.green,
      errorColor: Colors.red,
      warningColor: Colors.orange,
      playerColors: {
        PlayerColor.red: Colors.red.shade600,
        PlayerColor.blue: Colors.blue.shade600,
        PlayerColor.green: Colors.green.shade600,
        PlayerColor.yellow: Colors.yellow.shade700,
      },
      gradients: {
        'primary': LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        'background': LinearGradient(
          colors: [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
    );

    // Dark Theme
    _themes['dark'] = GameThemeData(
      id: 'dark',
      name: 'Dark Mode',
      description: 'Easy on the eyes for night gaming',
      isPremium: false,
      primaryColor: Colors.purple.shade400,
      secondaryColor: Colors.purple.shade900,
      backgroundColor: Colors.grey.shade900,
      surfaceColor: Colors.grey.shade800,
      cardColor: Colors.grey.shade800,
      textColor: Colors.white,
      subtitleColor: Colors.grey.shade400,
      successColor: Colors.green.shade400,
      errorColor: Colors.red.shade400,
      warningColor: Colors.orange.shade400,
      playerColors: {
        PlayerColor.red: Colors.red.shade400,
        PlayerColor.blue: Colors.blue.shade400,
        PlayerColor.green: Colors.green.shade400,
        PlayerColor.yellow: Colors.yellow.shade500,
      },
      gradients: {
        'primary': LinearGradient(
          colors: [Colors.purple.shade300, Colors.purple.shade500],
        ),
        'background': LinearGradient(
          colors: [Colors.grey.shade900, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
    );

    // Ocean Theme
    _themes['ocean'] = GameThemeData(
      id: 'ocean',
      name: 'Ocean Depths',
      description: 'Deep blue ocean-inspired theme',
      isPremium: true,
      primaryColor: Colors.teal.shade600,
      secondaryColor: Colors.teal.shade100,
      backgroundColor: Colors.cyan.shade50,
      surfaceColor: Colors.white,
      cardColor: Colors.white,
      textColor: Colors.grey.shade800,
      subtitleColor: Colors.grey.shade600,
      successColor: Colors.green.shade600,
      errorColor: Colors.red.shade600,
      warningColor: Colors.orange.shade600,
      playerColors: {
        PlayerColor.red: Colors.pink.shade400,
        PlayerColor.blue: Colors.blue.shade700,
        PlayerColor.green: Colors.teal.shade600,
        PlayerColor.yellow: Colors.amber.shade600,
      },
      gradients: {
        'primary': LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade700],
        ),
        'background': LinearGradient(
          colors: [Colors.cyan.shade50, Colors.teal.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      },
    );

    // Sunset Theme
    _themes['sunset'] = GameThemeData(
      id: 'sunset',
      name: 'Sunset Vibes',
      description: 'Warm sunset colors for a cozy feel',
      isPremium: true,
      primaryColor: Colors.orange.shade600,
      secondaryColor: Colors.orange.shade100,
      backgroundColor: Colors.orange.shade50,
      surfaceColor: Colors.white,
      cardColor: Colors.white,
      textColor: Colors.grey.shade800,
      subtitleColor: Colors.grey.shade600,
      successColor: Colors.green.shade600,
      errorColor: Colors.red.shade600,
      warningColor: Colors.amber.shade600,
      playerColors: {
        PlayerColor.red: Colors.red.shade600,
        PlayerColor.blue: Colors.indigo.shade600,
        PlayerColor.green: Colors.green.shade600,
        PlayerColor.yellow: Colors.amber.shade600,
      },
      gradients: {
        'primary': LinearGradient(
          colors: [Colors.orange.shade400, Colors.red.shade400],
        ),
        'background': LinearGradient(
          colors: [Colors.orange.shade50, Colors.pink.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
    );

    // Neon Theme
    _themes['neon'] = GameThemeData(
      id: 'neon',
      name: 'Neon Glow',
      description: 'Futuristic neon colors',
      isPremium: true,
      primaryColor: Colors.pink.shade400,
      secondaryColor: Colors.grey.shade900,
      backgroundColor: Colors.black,
      surfaceColor: Colors.grey.shade900,
      cardColor: Colors.grey.shade900,
      textColor: Colors.white,
      subtitleColor: Colors.grey.shade400,
      successColor: Colors.green.shade400,
      errorColor: Colors.red.shade400,
      warningColor: Colors.orange.shade400,
      playerColors: {
        PlayerColor.red: Colors.pink.shade400,
        PlayerColor.blue: Colors.cyan.shade400,
        PlayerColor.green: Colors.lime.shade400,
        PlayerColor.yellow: Colors.yellow.shade400,
      },
      gradients: {
        'primary': LinearGradient(
          colors: [Colors.pink.shade400, Colors.purple.shade400],
        ),
        'background': LinearGradient(
          colors: [Colors.black, Colors.grey.shade900],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      },
    );
  }

  /// Initialize board themes
  static void _initializeBoardThemes() {
    _boardThemes.clear();

    // Classic Board
    _boardThemes['classic'] = BoardThemeData(
      id: 'classic',
      name: 'Classic Board',
      description: 'Traditional Ludo board design',
      isPremium: false,
      boardBackgroundColor: Colors.white,
      boardBorderColor: Colors.black,
      pathColor: Colors.grey.shade200,
      safeZoneColor: Colors.green.shade100,
      homeAreaColors: {
        PlayerColor.red: Colors.red.shade100,
        PlayerColor.blue: Colors.blue.shade100,
        PlayerColor.green: Colors.green.shade100,
        PlayerColor.yellow: Colors.yellow.shade100,
      },
      finishAreaColors: {
        PlayerColor.red: Colors.red.shade200,
        PlayerColor.blue: Colors.blue.shade200,
        PlayerColor.green: Colors.green.shade200,
        PlayerColor.yellow: Colors.yellow.shade200,
      },
      centerDesign: BoardCenterDesign.classic,
      tokenStyle: TokenStyle.flat,
      backgroundPattern: null,
    );

    // Royal Board
    _boardThemes['royal'] = BoardThemeData(
      id: 'royal',
      name: 'Royal Palace',
      description: 'Elegant royal design with gold accents',
      isPremium: true,
      boardBackgroundColor: Colors.amber.shade50,
      boardBorderColor: Colors.amber.shade700,
      pathColor: Colors.amber.shade100,
      safeZoneColor: Colors.amber.shade200,
      homeAreaColors: {
        PlayerColor.red: Colors.red.shade200,
        PlayerColor.blue: Colors.blue.shade200,
        PlayerColor.green: Colors.green.shade200,
        PlayerColor.yellow: Colors.amber.shade200,
      },
      finishAreaColors: {
        PlayerColor.red: Colors.red.shade300,
        PlayerColor.blue: Colors.blue.shade300,
        PlayerColor.green: Colors.green.shade300,
        PlayerColor.yellow: Colors.amber.shade300,
      },
      centerDesign: BoardCenterDesign.royal,
      tokenStyle: TokenStyle.glossy,
      backgroundPattern: 'royal_pattern',
    );

    // Space Board
    _boardThemes['space'] = BoardThemeData(
      id: 'space',
      name: 'Space Adventure',
      description: 'Futuristic space-themed board',
      isPremium: true,
      boardBackgroundColor: Colors.indigo.shade900,
      boardBorderColor: Colors.cyan.shade400,
      pathColor: Colors.indigo.shade800,
      safeZoneColor: Colors.cyan.shade800,
      homeAreaColors: {
        PlayerColor.red: Colors.red.shade900,
        PlayerColor.blue: Colors.blue.shade900,
        PlayerColor.green: Colors.green.shade900,
        PlayerColor.yellow: Colors.amber.shade900,
      },
      finishAreaColors: {
        PlayerColor.red: Colors.red.shade800,
        PlayerColor.blue: Colors.blue.shade800,
        PlayerColor.green: Colors.green.shade800,
        PlayerColor.yellow: Colors.amber.shade800,
      },
      centerDesign: BoardCenterDesign.space,
      tokenStyle: TokenStyle.neon,
      backgroundPattern: 'space_pattern',
    );

    // Nature Board
    _boardThemes['nature'] = BoardThemeData(
      id: 'nature',
      name: 'Forest Grove',
      description: 'Natural wood and leaf designs',
      isPremium: true,
      boardBackgroundColor: Colors.brown.shade100,
      boardBorderColor: Colors.brown.shade600,
      pathColor: Colors.green.shade100,
      safeZoneColor: Colors.green.shade200,
      homeAreaColors: {
        PlayerColor.red: Colors.red.shade200,
        PlayerColor.blue: Colors.blue.shade200,
        PlayerColor.green: Colors.green.shade200,
        PlayerColor.yellow: Colors.yellow.shade200,
      },
      finishAreaColors: {
        PlayerColor.red: Colors.red.shade300,
        PlayerColor.blue: Colors.blue.shade300,
        PlayerColor.green: Colors.green.shade300,
        PlayerColor.yellow: Colors.yellow.shade300,
      },
      centerDesign: BoardCenterDesign.nature,
      tokenStyle: TokenStyle.wooden,
      backgroundPattern: 'wood_pattern',
    );
  }

  /// Get all available game themes
  static List<GameThemeData> getAllGameThemes() {
    return _themes.values.toList();
  }

  /// Get all available board themes
  static List<BoardThemeData> getAllBoardThemes() {
    return _boardThemes.values.toList();
  }

  /// Get game theme by ID
  static GameThemeData? getGameTheme(String id) {
    return _themes[id];
  }

  /// Get board theme by ID
  static BoardThemeData? getBoardTheme(String id) {
    return _boardThemes[id];
  }

  /// Get free game themes
  static List<GameThemeData> getFreeGameThemes() {
    return _themes.values.where((theme) => !theme.isPremium).toList();
  }

  /// Get premium game themes
  static List<GameThemeData> getPremiumGameThemes() {
    return _themes.values.where((theme) => theme.isPremium).toList();
  }

  /// Get free board themes
  static List<BoardThemeData> getFreeBoardThemes() {
    return _boardThemes.values.where((theme) => !theme.isPremium).toList();
  }

  /// Get premium board themes
  static List<BoardThemeData> getPremiumBoardThemes() {
    return _boardThemes.values.where((theme) => theme.isPremium).toList();
  }

  /// Create Flutter ThemeData from GameThemeData
  static ThemeData createFlutterTheme(GameThemeData gameTheme) {
    return ThemeData(
      primarySwatch: _createMaterialColor(gameTheme.primaryColor),
      primaryColor: gameTheme.primaryColor,
      scaffoldBackgroundColor: gameTheme.backgroundColor,
      cardColor: gameTheme.cardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: gameTheme.primaryColor,
        foregroundColor: gameTheme.textColor,
        elevation: 4,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: gameTheme.textColor),
        bodyMedium: TextStyle(color: gameTheme.textColor),
        bodySmall: TextStyle(color: gameTheme.subtitleColor),
        titleLarge: TextStyle(color: gameTheme.textColor),
        titleMedium: TextStyle(color: gameTheme.textColor),
        titleSmall: TextStyle(color: gameTheme.textColor),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: gameTheme.primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gameTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: gameTheme.primaryColor,
        brightness: _getBrightness(gameTheme),
      ),
    );
  }

  /// Create MaterialColor from Color
  static MaterialColor _createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (final strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  /// Determine brightness from theme
  static Brightness _getBrightness(GameThemeData theme) {
    return theme.backgroundColor.computeLuminance() > 0.5
        ? Brightness.light
        : Brightness.dark;
  }
}

/// Game theme data class
class GameThemeData {
  final String id;
  final String name;
  final String description;
  final bool isPremium;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final Color successColor;
  final Color errorColor;
  final Color warningColor;
  final Map<PlayerColor, Color> playerColors;
  final Map<String, Gradient> gradients;

  const GameThemeData({
    required this.id,
    required this.name,
    required this.description,
    required this.isPremium,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
    required this.playerColors,
    required this.gradients,
  });
}

/// Board theme data class
class BoardThemeData {
  final String id;
  final String name;
  final String description;
  final bool isPremium;
  final Color boardBackgroundColor;
  final Color boardBorderColor;
  final Color pathColor;
  final Color safeZoneColor;
  final Map<PlayerColor, Color> homeAreaColors;
  final Map<PlayerColor, Color> finishAreaColors;
  final BoardCenterDesign centerDesign;
  final TokenStyle tokenStyle;
  final String? backgroundPattern;

  const BoardThemeData({
    required this.id,
    required this.name,
    required this.description,
    required this.isPremium,
    required this.boardBackgroundColor,
    required this.boardBorderColor,
    required this.pathColor,
    required this.safeZoneColor,
    required this.homeAreaColors,
    required this.finishAreaColors,
    required this.centerDesign,
    required this.tokenStyle,
    this.backgroundPattern,
  });
}

/// Board center design types
enum BoardCenterDesign {
  classic,
  royal,
  space,
  nature,
  minimal,
}

/// Token style types
enum TokenStyle {
  flat,
  glossy,
  neon,
  wooden,
  metallic,
}

/// Theme unlock requirements
class ThemeUnlockRequirement {
  final String type; // 'achievement', 'level', 'purchase'
  final String requirement; // Achievement ID, level number, or purchase ID
  final String description;

  const ThemeUnlockRequirement({
    required this.type,
    required this.requirement,
    required this.description,
  });
}

/// Theme customization options
class ThemeCustomization {
  final String gameThemeId;
  final String boardThemeId;
  final Map<String, dynamic> customSettings;

  const ThemeCustomization({
    required this.gameThemeId,
    required this.boardThemeId,
    this.customSettings = const {},
  });

  ThemeCustomization copyWith({
    String? gameThemeId,
    String? boardThemeId,
    Map<String, dynamic>? customSettings,
  }) {
    return ThemeCustomization(
      gameThemeId: gameThemeId ?? this.gameThemeId,
      boardThemeId: boardThemeId ?? this.boardThemeId,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}