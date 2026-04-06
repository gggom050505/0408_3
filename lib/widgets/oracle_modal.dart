import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/oracle_assets.dart';

class OracleModal extends StatefulWidget {
  OracleModal({
    super.key,
    required this.ownedCardNumbers,
    required this.onClose,
  }) : assert(ownedCardNumbers.isNotEmpty);

  /// 보유 중인 오라클 카드 번호(1~80).
  final List<int> ownedCardNumbers;
  final VoidCallback onClose;

  @override
  State<OracleModal> createState() => _OracleModalState();
}

class _OracleModalState extends State<OracleModal> {
  late int _num;

  @override
  void initState() {
    super.initState();
    _num = _pickRandom();
  }

  int _pickRandom({int? exclude}) {
    final nums = widget.ownedCardNumbers;
    var pool =
        exclude == null ? nums : nums.where((n) => n != exclude).toList();
    if (pool.isEmpty) {
      pool = nums;
    }
    final r = math.Random();
    return pool[r.nextInt(pool.length)];
  }

  void _redraw() {
    setState(() => _num = _pickRandom(exclude: _num));
  }

  @override
  Widget build(BuildContext context) {
    final path = bundledOracleAssetPath(_num);
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.52),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final h = c.maxHeight;
                  if (path == null) {
                    return Center(
                      child: Text(
                        '#$_num',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return Center(
                    child: Image.asset(
                      path,
                      width: w,
                      height: h,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          '#$_num',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '오라클 카드 #$_num (보유 중)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: widget.onClose,
                          child: const Text('닫기'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: widget.ownedCardNumbers.length < 2 ? null : _redraw,
                          child: const Text('다시 뽑기'),
                        ),
                      ),
                    ],
                  ),
                  if (widget.ownedCardNumbers.length < 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '다른 번호를 더 모으면 다시 뽑기를 쓸 수 있어요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens full-screen oracle draw from [ownedOracleCardNumbers] only.
Future<void> showOracleOverlay(
  BuildContext context, {
  required List<int> ownedOracleCardNumbers,
}) async {
  final owned = ownedOracleCardNumbers.toSet().toList()..sort();
  if (owned.isEmpty) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('보유한 오라클 카드가 없어요. 출석·상점에서 모은 뒤 이용해 주세요.'),
      ),
    );
    return;
  }

  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return OracleModal(
          ownedCardNumbers: owned,
          onClose: () => Navigator.of(ctx).pop(),
        );
      },
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}
