
enum DanmakuShowType {
  l2r([1, 2]),
  r2l([3]),
  top([5]),
  bottom([4])
  ;
  final List<int> modeList;

  const DanmakuShowType(this.modeList);
}