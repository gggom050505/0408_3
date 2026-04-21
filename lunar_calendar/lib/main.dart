import 'dart:convert';

// ignore_for_file: unused_element, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LunarCalendarApp());
}

class LunarCalendarApp extends StatelessWidget {
  const LunarCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '음력 달력',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const LunarCalendarPage(),
    );
  }
}

class ChecklistItem {
  ChecklistItem({
    required this.text,
    this.isDone = false,
  });

  final String text;
  final bool isDone;

  ChecklistItem copyWith({
    String? text,
    bool? isDone,
  }) {
    return ChecklistItem(
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isDone': isDone,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      text: '${json['text'] ?? ''}',
      isDone: json['isDone'] == true,
    );
  }
}

class DayMemo {
  DayMemo({
    this.note = '',
    List<String>? tags,
    List<ChecklistItem>? checklist,
  })  : tags = tags ?? <String>[],
        checklist = checklist ?? <ChecklistItem>[];

  final String note;
  final List<String> tags;
  final List<ChecklistItem> checklist;

  bool get hasContent {
    return note.trim().isNotEmpty || tags.isNotEmpty || checklist.isNotEmpty;
  }

  DayMemo copyWith({
    String? note,
    List<String>? tags,
    List<ChecklistItem>? checklist,
  }) {
    return DayMemo(
      note: note ?? this.note,
      tags: tags ?? List<String>.from(this.tags),
      checklist: checklist ?? List<ChecklistItem>.from(this.checklist),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'note': note,
      'tags': tags,
      'checklist': checklist.map((item) => item.toJson()).toList(),
    };
  }

  factory DayMemo.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    final checklistRaw = json['checklist'];
    return DayMemo(
      note: '${json['note'] ?? ''}',
      tags: tagsRaw is List ? tagsRaw.map((e) => '$e').where((e) => e.trim().isNotEmpty).toList() : <String>[],
      checklist: checklistRaw is List
          ? checklistRaw
              .whereType<Map>()
              .map((e) => ChecklistItem.fromJson(e.cast<String, dynamic>()))
              .where((e) => e.text.trim().isNotEmpty)
              .toList()
          : <ChecklistItem>[],
    );
  }
}

class AssetItem {
  const AssetItem({
    required this.name,
    required this.market,
    required this.element,
  });

  final String name;
  final String market;
  final String element;

  AssetItem copyWith({
    String? name,
    String? market,
    String? element,
  }) {
    return AssetItem(
      name: name ?? this.name,
      market: market ?? this.market,
      element: element ?? this.element,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'market': market,
      'element': element,
    };
  }

  factory AssetItem.fromJson(Map<String, dynamic> json) {
    return AssetItem(
      name: '${json['name'] ?? ''}',
      market: '${json['market'] ?? '주식'}',
      element: '${json['element'] ?? '토'}',
    );
  }
}

class AssetPlan {
  AssetPlan({
    this.buyPrice = '',
    this.stopLoss = '',
    this.memo = '',
  });

  final String buyPrice;
  final String stopLoss;
  final String memo;

  AssetPlan copyWith({
    String? buyPrice,
    String? stopLoss,
    String? memo,
  }) {
    return AssetPlan(
      buyPrice: buyPrice ?? this.buyPrice,
      stopLoss: stopLoss ?? this.stopLoss,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'buyPrice': buyPrice,
      'stopLoss': stopLoss,
      'memo': memo,
    };
  }

  factory AssetPlan.fromJson(Map<String, dynamic> json) {
    return AssetPlan(
      buyPrice: '${json['buyPrice'] ?? ''}',
      stopLoss: '${json['stopLoss'] ?? ''}',
      memo: '${json['memo'] ?? ''}',
    );
  }
}

class LunarDayCell {
  const LunarDayCell({
    required this.lunarDay,
    required this.solarDate,
  });

  final int lunarDay;
  final DateTime solarDate;
}

class LunarCalendarPage extends StatefulWidget {
  const LunarCalendarPage({super.key});

  @override
  State<LunarCalendarPage> createState() => _LunarCalendarPageState();
}

class _LunarCalendarPageState extends State<LunarCalendarPage> with WidgetsBindingObserver {
  static const Map<String, String> _stemToKorean = {
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
  static const Map<String, String> _branchToKorean = {
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
  static const List<String> _weekdays = ['일', '월', '화', '수', '목', '금', '토'];
  static const List<String> _stemsKorean = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
  static const List<String> _branchesKorean = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];
  static final DateTime _dayCycleBaseUtc = DateTime.utc(1984, 2, 2); // 갑자일 기준
  static const String _prefsYearKey = 'year';
  static const String _prefsMonthKey = 'month';
  static const String _prefsSelectedDayKey = 'selected_day';
  static const String _prefsSelectedLunarDayKey = 'selected_lunar_day';
  static const String _prefsMemosKey = 'memos_json';
  static const String _prefsRiskProfileKey = 'risk_profile';
  static const String _prefsAssetPlansKey = 'asset_plans_json';
  static const String _prefsWatchAssetsKey = 'watch_assets_json';
  static const String _prefsGanjiGuideSeenKey = 'ganji_guide_seen';
  static const String _prefsTodayVisitDateKey = 'today_visit_date_v1';
  static const String _prefsTodayVisitCountKey = 'today_visit_count_v1';
  static const int _minYear = 2026;
  static const int _maxYear = 2030;
  static const List<String> _sajuFavorableElements = ['화', '토'];
  static const List<String> _sajuCautionElements = ['목', '수'];
  static const List<AssetItem> _defaultWatchAssets = [
    // 목(2)
    AssetItem(name: 'ADA', market: '코인', element: '목'),
    AssetItem(name: 'DOT', market: '코인', element: '목'),
    // 화(2)
    AssetItem(name: 'SOL', market: '코인', element: '화'),
    AssetItem(name: 'AVAX', market: '코인', element: '화'),
    // 토(2)
    AssetItem(name: 'BTC', market: '코인', element: '토'),
    AssetItem(name: 'LTC', market: '코인', element: '토'),
    // 금(2)
    AssetItem(name: 'XRP', market: '코인', element: '금'),
    AssetItem(name: 'XLM', market: '코인', element: '금'),
    // 수(2)
    AssetItem(name: 'ETH', market: '코인', element: '수'),
    AssetItem(name: 'LINK', market: '코인', element: '수'),
  ];
  static const Map<String, List<String>> _internationalDays = {
    '01-01': ['신정(New Year\'s Day)'],
    '01-27': ['국제 홀로코스트 추모의 날'],
    '02-04': ['세계 암의 날'],
    '02-11': ['여성과 소녀의 과학의 날'],
    '03-08': ['세계 여성의 날'],
    '03-20': ['국제 행복의 날'],
    '03-21': ['국제 인종차별 철폐의 날'],
    '03-22': ['세계 물의 날'],
    '04-07': ['세계 보건의 날'],
    '04-22': ['지구의 날'],
    '05-01': ['노동절'],
    '05-08': ['세계 적십자의 날'],
    '05-15': ['국제 가정의 날'],
    '05-17': ['세계 정보사회/통신의 날'],
    '06-05': ['세계 환경의 날'],
    '06-20': ['세계 난민의 날'],
    '06-26': ['세계 마약퇴치의 날'],
    '07-18': ['넬슨 만델라 국제의 날'],
    '08-12': ['국제 청년의 날'],
    '08-19': ['세계 인도주의의 날'],
    '09-08': ['세계 문해의 날'],
    '09-21': ['국제 평화의 날'],
    '09-27': ['세계 관광의 날'],
    '10-01': ['국제 노인의 날'],
    '10-05': ['세계 교사의 날'],
    '10-10': ['세계 정신건강의 날'],
    '10-16': ['세계 식량의 날'],
    '10-24': ['유엔의 날'],
    '11-16': ['국제 관용의 날'],
    '11-20': ['세계 어린이의 날'],
    '12-01': ['세계 에이즈의 날'],
    '12-03': ['국제 장애인의 날'],
    '12-10': ['세계 인권의 날'],
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
  static const Map<String, String> _specialLabelShort = {
    '음력 초하루': '초하루',
    '신정(New Year\'s Day)': '신정',
    '국제 홀로코스트 추모의 날': '홀로코스트 추모',
    '여성과 소녀의 과학의 날': '과학의 날',
    '국제 인종차별 철폐의 날': '인종차별 철폐',
    '세계 정보사회/통신의 날': '정보사회의 날',
    '세계 정신건강의 날': '정신건강의 날',
    '국제 장애인의 날': '장애인의 날',
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
  int _month = 3;
  DateTime? _selectedDate;
  String _riskProfile = '중립형';
  bool _showGanjiGuide = true;
  bool _hasSeenGanjiGuide = false;
  bool _showThreePillarsInCell = true;
  int _todayVisitCount = 1;

  final Map<String, DayMemo> _memos = {};
  final Map<String, AssetPlan> _assetPlans = {};
  final List<AssetItem> _watchAssets = List<AssetItem>.from(_defaultWatchAssets);
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _checklistController = TextEditingController();
  bool _isRestoring = false;
  bool _isPersisting = false;
  bool _needsPersistAgain = false;

  @override
  void initState() {
    super.initState();
    _registerTodayVisitLocal();
    WidgetsBinding.instance.addObserver(this);
    final solar = Lunar.fromYmd(_year, _month, 1).getSolar();
    _selectedDate = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
    _restoreFromStorage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _memoController.dispose();
    _tagController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _schedulePersist();
    }
  }

  String _dateKey(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  String _todayKey() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  Future<void> _registerTodayVisitLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final savedDay = prefs.getString(_prefsTodayVisitDateKey) ?? '';
    var count = prefs.getInt(_prefsTodayVisitCountKey) ?? 0;
    if (savedDay != today) {
      count = 1;
    } else {
      count += 1;
    }
    await prefs.setString(_prefsTodayVisitDateKey, today);
    await prefs.setInt(_prefsTodayVisitCountKey, count);
    if (!mounted) return;
    setState(() => _todayVisitCount = count);
  }

  List<int> _monthOptionsForYear(int year) {
    return LunarYear.fromYear(year).getMonthsInYear().map((m) => m.getMonth()).toList();
  }

  String _monthLabel(int month, {bool withSuffix = true}) {
    final prefix = month < 0 ? '윤' : '';
    final value = month.abs();
    return withSuffix ? '$prefix$value월' : '$prefix$value';
  }

  int _normalizeMonthForYear(int year, int month) {
    final options = _monthOptionsForYear(year);
    if (options.isEmpty) return 1;
    if (options.contains(month)) return month;
    for (final candidate in options) {
      if (candidate.abs() == month.abs()) return candidate;
    }
    return options.first;
  }

  String _ganji(DateTime date) {
    final lunar = Solar.fromYmd(date.year, date.month, date.day).getLunar();
    return _dayGanjiForLunar(lunar);
  }

  int _mod(int value, int n) {
    final r = value % n;
    return r < 0 ? r + n : r;
  }

  String _ganjiFromIndex(int cycleIndex) {
    final stem = _stemsKorean[_mod(cycleIndex, 10)];
    final branch = _branchesKorean[_mod(cycleIndex, 12)];
    return '$stem$branch';
  }

  String _ganjiFromHanja(String hanja) {
    if (hanja.length < 2) return hanja;
    final stem = _stemToKorean[hanja.substring(0, 1)] ?? hanja.substring(0, 1);
    final branch = _branchToKorean[hanja.substring(1, 2)] ?? hanja.substring(1, 2);
    return '$stem$branch';
  }

  String _lunarYmdKey(Lunar lunar) {
    final mm = lunar.getMonth().toString().padLeft(2, '0');
    final dd = lunar.getDay().toString().padLeft(2, '0');
    return '${lunar.getYear()}-$mm-$dd';
  }

  String _dayGanjiForLunar(Lunar lunar) {
    return _ganjiFromHanja(lunar.getDayInGanZhi());
  }

  String _yearGanjiKorean(Lunar lunar) {
    return _ganjiFromHanja(lunar.getYearInGanZhi());
  }

  String _monthGanjiKorean(Lunar lunar) {
    return _ganjiFromHanja(lunar.getMonthInGanZhi());
  }

  String _yearGanjiByFormula(Lunar lunar) {
    // 서기 4년을 갑자(0)로 두는 60갑자 순환 계산
    final cycleIndex = _mod(lunar.getYear() - 4, 60);
    return _ganjiFromIndex(cycleIndex);
  }

  String _monthGanjiByFormula(Lunar lunar) {
    // 오호법: 월건은 정월(인월) 기준으로 순환, 윤달은 앞달 월건 반복(abs month)
    final yearStemIndex = _mod(lunar.getYear() - 4, 10);
    final monthNumber = lunar.getMonth().abs(); // 윤달은 전월 반복
    final monthStemIndex = _mod(yearStemIndex * 2 + monthNumber + 1, 10);
    final monthBranchIndex = _mod(monthNumber + 1, 12); // 정월=인(2)
    return '${_stemsKorean[monthStemIndex]}${_branchesKorean[monthBranchIndex]}';
  }

  String _dayGanjiByFormula(DateTime solarDate) {
    final targetUtc = DateTime.utc(solarDate.year, solarDate.month, solarDate.day);
    final diffDays = targetUtc.difference(_dayCycleBaseUtc).inDays;
    final cycleIndex = _mod(diffDays, 60);
    return _ganjiFromIndex(cycleIndex);
  }

  ({int yearMismatch, int monthMismatch, int dayMismatch}) _monthlyGanjiValidation(List<LunarDayCell> days) {
    var yearMismatch = 0;
    var monthMismatch = 0;
    var dayMismatch = 0;

    for (final cell in days) {
      final solarDate = cell.solarDate;
      final lunar = Solar.fromYmd(solarDate.year, solarDate.month, solarDate.day).getLunar();

      final formulaYear = _yearGanjiByFormula(lunar);
      final formulaMonth = _monthGanjiByFormula(lunar);
      final formulaDay = _dayGanjiByFormula(solarDate);

      final libYear = _ganjiFromHanja(lunar.getYearInGanZhi());
      final libMonth = _ganjiFromHanja(lunar.getMonthInGanZhi());
      final libDay = _ganjiFromHanja(lunar.getDayInGanZhi());

      if (formulaYear != libYear) yearMismatch++;
      if (formulaMonth != libMonth) monthMismatch++;
      if (formulaDay != libDay) dayMismatch++;
    }

    return (yearMismatch: yearMismatch, monthMismatch: monthMismatch, dayMismatch: dayMismatch);
  }

  String _stemFromGanji(String ganji) {
    return ganji.isNotEmpty ? ganji.substring(0, 1) : '';
  }

  String _branchFromGanji(String ganji) {
    return ganji.length >= 2 ? ganji.substring(1, 2) : '';
  }

  Color _fiveElementColor(String element) {
    switch (element) {
      case '목':
        return const Color(0xFF00A651); // 청/녹
      case '화':
        return const Color(0xFFE60012); // 적
      case '토':
        return const Color(0xFFF2C300); // 황
      case '금':
        return const Color(0xFF8A8A8A); // 백(가독성 위해 은회색)
      case '수':
        return const Color(0xFF0B1A63); // 흑/남청
      default:
        return Colors.black;
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

  Color _ganColor(String ganji) {
    return _fiveElementColor(_stemElement(_stemFromGanji(ganji)));
  }

  Color _jiColor(String ganji) {
    return _fiveElementColor(_branchElement(_branchFromGanji(ganji)));
  }

  Widget _buildGanjiBadge(
    String ganji, {
    required double fontSize,
    EdgeInsetsGeometry? padding,
    double radius = 8,
    FontWeight fontWeight = FontWeight.w900,
  }) {
    final gan = _stemFromGanji(ganji);
    final ji = _branchFromGanji(ganji);
    final ganColor = _ganColor(ganji);
    final jiColor = _jiColor(ganji);
    final chipPadding = padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 2);

    Widget buildChip(String text, Color color) {
      return Container(
        padding: chipPadding,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: color,
            width: 3,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: 1.0,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 3,
      runSpacing: 1,
      children: [
        buildChip(gan, ganColor),
        buildChip(ji, jiColor),
      ],
    );
  }

  Widget _buildTopGanjiSummary(Lunar lunar, bool isVeryNarrow) {
    final yearGanji = _yearGanjiKorean(lunar);
    final monthGanji = _monthGanjiKorean(lunar);
    final dayGanji = _dayGanjiForLunar(lunar);
    final fontSize = isVeryNarrow ? 14.0 : 16.0;
    final titleStyle = TextStyle(
      fontSize: isVeryNarrow ? 11 : 12,
      color: Colors.grey.shade700,
      fontWeight: FontWeight.w600,
    );

    Widget buildItem(String label, String ganji, String unit) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: titleStyle),
          Text(
            '$ganji$unit',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.1,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: isVeryNarrow ? 8 : 12,
      runSpacing: 6,
      children: [
        buildItem('년주', yearGanji, '년'),
        buildItem('월주', monthGanji, '월'),
        buildItem('일주', dayGanji, '일'),
      ],
    );
  }

  Widget _buildGanjiImportantBanner(bool isVeryNarrow) {
    final baseStyle = TextStyle(
      fontSize: isVeryNarrow ? 11 : 12,
      color: Colors.brown.shade900,
      height: 1.35,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              final nextShow = !_showGanjiGuide;
              setState(() {
                _showGanjiGuide = nextShow;
                if (!nextShow) {
                  _hasSeenGanjiGuide = true;
                }
              });
              _schedulePersist();
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '**중요** 간지 계산법',
                    style: TextStyle(
                      fontSize: isVeryNarrow ? 12 : 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.brown.shade900,
                    ),
                  ),
                ),
                Icon(
                  _showGanjiGuide ? Icons.expand_less : Icons.expand_more,
                  color: Colors.brown.shade800,
                ),
              ],
            ),
          ),
          if (_showGanjiGuide) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• 이 앱은 한국천문연구원 표준 음력(합삭 기준) 흐름을 우선합니다.', style: baseStyle),
                  Text('• 월건(월주)은 절기 기준이라 음력 월 이름과 항상 1:1로 일치하지 않습니다.', style: baseStyle),
                  Text('• 윤달은 새 월건을 만들지 않고 앞달 월건을 반복합니다.', style: baseStyle),
                  Text('• 경계 시각(입춘/절입 시각, 자시 경계) 근처 출생은 결과가 달라질 수 있습니다.', style: baseStyle),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssetNameBadge(AssetItem item) {
    final color = _elementColor(item.element);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2.4),
      ),
      child: Text(
        '${item.market} ${item.name}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildAssetSymbolBadge(AssetItem item) {
    final color = _elementColor(item.element);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        item.name,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          height: 1.0,
        ),
      ),
    );
  }

  Future<void> _restoreFromStorage() async {
    _isRestoring = true;
    final prefs = await SharedPreferences.getInstance();
    final savedYear = prefs.getInt(_prefsYearKey) ?? _year;
    final savedMonth = prefs.getInt(_prefsMonthKey) ?? _month;
    final savedSelectedDay = prefs.getInt(_prefsSelectedLunarDayKey) ?? prefs.getInt(_prefsSelectedDayKey) ?? 1;
    final memosJson = prefs.getString(_prefsMemosKey);
    final plansJson = prefs.getString(_prefsAssetPlansKey);
    final assetsJson = prefs.getString(_prefsWatchAssetsKey);
    final savedRiskProfile = prefs.getString(_prefsRiskProfileKey);
    final savedGanjiGuideSeen = prefs.getBool(_prefsGanjiGuideSeenKey) ?? false;
    final nextMemos = <String, DayMemo>{};
    final nextPlans = <String, AssetPlan>{};
    final nextAssets = <AssetItem>[];

    if (memosJson != null && memosJson.isNotEmpty) {
      final decoded = jsonDecode(memosJson);
      if (decoded is Map<String, dynamic>) {
        for (final entry in decoded.entries) {
          final raw = entry.value;
          if (raw is String) {
            nextMemos[entry.key] = DayMemo(note: raw);
          } else if (raw is Map<String, dynamic>) {
            nextMemos[entry.key] = DayMemo.fromJson(raw);
          } else if (raw is Map) {
            nextMemos[entry.key] = DayMemo.fromJson(raw.cast<String, dynamic>());
          }
        }
      }
    }
    if (plansJson != null && plansJson.isNotEmpty) {
      final decoded = jsonDecode(plansJson);
      if (decoded is Map<String, dynamic>) {
        for (final entry in decoded.entries) {
          final raw = entry.value;
          if (raw is Map<String, dynamic>) {
            nextPlans[entry.key] = AssetPlan.fromJson(raw);
          } else if (raw is Map) {
            nextPlans[entry.key] = AssetPlan.fromJson(raw.cast<String, dynamic>());
          }
        }
      }
    }
    if (assetsJson != null && assetsJson.isNotEmpty) {
      final decoded = jsonDecode(assetsJson);
      if (decoded is List) {
        for (final raw in decoded) {
          if (raw is Map<String, dynamic>) {
            final item = AssetItem.fromJson(raw);
            if (item.name.trim().isNotEmpty) nextAssets.add(item);
          } else if (raw is Map) {
            final item = AssetItem.fromJson(raw.cast<String, dynamic>());
            if (item.name.trim().isNotEmpty) nextAssets.add(item);
          }
        }
      }
    }

    if (!mounted) {
      _isRestoring = false;
      return;
    }
    setState(() {
      _year = savedYear.clamp(_minYear, _maxYear);
      _month = _normalizeMonthForYear(_year, savedMonth);
      final maxDay = LunarMonth.fromYm(_year, _month)?.getDayCount() ?? 29;
      final day = savedSelectedDay.clamp(1, maxDay);
      final solar = Lunar.fromYmd(_year, _month, day).getSolar();
      _selectedDate = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
      _memos
        ..clear()
        ..addAll(nextMemos);
      _assetPlans
        ..clear()
        ..addAll(nextPlans);
      final restoredCoinsOnly = nextAssets.where((e) => e.market == '코인').toList();
      _watchAssets
        ..clear()
        ..addAll(restoredCoinsOnly.isEmpty ? _defaultWatchAssets : restoredCoinsOnly);
      if (savedRiskProfile == '보수형' || savedRiskProfile == '중립형' || savedRiskProfile == '공격형') {
        _riskProfile = savedRiskProfile!;
      }
      _hasSeenGanjiGuide = savedGanjiGuideSeen;
      _showGanjiGuide = !_hasSeenGanjiGuide;
      final selectedMemo = _memos[_dateKey(_selectedDate!)] ?? DayMemo();
      _memoController.text = selectedMemo.note;
      _tagController.text = selectedMemo.tags.join(', ');
    });
    _isRestoring = false;
  }

  Future<void> _persistToStorage() async {
    if (_isRestoring) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsYearKey, _year);
    await prefs.setInt(_prefsMonthKey, _month);
    final selectedLunarDay = _selectedDate == null ? 1 : Solar.fromDate(_selectedDate!).getLunar().getDay();
    await prefs.setInt(_prefsSelectedLunarDayKey, selectedLunarDay);
    await prefs.setInt(_prefsSelectedDayKey, selectedLunarDay);
    await prefs.setString(_prefsRiskProfileKey, _riskProfile);
    final jsonMap = _memos.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString(_prefsMemosKey, jsonEncode(jsonMap));
    final planMap = _assetPlans.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString(_prefsAssetPlansKey, jsonEncode(planMap));
    final assetList = _watchAssets.map((e) => e.toJson()).toList();
    await prefs.setString(_prefsWatchAssetsKey, jsonEncode(assetList));
    await prefs.setBool(_prefsGanjiGuideSeenKey, _hasSeenGanjiGuide);
  }

  void _schedulePersist() {
    if (_isRestoring) return;
    if (_isPersisting) {
      _needsPersistAgain = true;
      return;
    }
    _isPersisting = true;
    () async {
      try {
        do {
          _needsPersistAgain = false;
          await _persistToStorage();
        } while (_needsPersistAgain);
      } finally {
        _isPersisting = false;
      }
    }();
  }

  DayMemo _memoFor(DateTime date) {
    return _memos[_dateKey(date)] ?? DayMemo();
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _eventsFor(DateTime date) {
    final key = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _internationalDays[key] ?? const <String>[];
  }

  String _toKoreanSolarTerm(String term) {
    return _solarTermKorean[term] ?? term;
  }

  int _specialLabelPriority(String label) {
    // 절기(입춘/입동 등)를 최우선으로 보여 사용자 인지가 쉽도록 정렬합니다.
    if (_solarTermKorean.containsValue(label)) return 0;
    if (label == '음력 초하루') return 1;
    return 2;
  }

  String _shortSpecialLabel(String label) {
    final mapped = _specialLabelShort[label] ?? label;
    final withoutParen = mapped.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
    return withoutParen.trim();
  }

  String _toKoreanSpecialLabel(String label) {
    return _festivalKorean[label] ?? label;
  }

  List<String> _specialDayLabels(LunarDayCell dayCell) {
    final labels = <String>[];
    if (dayCell.lunarDay == 1) {
      labels.add('음력 초하루');
    }
    final lunar = Solar.fromDate(dayCell.solarDate).getLunar();
    final jieQi = lunar.getJieQi();
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
        labels.add(_toKoreanSpecialLabel(cleaned));
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

  List<String> _displaySpecialLabels(LunarDayCell dayCell, {required bool compact}) {
    final sorted = _specialDayLabels(dayCell);
    if (sorted.isEmpty) return const <String>[];
    if (compact) {
      // 칸이 좁을 때도 절기는 항상 보이게 우선 선택합니다.
      String? solarTerm;
      for (final label in sorted) {
        if (_solarTermKorean.containsValue(label)) {
          solarTerm = label;
          break;
        }
      }
      return <String>[_shortSpecialLabel(solarTerm ?? sorted.first)];
    }
    return sorted.take(2).map(_shortSpecialLabel).toList();
  }

  Color _elementColor(String element) {
    return _fiveElementColor(element);
  }

  int _signalScore(DateTime date, AssetItem item) {
    final ganji = _ganji(date);
    final stemElement = _stemElement(_stemFromGanji(ganji));
    final branchElement = _branchElement(_branchFromGanji(ganji));
    int score = 0;

    if (_sajuFavorableElements.contains(item.element)) score += 2;
    if (_sajuCautionElements.contains(item.element)) score -= 2;

    if (_sajuFavorableElements.contains(stemElement)) score += 1;
    if (_sajuFavorableElements.contains(branchElement)) score += 1;
    if (_sajuCautionElements.contains(stemElement)) score -= 1;
    if (_sajuCautionElements.contains(branchElement)) score -= 1;

    if (stemElement == item.element) score += 1;
    if (branchElement == item.element) score += 1;

    return score;
  }

  int _buyThreshold() {
    switch (_riskProfile) {
      case '보수형':
        return 5;
      case '공격형':
        return 3;
      default:
        return 4;
    }
  }

  int _sellThreshold() {
    switch (_riskProfile) {
      case '보수형':
        return -1;
      case '공격형':
        return -3;
      default:
        return -2;
    }
  }

  String _digitsOnly(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _formatThousands(String input) {
    final digits = _digitsOnly(input);
    if (digits.isEmpty) return '';
    final chars = digits.split('').reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(chars[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  String _timingText(String market, String signalLabel) {
    if (signalLabel == '매수 우세') return '$market 매수타이밍';
    if (signalLabel == '매도/비중축소') return '$market 매도타이밍';
    return '$market 관망타이밍';
  }

  List<AssetItem> _assetsByTiming(DateTime date, String signalLabel) {
    return _watchAssets.where((a) => _signalLabel(_signalScore(date, a)) == signalLabel).toList();
  }

  String _fortuneGrade(int score) {
    if (score >= 6) return '대길';
    if (score >= _buyThreshold()) return '길';
    if (score <= -4) return '경계';
    if (score <= _sellThreshold()) return '주의';
    return '평';
  }

  Color _fortuneGradeColor(String grade) {
    switch (grade) {
      case '대길':
        return const Color(0xFF008E3A);
      case '길':
        return const Color(0xFF1C9F4A);
      case '주의':
        return const Color(0xFFE67E22);
      case '경계':
        return const Color(0xFFD62D20);
      default:
        return const Color(0xFF5E5E5E);
    }
  }

  String _krw(String value) {
    final formatted = _formatThousands(value);
    if (formatted.isEmpty) return '';
    return '$formatted원';
  }

  String _signalLabel(int score) {
    if (score >= _buyThreshold()) return '매수 우세';
    if (score <= _sellThreshold()) return '매도/비중축소';
    return '관망';
  }

  Color _signalColor(int score) {
    if (score >= _buyThreshold()) return const Color(0xFF0A8F3C);
    if (score <= _sellThreshold()) return const Color(0xFFD62D20);
    return const Color(0xFF666666);
  }

  AssetPlan _planFor(AssetItem item) {
    return _assetPlans[item.name] ?? AssetPlan();
  }

  Future<void> _savePlanFor(AssetItem item, AssetPlan plan) async {
    setState(() {
      _assetPlans[item.name] = plan;
    });
    _schedulePersist();
  }

  Future<void> _addWatchAsset(AssetItem item) async {
    final exists = _watchAssets.any((e) => e.name.toUpperCase() == item.name.toUpperCase());
    if (exists) return;
    setState(() {
      _watchAssets.add(item);
    });
    _schedulePersist();
  }

  Future<void> _removeWatchAsset(AssetItem item) async {
    setState(() {
      _watchAssets.removeWhere((e) => e.name == item.name);
      _assetPlans.remove(item.name);
    });
    _schedulePersist();
  }

  Future<void> _reorderWatchAsset(int oldIndex, int newIndex) async {
    setState(() {
      var targetIndex = newIndex;
      if (targetIndex > oldIndex) {
        targetIndex -= 1;
      }
      final moved = _watchAssets.removeAt(oldIndex);
      _watchAssets.insert(targetIndex, moved);
    });
    _schedulePersist();
  }

  Future<void> _showManageAssetsDialog(BuildContext context) async {
    final symbolController = TextEditingController();
    final searchController = TextEditingController();
    const market = '코인';
    String element = '화';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = searchController.text.trim().toUpperCase();
            final filteredAssets = _watchAssets.where((item) {
              final matchQuery =
                  query.isEmpty || item.name.toUpperCase().contains(query) || item.element.contains(query);
              return matchQuery;
            }).toList();
            return AlertDialog(
              title: const Text('관심 종목 관리'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('현재 종목 (드래그로 순서 변경)'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: '검색 (심볼/오행)',
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 240,
                        child: filteredAssets.length == _watchAssets.length
                            ? ReorderableListView.builder(
                                buildDefaultDragHandles: false,
                                itemCount: _watchAssets.length,
                                onReorder: (oldIndex, newIndex) async {
                                  await _reorderWatchAsset(oldIndex, newIndex);
                                  if (context.mounted) setDialogState(() {});
                                },
                                itemBuilder: (context, index) {
                                  final item = _watchAssets[index];
                                  return Column(
                                    key: ValueKey('${item.name}-${item.market}-${item.element}'),
                                    children: [
                                      ListTile(
                                        dense: true,
                                        title: _buildAssetNameBadge(item),
                                        subtitle: Text('오행: ${item.element}'),
                                        leading: ReorderableDragStartListener(
                                          index: index,
                                          child: const Icon(Icons.drag_indicator),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () async {
                                            await _removeWatchAsset(item);
                                            if (context.mounted) setDialogState(() {});
                                          },
                                        ),
                                      ),
                                      const Divider(height: 1),
                                    ],
                                  );
                                },
                              )
                            : ListView.separated(
                                itemCount: filteredAssets.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = filteredAssets[index];
                                  return ListTile(
                                    dense: true,
                                    title: _buildAssetNameBadge(item),
                                    subtitle: Text('오행: ${item.element}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () async {
                                        await _removeWatchAsset(item);
                                        if (context.mounted) setDialogState(() {});
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      const Text('종목 추가'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: symbolController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '종목 코드/심볼 (예: MSFT, BTC)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: market,
                              readOnly: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: '시장(고정)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: element,
                              items: const [
                                DropdownMenuItem(value: '목', child: Text('목')),
                                DropdownMenuItem(value: '화', child: Text('화')),
                                DropdownMenuItem(value: '토', child: Text('토')),
                                DropdownMenuItem(value: '금', child: Text('금')),
                                DropdownMenuItem(value: '수', child: Text('수')),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setDialogState(() => element = v);
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: '오행',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () async {
                          final symbol = symbolController.text.trim().toUpperCase();
                          if (symbol.isEmpty) return;
                          await _addWatchAsset(AssetItem(name: symbol, market: market, element: element));
                          symbolController.clear();
                          if (context.mounted) setDialogState(() {});
                        },
                        child: const Text('종목 추가'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        );
      },
    );
    symbolController.dispose();
    searchController.dispose();
  }

  String _stemYinYang(String stem) {
    switch (stem) {
      case '갑':
      case '병':
      case '무':
      case '경':
      case '임':
        return '양';
      case '을':
      case '정':
      case '기':
      case '신':
      case '계':
        return '음';
      default:
        return '';
    }
  }

  String _branchYinYang(String branch) {
    switch (branch) {
      case '자':
      case '인':
      case '진':
      case '오':
      case '신':
      case '술':
        return '양';
      case '축':
      case '묘':
      case '사':
      case '미':
      case '유':
      case '해':
        return '음';
      default:
        return '';
    }
  }

  bool _isGenerating(String from, String to) {
    const generate = {
      '목': '화',
      '화': '토',
      '토': '금',
      '금': '수',
      '수': '목',
    };
    return generate[from] == to;
  }

  bool _isControlling(String from, String to) {
    const control = {
      '목': '토',
      '토': '수',
      '수': '화',
      '화': '금',
      '금': '목',
    };
    return control[from] == to;
  }

  String _relationText(String a, String b) {
    if (a.isEmpty || b.isEmpty) return '관계 판정 보류';
    if (a == b) return '비견/겁재 계열 동기화';
    if (_isGenerating(a, b)) return '상생(생출)';
    if (_isGenerating(b, a)) return '상생(생조)';
    if (_isControlling(a, b)) return '상극(극출)';
    if (_isControlling(b, a)) return '상극(피극)';
    return '혼합(중립)';
  }

  int _stableHash(String text) {
    var h = 2166136261;
    for (final c in text.codeUnits) {
      h ^= c;
      h = (h * 16777619) & 0x7fffffff;
    }
    return h;
  }

  String _pickByHash(List<String> options, int hash) {
    if (options.isEmpty) return '';
    return options[hash % options.length];
  }

  String _baseFlowText(String signal) {
    if (signal == '매수 우세') {
      return '기운이 순환하며 외부 에너지를 흡수해 확장하려는 흐름이 강합니다.';
    }
    if (signal == '매도/비중축소') {
      return '기운이 충돌하며 과열 또는 누수 구간으로 진입해 방어가 우선되는 흐름입니다.';
    }
    return '기운이 교차해 방향성이 한쪽으로 고정되지 않아 확인이 필요한 흐름입니다.';
  }

  String _signalReasonMemo(DateTime date, AssetItem item, int score) {
    final ganji = _ganji(date);
    final stem = _stemFromGanji(ganji);
    final branch = _branchFromGanji(ganji);
    final stemElement = _stemElement(stem);
    final branchElement = _branchElement(branch);
    final stemYinYang = _stemYinYang(stem);
    final branchYinYang = _branchYinYang(branch);
    final signal = _signalLabel(score);
    final hash = _stableHash('${date.toIso8601String()}-${item.name}-${item.market}-${item.element}-$score');

    final relStemAsset = _relationText(stemElement, item.element);
    final relBranchAsset = _relationText(branchElement, item.element);
    final relStemBranch = _relationText(stemElement, branchElement);

    final favorableMatchCount = [
      if (_sajuFavorableElements.contains(stemElement)) stemElement,
      if (_sajuFavorableElements.contains(branchElement)) branchElement,
      if (item.element == stemElement) '일간과 종목 오행 일치',
      if (item.element == branchElement) '일지와 종목 오행 일치',
    ].length;

    final cautionMatchCount = [
      if (_sajuCautionElements.contains(stemElement)) stemElement,
      if (_sajuCautionElements.contains(branchElement)) branchElement,
      if (_sajuCautionElements.contains(item.element)) item.element,
    ].length;

    final deficiency = _pickByHash(
      _sajuFavorableElements.map((e) => '$e 기운').toList(),
      hash + 3,
    );
    final excess = _pickByHash(
      _sajuCautionElements.map((e) => '$e 기운').toList(),
      hash + 7,
    );

    final openingLine = _pickByHash(
      [
        '오늘 장세는 표면상 가격보다 기운의 결이 먼저 읽히는 날입니다.',
        '오늘은 수급 신호보다 오행의 결속과 충돌이 가격에 선반영되기 쉬운 날입니다.',
        '당일 운의 맥은 숫자보다 기운의 방향성에서 먼저 드러나는 흐름입니다.',
        '오늘 시세는 추세선 이전에 음양의 균형/불균형이 먼저 작동하는 구간입니다.',
      ],
      hash,
    );

    final tacticalLine = _pickByHash(
      [
        '짧은 캔들 변동에는 흔들리지 말고, 기준가 중심의 분할 대응이 유리합니다.',
        '단일 진입보다 2~3회 분할로 평균단가를 관리하는 접근이 손익비를 지킵니다.',
        '호가 급변 구간에서는 추격보다 눌림 확인 후 대응이 더 안정적입니다.',
        '진입 자체보다 비중 조절이 성패를 가르는 날이므로 사이즈 관리가 핵심입니다.',
      ],
      hash + 11,
    );

    final signalNarrative = signal == '매수 우세'
        ? _pickByHash(
            [
              '매수 측으로 기운이 기울어 있어, 유리한 자리를 기다린 뒤 분할 진입하는 전략이 맞습니다.',
              '상생 흐름이 우세하므로 급등 추격보다 지지 확인 후 매수 누적이 효율적입니다.',
              '기운의 방향이 확장 쪽으로 열려 있어, 계획된 비중 내에서 매수 대응이 가능한 날입니다.',
            ],
            hash + 13,
          )
        : signal == '매도/비중축소'
            ? _pickByHash(
                [
                  '상극 압력이 커져 수익 보호가 우선이며, 반등 시 비중 축소가 합리적입니다.',
                  '충돌 신호가 겹쳐 방어 국면으로 해석되므로 신규 매수보다 리스크 절제가 우선입니다.',
                  '기운이 새는 구간이라 공격보다 이익 보존과 손절 규율 준수가 핵심입니다.',
                ],
                hash + 17,
              )
            : _pickByHash(
                [
                  '상생과 상극이 교차해 관망 우위이며, 확인봉 이후 방향 추종이 바람직합니다.',
                  '중립 혼조 구간이라 성급한 진입보다 시나리오를 나눠 대기하는 편이 유리합니다.',
                  '기운이 합충을 반복해 방향성이 약하므로, 조건 충족 전까지 관망이 맞습니다.',
                ],
                hash + 19,
              );

    return '''
[$signal · ${item.market} ${item.name} 사주 해설]

0) 총론
- $openingLine
- ${_baseFlowText(signal)}

1) 오늘의 기운(일간지/음양)
- 일간: $stem($stemYinYang$stemElement), 일지: $branch($branchYinYang$branchElement)
- 일간-일지 관계: $relStemBranch
- 오늘은 '$ganji'의 결이 작동하며, ${stemElement == branchElement ? '한 오행의 집중도가 커져 추세가 과장되거나 단기 과열이 나타나기 쉬운 구조' : '두 기운이 교차해 박스권 흔들림과 방향 전환 시도가 함께 나타나는 구조'}입니다.

2) 사주 제공자 기준(원국 보정 해석)
- 유리 오행: ${_sajuFavorableElements.join(', ')}
- 주의 오행: ${_sajuCautionElements.join(', ')}
- 현재 보강이 필요한 부족 기운(추정): $deficiency
- 과다/충돌 주의 기운(추정): $excess

3) 종목별 오행 충합 판독
- 대상 종목: ${item.name} (${item.market}) / 종목 오행: ${item.element}
- 일간($stemElement) ↔ 종목(${item.element}) 관계: $relStemAsset
- 일지($branchElement) ↔ 종목(${item.element}) 관계: $relBranchAsset
- 관계 해석: ${relStemAsset.contains('상생') || relBranchAsset.contains('상생') ? '유입/상승 모멘텀이 붙기 쉬운 구조' : relStemAsset.contains('상극') || relBranchAsset.contains('상극') ? '변동성 확대 및 되돌림 압력이 커지기 쉬운 구조' : '중립 구간으로 수급 확인이 필요한 구조'}

4) 점수/길흉 판단
- 유리한 일운/일지/종목 일치 요인: $favorableMatchCount개
- 경계해야 할 상극/주의 요인: $cautionMatchCount개
- 종합 점수: $score점 → $signal (${_timingText(item.market, signal)})
- 길흉 판정: ${score >= _buyThreshold() ? '길(吉) 기운 우세' : score <= _sellThreshold() ? '흉(凶) 기운 우세' : '평(平)~소흉/소길 혼재'}

5) 매수·매도 실전 해설
- $signalNarrative
- $tacticalLine

6) 리스크 관리 결론
- 오행 해석은 방향성 참고 도구이며, 실거래는 거래량·추세·변동성 확인 후 실행하세요.
- 동일 신호라도 ${item.market == '코인' ? '코인' : '주식'}은 ${item.market == '코인' ? '변동성이 커서 보수적 비중과 빠른 손절 규칙' : '갭 리스크를 고려한 분할 진입·분할 청산 규칙'}이 필수입니다.
- 오늘 결론: ${_timingText(item.market, signal)} 기준으로 대응하되, 계획가 이탈 시 감정 대응 대신 규칙 대응을 유지하세요.
''';
  }

  Future<void> _showSignalReasonDialog(
    BuildContext context, {
    required DateTime date,
    required AssetItem asset,
  }) async {
    final score = _signalScore(date, asset);
    final label = _signalLabel(score);
    final grade = _fortuneGrade(score);
    final signalColor = _signalColor(score);
    final gradeColor = _fortuneGradeColor(grade);
    final memo = _signalReasonMemo(date, asset, score);
    final currentPlan = _planFor(asset);
    final buyController = TextEditingController(text: _formatThousands(currentPlan.buyPrice));
    final stopController = TextEditingController(text: _formatThousands(currentPlan.stopLoss));
    final memoController = TextEditingController(text: currentPlan.memo);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text('${asset.market} ${asset.name}')),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: gradeColor, width: 1.4),
                ),
                child: Text(
                  '점괘 $grade',
                  style: TextStyle(
                    color: gradeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: signalColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: signalColor, width: 1.4),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: signalColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memo,
                    style: const TextStyle(height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const Text(
                    '내 매매 계획 메모',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: buyController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final formatted = _formatThousands(v);
                      if (formatted == v) return;
                      buyController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    },
                    decoration: const InputDecoration(
                      labelText: '내 매수가(예: 102,500원)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: stopController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final formatted = _formatThousands(v);
                      if (formatted == v) return;
                      stopController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    },
                    decoration: const InputDecoration(
                      labelText: '내 손절가/비중축소 기준(원)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: memoController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '개인 메모',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                await _savePlanFor(
                  asset,
                  AssetPlan(
                    buyPrice: _formatThousands(buyController.text.trim()),
                    stopLoss: _formatThousands(stopController.text.trim()),
                    memo: memoController.text.trim(),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('저장'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
    buyController.dispose();
    stopController.dispose();
    memoController.dispose();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      final memo = _memoFor(date);
      _memoController.text = memo.note;
      _tagController.text = memo.tags.join(', ');
    });
    _schedulePersist();
  }

  void _saveMemo() {
    if (_selectedDate == null) return;
    final key = _dateKey(_selectedDate!);
    final value = _memoController.text.trim();
    final tags = _parseTags(_tagController.text);
    final prev = _memos[key] ?? DayMemo();
    setState(() {
      final next = prev.copyWith(
        note: value,
        tags: tags,
      );
      if (!next.hasContent) {
        _memos.remove(key);
      } else {
        _memos[key] = next;
      }
    });
    _schedulePersist();
  }

  void _clearMemo() {
    if (_selectedDate == null) return;
    final key = _dateKey(_selectedDate!);
    setState(() {
      _memos.remove(key);
      _memoController.clear();
      _tagController.clear();
      _checklistController.clear();
    });
    _schedulePersist();
  }

  void _addChecklistItem() {
    if (_selectedDate == null) return;
    final text = _checklistController.text.trim();
    if (text.isEmpty) return;
    final key = _dateKey(_selectedDate!);
    final prev = _memos[key] ?? DayMemo();
    final nextItems = List<ChecklistItem>.from(prev.checklist)..add(ChecklistItem(text: text));
    setState(() {
      _memos[key] = prev.copyWith(
        note: _memoController.text.trim(),
        tags: _parseTags(_tagController.text),
        checklist: nextItems,
      );
      _checklistController.clear();
    });
    _schedulePersist();
  }

  void _toggleChecklistItem(int index, bool? value) {
    if (_selectedDate == null) return;
    final key = _dateKey(_selectedDate!);
    final prev = _memos[key] ?? DayMemo();
    if (index < 0 || index >= prev.checklist.length) return;
    final nextItems = List<ChecklistItem>.from(prev.checklist);
    nextItems[index] = nextItems[index].copyWith(isDone: value == true);
    setState(() {
      _memos[key] = prev.copyWith(
        note: _memoController.text.trim(),
        tags: _parseTags(_tagController.text),
        checklist: nextItems,
      );
    });
    _schedulePersist();
  }

  void _removeChecklistItem(int index) {
    if (_selectedDate == null) return;
    final key = _dateKey(_selectedDate!);
    final prev = _memos[key] ?? DayMemo();
    if (index < 0 || index >= prev.checklist.length) return;
    final nextItems = List<ChecklistItem>.from(prev.checklist)..removeAt(index);
    setState(() {
      final next = prev.copyWith(
        note: _memoController.text.trim(),
        tags: _parseTags(_tagController.text),
        checklist: nextItems,
      );
      if (!next.hasContent) {
        _memos.remove(key);
      } else {
        _memos[key] = next;
      }
    });
    _schedulePersist();
  }

  List<LunarDayCell> _daysOfLunarMonth() {
    final lunarMonth = LunarMonth.fromYm(_year, _month);
    if (lunarMonth == null) return const <LunarDayCell>[];
    final dayCount = lunarMonth.getDayCount();
    return List.generate(dayCount, (i) {
      final lunarDay = i + 1;
      final solar = Lunar.fromYmd(_year, _month, lunarDay).getSolar();
      final solarDate = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
      return LunarDayCell(lunarDay: lunarDay, solarDate: solarDate);
    });
  }

  void _changeMonth(int newMonth) {
    setState(() {
      _month = newMonth;
      final solar = Lunar.fromYmd(_year, _month, 1).getSolar();
      _selectedDate = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
      final memo = _memoFor(_selectedDate!);
      _memoController.text = memo.note;
      _tagController.text = memo.tags.join(', ');
    });
    _schedulePersist();
  }

  void _changeYear(int newYear) {
    setState(() {
      _year = newYear.clamp(_minYear, _maxYear);
      _month = _normalizeMonthForYear(_year, _month);
      final lunarDay = _selectedDate == null ? 1 : Solar.fromDate(_selectedDate!).getLunar().getDay();
      final maxDay = LunarMonth.fromYm(_year, _month)?.getDayCount() ?? 29;
      final solar = Lunar.fromYmd(_year, _month, lunarDay.clamp(1, maxDay)).getSolar();
      _selectedDate = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
      final memo = _memoFor(_selectedDate!);
      _memoController.text = memo.note;
      _tagController.text = memo.tags.join(', ');
    });
    _schedulePersist();
  }

  void _moveMonth(int delta) {
    setState(() {
      var lunarMonth = LunarMonth.fromYm(_year, _month) ?? LunarMonth.fromYm(_year, 1)!;
      lunarMonth = lunarMonth.next(delta);
      _year = lunarMonth.getYear();
      _month = lunarMonth.getMonth();
      final solar = Lunar.fromYmd(_year, _month, 1).getSolar();
      _selectedDate = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
      final memo = _memoFor(_selectedDate!);
      _memoController.text = memo.note;
      _tagController.text = memo.tags.join(', ');
    });
    _schedulePersist();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactWidth = screenWidth < 900;
    final days = _daysOfLunarMonth();
    final firstWeekday = days.isEmpty ? 0 : days.first.solarDate.weekday % 7; // 일=0
    final monthOptions = _monthOptionsForYear(_year);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isVeryNarrow = constraints.maxWidth < 430;
            return Row(
              children: [
                Expanded(
                  child: Text(
                    isCompactWidth ? '음력 달력' : '음력 달력 (간지·오방색)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _moveMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                SizedBox(
                  width: isVeryNarrow ? 68 : 90,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _year,
                      isDense: true,
                      isExpanded: true,
                      menuMaxHeight: 360,
                      items: List.generate(
                        _maxYear - _minYear + 1,
                        (i) {
                          final year = _minYear + i;
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year년'),
                          );
                        },
                      ),
                      onChanged: (v) {
                        if (v != null) _changeYear(v);
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: isVeryNarrow ? 58 : 74,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _month,
                      isDense: true,
                      isExpanded: true,
                      menuMaxHeight: 360,
                      items: monthOptions
                          .map(
                            (monthValue) => DropdownMenuItem(
                              value: monthValue,
                              child: Text(_monthLabel(monthValue)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _changeMonth(v);
                      },
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _moveMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            );
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isVeryNarrow = constraints.maxWidth < 560;
          final monthStartLunar = Lunar.fromYmd(_year, _month, 1);
          final gridSpacing = isVeryNarrow ? 4.0 : 6.0;
          final totalCells = firstWeekday + days.length;
          final rowCount = (totalCells / 7).ceil().clamp(1, 6);

          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '음력 $_year년 ${_monthLabel(_month)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFB6D4FE)),
                    ),
                    child: Text(
                      '오늘의 접속자수(로컬 기기 기준): $_todayVisitCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '음력 $_year년 ${_monthLabel(_month)} 1일 기준 간지',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '달력 칸 간지는 일간지(일주)입니다. 월주는 절기 기준으로 별도 계산됩니다.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isVeryNarrow ? 11 : 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '달력 칸 일/월/년 3줄 모드',
                          style: TextStyle(
                            fontSize: isVeryNarrow ? 11 : 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _showThreePillarsInCell,
                        onChanged: (value) {
                          setState(() => _showThreePillarsInCell = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildGanjiImportantBanner(isVeryNarrow),
                  const SizedBox(height: 6),
                  _buildTopGanjiSummary(monthStartLunar, isVeryNarrow),
                  const SizedBox(height: 8),
                  Row(
                    children: _weekdays
                        .map(
                          (w) => Expanded(
                            child: Center(
                              child: Text(
                                w,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, gridConstraints) {
                        final totalHorizontalSpacing = gridSpacing * 6;
                        final totalVerticalSpacing = gridSpacing * (rowCount - 1);
                        final cellWidth = (gridConstraints.maxWidth - totalHorizontalSpacing) / 7;
                        final cellHeight = (gridConstraints.maxHeight - totalVerticalSpacing) / rowCount;
                        final childAspectRatio = (cellWidth / cellHeight).clamp(0.55, 1.8);

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: rowCount * 7,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: gridSpacing,
                            crossAxisSpacing: gridSpacing,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemBuilder: (context, index) {
                            if (index < firstWeekday || index >= totalCells) {
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            }

                            final dayCell = days[index - firstWeekday];
                            final solarDay = dayCell.solarDate;
                            final ganji = _ganji(solarDay);
                            final lunarForCell = _showThreePillarsInCell ? Solar.fromDate(solarDay).getLunar() : null;
                            // 월주는 표시 중인 음력 월(_year/_month) 기준으로 고정합니다.
                            // (사용자 기대: 같은 음력 월 내에서 월주가 일자별로 바뀌지 않음)
                            final fixedMonthLunar = Lunar.fromYmd(_year, _month, 1);
                            final monthGanji = lunarForCell == null ? '' : _monthGanjiKorean(fixedMonthLunar);
                            final yearGanji = lunarForCell == null ? '' : _yearGanjiKorean(lunarForCell);
                            final selected = _selectedDate != null && _dateKey(_selectedDate!) == _dateKey(solarDay);
                            final specialLabels = _displaySpecialLabels(
                              dayCell,
                              compact: _showThreePillarsInCell,
                            );

                            return InkWell(
                              onTap: () => _selectDate(solarDay),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: EdgeInsets.all(isVeryNarrow ? 4 : 6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: selected ? Colors.blue : Colors.grey.shade300,
                                    width: selected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${dayCell.lunarDay}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isVeryNarrow ? 12 : 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${solarDay.month}/${solarDay.day}',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontSize: isVeryNarrow ? 9 : 11,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isVeryNarrow ? 1 : 2),
                                    _buildGanjiBadge(
                                      ganji,
                                      fontSize: isVeryNarrow ? 13 : 15,
                                      radius: isVeryNarrow ? 5 : 7,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isVeryNarrow ? 3 : 5,
                                        vertical: isVeryNarrow ? 1.5 : 2.5,
                                      ),
                                      fontWeight: FontWeight.w900,
                                    ),
                                    SizedBox(height: isVeryNarrow ? 1 : 2),
                                    Text(
                                      '일간지',
                                      style: TextStyle(
                                        fontSize: isVeryNarrow ? 8 : 9,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_showThreePillarsInCell) ...[
                                      SizedBox(height: isVeryNarrow ? 1 : 2),
                                      Row(
                                        children: [
                                          Text(
                                            '월주 ',
                                            style: TextStyle(
                                              fontSize: isVeryNarrow ? 8 : 9,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildGanjiBadge(
                                              monthGanji,
                                              fontSize: isVeryNarrow ? 8.5 : 9.5,
                                              radius: isVeryNarrow ? 4 : 5,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isVeryNarrow ? 2 : 3,
                                                vertical: isVeryNarrow ? 1 : 1.5,
                                              ),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isVeryNarrow ? 1 : 2),
                                      Row(
                                        children: [
                                          Text(
                                            '년주 ',
                                            style: TextStyle(
                                              fontSize: isVeryNarrow ? 8 : 9,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildGanjiBadge(
                                              yearGanji,
                                              fontSize: isVeryNarrow ? 8.5 : 9.5,
                                              radius: isVeryNarrow ? 4 : 5,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isVeryNarrow ? 2 : 3,
                                                vertical: isVeryNarrow ? 1 : 1.5,
                                              ),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (specialLabels.isNotEmpty) ...[
                                      SizedBox(height: isVeryNarrow ? 1 : 2),
                                      Text(
                                        specialLabels.join(' · '),
                                        style: TextStyle(
                                          fontSize: isVeryNarrow ? 8 : 9,
                                          color: const Color(0xFFB45309),
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
