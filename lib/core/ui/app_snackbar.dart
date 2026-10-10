import 'package:flutter/material.dart';

enum AppSnackBarType { success, error, warning, info }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (messenger == null) {
      return;
    }

    messenger.hideCurrentSnackBar();

    final appearance = _appearanceFor(type);

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 120, maxWidth: 460),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: appearance.backgroundColor,
                border: Border.all(color: appearance.borderColor),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      appearance.icon,
                      color: appearance.foregroundColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: appearance.foregroundColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: appearance.foregroundColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(actionLabel),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: AppSnackBarType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: AppSnackBarType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: AppSnackBarType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: AppSnackBarType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static _AppSnackBarAppearance _appearanceFor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return const _AppSnackBarAppearance(
          backgroundColor: Color(0xFFE8F5E9),
          borderColor: Color(0xFF81C784),
          foregroundColor: Color(0xFF1B5E20),
          icon: Icons.check_circle_outline,
        );

      case AppSnackBarType.error:
        return const _AppSnackBarAppearance(
          backgroundColor: Color(0xFFFFEBEE),
          borderColor: Color(0xFFE57373),
          foregroundColor: Color(0xFFB71C1C),
          icon: Icons.error_outline,
        );

      case AppSnackBarType.warning:
        return const _AppSnackBarAppearance(
          backgroundColor: Color(0xFFFFF8E1),
          borderColor: Color(0xFFFFB74D),
          foregroundColor: Color(0xFFE65100),
          icon: Icons.warning_amber_outlined,
        );

      case AppSnackBarType.info:
        return const _AppSnackBarAppearance(
          backgroundColor: Color(0xFFE3F2FD),
          borderColor: Color(0xFF64B5F6),
          foregroundColor: Color(0xFF0D47A1),
          icon: Icons.info_outline,
        );
    }
  }
}

class _AppSnackBarAppearance {
  const _AppSnackBarAppearance({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final IconData icon;
}
