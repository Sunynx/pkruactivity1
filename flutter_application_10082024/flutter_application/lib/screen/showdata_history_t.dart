import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_application/screen/showdata_history_t_detail.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

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
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
  final databaseClassRef = FirebaseDatabase.instance.ref().child('class');
  Map<String, String> classData = {};

  final databaseGradeRef = FirebaseDatabase.instance.ref().child('grade');
  Map<String, String> gradeData = {};

  final databaseUserRef = FirebaseDatabase.instance.ref().child('user');

  String _minTimeFormatted = "0 ชั่วโมง 0 นาที";
  String? selectedClassName;
  String? selectedClassFullName;

  String? selectedGradeYear;
  String? selectedGradeYearName;

  List<Map<dynamic, dynamic>> _userData = [];

  @override
  void initState() {
    super.initState();
    _fetchClassData();
    _fetchGradeData();
  }

  Future<void> _fetchClassData() async {
    try {
      DatabaseEvent event = await databaseClassRef.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          classData = {
            '0': 'ค้นหาสาขา',
            ...data.map((key, value) {
              final classInfo = Map<String, dynamic>.from(value as Map);
              return MapEntry(classInfo['className'], classInfo['classfullName']);
            }),
          };
          selectedClassName = '0';
          selectedClassFullName = classData[selectedClassName];
        });
      } else {
        print('No class data available');
      }
    } catch (error) {
      print('Failed to fetch class data: $error');
    }
  }

  Future<void> _fetchGradeData() async {
    try {
      DatabaseEvent event = await databaseGradeRef.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);

        var sortedEntries = data.entries.toList()
          ..sort((a, b) {
            var aInfo = Map<String, dynamic>.from(a.value as Map);
            var bInfo = Map<String, dynamic>.from(b.value as Map);
            return int.parse(aInfo['GradeYear']).compareTo(int.parse(bInfo['GradeYear']));
          });

        setState(() {
          gradeData = {
            '0': 'ค้นหาปี',
            ...Map.fromEntries(sortedEntries.map((entry) {
              final gradeInfo = Map<String, dynamic>.from(entry.value as Map);
              return MapEntry(gradeInfo['GradeYearName'], gradeInfo['GradeYear']);
            })),
          };
          selectedGradeYear = '0';
          selectedGradeYearName = gradeData[selectedGradeYear];
        });
      } else {
        print('No grade data available');
      }
    } catch (error) {
      print('Failed to fetch grade data: $error');
    }
  }

  Future<void> _fetchUserData(String selectedclassName, String selectedgradeYear) async {
    try {
      DatabaseEvent event = await databaseUserRef.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
        List<Map<dynamic, dynamic>> filteredUsers = [];

        for (var userId in users.keys) {
          var user = users[userId];
          String userClass = user['user_class'];
          String userIdStudent = user['user_id_student'];
          int minTimeInt = 0;

          final minTime = user['minTime'];

          if (minTime is int) {
            minTimeInt = minTime;
          } else if (minTime is String) {
            minTimeInt = int.tryParse(minTime) ?? 0;
          }

          final minTimeHours = minTimeInt ~/ 60;
          final minTimeMinutes = minTimeInt % 60;

          _minTimeFormatted = minTimeMinutes == 0
              ? '$minTimeHours ชั่วโมง'
              : '$minTimeHours ชั่วโมง $minTimeMinutes นาที';

          if (userClass.contains(selectedclassName) && userIdStudent.startsWith(selectedgradeYear)) {
            user['minTime'] = _minTimeFormatted;
            filteredUsers.add(user);
          }
        }

        filteredUsers.sort((a, b) => a['user_id_student'].compareTo(b['user_id_student']));

        setState(() {
          _userData = filteredUsers;
        });
      } else {
        print('No user data available.');
      }
    } catch (error) {
      print('Failed to fetch user data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ค้นหานักศึกษา', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange[200]!, Colors.orange[50]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'ค้นหาข้อมูลนักศึกษา',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
              SizedBox(height: 20),
              _buildDropdown(
                value: selectedClassFullName,
                hint: 'เลือกสาขา',
                items: classData.values,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedClassFullName = newValue;
                    selectedClassName = classData.entries
                        .firstWhere((entry) => entry.value == newValue)
                        .key;
                  });
                },
              ),
              SizedBox(height: 16.0),
              _buildDropdown(
                value: selectedGradeYearName,
                hint: 'เลือกปีการศึกษา',
                items: gradeData.values,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedGradeYearName = newValue;
                    selectedGradeYear = gradeData.entries
                        .firstWhere((entry) => entry.value == newValue)
                        .key;
                  });
                },
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                child: Text('ค้นหา', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                onPressed: _handleSearch,
              ),
              SizedBox(height: 24.0),
              Expanded(
                child: _userData.isEmpty
                    ? Center(
                        child: Text(
                          'ยังไม่มีข้อมูล กรุณาค้นหา',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _userData.length,
                        itemBuilder: (context, index) {
                          var user = _userData[index];
                          return _buildUserCard(user);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required Iterable<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.orange[700]),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: TextStyle(fontSize: 16)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<dynamic, dynamic> user) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor: Colors.orange[200],
          child: Text(
            user['user_name'][0],
            style: TextStyle(color: Colors.orange[800]),
          ),
        ),
        title: Text(
          '${user['user_name']}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รหัสนักศึกษา: ${user['user_id_student']}'),
            Text('สาขา: ${user['user_class']}'),
            Text('ชั่วโมงที่เก็บได้: ${user['minTime']}'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.orange[700]),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Showdata_history_t_detail(
                user_id_student: user['user_id_student'] ?? '',
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleSearch() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: LoadingAnimationWidget.inkDrop(
            color: Colors.orange[700]!,
            size: 50,
          ),
        );
      },
    );

    String selectedclassName = '$selectedClassName';
    String selectedgradeYear = '$selectedGradeYear';

    if (selectedclassName == '0' || selectedgradeYear == '0') {
      Navigator.pop(context);
      _showErrorSnackBar(
        selectedclassName == '0' ? 'กรุณาเลือกสาขา' : 'กรุณาเลือกชั้นปี',
      );
    } else {
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pop(context);
        _fetchUserData(selectedclassName, selectedgradeYear);
      });
    }
  }

  void _showErrorSnackBar(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'ข้อผิดพลาด',
        message: message,
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}