import 'dart:async';
import 'dart:core';

import 'package:server/components/agent_action.dart';
import 'package:server/components/field_info.dart';
import 'package:server/components/match_info.dart';

class Game {
  // Singletonの仕組み
  static final Game _singleton = Game._internal();

  Game._internal();

  factory Game() {
    return _singleton;
  }

  List<Player> players = <Player>[];
  List<Match> matches = <Match>[];
  List<FieldInfo> fieldInfos = <FieldInfo>[];
  MatchConfig config;

  int startTime = 0;
  int turn = 0;

  Timer timerStart, timerTurn;

  int get currentTime => DateTime.now().millisecondsSinceEpoch;

  int get elapseTime => currentTime - startTime;

  // <token, MatchInfo>
  Map<String, List<MatchInfo>> matchInfos = <String, List<MatchInfo>>{};

  void prepare() {
    print('Game.prepare()');

    clear();
//    startTime = 0;
//    turn = 0;

    int matchID = 1;
    int teamID = matches.length + 10;
    int agentID = 100;

    matches.forEach((match) {
      var field =
          fieldInfos.firstWhere((f) => f.field.fieldID == match.fieldID);
      final p1 = getPlayer(match.player1token);
      final p2 = getPlayer(match.player2token);

//      print('foreach: $match, $field, $p1, $p2');
//      print('         $field, $p1, $p2');
//      print('         $p1, $p2');

      if (field != null && p1 != null && p2 != null) {
        field
          ..matchID = matchID
          ..turn = 0
          ..startedAtUnixTime = 0
          ..remapIDs(teamID, agentID)
          ..teams[0].player = p1
          ..teams[1].player = p2;

//        fieldInfos.add(field);

        if (matchInfos[p1.token] == null) matchInfos[p1.token] = <MatchInfo>[];

        matchInfos[p1.token].add(MatchInfo()
          ..matchID = matchID
          ..teamID = field.teams[0].teamID
          ..matchTo = p2.name
          ..turnMillis = config.turnMillis
          ..intervalMillis = config.intervalMillis
          ..turns = config.turns);

        if (matchInfos[p2.token] == null) matchInfos[p2.token] = <MatchInfo>[];

        matchInfos[p2.token].add(MatchInfo()
          ..matchID = matchID
          ..teamID = field.teams[1].teamID
          ..matchTo = p1.name
          ..turnMillis = config.turnMillis
          ..intervalMillis = config.intervalMillis
          ..turns = config.turns);

        matchID++;
        teamID += 2;
        agentID += 20;
      }
    });

    print(matchInfos);
    print(' fieldInfos.length: ${fieldInfos.length}');

    fieldInfos[0].printInfo();
  }

  /// ゲームを開始しているかどうか
  bool get isStarted => startTime > 0 && startTime < currentTime;

  void start() {
    clear();

    // ５秒後にスタート！
    var cur = currentTime;
    startTime = ((cur / 1000.0).floor() + 5) * 1000;

    print("cur: $cur");
    print("startTime: $startTime");

    timerStart = Timer(Duration(milliseconds: startTime - cur), () {
      print('start!');
      timerTurn =
          Timer.periodic(Duration(milliseconds: config.totalTurnMillis), (t) {
        nextTurn();
      });
    });

    turn = 1;

    // 開始時間をセットする
    fieldInfos.forEach((f) {
      f.startedAtUnixTime = startTime;
      f.turn = 1;
    });
  }

  void finish() {
    _stopTimer();
  }

  void _stopTimer() {
    if (timerStart != null) {
      timerStart.cancel();
      timerStart = null;
    }
    if (timerTurn != null) {
      timerTurn.cancel();
      timerTurn = null;
    }
  }

  /// ゲーム開始前の初期状態に戻す
  void clear() {
    _stopTimer();
    startTime = 0;
    turn = 0;
    fieldInfos.forEach((f) => f.clear());
  }

  void nextTurn({bool force: false}) {
    print('nextTurn');
    var cur = currentTime;

    if (isTurnEnd(cur) || force) {
      print('  turn end');
      turn++;
      if (turn > config.turns) {
        // 規定ターン数終了
        finish();
      }
      fieldInfos.forEach((field) => field.nextTurn());

      fieldInfos.forEach((field) => field.printInfo());
    }
  }

  List<dynamic> getGameResult() {
    return fieldInfos.map((f) => f.getGameResult()).toList();
  }

  Map<String, dynamic> getGameStatus() {
    return {
      "startTime": startTime,
      "time": currentTime - startTime,
      "turn": turn,
      "config": config,
      "matches": fieldInfos.map((f) => f.getGameResult()).toList()
    };
  }

  /// ターン数を返す
  int _calcTurnCount(int time) => (time / config.totalTurnMillis).floor() + 1;

  /// ターンが終わったかどうか
  bool isTurnEnd(int time) =>
      startTime > 0 && _calcTurnCount(time - startTime) >= turn;

  /// 行動時間かどうかを返す
  bool isTurnAction(int time) {
    if (startTime == 0) return false;

    int dt = time - startTime; // 経過時間
    int st = (_calcTurnCount(time) - 1) * config.totalTurnMillis; // ターン開始時間

    return dt >= st && dt < st + config.turnMillis;
  }

  /// インターバルかを返す
  bool isTurnInterval(int time) {
    if (startTime == 0) return false;
    int dt = time - startTime; // 経過時間
    int st = _calcTurnCount(time) * config.totalTurnMillis; // ターン開始時間
    st += config.turnMillis;

    return dt >= st && dt < st + config.intervalMillis;
  }

  List<AgentAction> setActions(String token, List<AgentAction> actions) {
    List<AgentAction> result = <AgentAction>[];

    // 受付中か調べる
    if (!isStarted || isTurnInterval(currentTime)) {
      return null;
    }

    fieldInfos.forEach((f) {
      var r = f.setActions(token, actions);
      print('result: $r');
      result.addAll(r.where((rr) => rr != null));
    });

    fieldInfos.forEach((field) => field.printInfo());

    return result;
  }

  void readPlayers(Map<String, dynamic> object) {
    if (object == null) {
      print('Game.readConfig: object is null');
      return;
    }

    var playerList = object['players'] as List<dynamic>;
    print('Game.readPlayers: $playerList');

    if (playerList == null) {
      print('no players entry');
      return;
    }

    playerList.forEach((p) {
      Player player = Player.fromMap(p as Map<String, dynamic>);
      print('  add player => $player');
      players.add(player);
    });
  }

  void readFields(Map<String, dynamic> object) {
    if (object == null) {
      print('Game.readConfig: object is null');
      return;
    }

    var fieldList = object['fields'] as List<dynamic>;
    print('Game.readFields: $fieldList');

    if (fieldList == null) {
      print('no fields entry');
      return;
    }

    fieldList.forEach((f) {
      FieldInfo info = FieldInfo();
      info.readFromMap(f as Map<String, dynamic>);
      print('  $info');
      fieldInfos.add(info);
    });

    print(' fieldList.length: ${fieldList.length}');
    print(' fieldInfos.length: ${fieldInfos.length}');
  }

  void readMatchInfos(Map<String, dynamic> object) {
    if (object == null) {
      print('Game.readConfig: object is null');
      return;
    }

    var matchList = object['matches'] as List<dynamic>;
    print('Game.readMatches: $matchList');

    if (matchList == null) {
      print('no matches entry');
      return;
    }

    matchList.forEach((f) {
      Match match = Match();
      match.readFromMap(f as Map<String, dynamic>);
      print('  $match');
      matches.add(match);
    });
  }

  void readConfig(Map<String, dynamic> object) {
    if (object == null) {
      print('Game.readConfig: object is null');
      return;
    }
    var configList = object['config'] as Map<String, dynamic>;
    print('Game.readConfig: $configList');

    if (configList == null) {
      print('no config entry');
      return;
    }

    config = MatchConfig.fromMap(configList);
  }

  bool checkToken(String token) {
    return matchInfos.containsKey(token);
  }

  /// 指定したmatchIDとトークンが、試合リストに含まれているかチェックする
  bool checkMatch(int matchID, String token) {
    try {
      return null != matchInfos[token].firstWhere((m) => m.matchID == matchID);
    } catch (e) {
      return false;
    }
  }

  /// 指定したトークンを含むプレイヤーが登録されているかチェックする
  bool existPlayer(String token) => getPlayer(token) != null;

  /// 指定したトークンのプレイヤーを返す
  Player getPlayer(String token) {
    try {
      return players.firstWhere((p) => p.token == token);
    } catch (e) {
      return null;
    }
  }

  String getPlayerName(String token) {
    var p = getPlayer(token);
    if (p == null) return "nanashisan";

    return p.name;
  }

  List<MatchInfo> getMatchInfos(String token) => matchInfos[token];

  FieldInfo getFieldInfo(String token, int matchID) {
    try {
      return fieldInfos.firstWhere((f) =>
          f.matchID == matchID &&
          (f.teams[0].player.token == token ||
              f.teams[1].player.token == token));
    } catch (e) {
      return null;
    }
  }

  void printInfo() {
    fieldInfos.forEach((field) => field.printInfo());
  }
}
