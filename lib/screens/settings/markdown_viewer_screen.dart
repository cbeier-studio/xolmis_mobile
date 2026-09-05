import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// A simple screen to display markdown content from an asset file.
class MarkdownViewerScreen extends StatelessWidget {
  final String title;
  final String assetPath;

  const MarkdownViewerScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading $title'));
          }

          final theme = Theme.of(context);
          final textStyle = theme.textTheme.bodyMedium;

          return Markdown(
            data: snapshot.data ?? '',
            styleSheet: MarkdownStyleSheet(
              p: textStyle,
              h1: theme.textTheme.headlineLarge,
              h2: theme.textTheme.headlineMedium,
              h3: theme.textTheme.headlineSmall,
              h4: theme.textTheme.titleLarge,
              h5: theme.textTheme.titleMedium,
              h6: theme.textTheme.titleSmall,
              em: textStyle?.copyWith(fontStyle: FontStyle.italic),
              strong: textStyle?.copyWith(fontWeight: FontWeight.bold),
              del: textStyle?.copyWith(decoration: TextDecoration.lineThrough),
              a: textStyle?.copyWith(color: theme.colorScheme.primary, decoration: TextDecoration.underline),
              blockquote: textStyle,
              code: textStyle?.copyWith(
                fontFamily: 'monospace',
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              listBullet: textStyle,
            ),
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
              }
            },
          );
        },
      ),
    );
  }
}
