import 'package:flutter/material.dart';
import 'upload_view.dart';
import 'download_view.dart';

void main() {
  runApp(const PlotDataApp());
}

class PlotDataApp extends StatefulWidget {
  const PlotDataApp({super.key});

  @override
  _PlotDataAppState createState() => _PlotDataAppState();
}

class _PlotDataAppState extends State<PlotDataApp> {
  DateTime? selectedDate;

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("File Operations"),
          actions: [
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () {
                // 日付を選択
              },
            )
          ],
        ),
        body: Row(
          children: [
            Expanded(
              child: FileUploaderScreen(),
            ),
            Expanded(
              child: FileDownloaderScreen(selectedDate: selectedDate),
            ),
          ],
        ),
      ),
    );
  }
}