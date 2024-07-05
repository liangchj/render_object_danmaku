enum DanmakuShowType {
  l2r([6]),
  r2l([1, 2, 3]),
  top([5]),
  bottom([4]);

  final List<int> modeList;

  const DanmakuShowType(this.modeList);
}
