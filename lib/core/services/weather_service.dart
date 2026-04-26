// SPDX-License-Identifier: GPL-3.0-or-later
//
// Petto - An intelligent desktop assistant.
// Copyright (C) 2025 FunnyCups (https://github.com/funnycups)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:open_meteo/open_meteo.dart';
import '../../generated/l10n.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  static WeatherService get instance => _instance;

  WeatherService._internal();

  Future<String> getWeather() async {
    try {
      const weather = WeatherApi();
      // 已替换为国内可用IP定位，不卡50秒
      final geoData = await _getLocalGeoData();

      final response = await weather.request(
        latitude: geoData?['lat'] ?? 39.9042,
        longitude: geoData?['lon'] ?? 116.4074,
        current: {WeatherCurrent.weather_code, WeatherCurrent.temperature_2m},
      );

      final temperature = response.currentData[WeatherCurrent.temperature_2m]!.value;
      final weatherCode = response.currentData[WeatherCurrent.weather_code]!.value;

      String weatherStr = _getWeatherDescription(weatherCode);
      return S.current.currentWeather(weatherStr, temperature);
    } catch (e) {
      return "获取天气失败";
    }
  }

  // 国内可用IP定位API（完美解析你提供的返回格式）
  Future<Map<String, double>?> _getLocalGeoData() async {
    try {
      final response = await http.get(
        Uri.parse('https://whois.pconline.com.cn/ipJson.jsp'),
        headers: {'Referer': 'https://whois.pconline.com.cn'},
      );

      String text = response.body.trim();
      // 精准清洗你提供的返回格式
      text = text.replaceAll('if(window.IPCallBack) {IPCallBack(', '');
      text = text.replaceAll(');}', '');

      final Map<String, dynamic> data = jsonDecode(text);
      return {
        'lat': double.tryParse(data['lat'].toString()) ?? 39.9042,
        'lon': double.tryParse(data['lon'].toString()) ?? 116.4074,
      };
    } catch (e) {
      return null;
    }
  }

  String _getWeatherDescription(num weatherCode) {
    switch (weatherCode) {
      case 0:
      case 1:
        return S.current.sunny;
      case 2:
        return S.current.cloudy;
      case 3:
        return S.current.overcast;
      case 45:
      case 48:
        return S.current.fog;
      case 51:
      case 53:
      case 55:
        return S.current.drizzle;
      case 56:
      case 57:
        return S.current.freezingDrizzle;
      case 61:
        return S.current.lightRain;
      case 63:
        return S.current.moderateRain;
      case 65:
        return S.current.heavyRain;
      case 66:
      case 67:
        return S.current.freezingRain;
      case 71:
        return S.current.lightSnow;
      case 73:
        return S.current.moderateSnow;
      case 75:
        return S.current.heavySnow;
      case 77:
        return S.current.sleet;
      case 80:
        return S.current.lightShower;
      case 81:
        return S.current.moderateShower;
      case 82:
        return S.current.heavyShower;
      case 85:
        return S.current.lightSnowShower;
      case 86:
        return S.current.heavySnowShower;
      case 95:
        return S.current.thunderstorm;
      case 96:
        return S.current.thunderstormWithSmallHail;
      case 99:
        return S.current.thunderstormWithLargeHail;
      default:
        return "未知天气";
    }
  }

  static String getSeason(DateTime date) {
    int month = date.month;
    if (month >= 4 && month <= 5) {
      return S.current.spring;
    } else if (month >= 6 && month <= 9) {
      return S.current.summer;
    } else if (month >= 10 && month <= 11) {
      return S.current.autumn;
    } else {
      return S.current.winter;
    }
  }
}
