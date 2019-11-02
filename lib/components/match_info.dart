import 'dart:core';

import 'package:aqueduct/aqueduct.dart';

///
/// {player: String, token: String}
///
class Player extends Serializable {
  /// プレイヤー名
  String name;

  /// トークン
  String token;

  Player() : super();

  Player.fromMap(Map<String, dynamic> object) : super() {
    readFromMap(object);
  }

  @override
  Map<String, dynamic> asMap() => {'name': name, 'token': token};

  @override
  void readFromMap(Map<String, dynamic> object) {
    name = object['name'] as String;
    token = object['token'] as String;
  }

  @override
  String toString() => asMap().toString();
}

///
/// {player1: [Player.token], player2: [Player.token], fieldID: #}
///
class Match extends Serializable {
  String player1token, player2token;
  int fieldID;

  @override
  Map<String, dynamic> asMap() =>
      {'fieldID': fieldID, 'player1': player1token, 'player2': player2token};

  dynamic toJson() => asMap();

  @override
  void readFromMap(Map<String, dynamic> object) {
    fieldID = object['fieldID'] as int;
    player1token = object['player1'] as String;
    player2token = object['player2'] as String;
  }

  @override
  String toString() => asMap().toString();
}

//
// {intervalMillis: #, turnMillis: #, turns: #}
//
class MatchConfig extends Serializable {
  int intervalMillis;
  int turnMillis;
  int turns;

  int get totalTurnMillis => intervalMillis + turnMillis;

  MatchConfig() : super();

  MatchConfig.fromMap(Map<String, dynamic> object) : super() {
    readFromMap(object);
  }

  @override
  Map<String, dynamic> asMap() => {
        "intervalMillis": intervalMillis,
        "turnMillis": turnMillis,
        "turns": turns
      };

  dynamic toJson() => asMap();

  @override
  void readFromMap(Map<String, dynamic> object) {
    intervalMillis = object['intervalMillis'] as int;
    turnMillis = object['turnMillis'] as int;
    turns = object['turns'] as int;
  }

  @override
  String toString() => asMap().toString();
}

class MatchInfo extends Serializable {
  /// 試合ID
  int matchID;

  /// 自分の試合でのID
  int teamID;

  /// 対戦相手の名前
  String matchTo;

  /// 1ターンあたりの時間
  int turnMillis;

  /// ターン間の時間
  int intervalMillis;

  /// 試合のターン数
  int turns;

  @override
  void readFromMap(Map<String, dynamic> object) {
    matchID = object["id"] as int;
    teamID = object["teamID"] as int;
    matchTo = object["matchTo"] as String;
    turnMillis = object["turnMillis"] as int;
    intervalMillis = object["intervalMillis"] as int;
    turns = object["turns"] as int;
  }

  @override
  Map<String, dynamic> asMap() => {
        "id": matchID,
        "intervalMillis": intervalMillis,
        "matchTo": matchTo,
        "teamID": teamID,
        "turnMillis": turnMillis,
        "turns": turns
      };

  dynamic toJson() => asMap();

  @override
  String toString() => asMap().toString();
}
