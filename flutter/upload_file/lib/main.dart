import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(FileUploaderApp());
}

class FileUploaderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FileUploaderScreen(),
    );
  }
}

class FileUploaderScreen extends StatefulWidget {
  @override
  _FileUploaderScreenState createState() => _FileUploaderScreenState();
}

class _FileUploaderScreenState extends State<FileUploaderScreen> {
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  int? _uploadStatusCode;
  String _uploadResponse = "";
  String _serverResponse = "";

  // Pick a CSV file
  void _pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      setState(() {
        _selectedFileBytes = result.files.first.bytes;
        _selectedFileName = result.files.first.name;
      });
    }
  }

  // Send the file to the server
  void _sendFileToServer() async {
    if (_selectedFileBytes == null || _selectedFileName == null) {
      setState(() {
        _uploadResponse = "No file selected";
      });
      print("No file selected");
      return;
    }

    final base64FileData = base64Encode(_selectedFileBytes!);
    final response = await _performFileUpload(base64FileData);

    _updateUploadStatus(response);
  }

  // Perform the actual file upload
  Future<http.Response> _performFileUpload(String base64FileData) {
    return http.post(
      Uri.parse('https://3gxeogvzp2.execute-api.ap-northeast-1.amazonaws.com/Prod/upload'),
      body: jsonEncode({
        'file_name': _selectedFileName,
        'file_data': base64FileData,
      }),
      headers: {"Content-Type": "application/json"},
    );
  }

  // Update the upload status
  void _updateUploadStatus(http.Response response) {
    setState(() {
      _uploadStatusCode = response.statusCode;
    });

    var responseBody = jsonDecode(response.body);
    _uploadResponse = responseBody['message'];
    print("Server Message: $_uploadResponse");
    print("Status Code: $_uploadStatusCode");

    if (response.statusCode == 200) {
      print("File uploaded successfully");
    } else {
      print("Failed to upload file");
    }
  }

  // Fetch data from the server
  Future<void> _fetchServerData() async {
    try {
      final response = await http.get(Uri.parse('https://3gxeogvzp2.execute-api.ap-northeast-1.amazonaws.com/Prod/hello'));

      if (response.statusCode == 200) {
        setState(() {
          _serverResponse = json.decode(response.body)['message'];
        });
      } else {
        setState(() {
          _serverResponse = 'Failed to get data';
        });
      }
    } catch (e) {
      setState(() {
        _serverResponse = 'Exception occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("File Upload")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickCsvFile,
              child: const Text("Choose File"),
            ),
            const SizedBox(height: 10),
            Text("Selected File: $_selectedFileName"),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _sendFileToServer,
              child: const Text("Upload"),
            ),
            const SizedBox(height: 10),
            Text("Server Massage: $_uploadResponse"),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _fetchServerData,
              child: const Text("GET Data"),
            ),
            const SizedBox(height: 10),
            Text("Response: $_serverResponse"),
          ],
        ),
      ),
    );
  }
}
