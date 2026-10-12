import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<_HomePlaceholderText> _placeholderTextFuture;

  @override
  void initState() {
    super.initState();
    _placeholderTextFuture = _loadPlaceholderText();
  }

  Future<_HomePlaceholderText> _loadPlaceholderText() async {
    try {
      final text = await rootBundle.loadString(
        'assets/text/home_placeholder.txt',
      );
      final lines = text
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      return _HomePlaceholderText(
        title: lines.firstOrNull ?? 'Welcome to Billing Guru',
        subtitle: lines.length > 1 ? lines.sublist(1).join(' ') : '',
      );
    } catch (_) {
      return const _HomePlaceholderText(
        title: 'Welcome to Billing Guru',
        subtitle: 'Your home dashboard is being prepared. Use the navigation menu to manage your business.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: FutureBuilder<_HomePlaceholderText>(
            future: _placeholderTextFuture,
            builder: (context, snapshot) {
              final text =
                  snapshot.data ??
                  const _HomePlaceholderText(
                    title: 'Welcome to Billing Guru',
                    subtitle: 'Loading home information...',
                  );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/navigation/home.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.home_outlined,
                        size: 80,
                        color: colorScheme.primary,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    text.title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (text.subtitle.isNotEmpty)
                    Text(
                      text.subtitle,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomePlaceholderText {
  const _HomePlaceholderText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
