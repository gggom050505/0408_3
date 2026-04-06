import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../theme/app_colors.dart';

/// `docs/MAKING_NOTES.md` 에셋을 마크다운으로 보여 줍니다.
class MakingNotesScreen extends StatelessWidget {
  const MakingNotesScreen({super.key});

  static const assetPath = 'docs/MAKING_NOTES.md';

  static Future<void> open(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const MakingNotesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('메이킹 노트'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.scaffoldGradient),
        child: FutureBuilder<String>(
          future: rootBundle.loadString(assetPath),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '문서를 불러오지 못했어요.\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final baseSheet = MarkdownStyleSheet.fromTheme(theme);
            return Markdown(
              data: snap.data!,
              selectable: true,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              styleSheet: baseSheet.copyWith(
                h1: baseSheet.h1?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                ),
                h2: baseSheet.h2?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
                p: baseSheet.p?.copyWith(color: AppColors.textPrimary, height: 1.45),
                listBullet: baseSheet.listBullet?.copyWith(color: AppColors.textPrimary),
                tableHead: baseSheet.tableHead?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                tableBody: baseSheet.tableBody?.copyWith(color: AppColors.textPrimary),
                code: baseSheet.code?.copyWith(
                  backgroundColor: Colors.white.withValues(alpha: 0.55),
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
