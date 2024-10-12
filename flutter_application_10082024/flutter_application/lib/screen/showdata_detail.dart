import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_application/model/Event.dart';
import 'package:flutter_application/screen/showdata_history_t_detail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart.' as pw;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:barcode/barcode.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/services.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_application/screen/StudentDetailPage.dart';

class Showdata_detail extends StatelessWidget {
  final Event event;
  final TextEditingController id_studentController = TextEditingController();
  String studentName = '';

  Showdata_detail({required this.event});

  Future<void> insert_student_activity(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: LoadingAnimationWidget.inkDrop(
              color: Colors.white,
              size: 100,
            ),
          );
        },
      );

      String? key = event.key;
      String title = event.title;

      late DatabaseReference dbRef;

      String id_student = id_studentController.text;

      DatabaseReference ref =
          FirebaseDatabase.instance.ref("activity_detail/$key");

      DatabaseEvent events = await ref.once();

      if (events.snapshot != null) {
        DataSnapshot snapshot = events.snapshot!;
        List<dynamic>? data = snapshot.value as List<dynamic>?;

        if (data != null) {
          bool isStudentExist = false;

          // Check if id_student already exists in data
          for (var item in data) {
            if (item == id_student) {
              isStudentExist = true;
              break;
            }
          }

          if (isStudentExist) {
            Future.delayed(const Duration(seconds: 0), () {
              Navigator.pop(context); // ปิด showDialog หลังจาก 2 วินาที
            });

            Future.delayed(const Duration(seconds: 1), () {
              final snackBar = SnackBar(
                elevation: 0,
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.transparent,
                content: AwesomeSnackbarContent(
                  title: 'Error!',
                  message: 'ข้อมูลนักเรียน $id_student มีอยู่แล้วในกิจกรรมนี้!',
                  contentType: ContentType.failure,
                ),
              );

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(snackBar);
            });

            //print("ข้อมูลนักเรียน $id_student มีอยู่แล้วในกิจกรรมนี้");
          } else {
            List<dynamic> updatedData = [...data, id_student];
            await ref.set(updatedData);

            String activit_Time = event.activit_Time;
            int DB_activit_Time = int.parse(activit_Time);
            String minTime = '';

            dbRef = FirebaseDatabase.instance.ref().child('user');
            DatabaseEvent snapshot = await dbRef
                .orderByChild('user_id_student')
                .equalTo(id_student)
                .once();
            Map<dynamic, dynamic>? values =
                snapshot.snapshot.value as Map<dynamic, dynamic>?;

            if (values != null) {
              values.forEach((key2, item) {
                minTime = item['minTime'] ??
                    '0'; // อ่านค่า minTime จาก Firebase หรือกำหนดให้เป็น '0' ถ้าไม่มีค่า
                int currentMinTime = int.tryParse(minTime) ??
                    0; // แปลง minTime เป็น double หรือใช้ค่าเริ่มต้นเป็น 0.0 ถ้าเป็น null

                DB_activit_Time +=
                    currentMinTime; // เพิ่มค่า minTime เข้าไปใน DB_activit_Time

                String stractivit_Time = DB_activit_Time.toStringAsFixed(
                    0); // แปลง DB_activit_Time เป็นสตริงที่มีทศนิยม 2 ตำแหน่ง

                DatabaseReference itemRef = dbRef.child(key2);

                itemRef.update({
                  'minTime': stractivit_Time,
                });

                Future.delayed(const Duration(seconds: 0), () {
                  Navigator.pop(context); // ปิด showDialog หลังจาก 2 วินาที
                });

                Future.delayed(const Duration(seconds: 1), () {
                  final snackBar = SnackBar(
                    elevation: 0,
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
                    content: AwesomeSnackbarContent(
                      title: 'Success!',
                      message: 'เพิ่มข้อมูลสำเร็จ!',
                      contentType: ContentType.success,
                    ),
                  );

                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(snackBar);
                });

                //print('อัปเดตข้อมูลสำเร็จสำหรับ key $key2');
              });
            } else {
              Future.delayed(const Duration(seconds: 0), () {
                Navigator.pop(context); // ปิด showDialog หลังจาก 2 วินาที
              });

              Future.delayed(const Duration(seconds: 1), () {
                final snackBar = SnackBar(
                  elevation: 0,
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: 'Error!',
                    message: 'ไม่พบข้อมูลนักศึกษา!',
                    contentType: ContentType.failure,
                  ),
                );

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
              });

              //print('ไม่พบข้อมูลที่ต้องการอัปเดต');
            }
          }
        } else {
          print("ไม่พบข้อมูลในกิจกรรมนี้");
        }
      } else {
        print("ไม่พบข้อมูลในกิจกรรมนี้");
      }
    } catch (e) {
      print("เกิดข้อผิดพลาด : $e");
    }
  }

  Future<void> showStudentDetail(BuildContext context) async {
    try {
      String? key = event.key;
      print("key : $key");

      DatabaseReference ref =
          FirebaseDatabase.instance.ref("activity_detail/$key");
      DatabaseEvent events = await ref.once();

      if (events.snapshot != null) {
        DataSnapshot snapshot = events.snapshot!;
        List<dynamic>? data = snapshot.value as List<dynamic>?;

        if (data != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailPage(
                data: data,
                eventKey: key,
              ),
            ),
          );
        } else {
          print("ไม่พบข้อมูลในกิจกรรมนี้");
        }
      } else {
        print("ไม่พบข้อมูลในกิจกรรมนี้");
      }
    } catch (e) {
      print("เกิดข้อผิดพลาด : $e");
    }
  }

  Future<String> getStudentName(String studentId) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("user");
    DatabaseEvent snapshot =
        await ref.orderByChild('user_id_student').equalTo(studentId).once();
    Map<dynamic, dynamic>? values =
        snapshot.snapshot.value as Map<dynamic, dynamic>?;
    if (values != null) {
      String studentName = '';
      values.forEach((key, item) {
        studentName = item['user_name'];
      });
      return studentName;
    } else {
      return '';
    }
  }

  StreamController<String> _studentNameStreamController = StreamController();

  void _searchStudentName(String text, Function(String) updateName) async {
    final name = await getStudentName(text);
    updateName(name);
  }

  Stream<String> get _studentNameStream => _studentNameStreamController.stream;

  @override
  Widget build(BuildContext context) {
    String activit_Time = event.activit_Time;
    double db_activit_Time = double.parse(activit_Time);
    db_activit_Time = db_activit_Time / 60;

    int hours = db_activit_Time.toInt();
    int minutes = ((db_activit_Time - hours) * 60).toInt();

    String formattedHH = hours.toString().padLeft(2);
    String formattedMM = minutes.toString().padLeft(2, '0');

    String formattedTime = '$formattedHH:$formattedMM';

    String status = event.status ?? '';

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          color: Colors.orange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Center(
                child: Text(
                  "รายละเอียดกิจกรรม",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              if (status == 't' || status == 'a') ...[
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          showStudentDetail(context);
                        },
                        child: const Text(
                          'Report',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ),
                    SizedBox(width: 8), // เพิ่มช่องว่างระหว่างปุ่ม
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              String localStudentName = '';
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: Text(
                                      'กรอกรหัสนักศึกษา',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    content: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.8,
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.orange.shade100,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: id_studentController,
                                            onChanged: (text) {
                                              _searchStudentName(text, (name) {
                                                setState(() {
                                                  localStudentName = name;
                                                });
                                              });
                                            },
                                            decoration: InputDecoration(
                                              labelText: 'รหัสนักศึกษา',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                  10),
                                            ],
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            localStudentName.isNotEmpty
                                                ? 'ชื่อนักศึกษา: $localStudentName'
                                                : '',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 24),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  insert_student_activity(
                                                      context);
                                                },
                                                child: Text('ตกลง'),
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      Colors.orange,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('ยกเลิก'),
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor: Colors.grey,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: const Text(
                          'ลงทะเบียนกิจกรรม',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 10),
              Card(
                margin: EdgeInsets.symmetric(vertical: 10),
                elevation: 5,
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF4500),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'รายละเอียด:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        event.detail,
                        style: TextStyle(fontSize: 16),
                      ),
                      Divider(height: 30, thickness: 1),
                      Text(
                        'สำหรับปี:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        event.Class,
                        style: TextStyle(fontSize: 16),
                      ),
                      Divider(height: 30, thickness: 1),
                      Text(
                        'สถานที่:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        event.location,
                        style: TextStyle(fontSize: 16),
                      ),
                      Divider(height: 30, thickness: 1),
                      Text(
                        'เวลาเริ่มต้น:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '${event.startTime} น.',
                        style: TextStyle(fontSize: 16),
                      ),
                      Divider(height: 30, thickness: 1),
                      Text(
                        'เวลาสิ้นสุด:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '${event.endTime} น.',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Divider(height: 30, thickness: 1),
                      Text(
                        'ชั่วโมงที่ได้รับ:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (formattedMM == "00" || formattedMM == "0")
                        Text(
                          '${formattedHH} ชั่วโมง',
                          style: TextStyle(fontSize: 16),
                        ),
                      if (formattedMM != "00" && formattedMM != "0")
                        Text(
                          '${formattedHH} ชั่วโมง ${formattedMM} นาที',
                          style: TextStyle(fontSize: 16),
                        ),
                      Divider(height: 30, thickness: 1),
                      if (event.imageUrl.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'รูปภาพกิจกรรม:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Center(
                              child: Image.network(
                                width: 300,
                                height: 300,
                                event.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
