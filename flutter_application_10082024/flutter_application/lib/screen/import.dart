import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class ImportExcelPage extends StatefulWidget {
  const ImportExcelPage({Key? key}) : super(key: key);

  @override
  _ImportExcelPageState createState() => _ImportExcelPageState();
}

class _ImportExcelPageState extends State<ImportExcelPage> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('user');
  final DatabaseReference _importHistoryRef =
      FirebaseDatabase.instance.ref().child('import_history');
  List<Map<String, dynamic>> importHistory = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImportHistory();
  }

  Future<void> _loadImportHistory() async {
    final snapshot = await _importHistoryRef
        .orderByChild('timestamp')
        .limitToLast(10)
        .once();
    if (snapshot.snapshot.value != null) {
      final map = snapshot.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        importHistory = map.entries
            .map((e) => {
                  'timestamp': int.parse(e.value['timestamp'].toString()),
                  'fileName': e.value['fileName'],
                  'recordsCount': e.value['recordsCount'],
                })
            .toList();
        importHistory.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      });
    }
  }

  Future<void> _importExcel() async {
    setState(() => isLoading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        int recordsCount = 0;

        for (var table in excel.tables.keys) {
          for (var row in excel.tables[table]!.rows.skip(1)) {
            if (row.isNotEmpty) {
              String userIdStudent = row[0]?.value.toString() ?? '';
              String userName = row[1]?.value.toString() ?? '';
              String userClass = row[2]?.value.toString() ?? '';
              String userPassword = row[3]?.value.toString() ?? '';
              String status = row[4]?.value.toString() ?? '';
              String minTime = row[5]?.value.toString() ?? '0';

              // ตรวจสอบว่ามีผู้ใช้ที่มี ID หรือรหัสเดียวกันอยู่แล้วหรือไม่
              final existingUserRef = _database
                  .orderByChild('user_id_student')
                  .equalTo(userIdStudent);
              final existingUserSnapshot = await existingUserRef.once();
              if (existingUserSnapshot.snapshot.value != null) {
                // ถ้ามีผู้ใช้ ID หรือรหัสเดียวกันมีอยู่แล้ว ข้ามแถวนี้
                continue;
              }

              DatabaseReference newUserRef = _database.push();
              await newUserRef.set({
                'user_id_student': userIdStudent,
                'user_name': userName,
                'user_class': userClass,
                'user_password': userPassword,
                'status': status,
                'minTime': minTime,
              });

              recordsCount++;
            }
          }
        }

        await _importHistoryRef.push().set({
          'timestamp': ServerValue.timestamp,
          'fileName': result.files.single.name,
          'recordsCount': recordsCount,
        });

        await _loadImportHistory();

        _showSnackBar('นำเข้าข้อมูลสำเร็จ $recordsCount รายการ', Colors.green);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: ${e.toString()}', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('อัพเดตฐานข้อมูล'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'นำเข้าไฟล์ Excel',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : _importExcel,
                        icon: Icon(Icons.file_upload),
                        label: Text(
                            isLoading ? 'กำลังนำเข้า...' : 'เลือกไฟล์ Excel'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          textStyle: TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'ประวัติการนำเข้า',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Expanded(
                child: importHistory.isEmpty
                    ? Center(child: Text('ไม่มีประวัติการนำเข้า'))
                    : ListView.builder(
                        itemCount: importHistory.length,
                        itemBuilder: (context, index) {
                          final history = importHistory[index];
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              history['timestamp'] as int);
                          final formattedDate =
                              DateFormat('dd/MM/yyyy HH:mm').format(date);
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            child: ListTile(
                              leading: Icon(Icons.insert_drive_file,
                                  color: Colors.blue),
                              title: Text(history['fileName'],
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('นำเข้าเมื่อ: $formattedDate'),
                              trailing: Chip(
                                label:
                                    Text('${history['recordsCount']} รายการ'),
                                backgroundColor: Colors.blue.shade100,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
