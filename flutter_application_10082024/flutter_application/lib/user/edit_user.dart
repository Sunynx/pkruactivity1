import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class EditUser extends StatefulWidget {
  @override
  _EditUserState createState() => _EditUserState();
}

class _EditUserState extends State<EditUser> {
  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  String? selectedValueUser1;
  String? selectedValueUser2;
  String? selectedValueStatus;

  Map<String, String> userItems = {};

  Future<void> fetchUserData() async {
    final ref = FirebaseDatabase.instance.ref();
    final databaseSnapshot = await ref.child('user').get();

    if (databaseSnapshot.exists) {
      final Map<Object?, Object?>? data =
          databaseSnapshot.value as Map<Object?, Object?>?;
      if (data != null) {
        setState(() {
          userItems.clear();
          data.forEach((key, value) {
            if (value is Map) {
              final userName = value['user_name']?.toString() ?? '';
              final userId = value['user_id_student']?.toString() ?? '';
              if (userId.isNotEmpty && userName.isNotEmpty) {
                userItems[key.toString()] = "$userName\n$userId";
              }
            }
          });
        });
      }
    }
  }

  final Map<String, String> statusItems = {
    's': 'USER - นักศึกษา',
    't': 'Lecturer - อาจารย์',
    'a': 'ADMIN - แอดมิน',
  };

  Future<void> edit_user() async {
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

    DatabaseReference ref1 =
        FirebaseDatabase.instance.ref("user/$selectedValueUser2");

    await ref1.update({
      "status": selectedValueStatus,
    }).then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
      Future.delayed(const Duration(seconds: 1), () {
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
          ..showSnackBar(snackBar);
      });
    }).catchError((error) {
      print('Error updating data: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไขข้อมูลผู้ใช้'),
        backgroundColor: Colors.orange,
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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "ตั้งค่าผู้ใช้",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                SizedBox(height: 30),
                _buildDropdownContainer(
                  icon: Icons.person,
                  child: DropdownSearch<String>(
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      showSelectedItems: true,
                      itemBuilder: (context, item, isSelected) {
                        final parts = item.split(
                            '\n'); // Split based on newline to separate name and ID
                        return ListTile(
                          title: Text(
                            parts[0],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(parts[1]),
                        );
                      },
                    ),
                    items: userItems.values.toList(),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'โปรดเลือก User',
                        hintStyle: TextStyle(
                          color: Colors.orange.shade300,
                        ),
                      ),
                    ),
                    dropdownBuilder: (context, selectedItem) {
                      if (selectedItem != null) {
                        final parts = selectedItem.split(
                            '\n'); // Split based on newline to separate name and ID
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              parts[0],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              parts[1],
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        );
                      } else {
                        return Text(
                          'โปรดเลือก User',
                          style: TextStyle(color: Colors.orange.shade300),
                        );
                      }
                    },
                    onChanged: (value) {
                      setState(() {
                        selectedValueUser1 = value;
                        selectedValueUser2 = userItems.entries
                            .firstWhere((entry) => entry.value == value)
                            .key;
                      });
                    },
                    selectedItem: selectedValueUser1,
                  ),
                ),
                SizedBox(height: 20),
                _buildDropdownContainer(
                  icon: Icons.security,
                  child: DropdownSearch<String>(
                    popupProps: PopupProps.menu(
                      showSearchBox: false,
                      showSelectedItems: true,
                    ),
                    items: statusItems.values.toList(),
                    dropdownDecoratorProps:
                        _dropdownDecorProps('โปรดเลือก Status'),
                    onChanged: (value) {
                      setState(() {
                        selectedValueStatus = statusItems.entries
                            .firstWhere((entry) => entry.value == value)
                            .key;
                      });
                    },
                    selectedItem: selectedValueStatus != null
                        ? statusItems[selectedValueStatus]
                        : null,
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: edit_user,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'บันทึก',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownContainer(
      {required Widget child, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange),
            SizedBox(width: 15),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  DropDownDecoratorProps _dropdownDecorProps(String hintText) {
    return DropDownDecoratorProps(
      dropdownSearchDecoration: InputDecoration(
        border: InputBorder.none,
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.orange.shade300,
        ),
      ),
    );
  }
}
