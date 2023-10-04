import 'package:flutter/material.dart';
import 'api_service.dart';

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
  String _downloadMessage = "No File Downloaded";
  Image? _image;

  @override
  void initState() {
    super.initState();
    selectedRows = List<bool>.generate(widget.data.length, (index) => false);
  }

  void printSelectedRows() async {
    int selectedRowCount = 0;

    for (int i = 0; i < selectedRows.length; i++) {
      if (selectedRows[i]) {
        selectedRowCount++;
        selectedRow = i.toString();
      }
    }

    if (selectedRowCount == 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("警告"),
            content: Text("データが選択されていません。"),
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
    else if (selectedRowCount >= 2) {
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
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Date: ${widget.formattedDate}", style: TextStyle(fontSize: 20)),
              ),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
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
                                width: 35,
                                child: const Text('番号',style: TextStyle(color: Colors.white),
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
                            DataColumn(
                              label: Container(
                                color: Colors.deepPurple,
                                width: 100,
                                child: const Text('RAMデータ',style: TextStyle(color: Colors.white),
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
                                DataCell(Text(item['Message'].toString())),
                                DataCell(Text(item['file_name_csv'].toString())),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 1.0,
                        color: Colors.black,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 1.0,
                        color: Colors.black,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 1.0,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    onPressed: () {
                      printSelectedRows();
                    },
                    child: const Text('実験条件を編集'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    onPressed: () {
                      printSelectedRows();
                    },
                    child: const Text('実験結果をDL'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    onPressed: () {
                      printSelectedRows();
                    },
                    child: const Text('実験結果を確認'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
        const VerticalDivider(
          color: Colors.grey,
          thickness: 1.0,
        ),
        Expanded(
          flex: 5, // 4 parts of available space
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: () async{
                  await overwriteMessage(_textEditingController.text, widget.formattedDate, _textEditingController.text);
                },
                child: const Text("Download File"),
              ),
              const SizedBox(height: 10),
              Text(_downloadMessage),
              const SizedBox(height: 10),
              if (_image != null) _image!,
            ],
          ),
        ),
      ],
    );
  }
}
