import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application/screen/home.dart';
import 'package:flutter_application/screen/showdata_detail.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_activity.dart';
import 'showdata_detail.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_application/model/Event.dart';
import 'package:flutter_application/user/edit_user.dart';
import 'package:flutter_application/screen/showdata_history_t.dart';
import 'package:flutter_application/screen/showdata_history_s.dart';
import 'package:flutter_application/screen/profile.dart';

class showdata extends StatefulWidget {
  final Map<String, dynamic> userData;

  showdata({Key? key, required this.userData}) : super(key: key);

  @override
  _showdataState createState() => _showdataState();
}

class _showdataState extends State<showdata> {
  String user_id_student = '';
  String user_password_student = '';
  String user_name = '';
  String user_class = '';
  String status = '';
  String minTime = '';
  String formattedTime = '';
  String formattedHH = '';
  String formattedMM = '';

  late DatabaseReference dbRef;
  TextEditingController textFieldControllerCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    setData();
  }

  void setData() {
    user_id_student = widget.userData['user_id_student'] ?? '';
    user_password_student = widget.userData['user_password_student'] ?? '';
    user_name = widget.userData['user_name'] ?? '';
    user_class = widget.userData['user_class'] ?? '';
    status = widget.userData['status'] ?? '';
    minTime = widget.userData['minTime'] ?? '';

    double db_activit_Time = double.parse(minTime);
    db_activit_Time = db_activit_Time / 60;

    int hours = db_activit_Time.toInt();
    int minutes = ((db_activit_Time - hours) * 60).toInt();

    formattedHH = hours.toString().padLeft(2);
    formattedMM = minutes.toString().padLeft(2, '0');

    formattedTime = '$formattedHH:$formattedMM';
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    double bottomAppBarHeight = screenHeight * 0.12;
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.orange[200]!, Colors.white],
              ),
            ),
          ),
          Column(
            children: [
              if (status == 't' || status == 'a')
                Container(
                  margin: const EdgeInsets.only(top: 10, right: 30, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddActivityPage(),
                            ),
                          );
                        },
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text('เพิ่มกิจกรรม',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: MyCalendarWidget(status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            child: BottomAppBar(
              height: bottomAppBarHeight,
              color: Colors.white,
              child: Container(
                padding: EdgeInsets.only(
                    top: 0, bottom: 0), // เพิ่ม padding ด้านล่าง
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    buildBottomNavItem(
                      icon: status == 's' ? Icons.history : Icons.search,
                      label: status == 's' ? 'ประวัติกิจกรรม' : 'รายงานกิจกรรม',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => status == 's'
                                ? ShowdataHistory_s(
                                    user_id_student: '$user_id_student')
                                : ShowdataHistory_t(),
                          ),
                        );
                      },
                    ),
                    buildBottomNavItem(
                      icon: Icons.person,
                      label: 'ข้อมูลส่วนตัว',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                                userIdStudent: '$user_id_student'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBottomNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.orange[800], size: 28),
          ),
          SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.orange[800],
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class MyCalendarWidget extends StatefulWidget {
  final String status;

  MyCalendarWidget(this.status, {Key? key}) : super(key: key);

  @override
  _MyCalendarWidgetState createState() => _MyCalendarWidgetState();
}

class _MyCalendarWidgetState extends State<MyCalendarWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Event> _events = [];
  String? _selectedClassActivity = '5';

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("activity");
    final snapshot = await ref.once();

    final data = snapshot.snapshot.value as Map<Object?, Object?>?;
    if (data != null) {
      data.entries.forEach((entry) {
        var key = entry.key;
        var value = entry.value;

        if (value != null && value is Map) {
          final mapValue = Map<dynamic, dynamic>.from(value as Map);

          final keyString = key as String?;
          final dateString = mapValue['date'] as String?;
          final nameActivity = mapValue['name_activity'] as String?;
          final detailActivity = mapValue['detail_activity'] as String?;
          final classactivity = mapValue['class_activity'] as String?;
          final locationActivity = mapValue['location_activity'] as String?;
          final startTime = mapValue['start_time'] as String?;
          final endTime = mapValue['end_time'] as String?;
          final imageUrl = mapValue['imageUrl'] as String?;
          final activity_People = mapValue['activity_People'] as String?;
          final activit_Time = mapValue['activit_Time'] as String?;
          final status_activity = mapValue['status_activity'] as String?;

          DateTime? date;
          int? day;
          int? month;
          int? year;

          if (dateString != null) {
            try {
              date = DateFormat('d/M/yyyy').parse(dateString);
              day = date.day;
              month = date.month;
              year = date.year;
            } catch (e) {
              print('Error parsing date: $e');
            }
          }

          if (date != null) {
            if (mounted) {
              setState(() {
                _events.add(
                  Event(
                    key: keyString ?? '',
                    name: nameActivity ?? '',
                    detail: detailActivity ?? '',
                    Class: classactivity ?? '',
                    location: locationActivity ?? '',
                    date: date!,
                    startTime: startTime ?? '',
                    endTime: endTime ?? '',
                    imageUrl: imageUrl ?? '',
                    activity_People: activity_People ?? '',
                    activit_Time: activit_Time ?? '',
                    title: nameActivity ?? '',
                    status: widget.status,
                  ),
                );
              });
            }
          }
        }
      });
    }
  }

  bool _isRefreshing = false;

  Future<void> _refreshEvents() async {
    if (_isRefreshing) return; // ป้องกันการกดซ้ำระหว่างรีเฟรช

    setState(() {
      _isRefreshing = true;
    });

    // แสดง loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // หน่วงเวลา 2 วินาที (หรือตามที่คุณต้องการ)
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _events.clear();
    });

    await _fetchEvents();

    // ปิด loading indicator
    Navigator.of(context).pop();

    setState(() {
      _isRefreshing = false;
    });
  }

  List<Event> _getEventsForDay(DateTime day, String? classActivityFilter) {
    if (classActivityFilter == '5') {
      return _events.where((event) => isSameDay(event.date, day)).toList();
    } else {
      return _events
          .where((event) =>
              isSameDay(event.date, day) && event.Class == classActivityFilter)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          locale: 'th_TH',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) => _getEventsForDay(day, _selectedClassActivity),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  right: 1,
                  bottom: 1,
                  child: _buildEventsMarker(date, events),
                );
              }
              return null;
            },
          ),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Colors.orange[400],
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.orange[200],
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Colors.blue[300],
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'รายการกิจกรรม',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedClassActivity,
                  items: [
                    DropdownMenuItem(child: Text('ปี 1'), value: '1'),
                    DropdownMenuItem(child: Text('ปี 2'), value: '2'),
                    DropdownMenuItem(child: Text('ปี 3'), value: '3'),
                    DropdownMenuItem(child: Text('ปี 4'), value: '4'),
                    DropdownMenuItem(child: Text('ทั้งหมด'), value: '5'),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClassActivity = value;
                    });
                  },
                  underline: Container(),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.orange[600]),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.orange[600]),
                  onPressed: _refreshEvents,
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 10),
        _listview(_selectedDay ?? DateTime.now(), _selectedClassActivity),
      ],
    );
  }

  Widget _listview(DateTime selectedDay, String? classActivityFilter) {
    List<Event> events = _getEventsForDay(selectedDay, classActivityFilter);

    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: events.length,
      itemBuilder: (context, index) {
        Event event = events[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.orange[200],
              child: Text(
                event.title[0],
                style: TextStyle(
                    color: Colors.orange[800], fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              event.title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${event.startTime} - ${event.endTime}'),
            trailing: Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.orange[300]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Showdata_detail(event: event),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}

class AuthService {
  static Future<void> signOutAndClearLocalStorage(BuildContext context) async {
    try {
      // ลบข้อมูลทั้งหมดใน local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // ทำการ navigate กลับไปยังหน้า HomeScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    } catch (e) {}
  }
}
