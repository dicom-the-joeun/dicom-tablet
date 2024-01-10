import 'dart:convert';

import 'package:dicom_image_control_app/data/shared_handler.dart';
import 'package:dicom_image_control_app/model/series_tab.dart';
import 'package:dicom_image_control_app/model/study_tab.dart';
import 'package:dicom_image_control_app/static/search_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class HomeVM extends GetxController {
  List<StudyTab> studies = [];
  List<StudyTab> seriesList = [];
  List<StudyTab> filterStudies = [];
  String token = '';



  @override
  void onInit() async {
    super.onInit();
    token = await SharedHandler().fetchData();
    studies = await getStudyTabList();
    update();
  }

  final modalityList = staticEquipmentList;
  final examStatusList = staticVerifyList;
  final reportStatusList = staticDecipherList;

  /// textField controller
  TextEditingController userIDController = TextEditingController();
  TextEditingController userNameController = TextEditingController();

  /// 드롭다운 선택값 변수 목록
  String selectedModality = staticEquipmentList[0];
  String selectedExamStatus = staticVerifyList[0];
  String selectedReportStatus = staticDecipherList[0];

  /// 캘린더 선택날짜
  DateTime selectedDay = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  /// 검사일자 시작일, 종료일 초기값
  DateTime startDay = DateTime(2000, 1, 1);
  DateTime endDay = DateTime.now();

  /// 검사일자 변경 함수
  Future<DateTime> updateDatePicker(context, DateTime inputDay) async {
    DateTime day = (await showDatePicker(
          context: context,
          firstDate: DateTime(2000, 1, 1),
          lastDate: DateTime(2099, 12, 31),
          currentDate: inputDay,
        )) ??
        inputDay;
    update();
    return day;
  }

  /// 드롭다운 선택 시 선택값 변경 함수
  selectDropDown(String value, List<String> itemList) {
    if (itemList == modalityList) {
      selectedModality = value;
    } else if (itemList == examStatusList) {
      selectedExamStatus = value;
    } else {
      selectedReportStatus = value;
    }
    update();
  }

  /// 검색 조건 초기화 함수
  resetValues() {
    selectedModality = '장비 종류';
    selectedExamStatus = 'Verify';
    selectedReportStatus = '판독 상태';
    startDay = DateTime(2000, 1, 1);
    endDay = DateTime.now();
    userIDController.text = '';
    userNameController.text = '';
    update();
  }

  /// 스터디탭 읽어와 리스트 형식으로 리턴
  Future<List<StudyTab>> getStudyTabList() async {
    // 스터디 리스트 초기화
    List<StudyTab> studies = [];
    // endpoint 가져오기
    String url = '${dotenv.env['API_ENDPOINT']!}studies/';

    try {
      // 비동기 요청
      var response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'}
      );

      if (response.statusCode == 200) {
        // 응답 결과(리스트형식)을 담기
        String responseBody = utf8.decode(response.bodyBytes);
        List dataConvertedJSON = jsonDecode(responseBody);

        // 반복문으로 studies 리스트에 study 객체 담기
        for (var study in dataConvertedJSON) {
          // study를 Map형식으로 담아주기
          StudyTab tempStudy = StudyTab.fromMap(study);
          studies.add(tempStudy);
        }
      } else {
        // 200 코드가 아닌 경우 빈 리스트 리턴
        studies = [];
      }
    } catch (e) {
      // 예외 처리 및 변환
      // String errorMessage = "서버 요청 중 오류가 발생했습니다: $e";
      // return Future.error(errorMessage);
    }

    return studies;
  }

  Future<List<SeriesTab>> getSeriesTabList(int studyKey) async {
    // 시리즈 리스트 초기화
    List<SeriesTab> seriesList = [];
    // endpoint 가져오기
    String url = '${dotenv.env['API_ENDPOINT']!}dcms/thumbnails?studykey=$studyKey';

    try {
      // 비동기 요청
      var response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'}
      );

      if (response.statusCode == 200) {
        // 응답 결과(리스트형식)을 담기
        String responseBody = utf8.decode(response.bodyBytes);
        List dataConvertedJSON = jsonDecode(responseBody);

        // 반복문으로 studies 리스트에 study 객체 담기
        for (var series in dataConvertedJSON) {
          // study를 Map형식으로 담아주기
          SeriesTab tempSeries = SeriesTab.fromMap(series);
          seriesList.add(tempSeries);

        }
      } else {
        // 200 코드가 아닌 경우 빈 리스트 리턴
        seriesList = [];
      }
    } catch (e) {
      // 예외 처리 및 변환
      // String errorMessage = "서버 요청 중 오류가 발생했습니다: $e";
      // return Future.error(errorMessage);
    }

    return seriesList;
  }

  /// 조건 검색
  filterData(
      {String? pid,
      String? pname,
      String? equipment,
      String? examStatus,
      String? reportStatus}) {

    // 누적되지 않게 리셋
    filterStudies = [];

    for (var study in studies) {
      if (study.PID.toLowerCase() == pid!.trim().toLowerCase()) {
        filterStudies.add(study);
      }
    }

    update(); // 화면 갱신
  }
}
