import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:render_object_danmaku/models/canvas_danmaku_item.dart';
import 'package:render_object_danmaku/models/danmaku_option.dart';
import 'package:render_object_danmaku/utils/utils.dart';

class DanmakuRenderObjectWidget extends LeafRenderObjectWidget {
  final double animateProgress;
  final DanmakuOption option;
  final List<CanvasDanmakuItem> canvasDanmakuItems;
  final List<CanvasDanmakuItem> clickCanvasDanmakuItems;

  /// 当前点击的弹幕id
  final String clickDanmakuId;
  final bool running;
  final int currentTime;
  final int visibleTick;

  const DanmakuRenderObjectWidget({
    super.key,
    required this.animateProgress,
    required this.option,
    required this.canvasDanmakuItems,
    required this.clickCanvasDanmakuItems,
    required this.clickDanmakuId,
    required this.running,
    required this.currentTime,
    required this.visibleTick,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _DanmakuRenderBox(
      option: option,
      canvasDanmakuItems: canvasDanmakuItems,
      clickCanvasDanmakuItems: clickCanvasDanmakuItems,
      currentTime: currentTime,
      clickDanmakuId: clickDanmakuId,
      visibleTick: visibleTick,
      running: running,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _DanmakuRenderBox renderObject) {
    renderObject
      ..option = option
      ..canvasDanmakuItems = canvasDanmakuItems
      ..clickCanvasDanmakuItems = clickCanvasDanmakuItems
      ..clickDanmakuId = clickDanmakuId
      ..running = running
      ..currentTime = currentTime
      ..visibleTick = visibleTick;
  }
}

class _DanmakuRenderBox extends RenderBox {
  _DanmakuRenderBox({
    required DanmakuOption option,
    required List<CanvasDanmakuItem> canvasDanmakuItems,
    required List<CanvasDanmakuItem> clickCanvasDanmakuItems,
    required String clickDanmakuId,
    required bool running,
    required int currentTime,
    required int visibleTick,
    int? batchThreshold,
  })  : _option = option,
        _canvasDanmakuItems = canvasDanmakuItems,
        _clickCanvasDanmakuItems = clickCanvasDanmakuItems,
        _clickDanmakuId = clickDanmakuId,
        _running = running,
        _currentTime = currentTime,
        _visibleTick = visibleTick,
        _batchThreshold = batchThreshold ?? 10;

  DanmakuOption _option;
  DanmakuOption get option => _option;
  set option(DanmakuOption newValue) {
    if (newValue != _option) {
      _option = newValue;
    }
  }

  List<CanvasDanmakuItem> _canvasDanmakuItems;
  List<CanvasDanmakuItem> get canvasDanmakuItems => _canvasDanmakuItems;
  set canvasDanmakuItems(List<CanvasDanmakuItem> newValue) {
    if (newValue != _canvasDanmakuItems) {
      _canvasDanmakuItems = newValue;
      markNeedsPaint();
    }
  }

  List<CanvasDanmakuItem> _clickCanvasDanmakuItems;
  List<CanvasDanmakuItem> get clickCanvasDanmakuItems =>
      _clickCanvasDanmakuItems;
  set clickCanvasDanmakuItems(List<CanvasDanmakuItem> newValue) {
    if (newValue != _clickCanvasDanmakuItems) {
      _clickCanvasDanmakuItems = newValue;
      markNeedsPaint();
    }
  }

  /// 当前点击的弹幕id
  String _clickDanmakuId;
  String get clickDanmakuId => _clickDanmakuId;
  set clickDanmakuId(String newValue) {
    if (newValue != _clickDanmakuId) {
      _clickDanmakuId = newValue;
    }
  }

  bool _running;
  bool get running => _running;
  set running(bool newValue) {
    if (newValue != _running) {
      _running = newValue;
      markNeedsPaint();
    }
  }

  int _currentTime;
  int get currentTime => _currentTime;
  set currentTime(int newValue) {
    if (newValue != _currentTime) {
      _currentTime = newValue;
      markNeedsPaint();
    }
  }

  int _visibleTick;
  int get visibleTick => _visibleTick;
  set visibleTick(int newValue) {
    if (newValue != _visibleTick) {
      _visibleTick = newValue;
    }
  }

  int _batchThreshold;
  int get batchThreshold => _batchThreshold;
  set batchThreshold(int newValue) {
    if (newValue != _batchThreshold) {
      _batchThreshold = newValue;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    Canvas drawCanvas = context.canvas;
    drawCanvas.save();
    drawCanvas.translate(offset.dx, offset.dy);

    ui.PictureRecorder? pictureRecorder;
    if (canvasDanmakuItems.length + clickCanvasDanmakuItems.length >
        batchThreshold) {
      // 弹幕数量超过阈值时使用批量绘制
      pictureRecorder = ui.PictureRecorder();
      drawCanvas = Canvas(pictureRecorder);
    }

    for (CanvasDanmakuItem item in canvasDanmakuItems) {
      if (item.visibleTick != visibleTick) {
        continue;
      }
      Utils.danmakuItemDraw(item, drawCanvas, size, currentTime, option);
    }
    if (clickCanvasDanmakuItems.isNotEmpty) {
      for (CanvasDanmakuItem item in clickCanvasDanmakuItems) {
        if (item.visibleTick != visibleTick) {
          continue;
        }
        Utils.danmakuItemDraw(item, drawCanvas, size, currentTime, option,
            clickDanmakuId: item.danmakuItem.danmakuId == clickDanmakuId
                ? clickDanmakuId
                : "");
      }
    }

    if (pictureRecorder != null) {
      final ui.Picture picture = pictureRecorder.endRecording();
      context.canvas.drawPicture(picture);
    }
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final desiredWidth = constraints.maxWidth;
    final desiredSize = Size(desiredWidth, constraints.maxHeight);
    return constraints.constrain(desiredSize);
  }

  @override
  bool get isRepaintBoundary => false;

  @override
  bool hitTestSelf(Offset position) => true;
}
