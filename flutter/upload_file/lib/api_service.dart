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

Future<http.Response> performFileUpload(String base64FileData, String? selectedFileName, int? selectedMonth, int? selectedDay, int? selectedNumber, String message, String fileType) {
  String apiUrl = '$baseUri/upload_plot';
  String year = '2023';
  String formattedDate = '$year-$selectedMonth-$selectedDay';
  print(fileType);
  return http.post(
    Uri.parse(apiUrl),
    body: jsonEncode({
      'file_name': selectedFileName,
      'file_data': base64FileData,
      'experiment_date': formattedDate,
      'experiment_number': selectedNumber,
      'file_type': fileType,
      'message': message,
    }),
    headers: {"Content-Type": "application/json"},
  );
}

Future<void> overwriteMessage(String formattedDate, String selectedNumber, String newMessage) async {
  print("overwriteMessage");
  String apiUrl = '$baseUri/data_list';

  try {
    final response = await http.put(
      Uri.parse(apiUrl),
      body: jsonEncode({
        'experiment_date': formattedDate,
        'experiment_number': selectedNumber,
        'message': newMessage,
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

    final String base64StrLog = data['data_log'] ?? '';
    final String base64StrTra = data['data_trajectory'] ?? '';
    final String base64StrCon = data['data_continuous'] ?? '';

    final Uint8List bytesLog = base64StrLog.isNotEmpty ? base64Decode(base64StrLog) : Uint8List(0);
    final Uint8List bytesTra = base64StrTra.isNotEmpty ? base64Decode(base64StrTra) : Uint8List(0);
    final Uint8List bytesCon = base64StrCon.isNotEmpty ? base64Decode(base64StrCon) : Uint8List(0);

    String serverResponse = json.decode(response.body)['message'];
    print('serverResponse$serverResponse');
    return {
      'message': 'File Downloaded Successfully',
      'imageLog': bytesLog,
      'imageTra': bytesTra,
      'imageCon': bytesCon,
    };
  } else {
    print('Failed to get data');
    throw Exception('Failed to download file');
  }
}
