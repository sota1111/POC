import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class FileUploaderScreen extends StatefulWidget {
  const FileUploaderScreen({super.key});

  @override
  FileUploaderScreenState createState() => FileUploaderScreenState();
}

class FileUploaderScreenState extends State<FileUploaderScreen> {
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  int? _uploadStatusCode;
  String _uploadResponse = "";
  String _serverResponse = "";
  int? _selectedMonth;
  int? _selectedDay;
  int? _selectedNumber;


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
    if (_selectedFileBytes == null || _selectedFileName == null || _selectedMonth == null || _selectedDay == null || _selectedNumber == null) {
      setState(() {
        _uploadResponse = "選択していない項目があります";
      });
      debugPrint("No file selected");
      return;
    }
    setState(() {
      _uploadResponse = "ファイルをupload中";
    });
    final base64FileData = base64Encode(_selectedFileBytes!);
    final response = await _performFileUpload(base64FileData);

    _updateUploadStatus(response);
  }

  // Perform the actual file upload
  Future<http.Response> _performFileUpload(String base64FileData) {
    return http.post(
      Uri.parse('https://3gxeogvzp2.execute-api.ap-northeast-1.amazonaws.com/Prod/upload_plot'),
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
    debugPrint("Server Message: $_uploadResponse");
    debugPrint("Status Code: $_uploadStatusCode");

    if (response.statusCode == 200) {
      debugPrint("File uploaded successfully");
    } else {
      debugPrint("Failed to upload file");
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 月を選択するためのドロップダウン
                DropdownButton<int>(
                  hint: Text('月'),
                  value: _selectedMonth,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text((index + 1).toString()),
                    );
                  }),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedMonth = newValue;
                    });
                  },
                ),
                Text("/"),
                // 日を選択するためのドロップダウン
                DropdownButton<int>(
                  hint: Text('日'),
                  value: _selectedDay,
                  items: List.generate(31, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text((index + 1).toString()),
                    );
                  }),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedDay = newValue;
                    });
                  },
                ),
                Text("番号："),
                DropdownButton<int>(
                  hint: Text('number'),
                  value: _selectedNumber,
                  items: List.generate(20, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text((index + 1).toString()),
                    );
                  }),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedNumber = newValue;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _pickCsvFile,
                      child: const Text("Choose File"),
                    ),
                    const SizedBox(height: 10),
                    Text("Selected File: $_selectedFileName"),
                  ],
                ),
                const SizedBox(width: 150),
              ],
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: _sendFileToServer,
                  child: const Text("Upload File"),
                ),
              ],
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
