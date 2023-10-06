import 'package:flutter/material.dart';
import 'dart:typed_data';
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
  List<String> selectedRowsOrderID = [];
  final TextEditingController _textEditingController = TextEditingController();
  String _downloadMessage = "No File Downloaded";
  Uint8List? _imagePng;
  Uint8List? _imageTra;
  Uint8List? _imageCon;
  late List<Map<String, dynamic>> currentData;


  @override
  void initState() {
    super.initState();
    currentData = widget.data;
    selectedRows = List<bool>.generate(widget.data.length, (index) => false);
  }

  Future<bool> confirmSelectedRows() async {
    int selectedRowCount = 0;

    for (int i = 0; i < selectedRows.length; i++) {
      if (selectedRows[i]) {
        selectedRowCount++;
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
      return false;
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
      return false; // Exit the function.
    }else{
      selectedRow = selectedRowsOrderID[0];
      print(selectedRow);
    }
    return true;
  }

  void sendModifyMessage() async {
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
      await overwriteMessage(widget.formattedDate, selectedRow, _textEditingController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return width > 600
        ? // For tablets and larger screens
    Row(
      children: [
        _buildLeftColumn(),
        const VerticalDivider(
          color: Colors.grey,
          thickness: 1.0,
        ),
        _buildRightColumn(),
      ],
    )
        : // For phones
    Column(
      children: [
        _buildLeftColumn(),
      ],
    );
  }

  Widget _buildLeftColumn() {
    return Expanded(
      flex: 5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: Colors.green.shade700,
                ),
                onPressed: () async {
                  List<Map<String, dynamic>> newData = await fetchDataFromLambda(widget.formattedDate);
                  setState(() {
                    currentData = newData;
                    print(currentData);
                    selectedRows = List<bool>.generate(currentData.length, (index) => false);
                  });
                },
                child: const Icon(Icons.refresh_outlined),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text("Date: ${widget.formattedDate}", style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 30),
            ],
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
                            width: 30,
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
                            child: const Text('Log File',style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Container(
                            color: Colors.deepPurple,
                            width: 100,
                            child: const Text('trajectory',style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Container(
                            color: Colors.deepPurple,
                            width: 100,
                            child: const Text('continuous',style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                      rows: currentData.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> item = entry.value;
                        return DataRow(
                          selected: selectedRows[index],
                          onSelectChanged: (bool? value) {
                            setState(() {
                              if (value != null) {
                                selectedRows[index] = value;
                                if (value) {
                                  selectedRowsOrderID.add(item['OrderID'].toString());
                                } else {
                                  selectedRowsOrderID.remove(item['OrderID'].toString());
                                }
                              }
                            });
                          },
                          cells: [
                            DataCell(Text(item['OrderID'].toString())),
                            DataCell(Text(item['Message'].toString())),
                            DataCell(Text(item['log_csv'].toString())),
                            DataCell(Text(item['trajectory'].toString())),
                            DataCell(Text(item['continuous'].toString())),
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
                onPressed: () async{
                  bool result = await confirmSelectedRows();
                  if (result) {
                    sendModifyMessage();
                  }
                },
                child: const Text('実験条件を編集'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: () async {
                  bool result = await confirmSelectedRows();
                  if (result) {
                    await downloadFile(widget.formattedDate, selectedRow);
                  }
                },
                child: const Text('実験データをDL'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: () async {
                  bool result = await confirmSelectedRows();
                  if (result) {
                    Map<String, dynamic> dlResult = await downloadPlot(widget.formattedDate, selectedRow);
                    _imagePng = dlResult['imagePng'];
                    _imageTra = dlResult['imageTra'];
                    _imageCon = dlResult['imageCon'];

                    if (MediaQuery.of(context).size.width <= 600) {
                      // For smartphone, navigate to a new page containing _buildRightColumn
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: Text('実験結果'),
                            backgroundColor: Colors.black,
                          ),
                          body: _buildRightColumn(),
                        ),
                      ));
                    } else {
                      // For tablets or larger screens, update the state
                      if (_imagePng != null) setState(() { _imagePng = dlResult['imagePng'] as Uint8List?; });
                      if (_imageTra != null) setState(() { _imageTra = dlResult['imageTra'] as Uint8List?; });
                      if (_imageCon != null) setState(() { _imageCon = dlResult['imageCon'] as Uint8List?; });
                    }
                  }
                },
                child: const Text('実験結果を確認'),
              ),

            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRightColumn() {
    return MediaQuery.of(context).size.width > 600
        ? // For tablets and larger screens
    Expanded(
      flex: 5, // 4 parts of available space
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('実験結果'),
            if (_imagePng != null && _imagePng!.isNotEmpty)
              Image.memory(_imagePng!),
            if (_imageTra != null && _imageTra!.isNotEmpty)
              Image.memory(_imageTra!),
            if (_imageCon != null && _imageCon!.isNotEmpty)
              Image.memory(_imageCon!)
          ],
        ),
      ),
    )
        : // For phones
    SingleChildScrollView(
      child: Column(
        children: [
          if (_imagePng != null && _imagePng!.isNotEmpty)
            Image.memory(_imagePng!),
          if (_imageTra != null && _imageTra!.isNotEmpty)
            Image.memory(_imageTra!),
          if (_imageCon != null && _imageCon!.isNotEmpty)
            Image.memory(_imageCon!)
        ],
      ),
    );
  }
}
