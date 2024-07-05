import 'package:flutter/material.dart';

class DanmakuItem {
  // 弹幕danmakuId	int64	唯一 可用于操作参数
  final String danmakuId;
  // 弹幕内容
  final String content;
  // 	视频内弹幕出现时间	毫秒
  int time;
  // 	弹幕类型
  int mode;
  // 弹幕字号
  final double fontSize;
  // 弹幕颜色
  int color;

  // 弹幕发送时间	时间戳（创建时间）
  final Duration? createTime;

  // 发送者mid的HASH	string	用于屏蔽用户和查看用户发送的所有弹幕 也可反查用户id
  final String? sendUserId;

  int? backgroundColor;
  int? boldColor;

  DanmakuItem({
    required this.danmakuId,
    required this.content,
    required this.time,
    required this.mode,
    required this.fontSize,
    required this.color,
    this.createTime,
    this.sendUserId,
    this.backgroundColor,
    this.boldColor,
  });
  // {
  //   backgroundColor ??= Colors.black.withOpacity(0.6).value;
  //   boldColor ??= Colors.redAccent.value;
  // }

  factory DanmakuItem.fromJson(Map<String, dynamic> json) => DanmakuItem(
        danmakuId: json["danmakuId"],
        content: json["content"],
        time: json["time"],
        mode: json["mode"],
        fontSize: json["fontSize"],
        color: json["color"],
        createTime: json["createTime"],
        sendUserId: json["sendUserId"],
        backgroundColor: json["backgroundColor"],
        boldColor: json["boldColor"],
      );

  Map<String, dynamic> toJson() => {
        "danmakuId": danmakuId,
        "content": content,
        "time": time,
        "mode": mode,
        "fontSize": fontSize,
        "color": color,
        "createTime": createTime,
        "sendUserId": sendUserId,
        "backgroundColor": backgroundColor,
        "boldColor": boldColor,
      };
}
