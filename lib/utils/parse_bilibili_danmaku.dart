import 'dart:io';

import 'package:flutter/services.dart';
import 'package:render_object_danmaku/models/canvas_danmaku_item.dart';
import 'package:render_object_danmaku/models/danmaku_item.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

class ParseBilibiliDanmaku {
  static const String parentTagName = "i";
  static const String contentTagName = "d";
  static const String readAttrName = "p";
  static const String readAttrSplitChar = ",";
  // 最少只需要读取到颜色
  static const int readAttrMinLen = 4;
  static const String xpathParseXml = "//i//d[@p and not(*)]";

  static ParseBilibiliDanmaku? _instance;

  ParseBilibiliDanmaku._();

  factory ParseBilibiliDanmaku() {
    _instance = _instance ?? ParseBilibiliDanmaku._();
    return _instance!;
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

  // xpath方式读取（文件内容多会很慢，推荐使用逐级方式读取）
  Future<List<CanvasDanmakuItem>> parseBilibiliCanvasDanmakuByXmlForXpath(
      String xmlPath,
      {String? xpath,
      String? attrName,
      String? splitChar,
      bool fromAssets = false}) async {
    XmlDocument? document;
    if (fromAssets) {
      document = await _readXmlFromAssets(xmlPath);
    } else {
      document = _readXmlFromPath(xmlPath);
    }
    if (document == null) {
      return [];
    }
    List<CanvasDanmakuItem> danmakuList = [];
    if (document.childElements.isNotEmpty) {
      Iterable<XmlNode> iterable = document.xpath(xpath ?? xpathParseXml);
      for (XmlNode xmlNode in iterable) {
        String readAttrText = xmlNode.getAttribute(attrName ?? readAttrName)!;
        List<String> readAttrTextList =
            readAttrText.split(splitChar ?? readAttrSplitChar);
        if (readAttrTextList.isEmpty ||
            readAttrTextList.length < readAttrMinLen ||
            xmlNode.innerText.isEmpty) {
          continue;
        }

        CanvasDanmakuItem? danmakuItem =
            _createCanvasDanmakuModel(readAttrTextList, xmlNode.innerText);
        if (danmakuItem != null) {
          danmakuList.add(danmakuItem);
        }
      }
    }
    return danmakuList;
  }

  // 逐级方式读取
  Future<List<CanvasDanmakuItem>> parseBilibiliCanvasDanmakuByXml(
      String xmlPath,
      {String? parentTag,
      String? contentTag,
      String? attrName,
      String? splitChar,
      bool fromAssets = false}) async {
    XmlDocument? document;
    if (fromAssets) {
      document = await _readXmlFromAssets(xmlPath);
    } else {
      document = _readXmlFromPath(xmlPath);
    }
    if (document == null) {
      return [];
    }
    List<CanvasDanmakuItem> danmakuList = [];
    for (XmlElement xmlElement in document.childElements) {
      // 需要是指定（i）标签下的
      if (xmlElement.localName == (parentTag ?? parentTagName)) {
        for (XmlElement element in xmlElement.childElements) {
          CanvasDanmakuItem? danmakuItem = _getCanvasDanmakuItemByXmlElement(
              element,
              parentTag: parentTag,
              contentTag: contentTag,
              attrName: attrName,
              splitChar: splitChar);
          if (danmakuItem != null) {
            danmakuList.add(danmakuItem);
          }
        }
      } else {
        CanvasDanmakuItem? danmakuItem = _getCanvasDanmakuItemByXmlElement(
            xmlElement,
            parentTag: parentTag,
            contentTag: contentTag,
            attrName: attrName,
            splitChar: splitChar);
        if (danmakuItem != null) {
          danmakuList.add(danmakuItem);
        }
      }
    }
    return danmakuList;
  }

  CanvasDanmakuItem? _getCanvasDanmakuItemByXmlElement(
    XmlElement element, {
    String? parentTag,
    String? contentTag,
    String? attrName,
    String? splitChar,
  }) {
    // 只读取指定（d）标签，且没有子节点，内容不为空，有指定属性
    if (element.localName != (contentTag ?? contentTagName) ||
        element.childElements.isNotEmpty ||
        element.getAttribute(attrName ?? readAttrName) == null ||
        element.innerText.isEmpty) {
      return null;
    }
    String readAttrText = element.getAttribute(attrName ?? readAttrName)!;
    List<String> readAttrTextList =
        readAttrText.split(splitChar ?? readAttrSplitChar);
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
