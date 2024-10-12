import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Showdata_history_t_detail extends StatefulWidget {
  final String user_id_student;

  Showdata_history_t_detail({required this.user_id_student});

  @override
  _Showdata_history_t_detailState createState() =>
      _Showdata_history_t_detailState();
}

class _Showdata_history_t_detailState extends State<Showdata_history_t_detail> {
  late DatabaseReference _databaseRef;
  Map<dynamic, dynamic>? _userData;
  List<Map<dynamic, dynamic>>?
      _activities; // ลิสต์ของแผนที่เพื่อเก็บข้อมูลกิจกรรม
  List<Map<dynamic, dynamic>>? _activitiesTime;
  String _totalActivityHoursFormatted =
      "0 ชั่วโมง 0 นาที"; // ตัวแปรเก็บข้อมูลชั่วโมงทั้งหมดในรูปแบบที่ format แล้ว
  String _minTimeFormatted =
      "0 ชั่วโมง 0 นาที"; // ตัวแปรเก็บข้อมูลเวลาที่เก็บได้ในรูปแบบที่ format แล้ว
  String _activitTimeMinutes =
      "0 ชั่วโมง 0 นาที"; // ตัวแปรเก็บข้อมูลเวลาที่เก็บได้ในรูปแบบที่ format แล้ว

  @override
  void initState() {
    super.initState();
    _databaseRef = FirebaseDatabase.instance.ref();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      // Fetch user data
      DataSnapshot userSnapshot =
          (await _databaseRef.child('user').once()).snapshot;

      if (userSnapshot.value != null) {
        Map<dynamic, dynamic> users =
            userSnapshot.value as Map<dynamic, dynamic>;

        int minTimeInt = 0; // Default value

        for (var userId in users.keys) {
          var user = users[userId];
          if (user['user_id_student'] == widget.user_id_student) {
            setState(() {
              _userData = user;

              final minTime = user['minTime'];
              //print("minTime : $minTime");

              // Ensure minTime is an integer
              if (minTime is int) {
                minTimeInt = minTime;
              } else if (minTime is String) {
                minTimeInt = int.tryParse(minTime) ?? 0;
              } else {
                minTimeInt = 0;
              }

              final minTimeHours = minTimeInt ~/ 60;
              final minTimeMinutes = minTimeInt % 60;

              if (minTimeMinutes == 0) {
                _minTimeFormatted = '$minTimeHours ชั่วโมง';
              } else {
                _minTimeFormatted =
                    '$minTimeHours ชั่วโมง $minTimeMinutes นาที';
              }
            });
            break;
          }
        }

        DataSnapshot activitySnapshot =
            (await _databaseRef.child('activity_detail').once()).snapshot;

        if (activitySnapshot.value != null) {
          Map<dynamic, dynamic> activityDetails =
              activitySnapshot.value as Map<dynamic, dynamic>;

          List<String> activityKeys = [];

          for (var key in activityDetails.keys) {
            List<dynamic> studentIds = activityDetails[key];
            if (studentIds.contains(widget.user_id_student)) {
              activityKeys.add(key);
            }
          }

          // Fetch activities using the keys
          if (activityKeys.isNotEmpty) {
            List<Map<dynamic, dynamic>> activitiesList = [];

            for (var activityKey in activityKeys) {
              DataSnapshot activitySnapshot = (await _databaseRef
                      .child('activity')
                      .child(activityKey)
                      .once())
                  .snapshot;

              if (activitySnapshot.value != null) {
                Map<dynamic, dynamic> activityData =
                    activitySnapshot.value as Map<dynamic, dynamic>;

                final activitTime = activityData['activit_Time'];

                // Ensure activitTime is an integer
                int activitTimeInt;
                if (activitTime is int) {
                  activitTimeInt = activitTime;
                } else if (activitTime is String) {
                  activitTimeInt = int.tryParse(activitTime) ?? 0;
                } else {
                  activitTimeInt = 0;
                }

                final activitTimeHours = activitTimeInt ~/ 60;
                final activitTimeMinutes = activitTimeInt % 60;

                String activitTimeFormatted;
                if (activitTimeMinutes == 0) {
                  activitTimeFormatted = '$activitTimeHours ชั่วโมง';
                } else {
                  activitTimeFormatted =
                      '$activitTimeHours ชั่วโมง $activitTimeMinutes นาที';
                }

                activityData['activit_Time'] = activitTimeFormatted;

                activitiesList.add(activityData);
              }
            }
            // Fetch activity_hours data
            DataSnapshot activityHoursSnapshot =
                (await _databaseRef.child('activity_hours').once()).snapshot;
            if (activityHoursSnapshot.value != null) {
              final activityHoursData =
                  activityHoursSnapshot.value as Map<dynamic, dynamic>;
              final totalMinutes = activityHoursData['time'];

              //print("totalMinutes : $totalMinutes");

              if (totalMinutes is int) {
                final remainingMinutes = totalMinutes - minTimeInt;

                // Calculate hours and minutes
                final hours = remainingMinutes ~/ 60;
                final minutes = remainingMinutes % 60;

                // Format the result
                if (minutes == 0) {
                  _totalActivityHoursFormatted = '$hours ชั่วโมง';
                } else {
                  _totalActivityHoursFormatted = '$hours ชั่วโมง $minutes นาที';
                }
              } else {
                _totalActivityHoursFormatted = 'ข้อมูลไม่ถูกต้อง';
              }
            }

            String totalActivityTime = _totalActivityHoursFormatted;

            setState(() {
              _activitiesTime = [
                {'totalActivityTime': totalActivityTime}
              ];
            });

            setState(() {
              _activities = activitiesList;
            });
          } else {
            // Fetch activity_hours data
            DataSnapshot activityHoursSnapshot =
                (await _databaseRef.child('activity_hours').once()).snapshot;
            if (activityHoursSnapshot.value != null) {
              final activityHoursData =
                  activityHoursSnapshot.value as Map<dynamic, dynamic>;
              final totalMinutes = activityHoursData['time'];

              //print("totalMinutes : $totalMinutes");

              if (totalMinutes is int) {
                final remainingMinutes = totalMinutes - minTimeInt;

                // Calculate hours and minutes
                final hours = remainingMinutes ~/ 60;
                final minutes = remainingMinutes % 60;

                // Format the result
                if (minutes == 0) {
                  _totalActivityHoursFormatted = '$hours ชั่วโมง';
                } else {
                  _totalActivityHoursFormatted = '$hours ชั่วโมง $minutes นาที';
                }
              } else {
                _totalActivityHoursFormatted = 'ข้อมูลไม่ถูกต้อง';
              }
            }

            String totalActivityTime = _totalActivityHoursFormatted;

            setState(() {
              _activitiesTime = [
                {'totalActivityTime': totalActivityTime}
              ];
            });

            setState(() {
              _activities = [];
            });
          }
        } else {
          //print('No activity details available.');
        }
      }
    } catch (error) {
      //print('Failed to fetch data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดกิจกรรม',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[600],
        elevation: 0,
      ),
      body: _userData == null || _activities == null || _activitiesTime == null
          ? Center(child: CircularProgressIndicator(color: Colors.orange[600]))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[100]!, Colors.orange[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[600],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'ข้อมูลนักศึกษา',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildInfoRow(Icons.account_circle,
                                  'ชื่อ-นามสกุล', _userData!['user_name']),
                              _buildInfoRow(Icons.badge, 'รหัสนักศึกษา',
                                  _userData!['user_id_student']),
                              _buildInfoRow(Icons.school, 'สาขา',
                                  _userData!['user_class']),
                              _buildInfoRow(Icons.timer, 'ชั่วโมงที่เก็บได้',
                                  _minTimeFormatted),
                              _buildInfoRow(
                                  Icons.access_time_filled,
                                  'ชั่วโมงรวมกิจกรรมที่ขาดอีก',
                                  _totalActivityHoursFormatted),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('กิจกรรมที่เกี่ยวข้อง',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800])),
                        SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _activities!.length,
                          itemBuilder: (context, index) {
                            var activity = _activities![index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 16),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (activity['imageUrl'] != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          activity['imageUrl'],
                                          width: double.infinity,
                                          height: 150,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    SizedBox(height: 12),
                                    Text(
                                      activity['name_activity'],
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    _buildActivityInfoRow(Icons.calendar_today,
                                        'วันที่', activity['date']),
                                    _buildActivityInfoRow(
                                        Icons.access_time,
                                        'เวลา',
                                        '${activity['start_time']} - ${activity['end_time']}'),
                                    _buildActivityInfoRow(
                                        Icons.location_on,
                                        'สถานที่',
                                        activity['location_activity']),
                                    _buildActivityInfoRow(
                                        Icons.info_outline,
                                        'รายละเอียด',
                                        activity['detail_activity']),
                                    _buildActivityInfoRow(
                                        Icons.timer,
                                        'ชั่วโมงกิจกรรม',
                                        activity['activit_Time'] ??
                                            '0 ชั่วโมง 0 นาที'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.orange[700]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.orange[600]),
          SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                      text: '$label: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
