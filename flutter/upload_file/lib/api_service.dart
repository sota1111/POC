import 'dart:convert';
import 'dart:typed_data';
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

Future<void> overwriteMessage(String base64FileData, String formattedDate, String textEditingControllerText) async {
  String apiUrl = '$baseUri/upload_plot';

  try {
    final response = await http.put(
      Uri.parse(apiUrl),
      body: jsonEncode({
        'date': formattedDate,
        'OrderID': textEditingControllerText,
        'message': textEditingControllerText,
      }),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      String serverResponse = json.decode(response.body)['message'];
      print(serverResponse);
    } else {
      print('Failed to get data');
    }
  } catch (e) {
    print('Exception occurred: $e');
  }
}

Future<Map<String, dynamic>> downloadFile(formattedDate, selectedRow) async {
  print("selectedRow:$selectedRow");
  String apiUrl = '$baseUri/download_plot';
  final response = await http.post(
    Uri.parse(apiUrl),
    body: jsonEncode({
      'experiment_date': formattedDate,
      'experiment_number': selectedRow,
    }),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    final String base64Str = data['data'];
    final Uint8List bytes = base64Decode(base64Str);
    String serverResponse = json.decode(response.body)['message'];
    print(serverResponse);
    return {
      'message': 'File Downloaded Successfully',
      'image': bytes,
    };
  } else {
    print('Failed to get data');
    throw Exception('Failed to download file');
  }
}