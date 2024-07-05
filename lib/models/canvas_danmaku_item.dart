import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:render_object_danmaku/models/danmaku_item.dart';
import 'package:render_object_danmaku/models/danmaku_option.dart';
import 'package:render_object_danmaku/utils/utils.dart';

class CanvasDanmakuItem {
  final DanmakuItem danmakuItem;

  double textWidth;
  double width;
  // 文本高度
  double textHeight;
  // 总的高度（文本高度 + 上下外边距 + 上下内边距 + 上下边框宽度）
  double height;
  double xPosition;
  double yPosition;
  ui.Paragraph? paragraph;

  bool drawn;

  // 点击时的毫秒
  int? clickTimeMs;

  // 可以显示的计数
  int visibleTick;
  // 医用时长比例
  double usedTimeRatio;

  CanvasDanmakuItem({
    required this.danmakuItem,
    this.textWidth = 0.0,
    this.width = 0.0,
    this.textHeight = 0.0,
    this.height = 0.0,
    this.xPosition = 0.0,
    this.yPosition = 0.0,
    this.paragraph,
    this.drawn = false,
    this.clickTimeMs,
    this.visibleTick = -1, // 默认都不可以显示
    this.usedTimeRatio = 0.0,
  });

  ui.Paragraph updateParagraph(DanmakuOption option) {
    final textPainter = TextPainter(
      text: TextSpan(
          text: danmakuItem.content,
          style: TextStyle(
              fontSize: option.fontSize, color: Color(danmakuItem.color))),
      textDirection: TextDirection.ltr,
    )..layout();

    textWidth = textPainter.width;

    textHeight = textPainter.height;
    // 加上内外边距和边框
    height = textPainter.height +
        option.verticalMargin * 2.0 +
        option.verticalPadding * 2.0 +
        option.boldWidth * 2.0;

    width = textPainter.width + height - option.verticalMargin * 2.0;
    paragraph = Utils.generateParagraph(
        danmakuItem, textPainter.width, option.fontSize);
    drawn = false;
    return paragraph!;
  }
}
