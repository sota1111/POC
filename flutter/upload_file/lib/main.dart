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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
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
          Expanded(
            child: FileUploaderScreen(),
          ),
          Column(
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchDataFromLambda(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
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
          Expanded(
            child: FileDownloaderScreen(selectedDate: selectedDate),
          ),
        ],
      ),
    );
  }
}
