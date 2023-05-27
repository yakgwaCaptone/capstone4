import 'dart:ffi';

import 'package:captone4/model/member_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Token.dart';
import '../const/data.dart';

final memberNotifierProvider =
    StateNotifierProvider<MemberNotifier, MemberModel>((ref) {
  final dio = ref.watch(dioProvider);
  final token = ref.watch(tokenProvider);

  return MemberNotifier(
    dio: dio,
    token: token,
  );
});

class MemberNotifier extends StateNotifier<MemberModel> {
  final Dio dio;
  final Token token;

  MemberNotifier({
    required this.dio,
    required this.token,
  }) : super(
          MemberModel(
              memberId: "",
              nickname: "",
              imageUrls: [],
              birthYear: "",
              introduction: "",
              gender: "",
              mbti: "",
              averageScore: 0.0),
        );

  void getMemberInfoFromServer() async {
    print("_getMemberInfoFromServer 실행");
    final dio = Dio();

    try {
      final resp = await dio.get(
        'http://$ip/api/v1/members/${token.id}',
        options: Options(
          headers: {
            'authorization': 'Bearer ${token.accessToken}',
          },
        ),
      );
      print("성공");
      print(resp.data["memberId"].runtimeType);
      state = MemberModel.fromJson(json: resp.data);
      print("멤버 정보 가져오기 성공");
    } on DioError catch (e) {
      print(e);
    }
  }

  void postMemberInfoUpdate(
      String? nickname, String? introduction, String? mbti) async {
    print(" postMemberInfoUpdate 실행");
    final dio = Dio();
    final Map<String, dynamic> json = new Map<String, dynamic>();

    if(nickname != null && state.nickname != nickname)
      json['nickname'] = nickname;

    if(introduction != null)
      json['introduction'] = introduction;

    if(mbti != null)
      json['mbti'] = mbti;

    // {
    //   "nickname": nickname == null ? state.nickname : nickname,
    //   "introduction": introduction == null ? state.introduction : introduction,
    //   "mbti": mbti == null ? state.mbti : mbti,
    // };


    print("json - postMemberInfoUpdate : $json");

    try {
      final resp = await dio.post(
        'http://$ip/api/v1/members/${token.id}',
        data: json,
        options: Options(
          headers: {
            'authorization': 'Bearer ${token.accessToken}',
          },
        ),
      );

      print("resp.data : ${resp.data}");
      state = state.copyWith(json: resp.data);
    } on DioError catch (e) {
      if (e.response!.data['code'] == "DuplicateNicknameException") {
        throw Exception("DuplicateNicknameException");
      }
    }
  }
}