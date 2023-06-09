import 'dart:convert';

import 'package:captone4/MatchingUser.dart';
import 'package:captone4/Token.dart';
import 'package:captone4/model/GroupRoomListModel.dart';
import 'package:captone4/screen/chat_room_list_screen.dart';
import 'package:captone4/screen/group_chatting_screen.dart';
import 'package:captone4/screen/root_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../const/colors.dart';

class DefaultLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String? title;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;



  const DefaultLayout({
    required this.child,
    this.title,
    this.bottomNavigationBar,
    this.backgroundColor,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<DefaultLayout> createState() => _DefaultLayoutState();
}

class _DefaultLayoutState extends ConsumerState<DefaultLayout> {

  late StompClient? stompClient;
  late Token? token;
  MatchingUser? matchingUser;
  var body;
  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.0),
                Text('매칭 중...',
                  style: TextStyle(
                      fontFamily: 'Pacifico', fontSize: 15),)
              ],
            ),
          ),
        );
      },
    ).then((value) {
      stompClient!.send(destination: '/pub/matching/cancel', body: body);
      stompClient!.deactivate();
    });

  }

  @override
  void initState(){
    super.initState();

    token = ref.read(tokenProvider.notifier).state;
  }

  @override
  void dispose(){
    //취소 하는거 넣어야함

    print("레이아웃 종료");
    try{
      if(stompClient!.connected)
        {

          stompClient?.deactivate();

        }

    }
    catch (e){
      print("error : $e");
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      // 키보드 overflow 방지
      resizeToAvoidBottomInset: false,
      backgroundColor: widget.backgroundColor,
      extendBodyBehindAppBar: true,
      // AppBar 뒤쪽에 화면 보일 수 있게 함.
      appBar: renderAppBar(),
      body: widget.child,
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.bottomNavigationBar != null
          ? FloatingActionButton(
              backgroundColor: PRIMARY_COLOR,
              child: Icon(Icons.favorite_border_outlined),
              onPressed: () async {
                await connectToStomp();
                _showDialog(context);
                print("버튼 눌림");
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  AppBar? renderAppBar() {
    if (widget.title == null) {
      return null;
    } else {
      return AppBar(
        title: Text(
          widget.title!,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Pacifico', fontSize: 30, color: Colors.white),
        ),
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20)),
        ),
        elevation: 0,
        // backgroundColor: Colors.transparent,
      );
    }
  }

  void onConnectCallback(StompFrame connectFrame) {
    int id =  ref.read(tokenProvider.notifier).state.id!;
    String gender =  ref.read(tokenProvider.notifier).state.gender!;
    matchingUser = new MatchingUser(id: id, gender: gender);
    body = json.encode(matchingUser);

    stompClient!.subscribe(
        destination: '/topic/matchingResult',
        callback: (connectFrame){
          Map<String,dynamic> body2 = json.decode(connectFrame.body.toString());
          GroupRoomModel groupRoomModel = GroupRoomModel.fromJson(json: body2);
          // String createAt = groupRoomModel.createAt.toString();
          // DateTime dateTimeCreateAt = DateTime.parse(createAt).toLocal();
          //자기 매칭인지 확인
          if(groupRoomModel.mid1 == token!.id ||
              groupRoomModel.mid2 == token!.id ||
              groupRoomModel.mid3 == token!.id ||
              groupRoomModel.mid4 == token!.id ||
              groupRoomModel.mid5 == token!.id ||
              groupRoomModel.mid6 == token!.id ){
            Navigator.push(context, MaterialPageRoute(builder: (context) => RootTab(token: token, pageIndex: 1,)));
          }
          //자기꺼 맞으면 navigator푸시


    });

    //여기서 멤버 조회로 id값이랑 gender값 가져오기
    //가져온걸 send로 매칭에게 보내기
    stompClient!.send(
        destination: '/pub/matching',body: body);
    print(body);
  }

  connectToStomp(){
    print("매칭 연결");
    stompClient = StompClient(config: StompConfig(
      url: 'ws://ec2-3-34-216-149.ap-northeast-2.compute.amazonaws.com:9090/ws',
      onConnect: onConnectCallback,
    ));
    stompClient!.activate();
  }
}
