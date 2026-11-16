import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/backup/backup_providers.dart';

/// Makes a backup when the app window is closed, so the day's last sales are
/// in the backup folder even if this computer does not start again.
///
/// The Windows runner (windows/runner/flutter_window.cpp) holds the window
/// open and calls `beforeClose` on [channel]; the window closes when this
/// call returns.
class AutoBackupOnExit extends ConsumerStatefulWidget {
  const AutoBackupOnExit({super.key, required this.child});

  final Widget child;

  static const channel = MethodChannel('billing_guru/lifecycle');

  /// Closing is never blocked longer than this (e.g. a slow network drive).
  static const timeout = Duration(seconds: 60);

  @override
  ConsumerState<AutoBackupOnExit> createState() => _AutoBackupOnExitState();
}

class _AutoBackupOnExitState extends ConsumerState<AutoBackupOnExit> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    AutoBackupOnExit.channel.setMethodCallHandler(_handle);
  }

  Future<Object?> _handle(MethodCall call) async {
    if (call.method != 'beforeClose') {
      throw MissingPluginException(call.method);
    }
    if (mounted) setState(() => _saving = true);
    try {
      await ref
          .read(autoBackupServiceProvider)
          .run()
          .timeout(AutoBackupOnExit.timeout);
    } catch (_) {
      // Never keep the user from closing the app.
    }
    return null;
  }

  @override
  void dispose() {
    AutoBackupOnExit.channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always a Stack, so showing the overlay does not rebuild the app.
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (_saving)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0xCC000000),
              child: Center(
                child: Text(
                  'Saving backup before closing…',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 20),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
