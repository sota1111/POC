import 'package:flutter/material.dart';
import 'upload_view.dart';
import 'download_view.dart';
import 'select_table.dart';

void main() {
  runApp(PlotDataApp());
}

class PlotDataApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PlotDataPage(),
    );
  }
}

class PlotDataPage extends StatefulWidget {
  @override
  _PlotDataState createState() => _PlotDataState();
}

class _PlotDataState extends State<PlotDataPage> {
  DateTime? selectedDate;
  String? formattedDate;

  @override
  void initState() {
    super.initState();
    // 初期値として本日の日付を設定
    selectedDate = DateTime.now();
    formattedDate = formatDate(selectedDate!);
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString()}-${date.day.toString()}";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = DateTime(picked.year, picked.month, picked.day);
        formattedDate = formatDate(selectedDate!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              _selectDate(context);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // 最初の列（FileUploaderScreen）を占有可能なスペースの30%で表示
          const Expanded(
            flex: 3, // 3 parts of available space
            child: FileUploaderScreen(),
          ),
          const VerticalDivider(
            color: Colors.grey,
            thickness: 1.0,
          ),
          // 第二の列（DataTableExample）を占有可能なスペースの40%で表示
          Expanded(
            flex: 4, // 4 parts of available space
            child: Column(
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchDataFromLambda(formattedDate),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Expanded(
                        child: DataTableExample(data: snapshot.data!),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const VerticalDivider(
            color: Colors.grey,
            thickness: 1.0,
          ),
          Expanded(
            flex: 3, // 3 parts of available space
            child: FileDownloaderScreen(formattedDate),
          ),
        ],
      )

    );
  }
}
