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

class DataTableExample extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  DataTableExample({required this.data});

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Age')),
      ],
      rows: data.map((item) {
        return DataRow(
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
