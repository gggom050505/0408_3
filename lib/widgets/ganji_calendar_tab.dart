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
  int _selectedLunarDay = 1;
  bool _showSolarAlways = false;

  @override
  void initState() {
    super.initState();
    final todayLunar = Solar.fromDate(DateTime.now()).getLunar();
    if (todayLunar.getYear() >= _minYear && todayLunar.getYear() <= _maxYear) {
      _year = todayLunar.getYear();
      _month = todayLunar.getMonth();
      _selectedLunarDay = todayLunar.getDay();
    }
  }

  List<int> _monthOptionsForYear(int year) {
    return LunarYear.fromYear(year).getMonthsInYear().map((m) => m.getMonth()).toList();
  }

  String _monthLabel(int month) {
    final prefix = month < 0 ? '윤' : '';
    return '$prefix${month.abs()}월';
  }

  void _moveMonth(int delta) {
    final current = LunarMonth.fromYm(_year, _month);
    if (current == null) return;
    final next = current.next(delta);
    final nextYear = next.getYear();
    if (nextYear < _minYear || nextYear > _maxYear) return;
    setState(() {
      _year = nextYear;
      _month = next.getMonth();
      _selectedLunarDay = 1;
    });
  }

  void _jumpToTodayLunar() {
    final todayLunar = Solar.fromDate(DateTime.now()).getLunar();
    final y = todayLunar.getYear().clamp(_minYear, _maxYear);
    setState(() {
      _year = y;
      _month = todayLunar.getMonth();
      _selectedLunarDay = todayLunar.getDay();
    });
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

  String _yearGanjiKo(Lunar lunar) => _ganjiKo(lunar.getYearInGanZhi());
  String _monthGanjiKo(Lunar lunar) => _ganjiKo(lunar.getMonthInGanZhi());

  String _weekdayName(DateTime d) => _weekdays[d.weekday % 7];

  @override
  Widget build(BuildContext context) {
    final monthOptions = _monthOptionsForYear(_year);
    if (!monthOptions.contains(_month)) {
      _month = monthOptions.isEmpty ? 1 : monthOptions.first;
    }
    final monthObj = LunarMonth.fromYm(_year, _month);
    final dayCount = monthObj?.getDayCount() ?? 29;
    if (_selectedLunarDay > dayCount) _selectedLunarDay = dayCount;
    final cells = List.generate(dayCount, (i) {
      final lunar = Lunar.fromYmd(_year, _month, i + 1);
      final solar = lunar.getSolar();
      final solarDate = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
      final today = DateTime.now();
      final isToday = today.year == solarDate.year && today.month == solarDate.month && today.day == solarDate.day;
      return (
        lunarDay: i + 1,
        solar: solarDate,
        ganji: _ganjiKo(lunar.getDayInGanZhi()),
        lunar: lunar,
        isToday: isToday,
      );
    });
    final firstWeekday = cells.isEmpty ? 0 : cells.first.solar.weekday % 7;
    final selected = cells[_selectedLunarDay - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _moveMonth(-1),
                icon: const Icon(Icons.chevron_left),
                tooltip: '이전 달',
              ),
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
                    _selectedLunarDay = 1;
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
                  setState(() {
                    _month = v;
                    _selectedLunarDay = 1;
                  });
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _moveMonth(1),
                icon: const Icon(Icons.chevron_right),
                tooltip: '다음 달',
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _jumpToTodayLunar,
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('오늘'),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '한국천문연구원 표준 음력 기준 · 윤달 지원',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text('양력 항상 표시', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              Switch(
                value: _showSolarAlways,
                onChanged: (v) => setState(() => _showSolarAlways = v),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '선택: 음력 ${_monthLabel(_month)} ${selected.lunarDay}일 (${_weekdayName(selected.solar)})  ·  양력 ${selected.solar.month}/${selected.solar.day}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _ganjiBadge(selected.ganji),
                const SizedBox(width: 8),
                Text('년 ${_yearGanjiKo(selected.lunar)} · 월 ${_monthGanjiKo(selected.lunar)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Row(
            children: _weekdays
                .asMap()
                .entries
                .map((entry) => Expanded(
                      child: Center(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: entry.key == 0
                                ? const Color(0xFFD62D20)
                                : (entry.key == 6 ? const Color(0xFF1D4ED8) : null),
                          ),
                        ),
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
                final isSelected = item.lunarDay == _selectedLunarDay;
                final isWeekend = item.solar.weekday % 7 == 0 || item.solar.weekday % 7 == 6;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    color: item.isToday ? const Color(0x22F2C300) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _selectedLunarDay = item.lunarDay),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${item.lunarDay}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isWeekend ? const Color(0xFFD62D20) : null,
                                ),
                              ),
                              if (item.isToday) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2C300),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('오늘', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          _ganjiBadge(item.ganji),
                          const Spacer(),
                          Text(
                            _showSolarAlways || item.lunarDay % 5 == 0 ? '${item.solar.month}/${item.solar.day}' : '',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
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
