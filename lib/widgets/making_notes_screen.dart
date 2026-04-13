import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

/// `docs/MAKING_NOTES.md` 에셋을 마크다운으로 보여 줍니다.
class MakingNotesScreen extends StatefulWidget {
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
  State<MakingNotesScreen> createState() => _MakingNotesScreenState();
}

class _MakingNotesScreenState extends State<MakingNotesScreen> {
  late Future<String> _docFuture;

  @override
  void initState() {
    super.initState();
    _docFuture = rootBundle.loadString(MakingNotesScreen.assetPath);
  }

  void _reload() {
    setState(() {
      _docFuture = rootBundle.loadString(MakingNotesScreen.assetPath);
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _openMarkdownLink(BuildContext context, String href) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = Uri.tryParse(href);
    if (uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) {
        return;
      }
      if (!ok) {
        await Clipboard.setData(ClipboardData(text: href));
        messenger?.showSnackBar(
          SnackBar(content: Text('브라우저를 열 수 없어 링크를 복사했어요: $href')),
        );
      }
      return;
    }
    await Clipboard.setData(ClipboardData(text: href));
    if (!context.mounted) {
      return;
    }
    messenger?.showSnackBar(
      SnackBar(
        content: Text('경로를 복사했어요: $href'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  MarkdownStyleSheet _styleSheet(ThemeData theme) {
    final base = MarkdownStyleSheet.fromTheme(theme);
    return base.copyWith(
      h1: base.h1?.copyWith(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      h2: base.h2?.copyWith(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      h3: base.h3?.copyWith(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      p: base.p?.copyWith(color: AppColors.textPrimary, height: 1.5),
      strong: base.strong?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      listBullet: base.listBullet?.copyWith(color: AppColors.textPrimary),
      listIndent: 24,
      blockSpacing: 10,
      blockquote: base.blockquote?.copyWith(
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.accentPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppColors.accentPurple.withValues(alpha: 0.55),
            width: 3,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.cardBorder.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
      ),
      tableHead: base.tableHead?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      tableBody: base.tableBody?.copyWith(color: AppColors.textPrimary),
      tableBorder: TableBorder.all(
        color: AppColors.cardBorder.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      code: base.code?.copyWith(
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        fontFamily: 'monospace',
        fontSize: 12,
      ),
      a: base.a?.copyWith(
        color: AppColors.accentPurple,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        toolbarHeight: 72,
        title: Text.rich(
          TextSpan(
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              height: 1.15,
            ),
            children: const [
              TextSpan(text: '메이킹 노트\n'),
              TextSpan(
                text: '공공곰타로덱 · 기획·구현 요약(번들 문서)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppColors.bgMain,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '문서 다시 읽기',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.scaffoldGradient),
        child: FutureBuilder<String>(
          future: _docFuture,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '문서를 불러오지 못했어요.\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snap.hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.accentPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '불러오는 중…',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Scrollbar(
              thumbVisibility: true,
              child: Markdown(
                data: snap.data!,
                selectable: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                styleSheet: _styleSheet(theme),
                onTapLink: (text, href, title) {
                  if (href == null || href.isEmpty) {
                    return;
                  }
                  unawaited(_openMarkdownLink(context, href));
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
