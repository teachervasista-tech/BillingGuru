import 'package:flutter/material.dart';

enum AppSnackbarType { success, error, warning, info }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    AppSnackbarType type = AppSnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (messenger == null) {
      return;
    }

    messenger.hideCurrentSnackBar();

    final colors = _colors(type);

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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(colors.icon, color: colors.foreground, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message, type: AppSnackbarType.success);
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message,
      type: AppSnackbarType.error,
      duration: const Duration(seconds: 4),
    );
  }

  static void warning(BuildContext context, String message) {
    show(context, message, type: AppSnackbarType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message, type: AppSnackbarType.info);
  }

  static _SnackbarColors _colors(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return const _SnackbarColors(
          background: Color(0xFFE8F5E9),
          border: Color(0xFF81C784),
          foreground: Color(0xFF1B5E20),
          icon: Icons.check_circle_outline,
        );

      case AppSnackbarType.error:
        return const _SnackbarColors(
          background: Color(0xFFFFEBEE),
          border: Color(0xFFE57373),
          foreground: Color(0xFFB71C1C),
          icon: Icons.error_outline,
        );

      case AppSnackbarType.warning:
        return const _SnackbarColors(
          background: Color(0xFFFFF8E1),
          border: Color(0xFFFFB74D),
          foreground: Color(0xFFE65100),
          icon: Icons.warning_amber_outlined,
        );

      case AppSnackbarType.info:
        return const _SnackbarColors(
          background: Color(0xFFE3F2FD),
          border: Color(0xFF64B5F6),
          foreground: Color(0xFF0D47A1),
          icon: Icons.info_outline,
        );
    }
  }
}

class _SnackbarColors {
  const _SnackbarColors({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}
