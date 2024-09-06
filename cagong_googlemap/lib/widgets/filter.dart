import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cafe.dart';

class FilterOptions {
  bool isOpen;
  bool useRecommendedTime;
  double recommendedHours;

  FilterOptions({
    this.isOpen = false,
    this.useRecommendedTime = false,
    this.recommendedHours = 0,
  });
}

class FilterManager {
  FilterOptions options = FilterOptions();

  List<Cafe> applyFilters(List<Cafe> cafes) {
    return cafes.where((cafe) {
      if (options.isOpen && !_isCurrentlyOpen(cafe)) return false;
      if (options.useRecommendedTime && !_isRecommendedTime(cafe)) return false;
      return true;
    }).toList();
  }

  bool _isCurrentlyOpen(Cafe cafe) {
    final now = DateTime.now();
    final dayOfWeek = DateFormat('E').format(now);
    final currentTime = DateFormat('HH:mm').format(now);
    
    String todayHours = cafe.dailyHours[_koreanDayOfWeek(dayOfWeek)] ?? 'Not available';
    
    if (todayHours == 'Not available' || todayHours == '-1') {
      return false;
    }
    
    List<String> hours = todayHours.split('~');
    if (hours.length != 2) return false;
    
    String openTime = hours[0].trim();
    String closeTime = hours[1].trim();
    
    return _isTimeBetween(currentTime, openTime, closeTime);
  }

  bool _isRecommendedTime(Cafe cafe) {
    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final cafeRecommendedHours = isWeekend ? cafe.hoursWeekend : cafe.hoursWeekday;
    
    // If cafeRecommendedHours is -1 (무제한), it's always a recommended time
    if (cafeRecommendedHours == -1) return true;
    
    // If cafeRecommendedHours is 0 (권장X), it's never a recommended time
    if (cafeRecommendedHours == 0) return false;
    
    // Compare the cafe's recommended hours with the user's input
    return cafeRecommendedHours >= options.recommendedHours;
  }

  String _koreanDayOfWeek(String englishDay) {
    switch (englishDay) {
      case 'Mon': return '월';
      case 'Tue': return '화';
      case 'Wed': return '수';
      case 'Thu': return '목';
      case 'Fri': return '금';
      case 'Sat': return '토';
      case 'Sun': return '일';
      default: return '';
    }
  }

  bool _isTimeBetween(String current, String open, String close) {
    int currentMinutes = _timeToMinutes(current);
    int openMinutes = _timeToMinutes(open);
    int closeMinutes = _timeToMinutes(close);
    
    if (closeMinutes < openMinutes) {
      return currentMinutes >= openMinutes || currentMinutes <= closeMinutes;
    } else {
      return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
    }
  }  

    int _timeToMinutes(String time) {
    List<String> parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

}



void showFilterDialog(BuildContext context, FilterManager filterManager, Function applyFilters) {
  TextEditingController _hoursController = TextEditingController(
    text: filterManager.options.recommendedHours.toString()
  );

  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('필터'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  CheckboxListTile(
                    title: Text('영업중'),
                    value: filterManager.options.isOpen,
                    onChanged: (bool? value) {
                      setState(() {
                        filterManager.options.isOpen = value ?? false;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Text('권장 시간 (이상)', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _hoursController,
                    decoration: InputDecoration(
                      hintText: '예: 2',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      double? hours = double.tryParse(value);
                      setState(() {
                        if (hours != null && hours > 0) {
                          filterManager.options.useRecommendedTime = true;
                          filterManager.options.recommendedHours = hours;
                        } else {
                          filterManager.options.useRecommendedTime = false;
                          filterManager.options.recommendedHours = 0;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('취소'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('적용'),
                onPressed: () {
                  applyFilters();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
}