import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<void> saveFile(Uint8List bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);
  print('File saved to ${file.path}');
}
