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
    final currentTime = DateFormat('HH:mm').format(now);

    final todayHours = cafe.operatingHours.getTodayHours();

    if (todayHours == null || todayHours.begin == null || todayHours.end == null) {
      return false;
    }

    String openTime = todayHours.begin!;
    String closeTime = todayHours.end!;

    return _isTimeBetween(currentTime, openTime, closeTime);
  }

  bool _isRecommendedTime(Cafe cafe) {
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final cafeRecommendedHours =
        isWeekend ? cafe.hoursWeekend : cafe.hoursWeekday;

    // If cafeRecommendedHours is null or -1 (무제한), it's always a recommended time
    if (cafeRecommendedHours == null || cafeRecommendedHours == -1) return true;

    // If cafeRecommendedHours is 0 (권장X), it's never a recommended time
    if (cafeRecommendedHours == 0) return false;

    // Compare the cafe's recommended hours with the user's input
    return cafeRecommendedHours >= options.recommendedHours;
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

void showFilterDialog(
    BuildContext context, FilterManager filterManager, Function applyFilters) {
  TextEditingController hoursController = TextEditingController(
      text: filterManager.options.recommendedHours.toString());

  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('필터'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  CheckboxListTile(
                    title: const Text('영업중'),
                    value: filterManager.options.isOpen,
                    onChanged: (bool? value) {
                      setState(() {
                        filterManager.options.isOpen = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('권장 시간 (이상)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: hoursController,
                    decoration: const InputDecoration(
                      hintText: '예: 2',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                child: const Text('취소'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('적용'),
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
