import 'dart:convert';
import 'dart:typed_data';  // Added for Uint8List
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

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
  Uint8List? _fileBytes;  // To store the file bytes
  String? _fileName;  // To store the file name
  int? _statusCode;
  String _responseText = "No response yet";

  void _chooseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      setState(() {
        _fileBytes = result.files.first.bytes;
        _fileName = result.files.first.name;
      });
    }
  }

  void _uploadFile() async {
    if (_fileBytes != null && _fileName != null) {
      final base64Data = base64Encode(_fileBytes!);

      final response = await http.post(
        Uri.parse('https://3gxeogvzp2.execute-api.ap-northeast-1.amazonaws.com/Prod/upload'),
        body: jsonEncode({
          'file_name': _fileName,
          'file_data': base64Data,
        }),
        headers: {"Content-Type": "application/json"},
      );

      setState(() {
        _statusCode = response.statusCode;
      });
      var responseBody = jsonDecode(response.body);
      var serverMessage = responseBody['message'];

      print("Server Message: $serverMessage");  // Print server message
      print("Status Code: $_statusCode");  // Print status code

      if (response.statusCode == 200) {
        print("File uploaded successfully");
      } else {
        print("Failed to upload file");
      }
    }
  }

  Future<void> _getData() async {
    try {
      final response = await http.get(Uri.parse('https://3gxeogvzp2.execute-api.ap-northeast-1.amazonaws.com/Prod/hello'));

      if (response.statusCode == 200) {
        setState(() {
          _responseText = json.decode(response.body)['message'];
        });
      } else {
        setState(() {
          _responseText = 'Failed to get data';
        });
      }
    } catch (e) {
      setState(() {
        _responseText = 'Exception occurred: $e';
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
              child: Text("Choose File"),
            ),
            SizedBox(height: 10),
            Text("Selected File: $_fileName"), // Show selected file name
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _uploadFile,
              child: Text("Upload"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getData,
              child: Text("GET Data"),
            ),
            SizedBox(height: 20),
            Text("Response: $_responseText"),
          ],
        ),
      ),
    );
  }
}
