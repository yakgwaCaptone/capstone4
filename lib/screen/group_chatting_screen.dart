import 'dart:async';
import 'dart:convert';
import 'package:captone4/chat/message.dart';
import 'package:captone4/chat/new_message.dart';
import 'package:captone4/provider/time_provider.dart';
import 'package:captone4/screen/chat_room_list_screen.dart';
import 'package:captone4/utils/utils.dart';
import 'package:captone4/widget/poll.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../Token.dart';
import '../chat/chat_bubble.dart';
import '../const/data.dart';
import '../model/ChattingHistoryModel.dart';
import '../model/GroupRoomListModel.dart';
import '../model/member_model.dart';

class GroupChattingScreen extends ConsumerStatefulWidget {
  final Token? token;
  final GroupRoomModel? roomData;
  DateTime? createTime;
  List? midList;

  GroupChattingScreen(
      {required this.createTime,
      required this.roomData,
      required this.midList,
      Key? key,
      @required this.token})
      : super(key: key);

  @override
  ConsumerState<GroupChattingScreen> createState() =>
      _GroupChattingScreenState();
}

class ChatMessage {
  String? type;
  String? roomId;
  String? sender;
  String? message;
  String? roomType;

  Map<String, dynamic> toJson() => {
        'type': type,
        'roomId': roomId,
        'sender': sender,
        'message': message,
        'roomType': roomType,
      };

  ChatMessage(
      {required this.type,
      required this.roomId,
      required this.sender,
      required this.message,
      required this.roomType});

  factory ChatMessage.fromJson({required Map<String, dynamic> json}) {
    return ChatMessage(
        type: json['type'],
        roomId: json['roomId'],
        sender: json['sender'],
        message: json['message'],
        roomType: json['roomType'].map<ChatMessage>(
          (x) => ChatMessage.fromJson(json: x),
        ));
  }
}

class _GroupChattingScreenState extends ConsumerState<GroupChattingScreen> {
  late int _memberId;
  late String _memberToken;
  late String senderImage;
  late String senderGender;
  late GroupRoomModel groupRoomModel;
  late String userGender;
  var _userEnterMessage = '';

  bool _visibility = true;
  late Timer _timer;
  Duration? timeDiff = null;
  int time = 0;
  int defaultTime = 900;
  bool scrollMax = false;

  List<String> midGender = [];

  late StompClient _stompClient;

  TextEditingController messageController = TextEditingController();
  List<DateTime> roomCreateTimeList = [];
  late ScrollController _scrollController;
  List<String> img_ = [
    'https://static.wikia.nocookie.net/line/images/b/bb/2015-brown.png/revision/latest?cb=20150808131630',
    'https://static.wikia.nocookie.net/line/images/1/10/2015-cony.png/revision/latest?cb=20150806042102',
    'https://static.wikia.nocookie.net/line/images/a/af/Image-1.jpg/revision/latest?cb=20151124042517',
    'https://static.wikia.nocookie.net/line/images/4/4c/IMG_3360.JPG/revision/latest?cb=20221209161733',
    'https://static.wikia.nocookie.net/line/images/6/64/2015-jessica.png/revision/latest?cb=20150804060241',
    'https://static.wikia.nocookie.net/line/images/2/2f/2015-james.png/revision/latest?cb=20151224075718'
  ];

  List<ChattingHistory> chatHistoryList = [];

  late Token _token;

  Future<ChattingHistoryListModel> getGroupChatRecord() async {
    print("Get chat record's information");
    final dio = Dio();

    try {
      final response = await dio.get(
        CHATTING_API_URL +
            '/api/v1/group_records?groupId=${widget.roomData!.id.toString()}',
      );
      return ChattingHistoryListModel.fromJson(json: response.data);
    } on DioError catch (e) {
      print('error: $e');
      rethrow;
    }
  }

  Future<MemberModel> getUserGender() async {
    print("Get user's information");
    final dio = Dio();

    try {
      final getGender = await dio.get(
        CATCHME_URL + '/api/v1/members/${_memberId}',
        options: Options(
          headers: {'authorization': 'Bearer ${_memberToken}'},
        ),
      );
      return MemberModel.fromJson(json: getGender.data);
    } on DioError catch (e) {
      print('error: $e');
      rethrow;
    }
  }

  late String jerryGender;
  late int jerryId;

  void renderUserGenderBuild() async {
    MemberModel memberModel = await getUserGender();
    userGender = memberModel.gender;
    midGender.clear();
    if (widget.roomData!.mid1 == _memberId ||
        widget.roomData!.mid2 == _memberId ||
        widget.roomData!.mid5 == _memberId ||
        widget.roomData!.mid6 == _memberId) {
      if (userGender == 'M') {
        midGender.add("M");
        midGender.add("M");
        midGender.add("W");
        midGender.add("W");
        midGender.add("M");
        midGender.add("M");
      } else {
        midGender.add("W");
        midGender.add("W");
        midGender.add("M");
        midGender.add("M");
        midGender.add("W");
        midGender.add("W");
      }
    } else if (widget.roomData!.mid3 == _memberId ||
        widget.roomData!.mid4 == _memberId) {
      if (userGender == 'M') {
        midGender.add("W");
        midGender.add("W");
        midGender.add("M");
        midGender.add("M");
        midGender.add("W");
        midGender.add("W");
      } else {
        midGender.add("M");
        midGender.add("M");
        midGender.add("W");
        midGender.add("W");
        midGender.add("M");
        midGender.add("M");
      }
    }

    for (int i = 0; i < 6; i++) {
      if (widget.midList![i] == widget.roomData!.jerry_id) {
        if (midGender[i] == "M") {
          midGender[i] = "W";
        } else {
          midGender[i] = "M";
        }
        debugPrint("jerry id ${widget.roomData!.jerry_id} ${midGender[i]}");

        jerryGender = midGender[i];
        jerryId = widget.roomData!.jerry_id;
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    _scrollController = ScrollController();
    super.initState();

    _memberId = widget.token!.id!;
    _memberToken = widget.token!.accessToken!;

    if (widget.createTime != null) {
      timeDiff = DateTime.now().difference(widget.createTime!);
      // timeDiff = DateTime.now().difference(DateTime.now());
      // print("widget create Time ${DateTime.now().difference(DateTime.now())}");

      setState(
        () {
          if ((defaultTime - timeDiff!.inSeconds) > 0) {
            time = defaultTime - timeDiff!.inSeconds;
          } else {
            _visibility = false;
          }
        },
      );
    }

    _handleTimer();
    print("남은 시간 ${time}");

    DateTime room0CreateTime = DateTime.now(); // 임시로 현재 시간을 채팅방0 생성 시간으로 설정
    roomCreateTimeList.add(room0CreateTime); // 시간 리스트에 저장

    connectToStomp(); //stomp 연결
    print("웹 소캣 연결");
  }

  void connectToStomp() {
    _stompClient = StompClient(
        config: StompConfig(
      url: CHATTING_WS_URL, // Spring Boot 서버의 WebSocket URL
      onConnect: onConnectCallback,
    ) // 연결 성공 시 호출되는 콜백 함수
        );
    _stompClient.activate();
    print("chating 연결성공");
  }

  void onConnectCallback(StompFrame connectFrame) {
    //decoder, imgurl 앞에서 받아올것
    _stompClient.subscribe(
      //메세지 서버에서 받고 rabbitmq로 전송
      destination: '/topic/room.Multi' + widget.roomData!.id.toString(),
      headers: {"auto-delete": "true"},
      callback: (connectFrame) {
        print("connectFrame.body 출력 :");
        print(connectFrame.body); //메시지를 받았을때!
        setState(() {
          Map<String, dynamic> chat =
              (json.decode(connectFrame.body.toString()));

          ChatMessage? chatMessage;
          chatMessage?.type = chat["type"];
          chatHistoryList.add(ChattingHistory(
            id: chatHistoryList.last.id + 1,
            type: "TALK",
            roomId: widget.roomData!.id.toString(),
            sender: chat["sender"],
            message: chat["message"],
            roomType: "Multi",
            send_time: DateTime.now().toString(),
          ));

          chatMessage?.roomId = chat["roomId"];
          /*_name.add(chat["sender"] != _memberId.toString()
              ? widget.nickname
              : memberState.nickname);
          _sender.add(chat["sender"]);*/
          chatMessage?.roomType = chat["roomType"];

          scrollListToEnd();
        });
      },
    );
  }

  void sendMessage() {
    //encoder
    FocusScope.of(context).unfocus();
    String message = messageController.text;
    print("body출력");
    print(widget.roomData!.id.toString());

    ChatMessage chatMessage = ChatMessage(
        type: "TALK",
        roomId: widget.roomData!.id.toString(),
        sender: _memberId.toString(),
        message: message,
        roomType: "Multi");
    print(chatMessage);
    var body = json.encode(chatMessage);
    print(body);

    setState(() {
      _stompClient.send(
        // headers: {"auto-delete": "false", "id": "${_memberId}", "durable": "true"},
        destination: '/app/chat.enter.Multi' + widget.roomData!.id.toString(),
        // Spring Boot 서버의 메시지 핸들러 엔드포인트 경로  abc방에 보낸다
        body: body,
      );
    });

    print("전송!");

    scrollListToEnd();
    messageController.clear();
    _userEnterMessage = '';
  }

  void scrollListToEnd() {
    if (scrollMax) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _stompClient.deactivate();
    if (_stompClient.isActive) {
      _stompClient.deactivate();
    }
    super.dispose();
    if (_timer.isActive) _timer.cancel();
    print("dispose");

    // ref.read(TimerProvider.notifier).cancel();
    // ref.read(TimerProvider.notifier).pause();
  }

  void _handleTimer() {
    _timer = Timer.periodic(
      Duration(seconds: 1),
      (timer) {
        setState(() {
          if (time <= 0) {
            _visibility = false;
            _timer.cancel();
          } else {
            time = time - 1;
          }
        });
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      actions: [
        IconButton(
          icon: Icon(
            Icons.exit_to_app_sharp,
            color: Colors.black,
          ),
          onPressed: () {
            ChatRoomScreen();
          },
        )
      ],
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          colors: [
            Color(0xffFF6961),
            Color(0xffFF6961),
            Color(0xffFF6961),
            Color(0xffFF6961),
          ],
        )),
      ),
      title: Container(
        padding: EdgeInsets.only(top: 0, bottom: 0, right: 0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.only(top: 0, bottom: 0, right: 0),
              child: InkWell(
                child: SizedBox(
                  width: getMediaWidth(context) * 0.1,
                  height: getMediaHeight(context) * 0.1,
                  child: CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/images/information_image.png'),
                  ),
                ),
              ),
            ), // 채팅창 앱바 프로필 사진 파트
            Container(
              width: getMediaWidth(context) * 0.5,
              padding: const EdgeInsets.only(top: 0, bottom: 0, right: 0),
              child: Row(
                children: [
                  SizedBox(
                    width: getMediaWidth(context) * 0.2,
                    height: getMediaHeight(context) * 0.04,
                    child: GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          Text(
                            '채팅방',
                            style: TextStyle(
                              fontFamily: 'Avenir',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: getMediaWidth(context) * 0.1,
                  ),
                  Text(
                    "${(time / 60).toInt()}",
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    ':',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    (time % 60).toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15,
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

  @override
  Widget build(BuildContext context) {
    ScrollController _scrollController = ScrollController();
    renderUserGenderBuild();
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Container(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    child: FutureBuilder<ChattingHistoryListModel>(
                      future: getGroupChatRecord(),
                      builder: (_,
                          AsyncSnapshot<ChattingHistoryListModel> snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              snapshot.error.toString(),
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.data! != 0) {
                          // return _renderSingleRoomListView(snapshot.data!, indexNum);
                          ChattingHistoryListModel chattingHistoryListModel =
                              snapshot.data!;

                          if (chattingHistoryListModel.count != 0) {
                            chatHistoryList = List.from(
                                snapshot.data!.chattingHistory!.reversed);

                            SchedulerBinding.instance.addPostFrameCallback((_) {
                              _scrollController.jumpTo(
                                  _scrollController.position.maxScrollExtent);
                            });

                            return ListView.builder(
                              controller: _scrollController,
                              itemCount: chattingHistoryListModel.count,
                              itemBuilder: (context, index) {
                                print(
                                    "chatHistoryList[index].sender = ${chatHistoryList[index].sender}");

                                int genderIndex = 0;

                                /*chatHistoryList[index].sender가 midList에 몇번째에 있는지 보고 해당 숫자의
                              midGender 리스트 번째에 있는 값이 "W"면 여자x "M"이면 남자x를 ChatBubbles에 넘길 수 있게 해줘
                              예를 들어  chatHistoryList[index].sender가 1 이고 midList가[5,6,1,2,3,4]이고
                              midGender가 [W,W,M,M,W,W]이면 "여기"부분의 값이 남자3이 넘어가게 해줘*/

                                /* List<int> myList = [10, 20, 30, 40, 50];
                              int value = 30;
                              int index = myList.indexOf(value);
                              print(index);*/

                                print("genderIdx = $genderIndex");
                                return ChatBubbles(
                                  chatHistoryList[index].message,
                                  chatHistoryList[index].sender ==
                                      _memberId.toString(),
                                  getName(
                                    chatHistoryList[index].sender,
                                  ),
                                  getimg(
                                    chatHistoryList[index].sender,
                                  ),
                                );
                              },
                            );
                          } else {
                            return Center(
                              child: Text("해당 정보가 없습니다."),
                            );
                          }
                        } else {
                          return Center(
                            child: Text("해당 정보가 없습니다."),
                          );
                        }
                      },
                    ),
                  ),
                ),
                Visibility(
                  visible: _visibility,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            maxLines: null,
                            controller: messageController,
                            decoration: const InputDecoration(
                                labelText: 'Send a message...'),
                            onChanged: (value) {
                              setState(() {
                                // 이렇게 설정하면 변수에다가 입력된 값이 바로바로 들어가기 때문에 send 버튼 활성화,비활성화 설정가능
                                _userEnterMessage = value;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          // 텍스트 입력창에 텍스트가 입력되어 있을때만 활성화 되게 설정
                          onPressed: _userEnterMessage.trim().isEmpty
                              ? null
                              : sendMessage,
                          // 만약 메세지 값이 비어있다면 null을 전달하여 비활성화하고 값이 있다면 활성화시킴
                          icon: const Icon(Icons.send),
                          // 보내기 버튼
                          color: Colors.blue,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          PollsDemo(chatTime: time),
        ],
      ),
    );
  }

  String getimg(String sender) {
    for (int i = 0; i < 6; i++) {
      if (widget.midList![i].toString() == sender) {
        return img_[i];
      }
    }
    return "";
  }

  String getName(String sender) {
    for (int i = 0; i < 6; i++) {
      if (widget.midList![i].toString() == sender) {
        if (midGender[i] == 'M') {
          i++;
          return "남자" + i.toString();
        }
        if (midGender[i] == 'W') {
          i++;
          return "여자" + i.toString();
        }
      }
    }

    return "";
  }
}
