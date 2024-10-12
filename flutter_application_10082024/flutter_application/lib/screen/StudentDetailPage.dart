import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_application/model/Event.dart';
import 'package:flutter/material.dart';

class StudentDetailPage extends StatefulWidget {
  final List<dynamic> data;
  final String eventKey;

  StudentDetailPage({required this.data, required this.eventKey});

  @override
  _StudentDetailPageState createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  String _sortType = 'รหัสนักศึกษา';
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Widget Function(BuildContext, int)> widgets = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายงานกิจกรรม'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'รายชื่อนักศึกษา',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.sort, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'เรียงลำดับโดย:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        isExpanded: true,
                        value: _sortType,
                        onChanged: (value) {
                          setState(() {
                            _sortType = value as String;
                          });
                        },
                        items: [
                          DropdownMenuItem(
                            child: Text('รหัสนักศึกษา'),
                            value: 'รหัสนักศึกษา',
                          ),
                          DropdownMenuItem(
                            child: Text('ชื่อ'),
                            value: 'ชื่อ',
                          ),
                        ],
                        dropdownColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder(
                future: FirebaseDatabase.instance
                    .ref()
                    .child('user')
                    .orderByChild('user_id_student')
                    .once(),
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    Map<dynamic, dynamic>? values =
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
                    if (values != null) {
                      widgets.clear();
                      values.entries.forEach((entry) {
                        if (widget.data
                            .contains(entry.value['user_id_student'])) {
                          widgets.add(
                            (BuildContext context, int index) => ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                'รหัสนักศึกษา: ${entry.value['user_id_student']}',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'ชื่อ: ${entry.value['user_name']}',
                                style: TextStyle(fontSize: 14),
                              ),
                              tileColor: Colors.orange[50],
                            ),
                          );
                        }
                      });
                      if (_sortType == 'ชื่อ') {
                        widgets.sort((a, b) {
                          return (a(context, 0) as ListTile)
                              .subtitle!
                              .toString()
                              .compareTo((b(context, 0) as ListTile)
                                  .subtitle!
                                  .toString());
                        });
                      } else {
                        widgets.sort((a, b) {
                          return (a(context, 0) as ListTile)
                              .title!
                              .toString()
                              .compareTo((b(context, 0) as ListTile)
                                  .title!
                                  .toString());
                        });
                      }
                      if (widgets.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'ไม่พบข้อมูลนักศึกษา',
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'จำนวนนักศึกษาทั้งหมด: ${widgets.length}',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 16),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async {
                                // Implement refresh logic here
                              },
                              child: AnimatedList(
                                key: _listKey,
                                initialItemCount: widgets.length,
                                itemBuilder: (context, index, animation) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(-1, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: widgets[index](context, index),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Center(
                        child: Text('ไม่พบข้อมูลนักศึกษา',
                            style: TextStyle(fontSize: 20)),
                      );
                    }
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
