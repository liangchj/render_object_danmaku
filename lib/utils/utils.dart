import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:render_object_danmaku/models/canvas_danmaku_item.dart';
import 'package:render_object_danmaku/models/danmaku_item.dart';
import 'package:render_object_danmaku/models/danmaku_option.dart';
import 'package:render_object_danmaku/models/danmaku_show_type.dart';

class Utils {
  static void danmakuItemDraw(CanvasDanmakuItem canvasDanmakuItem,
      Canvas canvas, Size size, int currentTime, DanmakuOption option,
      {String? clickDanmakuId}) {
    if (clickDanmakuId == null || clickDanmakuId.isEmpty) {
      if (canvasDanmakuItem.paragraph == null) {
        canvasDanmakuItem.updateParagraph(option);
      }
      int elapsedTime = canvasDanmakuItem.danmakuItem.time - currentTime;
      // 右向左
      if (DanmakuShowType.r2l.modeList
          .contains(canvasDanmakuItem.danmakuItem.mode)) {
        // 开始位置
        double startPosition = size.width;

        double endPosition = -canvasDanmakuItem.width;
        double distance = startPosition - endPosition;

        canvasDanmakuItem.xPosition =
            startPosition + (elapsedTime / option.duration) * distance;

        if (canvasDanmakuItem.xPosition < -canvasDanmakuItem.width ||
            canvasDanmakuItem.xPosition > size.width) {
          return;
        }
      }
      // 左向右
      if (DanmakuShowType.l2r.modeList
          .contains(canvasDanmakuItem.danmakuItem.mode)) {
        // 开始位置
        double startPosition = -canvasDanmakuItem.width;
        double endPosition = size.width;
        double distance = endPosition - startPosition;

        canvasDanmakuItem.xPosition =
            startPosition - (elapsedTime / option.duration) * distance;

        if (canvasDanmakuItem.xPosition < -canvasDanmakuItem.width ||
            canvasDanmakuItem.xPosition > size.width) {
          return;
        }
      }
      if (canvasDanmakuItem.danmakuItem.time + option.duration < currentTime) {
        canvasDanmakuItem.usedTimeRatio = 1.0;
      } else {
        canvasDanmakuItem.usedTimeRatio =
            (currentTime - canvasDanmakuItem.danmakuItem.time) *
                1.0 /
                option.duration;
      }
    } else {
      debugPrint(
          "弹幕当前被点击：${canvasDanmakuItem.xPosition}, ${canvasDanmakuItem.yPosition}");
    }

    if (canvasDanmakuItem.danmakuItem.backgroundColor != null ||
        canvasDanmakuItem.danmakuItem.boldColor != null) {
      Radius radius = Radius.circular(
          (canvasDanmakuItem.height - option.verticalMargin * 2.0) / 2.0);
      RRect boxRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
              canvasDanmakuItem.xPosition,
              canvasDanmakuItem.yPosition + option.verticalMargin,
              canvasDanmakuItem.width,
              canvasDanmakuItem.height - option.verticalMargin * 2.0),
          radius);

      if (canvasDanmakuItem.danmakuItem.backgroundColor != null) {
        canvas.drawRRect(
            boxRRect,
            Paint()
              ..color = Color(canvasDanmakuItem.danmakuItem.backgroundColor!));
      }

      if (canvasDanmakuItem.danmakuItem.boldColor != null) {
        final Paint boldPaint = Paint()
          ..isAntiAlias = true
          ..color = Color(canvasDanmakuItem.danmakuItem.boldColor!)
          ..style = PaintingStyle.stroke
          ..strokeWidth = option.boldWidth
          ..strokeJoin = StrokeJoin.round;

        canvas.drawRRect(boxRRect, boldPaint);
      }
    }

    canvas.drawParagraph(
        canvasDanmakuItem.paragraph!,
        Offset(
            canvasDanmakuItem.xPosition +
                (canvasDanmakuItem.width - canvasDanmakuItem.textWidth) / 2.0,
            canvasDanmakuItem.yPosition +
                (canvasDanmakuItem.height - canvasDanmakuItem.textHeight) /
                    2.0));
    canvasDanmakuItem.drawn = true;
  }

  static generateParagraph(
      DanmakuItem danmakuItem, double danmakuWidth, double fontSize) {
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontSize: fontSize,
      textDirection: TextDirection.ltr,
    ))
      ..pushStyle(ui.TextStyle(
        color: Color(danmakuItem.color),
      ))
      ..addText(danmakuItem.content);
    return builder.build()
      ..layout(ui.ParagraphConstraints(width: danmakuWidth));
  }

  static generateStrokeParagraph(DanmakuItem danmakuItem, double danmakuWidth,
      double fontSize, double strokeWidth) {
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.black;

    final ui.ParagraphBuilder strokeBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontSize: fontSize,
      textDirection: TextDirection.ltr,
    ))
          ..pushStyle(ui.TextStyle(
            foreground: strokePaint,
          ))
          ..addText(danmakuItem.content);

    return strokeBuilder.build()
      ..layout(ui.ParagraphConstraints(width: danmakuWidth));
  }

  static Color decimalToColor(int decimalColor) {
    final red = (decimalColor & 0xFF0000) >> 16;
    final green = (decimalColor & 0x00FF00) >> 8;
    final blue = decimalColor & 0x0000FF;
    return Color.fromARGB(255, red, green, blue);
  }

  static bool isColorFulByInt(int color) {
    int red = (color >> 16) & 0xFF;
    int green = (color >> 8) & 0xFF;
    int blue = color & 0xFF;
    if (red == 0 && green == 0 && blue == 0) {
      return false;
    }
    if (red == 255 && green == 255 && blue == 255) {
      return false;
    }
    return red != green && green != blue && blue != red;
  }

  static bool isColorFulByColor(Color color) {
    if (color.red == 0 && color.green == 0 && color.blue == 0) {
      return false;
    }
    if (color.red == 255 && color.green == 255 && color.blue == 255) {
      return false;
    }
    return color.red != color.green &&
        color.green != color.blue &&
        color.blue != color.red;
  }
}
