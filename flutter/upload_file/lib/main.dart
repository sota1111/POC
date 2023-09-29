import 'package:flutter/material.dart';
import 'upload_view.dart';

void main() {
  runApp(const FileUploaderApp());
}

class FileUploaderApp extends StatelessWidget {
  const FileUploaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FileUploaderScreen(),
    );
  }
}