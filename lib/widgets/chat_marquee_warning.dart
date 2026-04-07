import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// 채팅 상단 안내 원문 ([_kMarqueeGap] 만큼 띄운 뒤 같은 문구가 이어짐).
const String kChatConductWarningText =
    '음담패설, 욕설, 폭언,, 정치, 종교, 플러팅등 다른 사용자에게 불쾌감이나 수치심을 유발시키는 말을 할 경우 법적조치 하겠음. 다른 사용자님들의 품위를 해치거나 선한 마음을 다치게 하지 말아주세요.';

/// 한 주기 끝의 공백 뒤 같은 문구가 이어짐. 신고 안내는 [AppConfig.communityMisconductReportLine].
String _kChatMarqueeSegment() =>
    '$kChatConductWarningText ${AppConfig.communityMisconductReportLine}     ';

class ChatMarqueeWarningBar extends StatefulWidget {
  const ChatMarqueeWarningBar({super.key});

  @override
  State<ChatMarqueeWarningBar> createState() => _ChatMarqueeWarningBarState();
}

class _ChatMarqueeWarningBarState extends State<ChatMarqueeWarningBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 45),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseSmall = Theme.of(context).textTheme.labelSmall;
    final style =
        (baseSmall ??
                const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5C4033),
                  fontWeight: FontWeight.w600,
                ))
            .copyWith(
              color: const Color(0xFF5C4033),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              fontSize: (baseSmall?.fontSize ?? 12) + 2,
            );

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewW = constraints.maxWidth;
        final segment = _kChatMarqueeSegment();
        final tp = TextPainter(
          text: TextSpan(text: segment, style: style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        final segW = tp.width;
        final loopText = segment + segment;

        return Material(
          color: const Color(0xFFFFF3E0).withValues(alpha: 0.92),
          child: Container(
            height: 44,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.orange.shade200.withValues(alpha: 0.65),
                ),
              ),
            ),
            child: ClipRect(
              child: SizedBox(
                width: viewW,
                height: 44,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // 우→좌: 왼쪽으로 이동 (한 블록(segW)마다 끊김 없이 이어짐).
                    final left = -segW * _controller.value;
                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          left: left,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Text(
                              loopText,
                              style: style,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
