/// 피드 상단 필터·게시물 태그 선택에 공통 사용. [matchKey]는 `#` 없이 저장·비교.
class FeedTagChip {
  const FeedTagChip({this.matchKey, required this.label});

  final String? matchKey;
  final String label;
}

const kFeedTagChips = <FeedTagChip>[
  FeedTagChip(matchKey: null, label: '전체'),
  FeedTagChip(matchKey: '오늘의타로', label: '#오늘의타로'),
  FeedTagChip(matchKey: '연애운', label: '#연애운'),
  FeedTagChip(matchKey: '직장운', label: '#직장운'),
  FeedTagChip(matchKey: '시험운', label: '#시험운'),
  FeedTagChip(matchKey: '건강운', label: '#건강운'),
  FeedTagChip(matchKey: '재물운', label: '#재물운'),
  FeedTagChip(matchKey: '사업운', label: '#사업운'),
  FeedTagChip(matchKey: '고민', label: '#고민'),
  FeedTagChip(matchKey: '희망', label: '#희망'),
];

/// 게시 화면·필터에서 쓸 수 있는 태그(「전체」 제외).
Iterable<FeedTagChip> get kFeedPostSelectableTags =>
    kFeedTagChips.where((c) => c.matchKey != null);
