import 'package:flutter/material.dart';


class FileDownloaderScreen extends StatefulWidget {
  const FileDownloaderScreen({super.key});

  @override
  _FileDownloaderScreenState createState() => _FileDownloaderScreenState();
}

class _FileDownloaderScreenState extends State<FileDownloaderScreen> {
  String _downloadMessage = "No File Downloaded";

  void _downloadFile() async {
    // ここにファイルのダウンロードロジックを書きます
    // サーバからファイルをダウンロードした後の処理など

    setState(() {
      _downloadMessage = "File Downloaded Successfully";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _downloadFile,
            child: const Text("Download File"),
          ),
          const SizedBox(height: 10),
          Text(_downloadMessage),
        ],
      ),
    );
  }
}
