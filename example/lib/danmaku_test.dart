import 'package:flutter/material.dart';
import 'package:fps_widget/fps_widget.dart';
import 'package:render_object_danmaku/parse/bili_danmaku_parser.dart';
import 'package:render_object_danmaku/render_object_danmaku.dart';

class DanmakuTest extends StatefulWidget {
  const DanmakuTest({super.key});

  @override
  State<DanmakuTest> createState() => _DanmakuTestState();
}

class _DanmakuTestState extends State<DanmakuTest> {
  late DanmakuController _controller;
  double fontSize = 16.0;
  double area = 1.0;
  bool _filterTop = false;
  bool _filterBottom = false;
  bool _filterScroll = false;
  bool _filterColour = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
      ),
      body: FPSWidget(
        show: true,
        child: Center(
          child: Column(
            children: [
              TextButton(
                  onPressed: () {
                    _controller.start(ms: 1);
                  },
                  child: Text("启动弹幕")),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                child: Slider(
                  value: fontSize,
                  min: 5.0,
                  max: 30.0,
                  onChanged: (value) {
                    setState(() {
                      fontSize = value;
                    });
                    _controller.onUpdateOption(
                        _controller.option.copyWith(fontSize: fontSize));
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                child: Slider(
                  value: area,
                  min: 0.25,
                  max: 1.0,
                  divisions: 4,
                  onChanged: (value) {
                    setState(() {
                      area = value;
                    });
                    _controller.onUpdateOption(
                        _controller.option.copyWith(area: area));
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Text(_filterTop ? "显示顶部" : "隐藏顶部"),
                        Switch(
                            value: _filterTop,
                            onChanged: (flag) {
                              setState(() {
                                _filterTop = flag;
                              });
                              _controller.updateOption(_controller.option
                                  .copyWith(filterTop: _filterTop));
                            }),
                      ],
                    ),
                    Column(
                      children: [
                        Text(_filterBottom ? "显示底部" : "隐藏底部"),
                        Switch(
                            value: _filterBottom,
                            onChanged: (flag) {
                              setState(() {
                                _filterBottom = flag;
                              });
                              _controller.updateOption(_controller.option
                                  .copyWith(filterBottom: _filterBottom));
                            }),
                      ],
                    ),
                    Column(
                      children: [
                        Text(_filterScroll ? "显示滚动" : "隐藏滚动"),
                        Switch(
                            value: _filterScroll,
                            onChanged: (flag) {
                              setState(() {
                                _filterScroll = flag;
                              });
                              _controller.updateOption(_controller.option
                                  .copyWith(filterScroll: _filterScroll));
                            }),
                      ],
                    ),
                    Column(
                      children: [
                        Text(_filterTop ? "显示彩色" : "隐藏彩色"),
                        Switch(
                            value: _filterColour,
                            onChanged: (flag) {
                              setState(() {
                                _filterColour = flag;
                              });
                              _controller.updateOption(_controller.option
                                  .copyWith(filterColour: _filterColour));
                            }),
                      ],
                    ),
                  ],
                ),
              ),
              AspectRatio(
                aspectRatio: 16 / 10.0,
                child: Container(
                  color: Colors.grey,
                  child: DanmakuView(
                    option: DanmakuOption(),
                    createdController: (c) {
                      _controller = c;

                      _controller.onDanmakuFileParse(
                          path: "assets/1_1.xml",
                          danmakuParser: BiliDanmakuParser(),
                          fromAssets: true,
                          isStart: false,
                          loaded: (flag) {
                            debugPrint("解析返回：$flag");
                            _controller.start();
                          });
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
