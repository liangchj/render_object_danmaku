import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:render_object_danmaku/parse/base_danmaku_parser.dart';
import 'package:render_object_danmaku/danmaku_controller.dart';
import 'package:render_object_danmaku/danmaku_render_object_widget.dart';
import 'package:render_object_danmaku/models/danmaku_item.dart';
import 'package:render_object_danmaku/models/danmaku_option.dart';
import 'package:render_object_danmaku/models/danmaku_show_type.dart';
import 'package:render_object_danmaku/utils/utils.dart';

import 'models/canvas_danmaku_item.dart';

class DanmakuView extends StatefulWidget {
  // 创建DanmakuView后返回控制器
  final Function(DanmakuController) createdController;
  final DanmakuOption option;

  const DanmakuView({
    super.key,
    required this.createdController,
    required this.option,
  });

  @override
  State<DanmakuView> createState() => _DanmakuViewState();
}

class _DanmakuViewState extends State<DanmakuView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// 弹幕控制器
  late DanmakuController _controller;

  /// 弹幕配置
  late DanmakuOption _option;

  /// 弹幕动画控制器
  late AnimationController _animationController;

  /// 视图宽度
  double _viewWidth = 0;

  /// 视图高度
  double _viewHeight = 0;

  /// 单个弹幕高度
  late double _danmakuHeight;

  /// 弹幕轨道数
  late int _trackCount;

  /// 弹幕轨道位置
  final List<double> _trackYPositions = [];

  /// 内部计时器（用于记录当前可以显示的弹幕）
  int _tick = -0;

  /// 间隔多久添加弹幕
  final int _addDanmakuItemsMs = 100;
  Timer? _timer;

  /// 记录弹幕对应时间区间
  /// 第一层 key：秒，value：这一秒的所有弹幕
  /// 第二层 key：每个间隔毫秒起始位置，value：这个间隔区间的所有弹幕
  Map<int, Map<int, List<CanvasDanmakuItem>>> _timeCanvasDanmakuItems = {};

  final List<CanvasDanmakuItem> _canvasDanmakuItems = [];

  /// 点击的弹幕列表
  final List<CanvasDanmakuItem> _clickCanvasDanmakuItems = [];

  /// 当前点击的弹幕id
  String _clickDanmakuId = "";

  DateTime? _startTime;

  /// 点击可以悬停时长（毫秒）
  int _clickPauseTimeMs = 5000;
  // 点击的定时器
  Timer? _clickTimer;

  @override
  void initState() {
    // 计时器初始化
    _option = widget.option;
    getDanmakuHeight();
    _controller = DanmakuController(
      onAddDanmaku: addDanmaku,
      onAddDanmakus: addDanmakus,
      onUpdateOption: updateOption,
      onDanmakuFileParse: danmakuFileParse,
      onStart: start,
      onPause: pause,
      onResume: resume,
      onClear: clearDanmakus,
    );
    _controller.option = _option;
    _controller.runTime = 0;
    _controller.running = false;
    widget.createdController.call(
      _controller,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _option.duration),
    );

    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void dispose() {
    _clickTimer?.cancel();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  /// 处理 Android/iOS 应用后台或熄屏导致的动画问题
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      pause();
    }
  }

  /// 计算获取弹幕高度
  double getDanmakuHeight() {
    /// 计算弹幕轨道
    final textPainter = TextPainter(
      text: TextSpan(text: '弹幕', style: TextStyle(fontSize: _option.fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    // 加上内外边距和边框
    _danmakuHeight = textPainter.height +
        _option.verticalMargin * 2.0 +
        _option.verticalPadding * 2.0 +
        _option.boldWidth * 2.0;
    return _danmakuHeight;
  }

  /// 更新幕布高度和可以绘制的数量、坐标
  void updateDanmakuCanvasHeight(double height) {
    _viewHeight = height;

    /// 为字幕留出余量
    // _trackCount = ((_viewHeight / _danmakuHeight - 1) * _option.area).floor();
    _trackCount = ((_viewHeight / _danmakuHeight) * _option.area).floor();

    _trackYPositions.clear();
    for (int i = 0; i < _trackCount; i++) {
      _trackYPositions.add(i * _danmakuHeight);
    }
    _tick++;
    // 重新调整可显示的弹幕
    if (_canvasDanmakuItems.isNotEmpty) {
      debugPrint("调整位置:${_trackYPositions.length}");
      // 遍历坐标是否还可以用
      for (var item in [..._clickCanvasDanmakuItems, ..._canvasDanmakuItems]) {
        if (item.visibleTick + 1 == _tick &&
            _trackYPositions.contains(item.yPosition)) {
          item.visibleTick = _tick;
        }
      }
    }
  }

  /// 点击弹幕幕布
  void _clickCanvas(Offset clickOffset) {
    _clickTimer?.cancel();
    CanvasDanmakuItem? clickCanvasDanmakuItem;
    if (_clickCanvasDanmakuItems.isNotEmpty) {
      clickCanvasDanmakuItem =
          _getClickCanvasDanmakuItem(clickOffset, _clickCanvasDanmakuItems);
    }
    if (clickCanvasDanmakuItem == null && _canvasDanmakuItems.isNotEmpty) {
      clickCanvasDanmakuItem =
          _getClickCanvasDanmakuItem(clickOffset, _canvasDanmakuItems);
    }
    if (_clickDanmakuId.isNotEmpty && _clickCanvasDanmakuItems.isNotEmpty) {
      int i = _clickCanvasDanmakuItems.length - 1;
      for (; i >= 0; i--) {
        // x + duration = y (runTime + _option.duration * (1-_option.usedTimeRatio))
        CanvasDanmakuItem item = _clickCanvasDanmakuItems[i];
        if (item.danmakuItem.danmakuId == _clickDanmakuId) {
          if (item.usedTimeRatio >= 1.0) {
            item.danmakuItem.time = _controller.runTime - _option.duration;
          } else {
            debugPrint("修改前时间：${item.danmakuItem.time}");
            item.danmakuItem.time = (_controller.runTime +
                    _option.duration * (1.0 - item.usedTimeRatio) -
                    _option.duration)
                .ceil()
                .abs();
            debugPrint("修改了时间：${item.danmakuItem.time}");
          }
          break;
        }
      }
    }
    setState(() {
      if (clickCanvasDanmakuItem != null) {
        debugPrint("有弹幕被点击：${clickCanvasDanmakuItem.danmakuItem.content}");
        _clickCanvasDanmakuItems.add(clickCanvasDanmakuItem);
      }
      _clickDanmakuId = clickCanvasDanmakuItem?.danmakuItem.danmakuId ?? "";
      if (clickCanvasDanmakuItem != null) {
        _clickTimer = Timer(Duration(milliseconds: _clickPauseTimeMs), () {
          if (clickCanvasDanmakuItem!.usedTimeRatio >= 1.0) {
            clickCanvasDanmakuItem.danmakuItem.time =
                _controller.runTime - _option.duration;
          } else {
            clickCanvasDanmakuItem.danmakuItem.time = (_controller.runTime +
                    _option.duration *
                        (1.0 - clickCanvasDanmakuItem.usedTimeRatio) -
                    _option.duration)
                .ceil()
                .abs();
          }
          setState(() {
            _clickDanmakuId = "";
          });
        });
      }
    });
  }

  /// 获取点击的弹幕
  CanvasDanmakuItem? _getClickCanvasDanmakuItem(
      Offset clickOffset, List<CanvasDanmakuItem> items) {
    CanvasDanmakuItem? clickItem;
    int i = items.length - 1;
    for (; i >= 0; i--) {
      CanvasDanmakuItem item = items[i];
      if (item.visibleTick != _tick) {
        continue;
      }
      // 获取弹幕点击点击生效区域
      Offset startOffset =
          Offset(item.xPosition, item.yPosition + _option.verticalMargin);
      Offset endOffset = Offset(item.xPosition + item.width,
          item.yPosition + item.height - _option.verticalMargin);

      if (clickOffset.dx >= startOffset.dx &&
          clickOffset.dx <= endOffset.dx &&
          clickOffset.dy >= startOffset.dy &&
          clickOffset.dy <= endOffset.dy) {
        clickItem = item;
        clickItem.clickTimeMs = _controller.runTime;
        items.remove(item);
        break;
      }
    }
    return clickItem;
  }

  Future<void> danmakuFileParse({
    required String path,
    required BaseDanmakuParser danmakuParser,
    required Function(bool) loaded,
    bool? fromAssets,
    bool? isStart,
    int? startMs,
  }) async {
    _timeCanvasDanmakuItems = await danmakuParser.parseCanvasDanmakusByXml(path,
        fromAssets: fromAssets ?? false);
    if (isStart != null && isStart) {
      start(ms: startMs);
    }
    loaded.call(true);
  }

  void addDanmakus(List<DanmakuItem> danmakuItems) {
    for (var item in danmakuItems) {
      addDanmaku(item);
    }
  }

  /// 添加弹幕
  void addDanmaku(DanmakuItem danmakuItem) {
    Duration duration = Duration(milliseconds: danmakuItem.time);
    int second = duration.inSeconds;
    Map<int, List<CanvasDanmakuItem>> secondItems =
        _timeCanvasDanmakuItems[second] ?? {};
    // 这一秒多出的毫秒
    int ms = duration.inMilliseconds - second * 1000;
    // 这个属于哪一个间隔区间
    int msInterval = (ms / _addDanmakuItemsMs).floor() * 100;
    List<CanvasDanmakuItem> msIntervalItems = secondItems[msInterval] ?? [];
    CanvasDanmakuItem item = CanvasDanmakuItem(
        danmakuItem: danmakuItem,
        xPosition: _viewWidth,
        height: _danmakuHeight);
    item.updateParagraph(_option);
    msIntervalItems.add(item);
    secondItems[msInterval] = msIntervalItems;
    _timeCanvasDanmakuItems[second] = secondItems;
  }

  /// 开始弹幕
  void start({int? ms}) {
    _controller.runTime = ms ?? 0;
    _controller.running = true;
    _startTime = DateTime.now();
    _animationController.repeat();
    if (_controller.runTime > 0) {
      int remainderMs = _controller.runTime % _addDanmakuItemsMs;
      // 启动位置不是定义显示弹幕的区间
      if (remainderMs > 0) {
        Future.delayed(Duration(milliseconds: remainderMs)).then((v) {
          _executeAddDanmakuItemToCanvas();
          // 防止停止
          if (_controller.running && _animationController.isAnimating) {
            _timerAddDanmakuItemToCanvas();
          }
        });
      } else {
        _timerAddDanmakuItemToCanvas();
      }
    } else {
      _timerAddDanmakuItemToCanvas();
    }
  }

  /// 暂停
  void pause() {
    _controller.running = false;
    _controller.runTime += _startTime == null
        ? 0
        : DateTime.now().difference(_startTime!).inMilliseconds;
    _animationController.stop();
  }

  /// 恢复
  void resume() {
    start(ms: _controller.runTime);
  }

  /// 更新弹幕设置
  void updateOption(DanmakuOption option) {
    DanmakuOption oldOption = _option;
    _option = option;
    _controller.option = _option;

    /// 清理已经存在的 Paragraph 缓存
    _animationController.stop();
    // 显示区域或文本大小发生变化时更新弹幕轨道信息
    if (oldOption.area != _option.area ||
        oldOption.verticalMargin != _option.verticalMargin ||
        oldOption.verticalPadding != _option.verticalPadding ||
        oldOption.fontSize != _option.fontSize) {
      if (oldOption.fontSize != _option.fontSize ||
          oldOption.verticalMargin != _option.verticalMargin ||
          oldOption.verticalPadding != _option.verticalPadding) {
        // 生成新的弹幕高度信息
        getDanmakuHeight();

        bool updateParagraph = oldOption.fontSize != _option.fontSize;

        for (var entry in _timeCanvasDanmakuItems.entries) {
          if (entry.value.isEmpty) {
            continue;
          }
          for (List<CanvasDanmakuItem> list in entry.value.values) {
            if (list.isEmpty) {
              continue;
            }
            for (var item in list) {
              if (item.height == 0) {
                item.height = _danmakuHeight;
              } else {
                int i = (item.yPosition / item.height).floor();
                item.height = _danmakuHeight;
                if (i > 0) {
                  item.yPosition = item.height * i;
                }
              }
              if (updateParagraph) {
                item.paragraph = null;
              } else {
                item.width =
                    item.width + item.height - option.verticalMargin * 2.0;
              }
            }
          }
        }
      }
      updateDanmakuCanvasHeight(_viewHeight);
    }

    // 检查是否修改了过滤
    bool filterChange = false;
    if (_option.filterTop != oldOption.filterTop) {
      filterChange = true;
    }
    if (!filterChange && _option.filterBottom != oldOption.filterBottom) {
      filterChange = true;
    }
    if (!filterChange && _option.filterScroll != oldOption.filterScroll) {
      filterChange = true;
    }
    if (!filterChange && _option.filterColour != oldOption.filterColour) {
      filterChange = true;
    }
    if (!filterChange && _option.filterRepeat != oldOption.filterRepeat) {
      filterChange = true;
    }
    if (!filterChange &&
        (_option.filterWords ?? []) != (oldOption.filterWords ?? [])) {
      filterChange = true;
    }
    if (filterChange) {
      _tick++;
      for (var item in [..._clickCanvasDanmakuItems, ..._canvasDanmakuItems]) {
        if (item.visibleTick + 1 == _tick) {
          if (!_validIsFilter(item)) {
            item.visibleTick = _tick;
          }
        }
      }
    }

    _animationController.repeat();
    setState(() {});
  }

  /// 清空弹幕
  void clearDanmakus() {
    _canvasDanmakuItems.clear();
    _clickCanvasDanmakuItems.clear();
  }

  /// 定制执行将弹幕列表显示至canvas幕布
  void _timerAddDanmakuItemToCanvas() {
    _timer = Timer.periodic(Duration(milliseconds: _addDanmakuItemsMs), (t) {
      _executeAddDanmakuItemToCanvas();
    });
  }

  /// 执行将弹幕列表显示至canvas幕布
  void _executeAddDanmakuItemToCanvas() {
    Duration duration = Duration(milliseconds: _controller.runTime);
    // 取出这一秒内所有弹幕
    int second = duration.inSeconds;
    Map<int, List<CanvasDanmakuItem>> secondItems =
        _timeCanvasDanmakuItems[second] ?? {};
    // 这一秒多出的毫秒
    int ms = duration.inMilliseconds - second * 1000;
    // 这个属于哪一个间隔区间
    int msInterval = (ms / _addDanmakuItemsMs).floor() * 100;
    List<CanvasDanmakuItem> msIntervalItems = secondItems[msInterval] ?? [];
    if (_canvasDanmakuItems.isNotEmpty) {
      msIntervalItems.removeWhere((item) => _canvasDanmakuItems
          .any((c) => c.danmakuItem.danmakuId == item.danmakuItem.danmakuId));
    }
    if (msIntervalItems.isNotEmpty) {
      msIntervalItems.sort((a, b) => a.danmakuItem.time - b.danmakuItem.time);

      _updateTrackDanmakuItemPosition(msIntervalItems);
    }
    _canvasDanmakuItems.removeWhere((item) {
      // 移除屏幕了或者耗时时长比例超过100%
      bool flag =
          (DanmakuShowType.r2l.modeList.contains(item.danmakuItem.mode) &&
                  item.xPosition + item.width <= 0) ||
              (DanmakuShowType.l2r.modeList.contains(item.danmakuItem.mode) &&
                  item.xPosition >= _viewWidth) ||
              item.usedTimeRatio >= 1.0 ||
              _controller.runTime >= _option.duration + item.danmakuItem.time;
      return flag;
    });

    _clickCanvasDanmakuItems.removeWhere((item) {
      bool flag =
          (DanmakuShowType.r2l.modeList.contains(item.danmakuItem.mode) &&
                  item.xPosition + item.width <= 0) ||
              (DanmakuShowType.l2r.modeList.contains(item.danmakuItem.mode) &&
                  item.xPosition >= _viewWidth) ||
              item.usedTimeRatio >= 1.0 ||
              _controller.runTime >= _option.duration + item.danmakuItem.time;
      return flag;
    });

    debugPrint(
        "总列表：${_canvasDanmakuItems.length},点击列表：${_clickCanvasDanmakuItems.length}");
  }

  /// 更新弹幕的轨迹位置
  void _updateTrackDanmakuItemPosition(
      List<CanvasDanmakuItem> canvasDanmakuItems) {
    for (var item in canvasDanmakuItems) {
      if (item.paragraph == null) {
        item.updateParagraph(_option);
      }
      if (_validIsFilter(item)) {
        continue;
      }
      if ([...DanmakuShowType.top.modeList, ...DanmakuShowType.bottom.modeList]
          .contains(item.danmakuItem.mode)) {
        item.xPosition = (_viewWidth - item.width) / 2;
      } else if (DanmakuShowType.r2l.modeList.contains(item.danmakuItem.mode)) {
        item.xPosition = _viewWidth;
      } else if (DanmakuShowType.l2r.modeList.contains(item.danmakuItem.mode)) {
        item.xPosition = -item.width;
      }
      if (_option.massiveMode) {
        var randomYPosition =
            _trackYPositions[Random().nextInt(_trackYPositions.length)];
        item.visibleTick = _tick;
        item.yPosition = randomYPosition;

        _canvasDanmakuItems.add(item);
      } else {
        for (double yPosition in _trackYPositions) {
          bool canAdd = _validCanAddTrack(yPosition, item);
          if (canAdd) {
            item.yPosition = yPosition;
            item.visibleTick = _tick;
            _canvasDanmakuItems.add(item);

            break;
          }
        }
      }
    }
  }

  bool _validIsFilter(CanvasDanmakuItem canvasDanmakuItem) {
    // 是否过滤顶部
    if (_option.filterTop &&
        DanmakuShowType.top.modeList
            .contains(canvasDanmakuItem.danmakuItem.mode)) {
      return true;
    }
    // 是否过滤底部
    if (_option.filterBottom &&
        DanmakuShowType.bottom.modeList
            .contains(canvasDanmakuItem.danmakuItem.mode)) {
      return true;
    }
    // 是否过滤滚动
    if (_option.filterScroll &&
        [...DanmakuShowType.l2r.modeList, ...DanmakuShowType.r2l.modeList]
            .contains(canvasDanmakuItem.danmakuItem.mode)) {
      return true;
    }
    // 是否过滤彩色
    if (_option.filterColour &&
        Utils.isColorFulByInt(canvasDanmakuItem.danmakuItem.color)) {
      return true;
    }

    // 是否包含过滤词
    if (_option.filterWords != null && _option.filterWords!.isNotEmpty) {
      bool filter = false;
      for (String word in _option.filterWords!) {
        if (word.contains(canvasDanmakuItem.danmakuItem.content)) {
          filter = true;
          break;
        }
      }
      if (filter) {
        return true;
      }
    }
    return false;
  }

  /// 确定弹幕是否可以添加
  bool _validCanAddTrack(
      double yPosition, CanvasDanmakuItem canvasDanmakuItem) {
    double newDanmakuWidth = canvasDanmakuItem.width;
    int mode = canvasDanmakuItem.danmakuItem.mode;
    bool flag = true;
    for (var item in _canvasDanmakuItems) {
      if (item.visibleTick != _tick) {
        continue;
      }
      // 滚动弹幕（右向左）
      if (DanmakuShowType.r2l.modeList.contains(item.danmakuItem.mode) &&
          DanmakuShowType.r2l.modeList.contains(mode)) {
        if (item.yPosition == yPosition &&
            item.danmakuItem.danmakuId !=
                canvasDanmakuItem.danmakuItem.danmakuId) {
          final existingEndPosition = item.xPosition + item.width;
          // 首先保证进入屏幕时不发生重叠，其次保证知道移出屏幕前不与速度慢的弹幕(弹幕宽度较小)发生重叠
          if (_viewWidth - existingEndPosition < 0) {
            flag = false;
            break;
          }
          if (item.width < newDanmakuWidth) {
            if ((1 -
                    ((_viewWidth - item.xPosition) /
                        (item.width + _viewWidth))) >
                ((_viewWidth) / (_viewWidth + newDanmakuWidth))) {
              flag = false;
              break;
            }
          }
        }
      }
      // 滚动弹幕（左向右）
      if (DanmakuShowType.l2r.modeList.contains(item.danmakuItem.mode) &&
          DanmakuShowType.l2r.modeList.contains(mode)) {
        if (item.yPosition == yPosition &&
            item.danmakuItem.danmakuId !=
                canvasDanmakuItem.danmakuItem.danmakuId) {
          // 首先保证进入屏幕时不发生重叠，其次保证知道移出屏幕前不与速度慢的弹幕(弹幕宽度较小)发生重叠
          // 还未完全进入
          if (item.xPosition <= 0) {
            flag = false;
            break;
          }
          if (item.width < newDanmakuWidth) {
            if ((1 -
                    ((item.xPosition - item.width) /
                        (item.width + _viewWidth))) >
                ((_viewWidth) / (_viewWidth + newDanmakuWidth))) {
              flag = false;
              break;
            }
          }
        }
      }
      // 固定弹幕
      else if ([
            ...DanmakuShowType.top.modeList,
            ...DanmakuShowType.bottom.modeList
          ].contains(item.danmakuItem.mode) &&
          [...DanmakuShowType.top.modeList, ...DanmakuShowType.bottom.modeList]
              .contains(mode)) {
        if (item.yPosition == yPosition) {
          flag = false;
          break;
        }
      }
    }
    return flag;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      /// 计算视图宽度
      if (constraints.maxWidth != _viewWidth) {
        _viewWidth = constraints.maxWidth;
      }
      if (constraints.maxHeight != _viewHeight) {
        updateDanmakuCanvasHeight(constraints.maxHeight);
      }
      return ClipRect(
        child: Listener(
          onPointerDown: (details) {
            debugPrint("点击了弹幕坐标：${details.localPosition}");
            _clickCanvas(details.localPosition);
          },
          // onTapDown: (details) {
          //   debugPrint("点击了弹幕坐标：${details.localPosition}");
          //   _clickCanvas(details.localPosition);
          // },
          child: Stack(
            children: [
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    _controller.runTime += _startTime == null
                        ? 0
                        : DateTime.now().difference(_startTime!).inMilliseconds;
                    _startTime = DateTime.now();
                    return DanmakuRenderObjectWidget(
                      animateProgress: _animationController.value,
                      option: _option,
                      canvasDanmakuItems: _canvasDanmakuItems,
                      clickCanvasDanmakuItems: _clickCanvasDanmakuItems,
                      clickDanmakuId: _clickDanmakuId,
                      running: _controller.running,
                      currentTime: _controller.runTime,
                      visibleTick: _tick,
                    );
                  },
                ),
              )
            ],
          ),
        ),
      );
    });
  }
}
