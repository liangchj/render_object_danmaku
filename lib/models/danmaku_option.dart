class DanmakuOption {
  /// 默认的字体大小
  final double fontSize;

  /// 显示区域，0.1-1.0
  final double area;

  /// 滚动弹幕运行时间，毫秒
  final int duration;

  /// 不透明度，0.1-1.0
  final double opacity;

  /// 文字描边宽度
  final double strokeWidth;

  /// 海量弹幕模式 (弹幕轨道占满时进行叠加)
  final bool massiveMode;

  // 边框宽度
  final double boldWidth;
  // 上下外边距
  final double verticalMargin;
  // 上下内边距
  final double verticalPadding;

  // 过滤顶部
  final bool filterTop;
  // 过滤底部
  final bool filterBottom;
  // 过滤滚动
  final bool filterScroll;
  // 过滤彩色
  final bool filterColour;
  // 过滤重复
  final bool filterRepeat;
  // 过滤词语
  final List<String>? filterWords;
  // 是否可以点击弹幕
  final bool clickItem;
  // 调整弹幕时间(毫秒)
  final int adjustTimeMs;

  DanmakuOption({
    this.fontSize = 16.0,
    this.area = 1.0,
    this.duration = 6000,
    this.opacity = 1.0,
    this.strokeWidth = 0.0,
    this.massiveMode = false,
    this.boldWidth = 1.0,
    this.verticalMargin = 1.0,
    this.verticalPadding = 0.0,
    this.filterTop = false,
    this.filterBottom = false,
    this.filterScroll = false,
    this.filterColour = false,
    this.filterRepeat = false,
    this.filterWords,
    this.clickItem = false,
    this.adjustTimeMs = 0,
  });

  DanmakuOption copyWith({
    double? fontSize,
    double? area,
    int? duration,
    double? opacity,
    double? strokeWidth,
    bool? massiveMode,
    double? boldWidth,
    double? verticalMargin,
    double? verticalPadding,
    bool? filterTop,
    bool? filterBottom,
    bool? filterScroll,
    bool? filterColour,
    bool? filterRepeat,
    List<String>? filterWords,
    bool? clickItem,
    int? adjustTimeMs,
  }) {
    return DanmakuOption(
      fontSize: fontSize ?? this.fontSize,
      area: area ?? this.area,
      duration: duration ?? this.duration,
      opacity: opacity ?? this.opacity,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      massiveMode: massiveMode ?? this.massiveMode,
      boldWidth: boldWidth ?? this.boldWidth,
      verticalMargin: verticalMargin ?? this.verticalMargin,
      verticalPadding: verticalPadding ?? this.verticalPadding,
      filterTop: filterTop ?? this.filterTop,
      filterBottom: filterBottom ?? this.filterBottom,
      filterScroll: filterScroll ?? this.filterScroll,
      filterColour: filterColour ?? this.filterColour,
      filterRepeat: filterRepeat ?? this.filterRepeat,
      filterWords: filterWords ?? this.filterWords,
      clickItem: clickItem ?? this.clickItem,
      adjustTimeMs: adjustTimeMs ?? this.adjustTimeMs,
    );
  }
}
