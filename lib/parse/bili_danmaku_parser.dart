import 'dart:io';

import 'package:flutter/services.dart';
import 'package:render_object_danmaku/parse/base_danmaku_parser.dart';
import 'package:render_object_danmaku/models/canvas_danmaku_item.dart';
import 'package:render_object_danmaku/models/danmaku_item.dart';
import 'package:xml/xml.dart';

class BiliDanmakuParser extends BaseDanmakuParser {
  String parentTagName = "i";
  String contentTagName = "d";
  String readAttrName = "p";
  String readAttrSplitChar = ",";
  // 最少只需要读取到颜色
  int readAttrMinLen = 4;
  String xpathParseXml = "//i//d[@p and not(*)]";

  BiliDanmakuParser({super.optionMap}) {
    if (optionMap != null) {
      parentTagName = optionMap!["parentTagName"] ?? parentTagName;
      contentTagName = optionMap!["contentTagName"] ?? contentTagName;
      readAttrName = optionMap!["readAttrName"] ?? readAttrName;
      readAttrSplitChar = optionMap!["readAttrSplitChar"] ?? readAttrSplitChar;
      readAttrMinLen = optionMap!["readAttrMinLen"] ?? readAttrMinLen;
      xpathParseXml = optionMap!["xpathParseXml"] ?? xpathParseXml;
    }
  }

  Future<XmlDocument?> _readXmlFromAssets(String xmlPath) async {
    String xmlStr = await rootBundle.loadString(xmlPath);
    if (xmlStr.isEmpty) {
      return Future.value(null);
    }
    XmlDocument document = XmlDocument.parse(xmlStr);
    return document;
  }

  XmlDocument? _readXmlFromPath(String xmlPath) {
    String xmlStr = File(xmlPath).readAsStringSync();
    if (xmlStr.isEmpty) {
      return null;
    }
    XmlDocument document = XmlDocument.parse(xmlStr);
    return document;
  }

  void _handleDanmakuItemTime(
      CanvasDanmakuItem? canvasDanmakuItem,
      Map<int, Map<int, List<CanvasDanmakuItem>>> timeItems,
      int addDanmakuItemsMs) {
    if (canvasDanmakuItem != null) {
      Duration duration =
          Duration(milliseconds: canvasDanmakuItem.danmakuItem.time);
      int second = duration.inSeconds;
      Map<int, List<CanvasDanmakuItem>> secondItems = timeItems[second] ?? {};
      // 这一秒多出的毫秒
      int ms = duration.inMilliseconds - second * 1000;
      // 这个属于哪一个间隔区间
      int msInterval = (ms / addDanmakuItemsMs).floor() * 100;
      List<CanvasDanmakuItem> msIntervalItems = secondItems[msInterval] ?? [];

      msIntervalItems.add(canvasDanmakuItem);
      secondItems[msInterval] = msIntervalItems;
      timeItems[second] = secondItems;
    }
  }

  @override
  Future<Map<int, Map<int, List<CanvasDanmakuItem>>>> parseCanvasDanmakusByXml(
    String xmlPath, {
    bool fromAssets = false,
    int addDanmakuItemsMs = 100,
  }) async {
    XmlDocument? document;
    if (fromAssets) {
      document = await _readXmlFromAssets(xmlPath);
    } else {
      document = _readXmlFromPath(xmlPath);
    }
    if (document == null) {
      return {};
    }
    Map<int, Map<int, List<CanvasDanmakuItem>>> timeItems = {};

    for (XmlElement xmlElement in document.childElements) {
      // 需要是指定（i）标签下的
      if (xmlElement.localName == (parentTagName)) {
        for (XmlElement element in xmlElement.childElements) {
          _handleDanmakuItemTime(
            _getCanvasDanmakuItemByXmlElement(element),
            timeItems,
            addDanmakuItemsMs,
          );
        }
      } else {
        _handleDanmakuItemTime(
          _getCanvasDanmakuItemByXmlElement(xmlElement),
          timeItems,
          addDanmakuItemsMs,
        );
      }
    }
    return timeItems;
  }

  CanvasDanmakuItem? _getCanvasDanmakuItemByXmlElement(XmlElement element) {
    // 只读取指定（d）标签，且没有子节点，内容不为空，有指定属性
    if (element.localName != contentTagName ||
        element.childElements.isNotEmpty ||
        element.getAttribute(readAttrName) == null ||
        element.innerText.isEmpty) {
      return null;
    }
    String readAttrText = element.getAttribute(readAttrName)!;
    List<String> readAttrTextList = readAttrText.split(readAttrSplitChar);
    // 属性长度
    if (readAttrTextList.isEmpty || readAttrTextList.length < readAttrMinLen) {
      return null;
    }
    return _createCanvasDanmakuModel(readAttrTextList, element.innerText);
  }

  // 生成弹幕内容
  CanvasDanmakuItem? _createCanvasDanmakuModel(
      List<String> readAttrTextList, String text) {
    // <d p="490.19100,1,25,16777215,1584268892,0,a16fe0dd,29950852386521095">从结尾回来看这里，更感动了！</d>
    // 0 视频内弹幕出现时间	float	秒

    // 1 弹幕类型	int32	1 2 3：普通弹幕
    //                  4：底部弹幕
    //                  5：顶部弹幕
    //                  6：逆向弹幕
    //                  7：高级弹幕
    //                  8：代码弹幕
    //                  9：BAS弹幕（pool必须为2）

    // 2	弹幕字号	int32	18：小
    //                  25：标准
    //                  36：大

    // 3	弹幕颜色	int32	十进制RGB888值

    // 4	弹幕发送时间	int32	时间戳

    // 5	弹幕池类型	int32	0：普通池
    //                      1：字幕池
    //                      2：特殊池（代码/BAS弹幕）

    // 6	发送者mid的HASH	string	用于屏蔽用户和查看用户发送的所有弹幕 也可反查用户id
    // 7	弹幕dmid	int64	唯一 可用于操作参数
    // 8	弹幕的屏蔽等级	int32	0-10，低于用户设定等级的弹幕将被屏蔽 （新增，下方样例未包含）
    late int time;
    // 	弹幕类型
    late int mode;
    // 弹幕字号
    late double fontSize;
    // 弹幕颜色（十进制RGB888值）
    late int color;
    // 弹幕发送时间	时间戳
    int? createTime;
    // 弹幕池类型
    // String? poolType;
    // 发送者mid的HASH	string	用于屏蔽用户和查看用户发送的所有弹幕 也可反查用户id
    String? sendUserId;
    // 弹幕dmid	int64	唯一 可用于操作参数
    late String danmakuId;
    // 弹幕的屏蔽等级
    // late int level;
    for (int i = 0; i < readAttrTextList.length; i++) {
      if (i > 9) {
        return null;
      }
      String value = readAttrTextList[i].trim();
      try {
        switch (i) {
          case 0:
            time = (double.parse(value) * 1000).floor();
            break;
          case 1:
            mode = int.tryParse(value) ?? 1;
            break;
          case 2:
            fontSize = double.parse(value);
            if (fontSize <= 0) {
              return null;
            }
            break;
          case 3:
            color = int.parse(value);
            break;
          case 4:
            createTime = int.tryParse(value);
            break;
          case 5:
            // poolType = value;
            break;
          case 6:
            sendUserId = value;
            break;
          case 7:
            danmakuId = value;
            break;
          case 8:
            // level = int.parse(value);
            break;
        }
      } catch (e) {
        return null;
      }
    }

    return CanvasDanmakuItem(
        danmakuItem: DanmakuItem(
      time: time,
      mode: mode,
      fontSize: fontSize,
      color: _decimalToColor(color).value,
      createTime:
          createTime == null ? null : Duration(milliseconds: createTime),
      sendUserId: sendUserId,
      danmakuId: danmakuId,
      content: text,
    ));
  }

  Color _decimalToColor(int decimalColor) {
    final red = (decimalColor & 0xFF0000) >> 16;
    final green = (decimalColor & 0x00FF00) >> 8;
    final blue = decimalColor & 0x0000FF;
    return Color.fromARGB(255, red, green, blue);
  }
}
