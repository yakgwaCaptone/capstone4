import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:captone4/const/data.dart';
import 'package:captone4/model/GroupRoomListModel.dart';
import 'package:captone4/screen/chat_room_list_screen.dart';
import 'package:captone4/screen/favorite_list_screen.dart';
import 'package:captone4/screen/main_page_screen.dart';
import 'package:captone4/screen/my_page/my_page_screen.dart';
import 'package:captone4/widget/default_layout.dart';
import 'package:flutter/material.dart';
import 'package:captone4/Token.dart'; //토큰 클래스
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../const/colors.dart';

class RootTab extends StatefulWidget {
  final Token? token;
  final int? pageIndex;

  const RootTab({
    Key? key,
    @required this.token,
    this.pageIndex,
  }) : super(key: key);

  @override
  State<RootTab> createState() => _RootTabState();
}

class _RootTabState extends State<RootTab> with TickerProviderStateMixin {
  late TabController controller;
  int _bottomNavIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = TabController(length: 4, vsync: this);
    controller.addListener(tabListener);

    if(widget.pageIndex != null){
      _bottomNavIndex = widget.pageIndex!;
    }

  }

  @override
  void dispose() {
    // TODO: implement dispose
    // print("메인 stomp 연결해제");
    controller.removeListener(tabListener);
    super.dispose();
  }

  void tabListener() {
    setState(() {
      _bottomNavIndex = controller.index;
    });
  }

  List<ImageIcon> iconList = [
    //list of icons that required by animated navigation bar.
    ImageIcon(AssetImage('assets/images/icons/main_icon.png')),
    ImageIcon(AssetImage('assets/images/icons/chat_icon.png')),
    ImageIcon(AssetImage('assets/images/icons/favorite_icon.png')),
    ImageIcon(AssetImage('assets/images/icons/my_page_icon.png')),
  ];

  List<Icon> tmp = [];

  List<String> iconText = [
    "Main",
    "Chat",
    "Favorite",
    "My Page",
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      // backgroundColor: BACKGROUND_COLOR,
      child: TabBarView(
        physics: NeverScrollableScrollPhysics(),
        controller: controller,
        children: [
          MainPageScreen(token: widget.token!),
          ChatRoomScreen(token: widget.token!),
          FavoriteListScreen(token: widget.token!),
          MyPageScreen(
            token: widget.token!,
          ),
        ],
      ),
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        notchSmoothness: NotchSmoothness.softEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        gapLocation: GapLocation.center,
        itemCount: iconList.length,
        borderColor: Colors.grey,
        borderWidth: 0.5,
        // splashSpeedInMilliseconds: 20,
        tabBuilder: (int index, bool isActive) {
          // final color = isActive ? Colors.red : Colors.green;
          return Column(
            // mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconList[index],
              const SizedBox(height: 4),
            ],
          );
        },
        onTap: (int index) {
          controller.animateTo(index);
        },
        activeIndex: _bottomNavIndex,
      ),
    );
  }
}
