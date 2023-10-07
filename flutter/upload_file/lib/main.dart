import 'package:flutter/material.dart';
import 'upload_view.dart';
import 'select_table.dart';
import 'api_service.dart';

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
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("実験結果まとめ"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              _selectDate(context);
            },
          ),
        ],
      ),
      body: width > 600
          ? // For tablets and larger screens
      Row(
        children: [
          const Expanded(
            flex: 3,
            child: FileUploaderScreen(),
          ),
          const VerticalDivider(
            color: Colors.grey,
            thickness: 1.0,
          ),
          Expanded(
            flex: 7,
            child: _buildDataColumn(),
          ),
          const VerticalDivider(
            color: Colors.grey,
            thickness: 1.0,
          ),
        ],
      )
          : // For phones
      _buildDataColumn(),
    );
  }

  Widget _buildDataColumn() {
    return Column(
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchDataFromLambda(formattedDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Replace CircularProgressIndicator with an empty Container or other widget
              return Container();  // Empty container
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Expanded(
                child: DataTablePage(
                    data: snapshot.data!, formattedDate: formattedDate ?? '2023-10-1'),
              );
            }
          },
        ),
      ],
    );
  }
}
