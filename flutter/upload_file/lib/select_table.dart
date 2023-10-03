import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

Future<List<Map<String, dynamic>>> fetchDataFromLambda(selectedDate) async {
  String apiUrl = '$baseUri/data_list';
  final response = await http.post(
    Uri.parse(apiUrl),
    body: jsonEncode({
      'experiment_date': selectedDate,
    }),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    Map<String, dynamic> responseBody = jsonDecode(response.body);
    List<dynamic> data = responseBody['data'];
    print(data);
    return data.map((dynamic item) => item as Map<String, dynamic>).toList();
  } else {
    throw Exception('Failed to load data');
  }
}


class DataTablePage extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String formattedDate;

  DataTablePage({required this.data, required this.formattedDate});

  @override
  _DataTablePageState createState() => _DataTablePageState();
}

class _DataTablePageState extends State<DataTablePage> {
  List<bool> selectedRows = [];

  @override
  void initState() {
    super.initState();
    selectedRows = List<bool>.generate(widget.data.length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Date: ${widget.formattedDate}", style: TextStyle(fontSize: 20)),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                  return Colors.deepPurple;
                }),
                columns: [
                  DataColumn(
                    label: Container(
                      color: Colors.deepPurple,
                      width: 100,
                      child: const Text('実験番号',style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      color: Colors.deepPurple,
                      width: 100,
                      child: const Text('ファイル名',style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      color: Colors.deepPurple,
                      width: 100,
                      child: const Text('実験条件',style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
                rows: widget.data.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> item = entry.value;
                  return DataRow(
                    selected: selectedRows[index],
                    onSelectChanged: (bool? value) {
                      setState(() {
                        if (value != null) {
                          selectedRows[index] = value;
                        }
                      });
                    },
                    cells: [
                      DataCell(Text(item['OrderID'].toString())),
                      DataCell(Text(item['file_name_csv'].toString())),
                      DataCell(Text(item['Message'].toString())),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
