import 'package:captone4/const/colors.dart';
import 'package:captone4/screen/login_screen.dart';
import 'package:captone4/widget/default_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:captone4/NumberFormatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:captone4/utils/alert.dart';
import '../const/data.dart';
import '../validate.dart';

class joinScreen extends StatefulWidget {
  const joinScreen({Key? key}) : super(key: key);

  @override
  State<joinScreen> createState() => _joinScreenState();
}

enum Gender { male, female }

class _joinScreenState extends State<joinScreen> {
  final idController = TextEditingController();
  final pwController = TextEditingController();
  final pwCheckController = TextEditingController();
  final nicknameController = TextEditingController();
  final phoneController = TextEditingController();
  final eMailController = TextEditingController();
  final birthYearController = TextEditingController();
  List<String> _year = [];
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _checkPasswordFocus = FocusNode();
  Gender? _gender = Gender.male; //남자 더많으니 처음에 남자로 세팅

  String selectedYear = "";

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
        title: "Sign Up",
        backgroundColor: BACKGROUND_COLOR,
        child: SafeArea(
          child: SingleChildScrollView(
              child: Form(
            key: formKey,
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.only(top: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 4 / 5,
                    margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: TextField(
                      textInputAction: TextInputAction.next,
                      controller: idController,
                      decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          labelText: 'ID',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          )),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 4 / 5,
                    margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: TextFormField(
                      textInputAction: TextInputAction.next,
                      obscureText: true,
                      focusNode: _passwordFocus,
                      keyboardType: TextInputType.visiblePassword,
                      controller: pwController,
                      validator: (value) => CheckValidate()
                          .validatePassword(_passwordFocus, value!),
                      decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          labelText: '비밀번호',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          )),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 4 / 5,
                    margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: TextFormField(
                      textInputAction: TextInputAction.next,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      controller: pwCheckController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력하세요';
                        } else if (value != pwController.text) {
                          return '비밀번호가 일치하지 않습니다.';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          labelText: '비밀번호 확인',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          )),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 4 / 5,
                    margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: TextFormField(
                      textInputAction: TextInputAction.next,
                      controller: phoneController,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        //숫자만!
                        NumberFormatter(),
                        // 자동하이픈
                        LengthLimitingTextInputFormatter(13)
                        //13자리만 입력받도록 하이픈 2개+숫자 11개
                      ],
                      decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          labelText: '휴대폰 번호',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          )),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 4 / 5,
                    margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: TextFormField(
                      textInputAction: TextInputAction.next,
                      controller: eMailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          labelText: 'e-mail',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          )),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 4 / 5,
                    margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: TextFormField(
                      textInputAction: TextInputAction.next,
                      controller: nicknameController,
                      decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          labelText: 'nickname',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          )),
                    ),
                  ),
                  Text(
                    '성별',
                    style: TextStyle(fontSize: 20.0),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 4 / 5,
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('남자'),
                          leading: Radio<Gender>(
                            value: Gender.male,
                            groupValue: _gender,
                            onChanged: (Gender? value) {
                              setState(() {
                                _gender = value;
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text('여자'),
                          leading: Radio<Gender>(
                            value: Gender.female,
                            groupValue: _gender,
                            onChanged: (Gender? value) {
                              setState(() {
                                _gender = value;
                              });
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 4 / 5,
                    margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: TextFormField(
                      readOnly: true,
                      controller: birthYearController,
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        labelText: '출생년도',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                      onTap: () {
                        FocusScope.of(context).requestFocus(new FocusNode());

                        CupertinoRoundedDatePicker.show(
                          context,
                          fontFamily: "Pacifico",
                          textColor: Colors.white,
                          // era: EraMode.BUDDHIST_YEAR,
                          background: PRIMARY_COLOR,
                          borderRadius: 16,
                          minimumYear: 1950,
                          maximumYear: 2023,
                          initialDatePickerMode: CupertinoDatePickerMode.date,
                          onDateTimeChanged: (newDateTime) {
                            setState(() {
                              selectedYear = newDateTime.year.toString();
                              birthYearController.text =
                                  "${newDateTime.year}년 ${newDateTime.month}월 ${newDateTime.day}일";
                            });
                          },
                        );
                      },
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        String gender = _gender == Gender.male ? "M" : "W";

                        joinPost(
                          idController.text,
                          pwController.text,
                          phoneController.text,
                          eMailController.text,
                          nicknameController.text,
                          selectedYear,
                          gender,
                        );
                      }
                    },
                    child: const Text('회원가입'),
                  )
                ],
              ),
            ),
          )),
        ));
  }

  Future<void> joinPost(String userId, String password, String phoneNumber,
      String email, String nickName, String birthYear, String gender) async {
    var url = CATCHME_URL + "/api/v1/join";
    try {
      Map data = {
        "userId": userId,
        "password": password,
        "phoneNumber": phoneNumber,
        "email": email,
        "nickname": nickName,
        "birthYear": birthYear,
        "gender": gender
      };

      var body = json.encode(data);
      print(data);
      final response = await http.post(Uri.parse(url),
          headers: <String, String>{"Content-Type": "application/json"},
          body: body);
      if (response.statusCode == 200) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        await Alert.showAlert(context, "로그인 완료", "로그인 화면으로 넘어갑니다.");
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const LoginScreen()));
      } else {
        print(response);
        print(data);

        throw Exception('로그인 오류');
      }
    } catch (e) {
      print(e);
      rethrow;
    }
  }
}
