enum AttendanceStatus { present, late, absent, injured }

class AttendanceModel {
  const AttendanceModel({
    required this.playerId,
    required this.playerName,
    required this.playerCode,
    required this.status,
    this.observation,
  });

  final String playerId;
  final String playerName;
  final String playerCode;

  final AttendanceStatus status;

  final String? observation;

  AttendanceModel copyWith({AttendanceStatus? status, String? observation}) {
    return AttendanceModel(
      playerId: playerId,
      playerName: playerName,
      playerCode: playerCode,
      status: status ?? this.status,
      observation: observation ?? this.observation,
    );
  }
}
