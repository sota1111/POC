import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';
import 'config.dart';

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
  String _fileType = "";
  final TextEditingController _textEditingController = TextEditingController();


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
        _fileType = "log";
      });
    }
  }

  void _pickTrajectoryFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFileBytes = result.files.first.bytes;
        _selectedFileName = result.files.first.name;
        _fileType = "trajectory";
      });
    }
  }

  void _pickContinuousPictureFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFileBytes = result.files.first.bytes;
        _selectedFileName = result.files.first.name;
        _fileType = "continuous";
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
    final response = await performFileUpload(base64FileData, _selectedFileName, _selectedMonth, _selectedDay, _selectedNumber, _textEditingController.text);
    _updateUploadStatus(response);
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
      debugPrint(_uploadResponse);
    }
  }

  // Fetch data from the server
  Future<void> _fetchServerData() async {
    try {
      String apiUrl = '$baseUri/hello';
      final response = await http.get(Uri.parse(apiUrl));

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
            const Text("実験日と実験番号、ファイルを選択し、\n送信ボタンを押してください。"),
            const SizedBox(height: 30),

            Row(
              children: [
                const Text("実験日:　"),
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
                Text("実験番号："),
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
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _pickCsvFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: const Text("CsvFile選択"),
                ),
                ElevatedButton(
                  onPressed: _pickTrajectoryFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: const Text("軌道写真選択"),
                ),
                ElevatedButton(
                  onPressed: _pickContinuousPictureFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: const Text("連続写真選択"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 10),
                Text("Selected File: $_selectedFileName"),
              ],
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _textEditingController,
              decoration: const InputDecoration(
                hintText: '実験条件を記入してください。\nここに記入した場合、\n既存の実験条件は上書きされます。',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              style: const TextStyle(
                fontSize: 18.0,
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _sendFileToServer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: const Text("送信"),
            ),
            const SizedBox(height: 10),
            Text("Server Massage: $_uploadResponse"),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _fetchServerData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: const Text("hello world"),
            ),
            const SizedBox(height: 10),
            Text("Response: $_serverResponse"),
          ],
        ),
      ),
    );
  }
}
