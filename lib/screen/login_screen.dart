import 'package:captone4/const/colors.dart';
import 'package:captone4/model/member_model.dart';
import 'package:captone4/screen/join_screen.dart';
import 'package:captone4/screen/my_page/profile_screen.dart';
import 'package:captone4/screen/root_tab.dart';
import 'package:captone4/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:captone4/login_platform.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:captone4/Token.dart';
import 'package:captone4/utils/alert.dart';

import '../const/data.dart';
import '../provider/member_profile_provider.dart';
import '../provider/member_provider.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool isLogin = false;
  String? accesToken;
  String? expiresAt;
  String? tokenType;
  String? nickName;
  String? refreshToken;

  bool passwordInvisible = true;

  Token? token;

  LoginPlatform _loginPlatform = LoginPlatform.none;

  final idController = TextEditingController();
  final pwController = TextEditingController();

  void signInWithNaver() async {
    //네이버 로그인 관리
    try {
      final NaverLoginResult result = await FlutterNaverLogin.logIn();
      NaverAccessToken accessTokenRes =
          await FlutterNaverLogin.currentAccessToken;
      //NaverAccessToken res = await FlutterNaverLogin.currentAccessToken;

      if (result.status == NaverLoginStatus.loggedIn) {
        //수정

        setState(() {
          _loginPlatform = LoginPlatform.naver;
          accesToken = accessTokenRes.accessToken;
          expiresAt = accessTokenRes.expiresAt;
          tokenType = accessTokenRes.tokenType;
          refreshToken = accessTokenRes.refreshToken;
          print(accessTokenRes);
          print(result.accessToken.tokenType);
        });
        if (_loginPlatform == LoginPlatform.naver) {
          await naverloginPost("naver");
        }

        if (isLogin == true) {
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;

          // 로그인 성공하면 provider로 토큰 넘김
          ref.read(tokenProvider.notifier).state = token!;

          // 로그인한 유저 프로필정보 받아오기
          final memberProfile = await ref
              .read(memberProfileNotifierProvider.notifier)
              .getProfileImage();

          print("memberProfile");
          print(memberProfile);

          // 만약 프로필이 설정되지 않은 유저라면 -> 신규 유저라고 판단 -> 프로필 및 개인 정보 설정 하도록 ProfileScreen()으로 라우팅
          if (memberProfile.images.isEmpty) {
            print("memberProfile.isEmpty : " +
                memberProfile.images.isEmpty.toString());

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  token: token!,
                  fromLogin: true,
                ),
              ),
            );
          } else {
            // 프로필이 설정되어있는 기존 유저라면 정상적으로 RootTab으로 라우팅
            print("실행");
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RootTab(token: token),
              ),
            );

            if(result == "logout")
              buttonNaverLogoutAndDeleteTokenPressed();
          }

          // 로그인 성공하면 아아디 패스워드 입력해둔거 지우기
          idController.clear();
          pwController.clear();

          // ID,PWD 입력 칸에 Focus 된거 풀어서 자연스럽게 만들기
          FocusScope.of(context).unfocus();
        } else {
          //아이디 비밀번호 확인해달라
          //회원가입하기?
        }
      }
    } catch (error) {
      print(error.toString());
    }
  }

  void signOut() async {
    //여러 로그인 방식 관리
    switch (_loginPlatform) {
      case LoginPlatform.facebook:
        break;
      case LoginPlatform.google:
        break;
      case LoginPlatform.kakao:
        break;
      case LoginPlatform.naver:
        await FlutterNaverLogin.logOut();
        break;
      case LoginPlatform.apple:
        break;
      case LoginPlatform.none:
        break;
    }

    setState(() {
      _loginPlatform = LoginPlatform.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    //화면 제작

    return Scaffold(
      //화면 그리기
      backgroundColor: BACKGROUND_COLOR,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                fit: BoxFit.contain,
                image: AssetImage('assets/images/login_back.png'),
              )),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 50),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.none,
                    image: AssetImage('assets/images/Main_logo.png'),
                  ),
                ),
              ),
            ),
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: getMediaHeight(context) * 0.45,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                      color: Color(0xffFF6961).withOpacity(0.96),
                    ),
                    child: Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            "Sign In",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25.0,
                              fontFamily: 'Pacifico',
                            ),
                          ),
                          // SizedBox(
                          //   width: MediaQuery.of(context).size.width * 2 / 3,
                          //   child: OutlinedButton(
                          //     onPressed: signInWithNaver, //로그인 함수 실행
                          //     child: Text(
                          //       "Naver Login",
                          //       style: TextStyle(
                          //         color: Colors.black,
                          //       ),
                          //     ),
                          //     style: ButtonStyle(
                          //         backgroundColor:
                          //             MaterialStateProperty.all(Colors.white),
                          //         shape: MaterialStateProperty.all<
                          //                 RoundedRectangleBorder>(
                          //             RoundedRectangleBorder(
                          //                 borderRadius:
                          //                     BorderRadius.circular(18.0),
                          //                 side:
                          //                     BorderSide(color: Colors.red)))),
                          //   ),
                          // ),
                          SizedBox(
                            //ID입력
                            width: MediaQuery.of(context).size.width * 2 / 3,
                            height: getMediaHeight(context) * 0.06,
                            child: OutlinedButton(
                              onPressed: buttonLoginPressed,
                              child: TextField(
                                controller: idController,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  icon: Icon(
                                    Icons.person,
                                    color: PRIMARY_COLOR,
                                  ),
                                  hintText: 'ID',
                                ),
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.white),
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                    side: BorderSide(color: Colors.red),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: SizedBox(
                              //password입력
                              width: MediaQuery.of(context).size.width * 2 / 3,
                              height: getMediaHeight(context) * 0.06,
                              child: OutlinedButton(
                                onPressed: buttonLoginPressed,
                                child: TextField(
                                  obscureText: passwordInvisible,
                                  controller: pwController,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    icon: Icon(
                                      Icons.lock,
                                      color: PRIMARY_COLOR,
                                    ),
                                    suffixIcon: IconButton(
                                      splashColor: Colors.transparent,
                                      icon: passwordInvisible
                                          ? Icon(
                                              Icons.visibility,
                                              color: PRIMARY_COLOR,
                                            )
                                          : Icon(
                                              Icons.visibility_off,
                                              color: PRIMARY_COLOR,
                                            ),
                                      onPressed: () {
                                        setState(() {
                                          passwordInvisible =
                                              !passwordInvisible;
                                        });
                                      },
                                    ),
                                    hintText: 'Password',
                                  ),
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                                style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all(Colors.white),
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18.0),
                                            side: BorderSide(
                                                color: Colors.red)))),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 2 / 3,
                            child: OutlinedButton(
                              onPressed: buttonLoginPressed,
                              child: Text(
                                "회원 로그인",
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.white),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18.0),
                                          side:
                                              BorderSide(color: Colors.red)))),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "가입해둔 계정이 없으신가요 ? ",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  memberJoin();
                                },
                                child: Text(
                                  "회원가입",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFD9D9D9),
                                  height: 1.5,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  "OR",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFD9D9D9),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              signInWithNaver();
                            },
                            child: Container(
                              height: getMediaHeight(context) * 0.052,
                              width: getMediaWidth(context) * 0.45,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: AssetImage(
                                          'assets/images/naver_login_btn.png'))),
                            ),
                            // Container(
                            //   padding: EdgeInsets.all(20),
                            //   decoration: BoxDecoration(
                            //     image: DecorationImage(
                            //       image: AssetImage(
                            //           'assets/images/icons/naver_icon.png'),
                            //     ),
                            //     color: Colors.white,
                            //     border: Border.all(
                            //       width: 2,
                            //       // color: Color(0xFF1EC800),
                            //       color: Colors.white,
                            //     ),
                            //     shape: BoxShape.circle,
                            //   ),
                            // ),
                          ),
                          // SizedBox(
                          //   width:
                          //   MediaQuery.of(context).size.width * 1 / 4,
                          //   child: OutlinedButton(
                          //     onPressed: memberJoin,
                          //     child: Text(
                          //       "회원가입",
                          //       style: TextStyle(
                          //         color: Colors.black,
                          //       ),
                          //     ),
                          //     style: ButtonStyle(
                          //       backgroundColor:
                          //       MaterialStateProperty.all(Colors.white),
                          //       shape: MaterialStateProperty.all<
                          //           RoundedRectangleBorder>(
                          //         RoundedRectangleBorder(
                          //           borderRadius:
                          //           BorderRadius.circular(18.0),
                          //           side: BorderSide(color: Colors.red),
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> loginPost(String userId, String password) async {
    var url = CATCHME_URL +"/api/v1/login";
    try {
      Map data = {"userId": userId, "password": password};

      var body = json.encode(data);

      final response = await http.post(Uri.parse(url),
          headers: <String, String>{"Content-Type": "application/json"},
          body: body);
      if (response.statusCode == 200) {
        print('일반 로그인 토큰 발행');
        token = Token.fromJson(json.decode(response.body));
        print(token?.gender);
        if (token != null) {
          isLogin = true;
        }
      } else {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Alert.showAlert(context, "로그인 오류", "아이디 혹은 비밀번호를 확인해 주세요");
        throw Exception('로그인 오류');
      }
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> naverloginPost(String type) async {
    var url = CATCHME_URL + "/api/v1/oauth/login";
    try {
      Map data = {"accessToken": accesToken, "type": type};

      var body = json.encode(data);

      final response = await http.post(Uri.parse(url),
          headers: <String, String>{"Content-Type": "application/json"},
          body: body);
      if (response.statusCode == 200) {
        print('네이버 로그인 토큰 발행');
        token = Token.fromJson(json.decode(response.body));
        print(token);
        if (token != null) {
          isLogin = true;
        }
      } else {
        throw Exception('로그인 오류');
      }
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void>
      buttonLoginPressed() async //일반 로그인 실행 - 서버 요청 토큰 받아와 return token
  {
    String userId = idController.text;
    String password = pwController.text;

    print(userId);
    print(password);

    await loginPost(userId, password);

    if (isLogin == true) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      // 로그인 성공하면 provider로 토큰 넘김
      ref.read(tokenProvider.notifier).state = token!;

      // 로그인한 유저 프로필정보 받아오기
      final memberProfile = await ref
          .read(memberProfileNotifierProvider.notifier)
          .getProfileImage();

      print("memberProfile");
      print(memberProfile);

      // 만약 프로필이 설정되지 않은 유저라면 -> 신규 유저라고 판단 -> 프로필 및 개인 정보 설정 하도록 ProfileScreen()으로 라우팅
      if (memberProfile.images.isEmpty) {
        print("memberProfile.isEmpty : " +
            memberProfile.images.isEmpty.toString());

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              token: token!,
              fromLogin: true,
            ),
          ),
        );
      } else {
        // 프로필이 설정되어있는 기존 유저라면 정상적으로 RootTab으로 라우팅
        print("실행");
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => RootTab(token: token)));
      }

      // 로그인 성공하면 아아디 패스워드 입력해둔거 지우기
      idController.clear();
      pwController.clear();

      // ID,PWD 입력 칸에 Focus 된거 풀어서 자연스럽게 만들기
      FocusScope.of(context).unfocus();
    } else {}
  }

  Future<void> buttonNaverLoginPressed() async //로그인 눌렀을때 동작
  {
    try {
      final NaverLoginResult res = await FlutterNaverLogin.logIn();
      setState(() {
        nickName = res.account.nickname;
        isLogin = true;
      });
    } catch (error) {
      print(error.toString());
    }
  }

  Widget _loginButton(String path, VoidCallback onTap) //네이버 로그인 버튼
  {
    return ElevatedButton(
      onPressed: signInWithNaver,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(
          const Color(0xff0165E1),
        ),
      ),
      child: const Text('네이버 로그인'),
    );
  }

  Widget _logoutButton() {
    if (_loginPlatform == LoginPlatform.none) {
      return const SizedBox.shrink();
    } else {
      return ElevatedButton(
        onPressed: signOut,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(
            const Color(0xff0165E1),
          ),
        ),
        child: const Text('로그아웃'),
      );
    }
  }

  void _showSnackError(String error) {
    snackbarKey.currentState?.showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(error.toString()),
      ),
    );
  }

  Future<void> buttonNaverLogoutAndDeleteTokenPressed() async {
    print("buttonNaverLogoutAndDeleteTokenPressed 실행");
    //로그아웃 및 토큰 제거
    try {
      await FlutterNaverLogin.logOutAndDeleteToken();
      setState(() {
        isLogin = false;
        accesToken = null;
        tokenType = null;
        nickName = null;
      });
    } catch (error) {
      _showSnackError(error.toString());
    }
  }

  Future<void> buttonLogoutPressed() async {
    print("buttonLogoutPressed 실행");
    //로그아웃만
    try {
      await FlutterNaverLogin.logOut();
      setState(() {
        isLogin = false;
        accesToken = null;
        tokenType = null;
        nickName = null;
      });
    } catch (error) {
      _showSnackError(error.toString());
    }
  }

  void memberJoin() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const joinScreen()));
  }
}
