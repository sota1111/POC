import 'dart:convert';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _file;

  void _chooseFile() {
    FileUploadInputElement uploadInput = FileUploadInputElement();
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.length > 0) {
        final file = files[0];
        setState(() {
          _file = file;
        });
      }
    });
  }

  void _uploadFile() async {
    if (_file != null) {
      final reader = FileReader();
      reader.readAsDataUrl(_file!);
      reader.onLoadEnd.listen((event) async {
        final content = reader.result as String;
        final base64Data = content.split(",").last;

        final response = await http.post(
          Uri.parse('YOUR_AWS_LAMBDA_ENDPOINT_HERE'),
          body: jsonEncode({
            'file_name': _file!.name,
            'file_data': base64Data,
          }),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          print("File uploaded successfully");
        } else {
          print("Failed to upload file");
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("File Upload")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _chooseFile,
              child: Text("ファイル選択"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadFile,
              child: Text("送信"),
            ),
          ],
        ),
      ),
    );
  }
}
