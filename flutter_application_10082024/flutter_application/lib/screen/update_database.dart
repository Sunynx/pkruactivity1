/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';

class ImportExcelPage extends StatefulWidget {
  @override
  _ImportExcelPageState createState() => _ImportExcelPageState();
}

class _ImportExcelPageState extends State<ImportExcelPage> {
  String? _filePath;
  List<String> _importHistory = [];

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
      });
      print('Selected file path: $_filePath');
    }
  }

  Future<void> _importFile() async {
    if (_filePath != null) {
      File file = File(_filePath!);
      try {
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        for (var table in excel.tables.keys) {
          print('Processing table: $table');
          var sheet = excel.tables[table];
          for (var row in sheet!.rows.skip(1)) {
            // Skip header row
            if (row.isNotEmpty) {
              var userIdStudent = row[0]?.value;
              var userName = row[1]?.value;
              var userClass = row[2]?.value;
              var userPassword = row[3]?.value;
              var status = row[4]?.value;
              var minTime = row[5]?.value;

              print('Processing row: $row');

              var snapshot = await _databaseRef
                  .child('users')
                  .orderByChild('user_id_student')
                  .equalTo(userIdStudent)
                  .get();

              if (snapshot.exists) {
                // Update existing data
                Map<dynamic, dynamic> users =
                    snapshot.value as Map<dynamic, dynamic>;
                String key = users.keys.first;
                await _databaseRef.child('users/$key').update({
                  'user_name': userName,
                  'user_class': userClass,
                  'user_password': userPassword,
                  'status': status,
                  'minTime': minTime,
                });
                print('Updated user: $userIdStudent');
              } else {
                // Add new data
                await _databaseRef.child('users').push().set({
                  'user_id_student': userIdStudent,
                  'user_name': userName,
                  'user_class': userClass,
                  'user_password': userPassword,
                  'status': status,
                  'minTime': minTime,
                });
                print('Added new user: $userIdStudent');
              }

              DateTime now = DateTime.now();
              _importHistory.add('Imported user: $userName - $now');
            }
          }
        }

        setState(() {
          _filePath = null;
        });

        print('File imported successfully');
      } catch (e) {
        print('Failed to import file: $e');
      }
    } else {
      print('Please select a file first');
    }
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการนำเข้า'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('คุณต้องการนำเข้าไฟล์นี้ใช่หรือไม่?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('ตกลง'),
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Close dialog and proceed with import
                _importFile(); // Call import file function
              },
            ),
            TextButton(
              child: Text('ไม่'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without importing
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('นำเข้าไฟล์ Excel'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('เลือกไฟล์'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 16),
            _filePath != null
                ? Text(
                    'ไฟล์ที่เลือก: $_filePath',
                    style: TextStyle(color: Colors.orange),
                  )
                : Text(
                    'ยังไม่ได้เลือกไฟล์',
                    style: TextStyle(color: Colors.grey),
                  ),
            ElevatedButton(
              onPressed: () {
                _showConfirmationDialog(); // Show confirmation dialog
              },
              child: Text('ยืนยัน'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'ประวัติการนำเข้า:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.builder(
                  itemCount: _importHistory.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        _importHistory[index],
                        style: TextStyle(color: Colors.orange),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/
