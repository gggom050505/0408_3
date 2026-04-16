import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

class GanjiCalendarTab extends StatefulWidget {
  const GanjiCalendarTab({super.key});

  @override
  State<GanjiCalendarTab> createState() => _GanjiCalendarTabState();
}

class _GanjiCalendarTabState extends State<GanjiCalendarTab> {
  static const _minYear = 2026;
  static const _maxYear = 2035;
  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];
  static const _stemKo = {
    '甲': '갑',
    '乙': '을',
    '丙': '병',
    '丁': '정',
    '戊': '무',
    '己': '기',
    '庚': '경',
    '辛': '신',
    '壬': '임',
    '癸': '계',
  };
  static const _branchKo = {
    '子': '자',
    '丑': '축',
    '寅': '인',
    '卯': '묘',
    '辰': '진',
    '巳': '사',
    '午': '오',
    '未': '미',
    '申': '신',
    '酉': '유',
    '戌': '술',
    '亥': '해',
  };

  int _year = 2026;
  int _month = 1;

  List<int> _monthOptionsForYear(int year) {
    return LunarYear.fromYear(year).getMonthsInYear().map((m) => m.getMonth()).toList();
  }

  String _monthLabel(int month) {
    final prefix = month < 0 ? '윤' : '';
    return '$prefix${month.abs()}월';
  }

  Color _fiveElementColor(String element) {
    switch (element) {
      case '목':
        return const Color(0xFF00A651);
      case '화':
        return const Color(0xFFE60012);
      case '토':
        return const Color(0xFFF2C300);
      case '금':
        return const Color(0xFF8A8A8A);
      case '수':
        return const Color(0xFF0B1A63);
      default:
        return Colors.black87;
    }
  }

  String _stemElement(String stem) {
    switch (stem) {
      case '갑':
      case '을':
        return '목';
      case '병':
      case '정':
        return '화';
      case '무':
      case '기':
        return '토';
      case '경':
      case '신':
        return '금';
      case '임':
      case '계':
        return '수';
      default:
        return '';
    }
  }

  String _branchElement(String branch) {
    switch (branch) {
      case '인':
      case '묘':
        return '목';
      case '사':
      case '오':
        return '화';
      case '진':
      case '술':
      case '축':
      case '미':
        return '토';
      case '신':
      case '유':
        return '금';
      case '해':
      case '자':
        return '수';
      default:
        return '';
    }
  }

  String _ganjiKo(String hanja) {
    if (hanja.length < 2) return hanja;
    return '${_stemKo[hanja[0]] ?? hanja[0]}${_branchKo[hanja[1]] ?? hanja[1]}';
  }

  Widget _ganjiBadge(String ganji) {
    final gan = ganji.isNotEmpty ? ganji[0] : '';
    final ji = ganji.length >= 2 ? ganji[1] : '';
    final ganColor = _fiveElementColor(_stemElement(gan));
    final jiColor = _fiveElementColor(_branchElement(ji));
    return Wrap(
      spacing: 2,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: ganColor, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(gan, style: TextStyle(color: ganColor, fontWeight: FontWeight.w900)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: jiColor, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(ji, style: TextStyle(color: jiColor, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthOptions = _monthOptionsForYear(_year);
    if (!monthOptions.contains(_month)) {
      _month = monthOptions.isEmpty ? 1 : monthOptions.first;
    }
    final monthObj = LunarMonth.fromYm(_year, _month);
    final dayCount = monthObj?.getDayCount() ?? 29;
    final cells = List.generate(dayCount, (i) {
      final lunar = Lunar.fromYmd(_year, _month, i + 1);
      final solar = lunar.getSolar();
      final solarDate = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
      return (lunarDay: i + 1, solar: solarDate, ganji: _ganjiKo(lunar.getDayInGanZhi()));
    });
    final firstWeekday = cells.isEmpty ? 0 : cells.first.solar.weekday % 7;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DropdownButton<int>(
                value: _year,
                items: List.generate(
                  _maxYear - _minYear + 1,
                  (i) => DropdownMenuItem(value: _minYear + i, child: Text('${_minYear + i}년')),
                ),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _year = v;
                    final options = _monthOptionsForYear(_year);
                    if (!options.contains(_month)) _month = options.first;
                  });
                },
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _month,
                items: monthOptions
                    .map((m) => DropdownMenuItem(value: m, child: Text(_monthLabel(m))))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _month = v);
                },
              ),
            ],
          ),
          Text(
            '한국천문연구원 표준 음력 기준 · 윤달 지원',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: _weekdays
                .map((w) => Expanded(
                      child: Center(
                        child: Text(w, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              itemCount: firstWeekday + cells.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                if (index < firstWeekday) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }
                final item = cells[index - firstWeekday];
                return DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.lunarDay}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        _ganjiBadge(item.ganji),
                        const Spacer(),
                        Text(
                          '${item.solar.month}/${item.solar.day}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
