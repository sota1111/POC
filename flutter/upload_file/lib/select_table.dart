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
  late String selectedRow = "";
  List<bool> selectedRows = [];
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedRows = List<bool>.generate(widget.data.length, (index) => false);
  }

  Future<void> _overwriteMessage(String base64FileData) async {
    String apiUrl = '$baseUri/upload_plot';

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        body: jsonEncode({
          'date': widget.formattedDate,
          'OrderID': _textEditingController.text,
          'message': _textEditingController.text,
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          String serverResponse = json.decode(response.body)['message'];
          debugPrint(serverResponse);
        });
      } else {
        setState(() {
          String serverResponse = 'Failed to get data';
          debugPrint(serverResponse);
        });
      }
    } catch (e) {
      setState(() {
        String serverResponse = 'Exception occurred: $e';
        debugPrint(serverResponse);
      });
    }
  }

  void printSelectedRows() async {
    int selectedRowCount = 0;

    for (int i = 0; i < selectedRows.length; i++) {
      if (selectedRows[i]) {
        selectedRowCount++;
        selectedRow = i.toString();
      }
    }

    // Show a message box if two or more rows are selected.
    if (selectedRowCount >= 2) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("警告"),
            content: Text("2つ以上のデータが選択されています。"),
            actions: [
              ElevatedButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
      return; // Exit the function.
    }

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("入力してください"),
          content: Container(
            width: 300,
            child: TextField(
              controller: _textEditingController,
              decoration: InputDecoration(hintText: "内容を入力"),
              maxLines: 10,
              minLines: 3,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(_textEditingController.text);
              },
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      // ここでAPIを呼び出す処理を行う
      // fetchDataFromLambda(result) など
      print("入力されたテキスト: $result");
      print("選択された行: $selectedRow");

      //await _overwriteMessage(_textEditingController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                printSelectedRows();
              },
              child: const Text('実験条件を編集'),
            ),
            ElevatedButton(
              onPressed: () {
                printSelectedRows();
              },
              child: const Text('実験結果をDL'),
            ),
            ElevatedButton(
              onPressed: () {
                printSelectedRows();
              },
              child: const Text('実験結果を確認'),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
