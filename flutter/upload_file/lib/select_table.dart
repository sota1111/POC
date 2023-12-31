import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'api_service.dart';
import 'upload_view.dart';
import 'stream_video.dart';

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
  bool isLoading = false;


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
    final initialMessage = currentData.firstWhere((element) => element['OrderID'].toString() == selectedRow)['Message'].toString();
    _textEditingController.text = initialMessage;

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
        _buildLeftColumn(context),
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
        _buildLeftColumn(context),
      ],
    );
  }

  Widget _buildLeftColumn(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
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
                  setState(() {
                    isLoading = true;
                  });
                  print("isLoading:$isLoading");
                  List<Map<String, dynamic>> newData = await fetchDataFromLambda(widget.formattedDate);
                  setState(() {
                    currentData = newData;
                    print(currentData);
                    selectedRows = List<bool>.generate(currentData.length, (index) => false);
                    isLoading = false;
                    print("isLoading:$isLoading");
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
                      dataRowHeight: 200,
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
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.6),
                      child: Center(
                        child: CircularProgressIndicator(),
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: () async {
                  if (width > 600) {
                    bool result = await confirmSelectedRows();
                    if (result) {
                      sendModifyMessage();
                    }
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          title: Text('実験条件編集'),
                          backgroundColor: Colors.black,
                        ),
                        body: FileUploaderScreen(),
                      ),
                    ));
                  }
                },
                child: Text(width <= 600 ? 'upload' : 'edit'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: () async {
                  bool result = await confirmSelectedRows();
                  if (result) {
                    setState(() {
                      isLoading = true;
                    });
                    await downloadFile(widget.formattedDate, selectedRow);
                  }
                  setState(() {
                    isLoading = false;
                  });
                },
                child: const Text('DL'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: () async {
                  bool result = await confirmSelectedRows();
                  if (result) {
                    setState(() {
                      isLoading = true;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StreamVideo(formattedDate:widget.formattedDate,  selectedRow:selectedRow)
                      ),
                    );

                    setState(() {
                      isLoading = false;
                    });
                  }
                },
                child: const Text('video'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: () async {
                  bool result = await confirmSelectedRows();
                  if (result) {
                    setState(() {
                      isLoading = true;
                    });
                    print("isLoading:$isLoading");
                    _imagePng = null;
                    _imageTra = null;
                    _imageCon = null;
                    Map<String, dynamic> dlResult = await downloadPlot(widget.formattedDate, selectedRow);
                    _imagePng = dlResult['imagePng'];
                    _imageTra = dlResult['imageTra'];
                    _imageCon = dlResult['imageCon'];
                    setState(() {
                      isLoading = false;
                    });

                    print("isLoading:$isLoading");
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
                child: const Text('graph'),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildImageWidget(Uint8List? imageData, {bool withBorder = false}) {
    if (imageData == null || imageData.isEmpty) return SizedBox.shrink();
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 5.0,
      child: Container(
        decoration: withBorder
            ? BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
        )
            : null,
        child: Image.memory(imageData),
      ),
    );
  }

  Widget _buildRightColumn() {
    List<Widget> buildChildren() {
      return [
        if (_imagePng != null && _imagePng!.isNotEmpty) _buildImageWidget(_imagePng),
        if (_imageTra != null && _imageTra!.isNotEmpty) _buildImageWidget(_imageTra, withBorder: true),
        if (_imageCon != null && _imageCon!.isNotEmpty) _buildImageWidget(_imageCon, withBorder: true),
      ];
    }

    var commonChildren = buildChildren();
    return MediaQuery.of(context).size.width > 600
        ? Expanded(
          flex: 5,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [const Text('実験結果'), ...commonChildren],
            ),
          ),
        )
        : SingleChildScrollView(
            child: Column(
              children: [...commonChildren, const SizedBox(height: 30)],
            ),
    );
  }
}
