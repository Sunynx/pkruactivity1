import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:translator/translator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class AddActivityPage extends StatefulWidget {
  @override
  _AddActivityPageState createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  late DatabaseReference dbRef;
  late DatabaseReference dbRef2;

  final Map<String, bool> classLevel = {
    'ปี 1': false,
    'ปี 2': false,
    'ปี 3': false,
    'ปี 4': false,
    'ทุกชั้นปี': false,
  };

  /*final Map<String, String> genderItems = {
    '1': 'ปี 1',
    '2': 'ปี 2',
    '3': 'ปี 3',
    '4': 'ปี 4',
    '5': 'ทุกชั้นปี',
  };*/

  List<String> _selectedClassActivity = [];
  String? selectedValue;

  final String title = 'Firebase App Check';

  File? _imageFile;
  String? _downloadUrl;

  DateTime? _selectedDate;
  final DateFormat timeFormat = DateFormat('HH:mm');
  TextEditingController timeStartController = TextEditingController();
  TextEditingController timeLastController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  TextEditingController activityName = TextEditingController();
  TextEditingController activityDetail = TextEditingController();
  TextEditingController activityLocaltion = TextEditingController();

  TextEditingController activityPeople = TextEditingController();
  TextEditingController activitTime = TextEditingController();

  Future<void> _selectStartTime(BuildContext context) async {
    if (context != null) {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() {
          String formattedTime =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          timeStartController.text = formattedTime;
          // รวมวันที่และเวลาเข้าด้วยกัน
          _combineDateAndTime();
        });
      }
    }
  }

  Future<void> _selectLastTime(BuildContext context) async {
    if (context != null) {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() {
          String formattedTime =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          timeLastController.text = formattedTime;
          // รวมวันที่และเวลาเข้าด้วยกัน
          _combineDateAndTime();
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: Locale('th', 'TH'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            primaryColor: Colors.orange, // เปลี่ยนสีพื้นหลังเป็นสีส้ม
            primaryColorDark: Colors.white, // เปลี่ยนสีพื้นหลังเป็นสีขาว
            colorScheme: ColorScheme.light(
                primary: Colors.orange), // เปลี่ยนสีของสไตล์แบบวัสดุเป็นสีส้ม
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        dateController.text = "${picked.day}/${picked.month}/${picked.year}";
        // รวมวันที่และเวลาเข้าด้วยกัน
        _combineDateAndTime();
      });
    }
  }

  void _combineDateAndTime() {
    if (dateController.text.isNotEmpty &&
        timeStartController.text.isNotEmpty &&
        timeLastController.text.isNotEmpty) {
      final List<String> dateParts = dateController.text.split('/');
      final int day = int.parse(dateParts[0]);
      final int month = int.parse(dateParts[1]);
      final int year = int.parse(dateParts[2]);
      final List<String> timeStartParts = timeStartController.text.split(':');
      final int hourStart = int.parse(timeStartParts[0]);
      final int minuteStart = int.parse(timeStartParts[1]);

      final List<String> timeLastParts = timeLastController.text.split(':');
      final int hourLast = int.parse(timeLastParts[0]);
      final int minuteLast = int.parse(timeLastParts[1]);

      _selectedDate = DateTime(
          year, month, day, hourStart, minuteStart, hourLast, minuteLast);

      final DateFormat dateFormat = DateFormat('yyyy-MM-dd:HH:mm');
      final String formattedDateTime = dateFormat.format(_selectedDate!);
    }
  }

  Future<String> addUserActivity(
    String name_activity,
    String detail_activity,
    String class_activity,
    String location_activity,
    String date,
    String start_time,
    String end_time,
    String activity_People,
    String activit_Time,
    File imageFile,
  ) async {
    dbRef = FirebaseDatabase.instance.ref().child('activity');
    DatabaseEvent snapshot =
        await dbRef.orderByChild('name_activity').equalTo(name_activity).once();
    Map<dynamic, dynamic>? values =
        snapshot.snapshot.value as Map<dynamic, dynamic>?;
    bool isDuplicate = false;
    if (values != null) {
      values.forEach((key, item) {
        if (item['name_activity'] == name_activity &&
            item['detail_activity'] == detail_activity &&
            item['class_activity'] == class_activity &&
            item['location_activity'] == location_activity &&
            item['date'] == date &&
            item['start_time'] == start_time &&
            item['activity_People'] == activity_People &&
            item['activit_Time'] == activit_Time &&
            item['end_time'] == end_time) {
          isDuplicate = true;
        }
      });
    }

    DateTime startTime = DateFormat('HH:mm').parse(start_time);
    DateTime endTime = DateFormat('HH:mm').parse(end_time);

    if (!startTime.isBefore(endTime)) {
      return "TimeError";
    }

    bool isConflict = false;
    values?.forEach((key, item) {
      DateTime existingStartTime =
          DateFormat('HH:mm').parse(item['start_time']);
      DateTime existingEndTime = DateFormat('HH:mm').parse(item['end_time']);
      DateTime existingDate = DateFormat('d/M/yyyy').parse(item['date']);
      DateTime newDate = DateFormat('d/M/yyyy').parse(date);
      if (item['location_activity'] == location_activity &&
          existingDate.isAtSameMomentAs(newDate) &&
          ((startTime.isAfter(existingStartTime) &&
                  startTime.isBefore(existingEndTime)) ||
              (endTime.isAfter(existingStartTime) &&
                  endTime.isBefore(existingEndTime)))) {
        isConflict = true;
      }
    });

    if (isConflict) {
      return "NotSuccess";
    }

    String imageUrl = await _uploadImage(imageFile);

    DatabaseReference newRef = dbRef.push();

    // ทำการเพิ่มข้อมูล
    await newRef.set({
      'name_activity': name_activity,
      'detail_activity': detail_activity,
      'class_activity': class_activity,
      'location_activity': location_activity,
      'date': date,
      'start_time': start_time,
      'end_time': end_time,
      'activity_People': activity_People,
      'activit_Time': activit_Time,
      'imageUrl': imageUrl,
      'status_activity': 'D' //D = ปิดไปแล้วหรือยังไม่เปิด E = เปิดกิจกรรม
    });

    String generateRandomString(int length) {
      const chars = '0123456789';
      final random = Random();
      return List.generate(
          length, (index) => chars[random.nextInt(chars.length)]).join();
    }

    String newPath = newRef.path;
    String newPathSuffix = newPath.substring(newPath.lastIndexOf('/') + 1);

// int activity_PeopleInt = int.parse(activity_People);

//   for (int i = 1; i <= activity_PeopleInt; i++) {
//   String randomString = generateRandomString(13);
//   DatabaseReference dbRef2 = FirebaseDatabase.instance.ref().child('codes/$randomString');

//   await dbRef2.set({
//     'id_activity': newPathSuffix,
//     'status_activity': "E",
//   });
// }

    DatabaseReference dbRef3 =
        FirebaseDatabase.instance.ref().child('activity_detail/$newPathSuffix');

    await dbRef3.set([""]);

    return "Success";
  }

  Future<String> _uploadImage(File imageFile) async {
    Random random = Random();
    int i = random.nextInt(10000);

    FirebaseStorage storage = FirebaseStorage.instance;
    // อ้างอิงไปยังโฟลเดอร์ image_activity
    Reference ref = storage.ref().child('image_activity/activity$i.png');
    UploadTask uploadTask = ref.putFile(imageFile);

    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
    String downloadUrl = await ref.getDownloadURL();

    return downloadUrl;
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        // อัปเดตไฟล์ใหม่
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Container(
          padding:
              EdgeInsets.all(20), // เพิ่ม padding เพื่อให้มีขอบรอบของ content
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Center(
                child: Text(
                  "เพิ่มกิจกรรม",
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    SizedBox(
                      width: 350,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Color.fromARGB(
                              255, 248, 171, 55), // เปลี่ยนสีพื้นหลังเป็นสีส้ม
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: TextField(
                            style: TextStyle(
                              color: Colors.white, // กำหนดสีของ font เป็นสีขาว
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'ชื่อกิจกรรม',
                              hintStyle: TextStyle(
                                color:
                                    Colors.white, // กำหนดสีของ font เป็นสีขาว
                              ),
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(left: 20, right: 20),
                                child: IconTheme(
                                  data: IconThemeData(
                                    color: Colors
                                        .white, // กำหนดสีของไอคอนเป็นสีขาว
                                  ),
                                  child: Icon(Icons.event),
                                ),
                              ),
                              prefixIconConstraints:
                                  BoxConstraints(minWidth: 0),
                              contentPadding: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).size.height *
                                      0.015), // กำหนดระยะห่าง top และ bottom
                            ),
                            maxLines: 1,
                            keyboardType: TextInputType.multiline,
                            textAlignVertical: TextAlignVertical.center,
                            controller: activityName,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      width: 350,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Color.fromARGB(255, 248, 171, 55),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 20, right: 20),
                                child: IconTheme(
                                  data: IconThemeData(color: Colors.white),
                                  child: Icon(Icons.description),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'รายละเอียดกิจกรรม',
                                    hintStyle: TextStyle(color: Colors.white),
                                    contentPadding: EdgeInsets.only(
                                        bottom:
                                            MediaQuery.of(context).size.height *
                                                0.015),
                                  ),
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  textAlignVertical: TextAlignVertical.center,
                                  controller: activityDetail,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: 350,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Color.fromARGB(255, 248, 171, 55),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Column(
                            children: [
                              CheckboxListTile(
                                title: Text('ปี 1'),
                                value: classLevel['ปี 1'],
                                onChanged: (value) {
                                  setState(() {
                                    classLevel['ปี 1'] = value!;
                                    if (value) {
                                      _selectedClassActivity.add('ปี 1');
                                    } else {
                                      _selectedClassActivity.remove('ปี 1');
                                    }
                                  });
                                },
                              ),
                              CheckboxListTile(
                                title: Text('ปี 2'),
                                value: classLevel['ปี 2'],
                                onChanged: (value) {
                                  setState(() {
                                    classLevel['ปี 2'] = value!;
                                    if (value) {
                                      _selectedClassActivity.add('ปี 2');
                                    } else {
                                      _selectedClassActivity.remove('ปี 2');
                                    }
                                  });
                                },
                              ),
                              CheckboxListTile(
                                title: Text('ปี 3'),
                                value: classLevel['ปี 3'],
                                onChanged: (value) {
                                  setState(() {
                                    classLevel['ปี 3'] = value!;
                                    if (value) {
                                      _selectedClassActivity.add('ปี 3');
                                    } else {
                                      _selectedClassActivity.remove('ปี 3');
                                    }
                                  });
                                },
                              ),
                              CheckboxListTile(
                                title: Text('ปี 4'),
                                value: classLevel['ปี 4'],
                                onChanged: (value) {
                                  setState(() {
                                    classLevel['ปี 4'] = value!;
                                    if (value) {
                                      _selectedClassActivity.add('ปี 4');
                                    } else {
                                      _selectedClassActivity.remove('ปี 4');
                                    }
                                  });
                                },
                              ),
                              CheckboxListTile(
                                title: Text('ทุกชั้นปี'),
                                value: classLevel['ทุกชั้นปี'],
                                onChanged: (value) {
                                  setState(() {
                                    classLevel['ทุกชั้นปี'] = value!;
                                    if (value) {
                                      _selectedClassActivity.add('ทุกชั้นปี');
                                    } else {
                                      _selectedClassActivity
                                          .remove('ทุกชั้นปี');
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              //),
              //),
              SizedBox(height: 10),
              SizedBox(
                width: 350,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color.fromARGB(255, 248, 171, 55),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'สถานที่',
                        hintStyle: TextStyle(color: Colors.white),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 20, right: 20),
                          child: IconTheme(
                            data: IconThemeData(
                                color:
                                    Colors.white), // กำหนดสีของไอคอนเป็นสีขาว
                            child: Icon(Icons.location_city),
                          ),
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 0),
                        contentPadding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height * 0.015),
                      ),
                      maxLines: 1,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.center,
                      controller: activityLocaltion,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 350,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color.fromARGB(255, 248, 171, 55),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'วันที่',
                        hintStyle: TextStyle(color: Colors.white),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 20, right: 20),
                          child: IconTheme(
                            data: IconThemeData(
                                color:
                                    Colors.white), // กำหนดสีของไอคอนเป็นสีขาว
                            child: Icon(Icons.date_range),
                          ),
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 0),
                        contentPadding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height * 0.015),
                      ),
                      maxLines: 1,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.center,
                      controller: dateController,
                      readOnly: true,
                      onTap: () {
                        _selectDate(context);
                      },
                      onSubmitted: (value) {},
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 350,
                child: Row(
                  children: [
                    Flexible(
                      flex: 2,
                      fit: FlexFit.tight,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: InkWell(
                            onTap: () {
                              _selectStartTime(context);
                            },
                            child: IgnorePointer(
                              child: Center(
                                // Center widget to center the text
                                child: Text(
                                  "เริ่มเวลา",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      flex: 2,
                      fit: FlexFit.tight,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: InkWell(
                            onTap: () {
                              _selectLastTime(context);
                            },
                            child: IgnorePointer(
                              child: Center(
                                // Center widget to center the text
                                child: Text(
                                  "ถึงเวลา",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 350,
                child: Row(
                  children: [
                    Flexible(
                      flex: 2,
                      fit: FlexFit.tight,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Color.fromARGB(255, 248, 171, 55),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: InkWell(
                            onTap: () {
                              _selectStartTime(context);
                            },
                            child: IgnorePointer(
                              child: TextField(
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'เริ่มเวลา',
                                  hintStyle: TextStyle(color: Colors.white),
                                  prefixIcon: Padding(
                                    padding:
                                        EdgeInsets.only(left: 20, right: 20),
                                    child: IconTheme(
                                      data: IconThemeData(
                                          color: Colors
                                              .white), // กำหนดสีของไอคอนเป็นสีขาว
                                      child: Icon(Icons.timer_sharp),
                                    ),
                                  ),
                                  prefixIconConstraints:
                                      BoxConstraints(minWidth: 0),
                                  contentPadding: EdgeInsets.only(
                                      bottom:
                                          MediaQuery.of(context).size.height *
                                              0.015),
                                ),
                                maxLines: 1,
                                keyboardType: TextInputType.multiline,
                                textAlignVertical: TextAlignVertical.center,
                                controller: timeStartController,
                                readOnly: true,
                                onSubmitted: (value) {},
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      flex: 2,
                      fit: FlexFit.tight,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Color.fromARGB(255, 248, 171, 55),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: InkWell(
                            onTap: () {
                              _selectLastTime(context);
                            },
                            child: IgnorePointer(
                              child: TextField(
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'ถึงเวลา',
                                  hintStyle: TextStyle(color: Colors.white),
                                  prefixIcon: Padding(
                                    padding:
                                        EdgeInsets.only(left: 20, right: 20),
                                    child: IconTheme(
                                      data: IconThemeData(
                                          color: Colors
                                              .white), // กำหนดสีของไอคอนเป็นสีขาว
                                      child: Icon(Icons.timer_sharp),
                                    ),
                                  ),
                                  prefixIconConstraints:
                                      BoxConstraints(minWidth: 0),
                                  contentPadding: EdgeInsets.only(
                                      bottom:
                                          MediaQuery.of(context).size.height *
                                              0.015),
                                ),
                                maxLines: 1,
                                keyboardType: TextInputType.multiline,
                                textAlignVertical: TextAlignVertical.center,
                                controller: timeLastController,
                                readOnly: true,
                                onSubmitted: (value) {},
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 300,
                width: 350,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color.fromARGB(255, 248, 171, 55),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("เลือกวิธี"),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: [
                                    GestureDetector(
                                      child: Text("เลือกจากแกลเลอรี่"),
                                      onTap: () {
                                        _getImage(ImageSource.gallery);
                                        Navigator.pop(context);
                                      },
                                    ),
                                    Padding(padding: EdgeInsets.all(10)),
                                    GestureDetector(
                                      child: Text("ถ่ายภาพ"),
                                      onTap: () {
                                        _getImage(ImageSource.camera);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        child: Stack(
                          children: [
                            if (_imageFile != null)
                              Positioned(
                                top: 80,
                                left: 25,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                        height: 200.0,
                                        width: 200,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Positioned(
                              top: 20,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    'เลือกไฟล์ภาพ',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 350,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color.fromARGB(255, 248, 171, 55),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'จำนวนผู้เข้าร่วม',
                        hintStyle: TextStyle(color: Colors.white),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 20, right: 20),
                          child: IconTheme(
                            data: IconThemeData(
                                color:
                                    Colors.white), // กำหนดสีของไอคอนเป็นสีขาว
                            child: Icon(Icons.people),
                          ),
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 0),
                        contentPadding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height * 0.015),
                      ),
                      maxLines: 1,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.center,
                      controller: activityPeople,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () async {
                    String ActivityName = activityName.text;
                    String ActivityDetail = activityDetail.text;
                    String ActivityLocaltion = activityLocaltion.text;
                    String DatabaseEvent = dateController.text;
                    String TimeStartController = timeStartController.text;
                    String TimeLastController = timeLastController.text;
                    String ActivityPeopleController = activityPeople.text;
                    String activityClassName =
                        _selectedClassActivity.join(', ');

                    int convertTimeToMinutes(String time) {
                      List<String> parts = time.split(':');
                      int hours = int.parse(parts[0]);
                      int minutes = int.parse(parts[1]);
                      return hours * 60 + minutes;
                    }

                    void showEmptyFieldAlert(
                        BuildContext context, String fieldName) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('แจ้งเตือน'),
                            content: Text('$fieldName กิจกรรม'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // ปิด AlertDialog
                                },
                                child: Text('ตกลง'),
                              ),
                            ],
                          );
                        },
                      );
                    }

                    if (ActivityName.isEmpty) {
                      showEmptyFieldAlert(context, 'โปรดกรอกชื่อ');
                      return; // หยุดการทำงานของฟังก์ชันถ้าพบข้อมูลว่าง
                    }

                    if (ActivityDetail.isEmpty) {
                      showEmptyFieldAlert(context, 'โปรดกรอกรายละเอียด');
                      return;
                    }

                    if (activityClassName == null ||
                        activityClassName == "null") {
                      showEmptyFieldAlert(
                          context, 'โปรดเลือกระดับชั้นปีสำหรับ');
                      return;
                    }

                    if (ActivityLocaltion.isEmpty) {
                      showEmptyFieldAlert(context, 'โปรดกรอกสถานที่');
                      return;
                    }

                    if (DatabaseEvent.isEmpty) {
                      showEmptyFieldAlert(context, 'โปรดกรอกวันที่');
                      return;
                    }

                    if (TimeStartController.isEmpty) {
                      showEmptyFieldAlert(context, 'โปรดกรอกเวลาเริ่ม');
                      return;
                    }

                    if (TimeLastController.isEmpty) {
                      showEmptyFieldAlert(context, 'โปรดกรอกเวลาจบ');
                      return;
                    }
                    if (ActivityPeopleController.isEmpty) {
                      showEmptyFieldAlert(context, 'โปรดกรอกจำนวนผู้เข้าร่วม');
                      return;
                    }

                    if (_imageFile == null) {
                      showEmptyFieldAlert(context, 'โปรดเลือกรูป');
                      return;
                    }

                    int intTimeStartController =
                        convertTimeToMinutes(TimeStartController);
                    int intTimeLastController =
                        convertTimeToMinutes(TimeLastController);

// คำนวณระยะเวลาของกิจกรรม
                    int intActivityTimeController =
                        intTimeLastController - intTimeStartController;

// แปลงค่าผลลัพธ์กลับเป็น String เพื่อแสดงผลหรือเก็บในตัวแปร
                    String activityTimeController =
                        intActivityTimeController.toString();

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

                    if (_imageFile != null) {
                      String result = await addUserActivity(
                          ActivityName,
                          ActivityDetail,
                          activityClassName,
                          ActivityLocaltion,
                          DatabaseEvent,
                          TimeStartController,
                          TimeLastController,
                          ActivityPeopleController,
                          activityTimeController,
                          _imageFile!);
                      if (result == "Success") {
                        Future.delayed(const Duration(seconds: 2), () {
                          Navigator.pop(
                              context); // ปิด showDialog หลังจาก 2 วินาที
                        });

                        Future.delayed(const Duration(seconds: 2), () {
                          final snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: AwesomeSnackbarContent(
                              title: 'Success!',
                              message: 'เพิ่มข้อมูลสำเร็จ!',
                              contentType: ContentType.success,
                            ),
                          );

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar)
                                .closed // เมื่อ SnackBar ปิด
                                .then((reason) {
                              Navigator.pop(context);
                            });
                        });
                      } else if (result == "TimeError") {
                        Future.delayed(const Duration(seconds: 2), () {
                          Navigator.pop(
                              context); // ปิด showDialog หลังจาก 2 วินาที
                        });

                        Future.delayed(const Duration(seconds: 2), () {
                          final snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: AwesomeSnackbarContent(
                              title: 'Error!',
                              message:
                                  'ไม่สามารถเพิ่มข้อมูลได้ เวลาจบกิจกรรมต้องมากกว่าเวลาเรื่มกิจกรรม!',
                              contentType: ContentType.failure,
                            ),
                          );

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                        });
                      } else if (result == "NotSuccess") {
                        Future.delayed(const Duration(seconds: 2), () {
                          Navigator.pop(
                              context); // ปิด showDialog หลังจาก 2 วินาที
                        });

                        Future.delayed(const Duration(seconds: 2), () {
                          final snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: AwesomeSnackbarContent(
                              title: 'Error!',
                              message:
                                  'ไม่สามารถเพิ่มข้อมูลได้ อาจมีข้อมูลอยู่แล้ว!',
                              contentType: ContentType.failure,
                            ),
                          );

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                        });
                      }
                    } else {
                      // Handle the case where no image is selected
                      print('No image selected');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 248, 171, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Add this line
                      children: [
                        Text(
                          'บันทึก',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        /*],
          ),
        ),*/
      ),
    );
  }
}
