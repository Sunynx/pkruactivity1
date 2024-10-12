import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class ShowdataHistory_s extends StatefulWidget {
  final String user_id_student;

  ShowdataHistory_s({required this.user_id_student});

  @override
  _ShowdataHistory_sState createState() => _ShowdataHistory_sState();
}

class _ShowdataHistory_sState extends State<ShowdataHistory_s> {
  final databaseActivity_detail_Ref = FirebaseDatabase.instance.ref().child('activity_detail');
  final databaseActivityRef = FirebaseDatabase.instance.ref().child('activity');

  Future<Map<String, dynamic>> fetchactivity_data(String user_id_student) async {
    final detailSnapshot = await databaseActivity_detail_Ref.get();
    Map<String, dynamic> result = {};

    if (detailSnapshot.exists) {
      final detailData = detailSnapshot.value as Map<dynamic, dynamic>?;

      if (detailData != null) {
        for (var key in detailData.keys) {
          final list = detailData[key] as List<dynamic>?;
          if (list != null && list.contains(user_id_student)) {
            final activitySnapshot = await databaseActivityRef.child(key).get();

            if (activitySnapshot.exists) {
              final activityData = activitySnapshot.value as Map<dynamic, dynamic>?;

              if (activityData != null) {
                final nameActivity = activityData['name_activity'] as String?;
                final activityTime = activityData['activit_Time'] as String?;
                final activityimageUrl = activityData['imageUrl'] as String?;

                if (nameActivity != null && activityTime != null && activityimageUrl != null) {
                  result[key] = {
                    'name_activity': nameActivity,
                    'activit_Time': activityTime,
                    'activityimageUrl': activityimageUrl
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

    return result;
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('ประวัติเข้าร่วมกิจกรรม'),
      backgroundColor: Colors.orange,
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: fetchactivity_data(widget.user_id_student),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('ยังไม่ได้เข้าร่วมกิจกรรม'));
        } else {
          var data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              String key = data.keys.elementAt(index);
              var activity = data[key];

              // แปลง activit_Time จากนาทีเป็นชั่วโมงและนาที
              int activityTimeInMinutes = int.parse(activity['activit_Time']);
              int hours = activityTimeInMinutes ~/ 60;
              int minutes = activityTimeInMinutes % 60;

              String activityImageUrl = activity['activityimageUrl'];

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Image.network(
                    activityImageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    activity['name_activity'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('ชั่วโมงกิจกรรม: ${hours} ชั่วโมง ${minutes} นาที'),
                ),
              );
            },
          );
        }
      },
    ),
  );
}


}
