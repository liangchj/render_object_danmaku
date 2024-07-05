import 'package:render_object_danmaku/models/danmaku_item.dart';
import 'package:render_object_danmaku/models/danmaku_option.dart';
import 'package:render_object_danmaku/parse/base_danmaku_parser.dart';

class DanmakuController {
  final Function(DanmakuItem) onAddDanmaku;
  final Function(List<DanmakuItem>) onAddDanmakus;
  final Function(DanmakuOption) onUpdateOption;
  final Function({
    required String path,
    required BaseDanmakuParser danmakuParser,
    required Function(bool) loaded,
    bool? fromAssets,
    bool? isStart,
    int? startMs,
  }) onDanmakuFileParse;
  final Function({int? ms}) onStart;
  final Function onPause;
  final Function onResume;
  final Function onClear;

  DanmakuController({
    required this.onAddDanmaku,
    required this.onAddDanmakus,
    required this.onUpdateOption,
    required this.onDanmakuFileParse,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onClear,
  });

  bool _running = true;

  /// 是否运行中
  /// 可以调用pause()暂停弹幕
  bool get running => _running;
  set running(e) {
    _running = e;
  }

  DanmakuOption _option = DanmakuOption();
  DanmakuOption get option => _option;
  set option(e) {
    _option = e;
  }

  int _runTime = 0;
  int get runTime => _runTime;
  set runTime(i) => _runTime = i;

  /// 加载弹幕文件
  void danmakuFileParse({
    required String path,
    required BaseDanmakuParser danmakuParser,
    required Function(bool) loaded,
    bool? fromAssets,
    bool? isStart,
    int? startMs,
  }) {
    onDanmakuFileParse.call(
        path: path,
        danmakuParser: danmakuParser,
        loaded: loaded,
        fromAssets: fromAssets,
        isStart: isStart,
        startMs: startMs);
  }

  /// 启动弹幕
  void start({int? ms}) {
    onStart.call(ms: ms);
  }

  /// 暂停弹幕
  void pause() {
    onPause.call();
  }

  /// 继续弹幕
  void resume() {
    onResume.call();
  }

  /// 清空弹幕
  void clear() {
    onClear.call();
  }

  /// 添加弹幕
  void addDanmaku(DanmakuItem item) {
    onAddDanmaku.call(item);
  }

  void addDanmakus(List<DanmakuItem> items) {
    onAddDanmakus.call(items);
  }

  /// 更新弹幕配置
  void updateOption(DanmakuOption option) {
    onUpdateOption.call(option);
  }
}
