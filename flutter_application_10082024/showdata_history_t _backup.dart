/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ค้นหานักศึกษา',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ShowdataHistory_t(),
    );
  }
}

class ShowdataHistory_t extends StatefulWidget {
  @override
  _ShowdataHistory_tState createState() => _ShowdataHistory_tState();
}

class _ShowdataHistory_tState extends State<ShowdataHistory_t> {
  final databaseUserRef = FirebaseDatabase.instance.ref().child('user');
  final databaseActivity_hours_Ref =
      FirebaseDatabase.instance.ref().child('activity_hours');
  final databaseActivity_detail_Ref =
      FirebaseDatabase.instance.ref().child('activity_detail');
  final databaseActivityRef = FirebaseDatabase.instance.ref().child('activity');

  String searchQuery = "";

  Future<Map<String, dynamic>> fetchactivity_hours() async {
    final snapshot = await databaseActivity_hours_Ref.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final time = data['time'] as int?;
      return {'time': time ?? 0}; // Return 0 if time is null
    } else {
      return {'time': 0};
    }
  }

  Future<Map<String, dynamic>?> fetchactivity_data(String userId) async {
    final detailSnapshot = await databaseActivity_detail_Ref.get();
    Map<String, dynamic> result = {};

    if (detailSnapshot.exists) {
      final detailData = detailSnapshot.value as Map<dynamic, dynamic>?;

      if (detailData != null) {
        for (var key in detailData.keys) {
          final list = detailData[key] as List<dynamic>?;
          if (list != null && list.contains(userId)) {
            final activitySnapshot = await databaseActivityRef.child(key).get();

            if (activitySnapshot.exists) {
              final activityData =
                  activitySnapshot.value as Map<dynamic, dynamic>?;

              if (activityData != null) {
                final nameActivity = activityData['name_activity'] as String?;
                final activityTime = activityData['activit_Time'] as String?;
                final activityimageUrl = activityData['imageUrl'] as String?;

                if (nameActivity != null &&
                    activityTime != null &&
                    activityimageUrl != null) {
                  result[key] = {
                    'name_activity': nameActivity,
                    'activit_Time': activityTime,
                    'activityimageUrl': activityimageUrl,
                  };
                } else {
                  print("Missing activityData fields for key: $key");
                }
              } else {
                print("activityData is null for key: $key");
              }
            } else {
              print("activitySnapshot does not exist for key: $key");
            }
          }
        }
      } else {
        print("detailData is null");
      }
    } else {
      print("detailSnapshot does not exist");
    }

    return result.isNotEmpty ? result : null;
  }

  Future<List<Map<String, dynamic>>> fetchUserAndActivityData() async {
    final userSnapshot = await databaseUserRef.get();
    if (!userSnapshot.exists) return [];

    final userData = userSnapshot.value as Map<dynamic, dynamic>;
    final filteredData = userData.values.where((item) {
      final user = item as Map<dynamic, dynamic>;
      return user['user_id_student'] == searchQuery;
    }).toList();

    return Future.wait(filteredData.map((user) async {
      final userMap = user as Map<dynamic, dynamic>;
      final userId = userMap['user_id_student'];
      final activity_hours = await fetchactivity_hours();
      final activityData = await fetchactivity_data(userId);

      return {
        'user': userMap,
        'activity_hours': activity_hours,
        'activityData': activityData
      };
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('ค้นหานักศึกษา'),
          backgroundColor: Colors.orange,
        ),
        body: Container(
          color: const Color.fromARGB(255, 255, 255, 255),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาโดยรหัสนักศึกษา...',
                    filled: true,
                    fillColor: Colors.grey[300],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  keyboardType: TextInputType.number,
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchUserAndActivityData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('กรูณากรอกรหัสนักศึกษา'));
                    } else {
                      final activityDataList = snapshot.data!;
                      return ListView.builder(
                        itemCount: activityDataList.length,
                        itemBuilder: (context, index) {
                          final userData = activityDataList[index]['user']
                              as Map<dynamic, dynamic>;
                          final activityHours = activityDataList[index]
                              ['activity_hours'] as Map<dynamic, dynamic>;
                          final activityData = activityDataList[index]
                              ['activityData'] as Map<dynamic, dynamic>?;

                          List<Widget> activityWidgets = [];
                          if (activityData != null) {
                            activityData.forEach((key, value) {
                              final nameActivity =
                                  value['name_activity'] as String?;
                              final activityTime =
                                  value['activit_Time'] as String?;
                              final activityimageUrl =
                                  value['activityimageUrl'] as String?;

                              int? activityTime_Int = activityTime != null &&
                                      activityTime.isNotEmpty &&
                                      activityimageUrl != null
                                  ? int.tryParse(activityTime)
                                  : null;

                              String hoursAndMinutes_activity = '';
                              if (activityTime_Int != null) {
                                final hours = activityTime_Int ~/ 60;
                                final minutes = activityTime_Int % 60;
                                hoursAndMinutes_activity =
                                    '${hours} ชั่วโมง ${minutes} นาที';
                              } else {
                                hoursAndMinutes_activity = 'ข้อมูลไม่ถูกต้อง';
                              }

                              activityWidgets.add(
                               Card(
  margin: EdgeInsets.all(8.0),
  child: ListTile(
    leading: Image.network(
      '$activityimageUrl',
      width: 100,
      height: 100,
      fit: BoxFit.cover,
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${nameActivity ?? 'ไม่พบกิจกรรมที่เข้าร่วม'}',
          style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,),
        ),
        SizedBox(height: 8.0), // ระยะห่างระหว่าง title และ subtitle
      ],
    ),
    subtitle: Text(
      'เวลา: ${hoursAndMinutes_activity ?? 'ไม่พบกิจกรรมที่เข้าร่วม'}',
      style: TextStyle(fontSize: 16),
    ),
  ),
),

                              );
                            });
                          } else {
                            activityWidgets.add(
                              Container(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                padding: const EdgeInsets.all(8.0),
                                child: Text('ไม่พบกิจกรรมที่เข้าร่วม',
                                    style: TextStyle(fontSize: 16)),
                              ),
                            );
                          }

                          // แปลงค่า minTime
                          String? minTimeString =
                              userData['minTime'] as String?;
                          int? minTime =
                              minTimeString != null && minTimeString.isNotEmpty
                                  ? int.tryParse(minTimeString)
                                  : null;

                          String hoursAndMinutes = '';
                          if (minTime != null) {
                            final hours = minTime ~/ 60;
                            final minutes = minTime % 60;
                            hoursAndMinutes =
                                '${hours} ชั่วโมง ${minutes} นาที';
                          } else {
                            hoursAndMinutes = 'ข้อมูลไม่ถูกต้อง';
                          }

                          // แปลงค่า time ใน activity_hours
                          final timeActivityHours =
                              activityHours['time'] as int?;
                          String activityHoursString = '';
                          if (timeActivityHours != null && minTime != null) {
                            final remainingTime = timeActivityHours - minTime;
                            final hours = remainingTime ~/ 60;
                            final minutes = remainingTime % 60;
                            activityHoursString =
                                '${hours} ชั่วโมง ${minutes} นาที';
                          } else {
                            activityHoursString = 'ข้อมูลไม่ถูกต้อง';
                          }

                          return Card(
  margin: EdgeInsets.all(8.0),
  color: Colors.white, // ตั้งค่าสีพื้นหลังของ Card ให้เป็นสีขาว
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ชื่อ ${userData['user_name']}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          'รหัสนักศึกษา: ${userData['user_id_student']}',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 8.0),
        Text(
          'ชั่วโมงกิจกรรม: $hoursAndMinutes',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 8.0),
        Text(
          'ชั่วโมงกิจกรรมขาดอีก: $activityHoursString',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 40.0),
        Text(
          'กิจกรรมที่เข้าร่วม',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.0),
        ...activityWidgets,
      ],
    ),
  ),
);

                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ));
  }
}*/
