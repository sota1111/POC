import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

Future<List<Map<String, dynamic>>> fetchDataFromLambda() async {
  String apiUrl = '$baseUri/data_list';
  final response = await http.get(Uri.parse(apiUrl));

  if (response.statusCode == 200) {
    Map<String, dynamic> responseBody = jsonDecode(response.body);
    List<dynamic> data = responseBody['data'];
    return data.map((dynamic item) => item as Map<String, dynamic>).toList();
  } else {
    throw Exception('Failed to load data');
  }
}

class DataTableExample extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  DataTableExample({required this.data});

  @override
  _DataTableExampleState createState() => _DataTableExampleState();
}

class _DataTableExampleState extends State<DataTableExample> {
  List<bool> selectedRows = [];

  @override
  void initState() {
    super.initState();
    selectedRows = List<bool>.generate(widget.data.length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    return DataTable(
      headingRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        return Colors.deepPurple;
      }),
      columns: [
        DataColumn(
          label: Container(
            color: Colors.deepPurple,
            child: const Text('ID',style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        DataColumn(
          label: Container(
            color: Colors.deepPurple,
            child: const Text('Name',style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        DataColumn(
          label: Container(
            color: Colors.deepPurple,
            child: const Text('Age',style: TextStyle(color: Colors.white),
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
            DataCell(Text(item['id'].toString())),
            DataCell(Text(item['name'].toString())),
            DataCell(Text(item['age'].toString())),
          ],
        );
      }).toList(),
    );
  }
}
