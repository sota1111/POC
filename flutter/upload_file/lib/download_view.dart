import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'config.dart';

class FileDownloaderScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const FileDownloaderScreen(this.selectedDate, {Key? key}) : super(key: key);

  @override
  _FileDownloaderScreenState createState() => _FileDownloaderScreenState();
}

class _FileDownloaderScreenState extends State<FileDownloaderScreen> {
  String _downloadMessage = "No File Downloaded";
  Image? _image;

  void _downloadFile() async {
    try {
      String apiUrl = '$baseUri/download_plot';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String base64Str = data['data'];
        final Uint8List bytes = base64Decode(base64Str);

        setState(() {
          _downloadMessage = "File Downloaded Successfully";
          _image = Image.memory(bytes);
        });
      } else {
        setState(() {
          _downloadMessage = 'Failed to download file';
        });
      }
    } catch (e) {
      setState(() {
        _downloadMessage = 'Exception occurred: $e';
      });
    }
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
          const SizedBox(height: 10),
          if (_image != null) _image!,
        ],
      ),
    );
  }
}
