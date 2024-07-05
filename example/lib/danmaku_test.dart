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
