import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(StreamVideo());
}

class StreamVideo extends StatefulWidget {
  @override
  _StreamVideoState createState() => _StreamVideoState();
}

class _StreamVideoState extends State<StreamVideo> {
  late VideoPlayerController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network('https://d26nj1ndv161pg.cloudfront.net/output/side_1009_12.m3u8');
    _controller.initialize().then((_) {
      setState(() {});
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
          child: _controller.value.isInitialized
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
            ],
          )
              : Center(child: CircularProgressIndicator()),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
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
    final newPosition = _controller.value.position + Duration(seconds: 1);  // 進む長さを5秒に設定
    if (newPosition <= _controller.value.duration) {
      _controller.seekTo(newPosition);
    } else {
      _controller.seekTo(_controller.value.duration);
    }
  }

  void _seekBackward() {
    final newPosition = _controller.value.position - Duration(seconds: 1);  // 戻る長さを5秒に設定
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
