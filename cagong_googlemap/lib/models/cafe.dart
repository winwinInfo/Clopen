class Cafe {
  final String name;
  final double latitude;
  final double longitude;
  final String message;
  final String address;
  final double hoursWeekday;
  final double hoursWeekend;
  final String price;
  final String videoUrl;
  final String businessHours;
  final List<Seating> seatingTypes;
  final int coWork;
  final double id;

  Cafe({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.message = 'No message provided', // 기본값 설정
    this.address = 'No address provided', // 기본값 설정
    this.hoursWeekday = -1.0, // 기본값 설정
    this.hoursWeekend = -1.0, // 기본값 설정
    this.price = 'Price not available', // 기본값 설정
    this.videoUrl = '', // 기본값 설정
    this.businessHours = 'Hours not available', // 기본값 설정
    required this.seatingTypes,
    this.coWork = 0, // 기본값 설정
    required this.id,
  });

  factory Cafe.fromJson(Map<String, dynamic> json) {
    List<Seating> seatingList = [];
    for (int i = 1; i <= 5; i++) {
      if (json['Seating Type $i'] != null) {
        seatingList.add(Seating(
          type: json['Seating Type $i'] ?? 'Unknown', // 기본값 설정
          count: json['Seating Count $i']?.toDouble() ?? 0.0, // 기본값 설정
          powerCount: json['Power Count $i']?.toString() ?? '0', // 기본값 설정
        ));
      }
    }

    return Cafe(
      name: json['Name'] ?? 'Unnamed Cafe', // 기본값 설정
      latitude: json['Position (Latitude)']?.toDouble() ?? 0.0, // 기본값 설정
      longitude: json['Position (Longitude)']?.toDouble() ?? 0.0, // 기본값 설정
      message: json['Message'] ?? 'No message provided', // 기본값 설정
      address: json['Address'] ?? 'No address provided', // 기본값 설정
      hoursWeekday: json['Hours_weekday']?.toDouble() ?? -1.0, // 기본값 설정
      hoursWeekend: json['Hours_weekend']?.toDouble() ?? -1.0, // 기본값 설정
      price: json['Price'] ?? 'Price not available', // 기본값 설정
      videoUrl: json['Video URL'] ?? '', // 기본값 설정
      businessHours: json['영업 시간'] ?? 'Hours not available', // 기본값 설정
      seatingTypes: seatingList,
      coWork: json['Co-work'] ?? 0, // 기본값 설정
      id: json['ID']?.toDouble() ?? 0.0, // 기본값 설정
    );
  }
}

class Seating {
  final String type;
  final double count;
  final String powerCount;

  Seating({
    required this.type,
    required this.count,
    required this.powerCount,
  });
}
