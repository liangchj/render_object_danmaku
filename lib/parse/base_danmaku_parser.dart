import 'package:render_object_danmaku/models/canvas_danmaku_item.dart';

abstract class BaseDanmakuParser {
  final Map<String, dynamic>? optionMap;

  BaseDanmakuParser({required this.optionMap});

  /// 记录弹幕对应时间区间
  /// 第一层 key：秒，value：这一秒的所有弹幕
  /// 第二层 key：每个间隔毫秒起始位置，value：这个间隔区间的所有弹幕
  Future<Map<int, Map<int, List<CanvasDanmakuItem>>>> parseCanvasDanmakusByXml(
    String xmlPath, {
    bool fromAssets = false,
    int addDanmakuItemsMs = 100,
  });
}
