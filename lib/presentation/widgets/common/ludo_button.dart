import 'package:flutter/material.dart';

/// Custom button widget with Ludo game styling
class LudoButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;
  final Color? customColor;
  final double? width;

  const LudoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.customColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isButtonEnabled = isEnabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width ?? _getButtonWidth(),
      height: _getButtonHeight(),
      child: _buildButton(context, theme, isButtonEnabled),
    );
  }

  Widget _buildButton(BuildContext context, ThemeData theme, bool isButtonEnabled) {
    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isButtonEnabled ? onPressed : null,
          style: _getElevatedButtonStyle(theme),
          child: _buildButtonContent(theme.colorScheme.onPrimary),
        );
      case ButtonType.secondary:
        return OutlinedButton(
          onPressed: isButtonEnabled ? onPressed : null,
          style: _getOutlinedButtonStyle(theme),
          child: _buildButtonContent(customColor ?? theme.primaryColor),
        );
      case ButtonType.text:
        return TextButton(
          onPressed: isButtonEnabled ? onPressed : null,
          style: _getTextButtonStyle(theme),
          child: _buildButtonContent(customColor ?? theme.primaryColor),
        );
      case ButtonType.danger:
        return ElevatedButton(
          onPressed: isButtonEnabled ? onPressed : null,
          style: _getDangerButtonStyle(theme),
          child: _buildButtonContent(Colors.white),
        );
    }
  }

  Widget _buildButtonContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: _getLoadingSize(),
        height: _getLoadingSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize(), color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: _getFontSize(),
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  ButtonStyle _getElevatedButtonStyle(ThemeData theme) {
    return ElevatedButton.styleFrom(
      backgroundColor: customColor ?? theme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: _getPadding(),
    );
  }

  ButtonStyle _getOutlinedButtonStyle(ThemeData theme) {
    return OutlinedButton.styleFrom(
      foregroundColor: customColor ?? theme.primaryColor,
      side: BorderSide(
        color: customColor ?? theme.primaryColor,
        width: 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: _getPadding(),
    );
  }

  ButtonStyle _getTextButtonStyle(ThemeData theme) {
    return TextButton.styleFrom(
      foregroundColor: customColor ?? theme.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: _getPadding(),
    );
  }

  ButtonStyle _getDangerButtonStyle(ThemeData theme) {
    return ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.error,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: _getPadding(),
    );
  }

  double? _getButtonWidth() {
    switch (size) {
      case ButtonSize.small:
        return null;
      case ButtonSize.medium:
        return null;
      case ButtonSize.large:
        return double.infinity;
    }
  }

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getLoadingSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case ButtonSize.small:
        return 8;
      case ButtonSize.medium:
        return 12;
      case ButtonSize.large:
        return 16;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    }
  }
}

/// Button type enum
enum ButtonType {
  primary,
  secondary,
  text,
  danger,
}

/// Button size enum
enum ButtonSize {
  small,
  medium,
  large,
}