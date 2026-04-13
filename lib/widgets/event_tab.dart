import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event_item.dart';
import '../standalone/data_sources.dart';
import '../theme/app_colors.dart';
import 'app_motion.dart';

const _kAuthorInstagramUrl = 'https://www.instagram.com/wookoong2025/';

class EventTab extends StatefulWidget {
  const EventTab({super.key, required this.repo});

  final EventDataSource repo;

  @override
  State<EventTab> createState() => _EventTabState();
}

class _EventTabState extends State<EventTab> {
  List<EventItemRow> _events = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await widget.repo.fetchActiveEvents();
      if (mounted) {
        setState(() {
          _events = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _events = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppearAnimation(
          duration: const Duration(milliseconds: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎁 이벤트',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '출석·오늘의 타로(데일리 5×2) 등 안내와, 타로 매트·별조각·오라클·'
                  '채팅까지 앱을 즐기는 방법을 모아 두었어요. 아래 카드를 당겨 새로고침할 수 있어요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 12),
                const _AuthorCredit(),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: Text('로딩중...', style: TextStyle(color: AppColors.textSecondary)))
              : _events.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          '현재 진행 중인 이벤트가 없습니다',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _events.length,
                        itemBuilder: (context, idx) {
                          final ev = _events[idx];
                          return _EventCard(ev: ev, delayIdx: idx);
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.ev, required this.delayIdx});

  final EventItemRow ev;
  final int delayIdx;

  static const _fallbackGradient = LinearGradient(
    colors: [Color(0xFFB89CD4), Color(0xFFA088C2), Color(0xFF8B6EAA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 280 + delayIdx * 80),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.95 + 0.05 * t,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.textOnLightCard.withValues(alpha: 0.09)),
          gradient: _parseCssGradient(ev.gradient) ?? _fallbackGradient,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9678B4).withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (ev.type == 'notice')
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.textOnLightCard.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.textOnLightCard.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Text(
                            '공지',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textOnLightCard,
                            ),
                          ),
                        ),
                      if (ev.type == 'maintenance')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.textOnLightCard.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.textOnLightCard.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Text(
                            '점검',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textOnLightCard,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    ev.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnLightCard,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ev.description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textOnLightCardMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (ev.badgeText != null && ev.badgeText!.isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.textOnLightCard.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    ev.badgeText!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnLightCard,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// `linear-gradient(...)` 문자열만 간단 파싱. 실패 시 null → 기본 그라데이션.
  LinearGradient? _parseCssGradient(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final m = RegExp(r'linear-gradient\s*\(\s*[^,]+,\s*([^)]+)\)', caseSensitive: false).firstMatch(raw);
    if (m == null) {
      return null;
    }
    final part = m.group(1)!;
    final hexes = RegExp(r'#([0-9a-fA-F]{6})').allMatches(part).map((x) => x.group(0)!).toList();
    if (hexes.length < 2) {
      return null;
    }
    final colors = hexes.map((h) {
      final v = h.substring(1);
      return Color(int.parse('FF$v', radix: 16));
    }).toList();
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

class _AuthorCredit extends StatelessWidget {
  const _AuthorCredit();

  Future<void> _openInstagram() async {
    final uri = Uri.parse(_kAuthorInstagramUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openInstagram,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Text(
                '저작자',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '@wookoong2025',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.accentPurple,
                      ),
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
