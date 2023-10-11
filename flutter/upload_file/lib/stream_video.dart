import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class StreamVideo extends StatefulWidget {
  final String formattedDate;
  final String selectedRow;

  StreamVideo({required this.formattedDate, required this.selectedRow});

  @override
  _StreamVideoState createState() => _StreamVideoState();
}

class _StreamVideoState extends State<StreamVideo> {
  late VideoPlayerController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasError = false; // エラーフラグ
  String _errorMessage = ''; // エラーメッセージ

  String generateVideoUrl(String formattedDate, String selectedRow) {
    return 'https://d26nj1ndv161pg.cloudfront.net/output/$formattedDate/$selectedRow/side.m3u8';
  }

  @override
  void initState() {
    super.initState();
    String videoUrl = generateVideoUrl(widget.formattedDate, widget.selectedRow);
    print("videoUrl:$videoUrl");
    _controller = VideoPlayerController.network(videoUrl);
    _controller.initialize().then((_) {
      setState(() {});
    }).catchError((error) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
      });
      print("Error Occurred: $error");
    });

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: RawKeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKey: (RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _seekForward();
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _seekBackward();
              }
            }
          },
          child: _hasError  // エラーフラグに基づいてUIを変更
              ? Stack(
            children: [
              Center(child: Text("動画がupされてません\nエラー: $_errorMessage")),  // エラーメッセージも表示
              Positioned(
                top: 10,
                left: 10,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pop(context);  // 画面遷移から戻る
                  },
                  child: Icon(Icons.arrow_back),
                ),
              ),
            ],
          )
              : (_controller.value.isInitialized
              ? Stack(
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Slider(
                  value: _controller.value.position.inMilliseconds.toDouble(),
                  min: 0.0,
                  max: _controller.value.duration.inMilliseconds.toDouble(),
                  onChanged: (double value) {
                    setState(() {
                      _controller.seekTo(Duration(milliseconds: value.toInt()));
                    });
                  },
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: FloatingActionButton(
                  heroTag: "tag-stream",
                  mini: true,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.arrow_back),
                ),
              ),
            ],
          )
              : Center(child: CircularProgressIndicator())),
        ),
        floatingActionButton: _hasError
            ? null  // エラー時には再生/一時停止ボタンを非表示に
            : FloatingActionButton(
          onPressed: () {
            setState(() {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            });
          },
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      ),
    );
  }


  void _seekForward() {
    final newPosition = _controller.value.position + Duration(seconds: 1);
    if (newPosition <= _controller.value.duration) {
      _controller.seekTo(newPosition);
    } else {
      _controller.seekTo(_controller.value.duration);
    }
  }

  void _seekBackward() {
    final newPosition = _controller.value.position - Duration(seconds: 1);
    if (newPosition >= Duration.zero) {
      _controller.seekTo(newPosition);
    } else {
      _controller.seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _focusNode.dispose();
  }
}
