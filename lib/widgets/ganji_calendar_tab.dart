import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';

import '../data/five_elements_guide.dart';
import '../data/ganji_sixty_day_patterns.dart';

class GanjiCalendarTab extends StatefulWidget {
  const GanjiCalendarTab({super.key});

  @override
  State<GanjiCalendarTab> createState() => _GanjiCalendarTabState();
}

class _GanjiCalendarTabState extends State<GanjiCalendarTab> {
  static const _minYear = 2026;
  static const _maxYear = 2035;
  static const _solarMinYear = 2020;
  static const _solarMaxYear = 2040;
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
  static const Map<String, String> _solarTermKorean = {
    '立春': '입춘',
    '雨水': '우수',
    '惊蛰': '경칩',
    '春分': '춘분',
    '清明': '청명',
    '谷雨': '곡우',
    '立夏': '입하',
    '小满': '소만',
    '芒种': '망종',
    '夏至': '하지',
    '小暑': '소서',
    '大暑': '대서',
    '立秋': '입추',
    '处暑': '처서',
    '白露': '백로',
    '秋分': '추분',
    '寒露': '한로',
    '霜降': '상강',
    '立冬': '입동',
    '小雪': '소설',
    '大雪': '대설',
    '冬至': '동지',
    '小寒': '소한',
    '大寒': '대한',
  };
  static const Map<String, String> _festivalKorean = {
    '春节': '설날',
    '元宵节': '정월대보름',
    '龙头节': '용두절',
    '上巳节': '삼짇날',
    '寒食节': '한식',
    '端午节': '단오',
    '七夕节': '칠석',
    '中元节': '백중',
    '中秋节': '추석',
    '重阳节': '중양절',
    '寒衣节': '한옷날',
    '下元节': '하원절',
    '腊八节': '납일',
    '除夕': '섣달그믐',
  };

  int _year = 2026;
  int _month = 1;
  int _selectedLunarDay = 1;
  int _solarYear = 2026;
  int _solarMonth = 1;
  int _solarDay = 1;
  final TextEditingController _solarDateController = TextEditingController();

  void _syncToTodayAsDefault() {
    final now = DateTime.now();
    final todayLunar = Solar.fromDate(now).getLunar();
    final inRange = todayLunar.getYear() >= _minYear && todayLunar.getYear() <= _maxYear;

    _solarYear = now.year;
    _solarMonth = now.month;
    _solarDay = now.day;
    _solarDateController.text = _formatYmd(now);

    if (inRange) {
      _year = todayLunar.getYear();
      _month = todayLunar.getMonth();
      _selectedLunarDay = todayLunar.getDay();
      return;
    }

    final fallbackLunar = Solar.fromDate(DateTime(_minYear, 1, 1)).getLunar();
    _year = fallbackLunar.getYear();
    _month = fallbackLunar.getMonth();
    _selectedLunarDay = fallbackLunar.getDay();
  }

  @override
  void initState() {
    super.initState();
    _syncToTodayAsDefault();
  }

  @override
  void dispose() {
    _solarDateController.dispose();
    super.dispose();
  }

  List<int> _monthOptionsForYear(int year) {
    return LunarYear.fromYear(year).getMonthsInYear().map((m) => m.getMonth()).toList();
  }

  String _monthLabel(int month) {
    final prefix = month < 0 ? '윤' : '';
    return '$prefix${month.abs()}월';
  }

  String _formatYmd(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
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
      _solarDateController.text = _formatYmd(DateTime.now());
    });
  }

  void _jumpToSolarInput() {
    final raw = _solarDateController.text.trim();
    final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(raw);
    if (m == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('양력 날짜 형식은 YYYY-MM-DD 로 입력해 주세요.')),
      );
      return;
    }
    final y = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    final d = int.tryParse(m.group(3)!);
    if (y == null || mo == null || d == null) return;
    final dt = DateTime(y, mo, d);
    if (dt.year != y || dt.month != mo || dt.day != d) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('유효한 날짜를 입력해 주세요.')),
      );
      return;
    }
    final lunar = Solar.fromDate(dt).getLunar();
    if (lunar.getYear() < _minYear || lunar.getYear() > _maxYear) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('지원 연도는 $_minYear~$_maxYear 입니다.')),
      );
      return;
    }
    setState(() {
      _year = lunar.getYear();
      _month = lunar.getMonth();
      _selectedLunarDay = lunar.getDay();
      _solarYear = dt.year;
      _solarMonth = dt.month;
      _solarDay = dt.day;
    });
  }

  void _jumpToSolarSelection() {
    final dt = DateTime(_solarYear, _solarMonth, _solarDay);
    _solarDateController.text = _formatYmd(dt);
    _jumpToSolarInput();
  }

  Future<void> _pickSolarDate() async {
    final now = DateTime.now();
    final parsed = DateTime.tryParse(_solarDateController.text.trim());
    final initial = parsed ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2040, 12, 31),
      helpText: '양력 날짜 선택',
      locale: const Locale('ko'),
    );
    if (picked == null) return;
    setState(() {
      _solarYear = picked.year;
      _solarMonth = picked.month;
      _solarDay = picked.day;
      _solarDateController.text = _formatYmd(picked);
    });
    _jumpToSolarSelection();
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

  String _toKoreanSolarTerm(String term) => _solarTermKorean[term] ?? term;
  String _toKoreanFestival(String label) => _festivalKorean[label] ?? label;

  int _specialLabelPriority(String label) {
    // 절기 > 명절/기타로 우선 노출
    if (_solarTermKorean.containsValue(label)) return 0;
    return 1;
  }

  List<String> _specialDayLabels(Lunar lunar) {
    final labels = <String>[];
    final jieQi = lunar.getJieQi().trim();
    if (jieQi.isNotEmpty) {
      labels.add(_toKoreanSolarTerm(jieQi));
    }
    final festivals = <String>[
      ...lunar.getFestivals(),
      ...lunar.getOtherFestivals(),
    ];
    for (final festival in festivals) {
      final cleaned = festival.trim();
      if (cleaned.isNotEmpty) {
        labels.add(_toKoreanFestival(cleaned));
      }
    }
    final unique = labels.toSet().toList();
    unique.sort((a, b) {
      final p = _specialLabelPriority(a).compareTo(_specialLabelPriority(b));
      if (p != 0) return p;
      return a.compareTo(b);
    });
    return unique;
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

  void _openGanjiDaySheet({
    required int lunarDay,
    required DateTime solar,
    required String dayGanjiKo,
    required Lunar lunar,
  }) {
    final dayPat = lookupGanjiDayPatternKo(dayGanjiKo);
    final yearKo = _yearGanjiKo(lunar);
    final monthKo = _monthGanjiKo(lunar);
    final yearPat = lookupGanjiDayPatternKo(yearKo);
    final monthPat = lookupGanjiDayPatternKo(monthKo);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '음력 ${_monthLabel(_month)} $lunarDay일 · '
                    '양력 ${solar.year}-${solar.month.toString().padLeft(2, '0')}-${solar.day.toString().padLeft(2, '0')} '
                    '(${_weekdayName(solar)})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '일진(그날의 간)',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _ganjiBadge(dayGanjiKo),
                      if (dayPat != null)
                        Text(
                          '#${dayPat.orderIndex}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                  if (dayPat != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      dayPat.themeShort,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayPat.patternNote,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.88,
                        ),
                      ),
                    ),
                    if (dayPat.notableYearEvent != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '역사적 명칭 예: ${dayPat.notableYearEvent}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '이 일진에 대한 자세한 패턴 문구는 준비 중이에요.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    '연간 · 월간 (참고)',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(
                        width: 36,
                        child: Text(
                          '연',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _ganjiBadge(yearKo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          yearPat?.patternNote ??
                              '같은 두 글자 간지의 기운을 연 단위로 보는 참고입니다.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (yearPat?.notableYearEvent != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '연호·사건명 예: ${yearPat!.notableYearEvent}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 36,
                        child: Text(
                          '월',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _ganjiBadge(monthKo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          monthPat?.themeShort ??
                              '이 음력 달의 월간을 요약한 참고입니다.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    kGanjiDisclaimerShortKo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiveElementsBanner(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.28)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Icon(
            Icons.auto_awesome_motion,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          title: Text(
            '오행(목·화·토·금·수) 안내',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            '성질·특성·기운의 기질 — 탭하여 펼치기',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kFiveElementsOneLinerKo,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...kFiveElementsSectionsOrdered.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e.symbolHan}  ${e.nameKo}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                e.natureKo,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.traitsKo,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.42,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kGanjiDisclaimerShortKo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          height: 1.38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    final fixedMonthLunar = Lunar.fromYmd(_year, _month, 1);
    final fixedMonthGanji = _monthGanjiKo(fixedMonthLunar);
    final selectedSpecials = _specialDayLabels(selected.lunar);

    final theme = Theme.of(context);
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
          const SizedBox(height: 6),
          Row(
            children: [
              DropdownButton<int>(
                value: _solarYear,
                items: List.generate(
                  _solarMaxYear - _solarMinYear + 1,
                  (i) => DropdownMenuItem(value: _solarMinYear + i, child: Text('${_solarMinYear + i}년')),
                ),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _solarYear = v;
                    final maxDay = _daysInMonth(_solarYear, _solarMonth);
                    if (_solarDay > maxDay) _solarDay = maxDay;
                  });
                },
              ),
              const SizedBox(width: 6),
              DropdownButton<int>(
                value: _solarMonth,
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}월')),
                ),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _solarMonth = v;
                    final maxDay = _daysInMonth(_solarYear, _solarMonth);
                    if (_solarDay > maxDay) _solarDay = maxDay;
                  });
                },
              ),
              const SizedBox(width: 6),
              DropdownButton<int>(
                value: _solarDay,
                items: List.generate(
                  _daysInMonth(_solarYear, _solarMonth),
                  (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}일')),
                ),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _solarDay = v);
                },
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _jumpToSolarSelection,
                child: const Text('이동'),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: '날짜 선택',
                onPressed: _pickSolarDate,
                icon: const Icon(Icons.calendar_month),
              ),
            ],
          ),
          Text(
            '한국천문연구원 표준 음력 기준 · 윤달 지원 · 양력 날짜 상시 표시',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          _buildFiveElementsBanner(theme),
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
                    '선택: 음력 ${_monthLabel(_month)} ${selected.lunarDay}일 (${_weekdayName(selected.solar)})  ·  양력 ${selected.solar.month}/${selected.solar.day}'
                    '${selectedSpecials.isNotEmpty ? '  ·  ${selectedSpecials.join(' · ')}' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('년', style: TextStyle(fontWeight: FontWeight.w700)),
                    _ganjiBadge(_yearGanjiKo(selected.lunar)),
                    const Text('월', style: TextStyle(fontWeight: FontWeight.w700)),
                    _ganjiBadge(fixedMonthGanji),
                    const Text('일진', style: TextStyle(fontWeight: FontWeight.w700)),
                    _ganjiBadge(selected.ganji),
                  ],
                ),
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
            child: LayoutBuilder(
              builder: (context, c) {
                final total = firstWeekday + cells.length;
                final rows = (total / 7).ceil().clamp(1, 6);
                const spacing = 6.0;
                final gridWidth = c.maxWidth;
                final cellWidth = (gridWidth - spacing * 6) / 7;
                final preferredHeight = cellWidth * 1.02;
                final cellHeight = preferredHeight > 102.0
                    ? preferredHeight
                    : 102.0;
                final gridHeight = rows * cellHeight + (rows - 1) * spacing;

                return Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: gridWidth,
                      child: SizedBox(
                        height: gridHeight,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: firstWeekday + cells.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: spacing,
                            crossAxisSpacing: spacing,
                            childAspectRatio: cellWidth / cellHeight,
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
                            final specials = _specialDayLabels(item.lunar);
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
                                onTap: () {
                                  setState(() => _selectedLunarDay = item.lunarDay);
                                  _openGanjiDaySheet(
                                    lunarDay: item.lunarDay,
                                    solar: item.solar,
                                    dayGanjiKo: item.ganji,
                                    lunar: item.lunar,
                                  );
                                },
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
                                        '${item.solar.month}/${item.solar.day}',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                      ),
                                      if (specials.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          specials.first,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFB45309),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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
