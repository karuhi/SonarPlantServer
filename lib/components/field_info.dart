import 'package:aqueduct/aqueduct.dart';
import 'package:server/components/agent.dart';
import 'package:server/components/agent_action.dart';
import 'package:server/components/field.dart';
import 'package:server/components/point.dart';
import 'package:server/components/team.dart';
import 'package:sprintf/sprintf.dart';

class FieldInfo extends Serializable {
  int matchID;
  Field field, fieldOrig;

  int get width => field.width;

  int get height => field.height;

  Point get fieldSize => field.size;

  int startedAtUnixTime = 0;
  int turn;
  List<Team> teams = <Team>[];
  List<AgentAction> actions = <AgentAction>[];

  Map<int, AgentAction> actionsPool = <int, AgentAction>{};

  int get agentCount => teams[0].agents.length + teams[1].agents.length;

  void clear() {
    field.setTiles(fieldOrig);
//    field = fieldOrig.clone();
    startedAtUnixTime = 0;
    turn = 0;
    actions = <AgentAction>[];
    actionsPool = <int, AgentAction>{};
  }

  void remapIDs(int startTeamID, int startAgentID) {
    var tid = startTeamID;
    var aid = startAgentID;
    for (var t in teams) {
      t.teamID = tid++;
      for (var a in t.agents) {
        a.agentID = aid++;
      }
    }
    print('remapIDs: team0=${teams[0].teamID}, team1=${teams[1].teamID}');

    field.remapTeamID(teams[0].teamID, teams[1].teamID);
    fieldOrig.setTiles(field);
  }

  Map<String, dynamic> getGameResult() {
    var t0 = field.getTilePoint(teams[0].teamID);
    var a0 = field.getAreaPoint(teams[0].teamID);
    var t1 = field.getTilePoint(teams[1].teamID);
    var a1 = field.getAreaPoint(teams[1].teamID);
    var winner = "";

    if (t0 + a0 > t1 + a1) {
      winner = teams[0].player.name;
    } else if (t0 + a0 < t1 + a1) {
      winner = teams[1].player.name;
    } else {
      if (t0 > t1) {
        winner = teams[0].player.name;
      } else if (t0 < t1) {
        winner = teams[1].player.name;
      } else {
        winner = 'じゃんけん';
      }
    }

    return {
      "winner": winner,
      teams[0].player.name: {"tile": t0, "area": a0},
      teams[1].player.name: {"tile": t1, "area": a1}
    };
  }

  bool checkAction(String token, AgentAction action) {
    print('checkAction: $action');

    Agent agent = getAgent(action.agentID);

    if (agent == null) return false;
    if (token != agent.team.player.token) return false;

    if (action.dx.abs() > 1 || action.dy.abs() > 1) return false;

    return true;
  }

  // Actionを登録する
  List<AgentAction> setActions(String token, List<AgentAction> actions) =>
      actions.map((a) => setAction(token, a)).toList();

  // Actionを登録する
  AgentAction setAction(String token, AgentAction action) {
//    if (checkAction(token, action)) {
    // どんどん上書きする

    // ターンエンド処理用にいろいろセットする
    action.token = token;
    var t = getTeam(token);
    if (t != null) {
      action.agent = t.getAgent(action.agentID);
    }

    actionsPool[action.agentID] = action;
    AgentAction result = action.clone();
    result.turn = turn;
    return result;
//    } else {
//      action.apply = AgentActionApply.Invalid;
//      action.agent = getAgent(action.agentID);
//    }
//    return null;
  }

  Team getTeam(String token) {
    if (teams[0].player.token == token) return teams[0];
    if (teams[1].player.token == token) return teams[1];
    return null;
  }

  Agent getAgent(agentID) {
    for (int t = 0; t < 2; t++) {
      for (int i = 0; i < teams[t].agents.length; i++) {
        if (teams[t].agents[i].agentID == agentID) return teams[t].agents[i];
      }
    }
    return null;
  }

  /// Actionが有効かしらべる
  /// 無効なActionにはInvalidフラグをつけていく
  void _validateAction(AgentAction action) {
    // tokenやagentID間違いでagentが取れない命令の場合
    if (action.agent == null) {
      action.setInvalid();
      return;
    }

    // Stayは無条件で有効に
    if (action.type == AgentActionType.Stay) {
      action.setValid();
      return;
    }

    // 移動方向の指定がおかしい場合
    if (action.dx.abs() > 1 || action.dy.abs() > 1) {
      action.setInvalid();
      return;
    }

    final Point t = action.target;

    // ターゲットがフィールド外の場合
    if (!field.inside(t)) {
      action.setInvalid();
    }
  }

  /// 全てのエージェントのリストを得る
  List<Agent> get allAgents {
    List<Agent> list = <Agent>[];
    list.addAll(teams[0].agents);
    list.addAll(teams[1].agents);
    return list;
  }

  /// ActionTargetsをつくる
  ActionTargets getActionTargets() {
    ActionTargets actionTargets = ActionTargets();

    // Actionが指定されていないAgentについてはダミーActionを作る
    allAgents.forEach((a) {
      if (!actionsPool.containsKey(a.agentID)) {
        actionTargets.addDummy(a);
      }
    });

    // Removeも場所を移動しないので、ダミーActionを作る
    actionsPool.forEach((agentID, action) {
      if (action.type == AgentActionType.Remove) {
        actionTargets.addDummy(getAgent(agentID));
      }
    });

    // InvalidがついていないActionのMove, Removeの適応先を登録していく
    actionsPool.forEach((agentID, action) {
      if (action.apply != AgentActionApply.Invalid) {
        if (action.type == AgentActionType.Move ||
            action.type == AgentActionType.Remove) {
          actionTargets.add(getAgent(agentID), action);
        }
      }
    });

    return actionTargets;
  }

  /// ターン終了の前処理
  void _prepareNextTurn() {
    // 初期化
    field.clearCheckArray();
    actionsPool.forEach((agentID, action) {
      action.apply = AgentActionApply.Unknown;
    });

    // 無効なActionにフラグをつけていく
    actionsPool.forEach((agentID, action) => _validateAction(action));
  }

  /// Actionを適用させる
  void _applyActions() {
    actionsPool.forEach((agentID, action) {
      if (action.apply == AgentActionApply.Valid) {
        print("_applyActions: $agentID");
        Agent agent = getAgent(agentID);
        ActionTarget t = ActionTarget(agent, action);

        if (action.type == AgentActionType.Move) {
          field.tileP(t.target).state = agent.team.teamID;
          agent?.apply(action); // エージェントを動かす
        }
        if (action.type == AgentActionType.Remove) {
          field.tileP(t.target).state = Tile.Free;
        }
      }
    });
  }

  void nextTurn() {
    // 初期化
    _prepareNextTurn();

    ActionTargets actionTargets = getActionTargets();
    print('actionTargets: $actionTargets}');

    // エージェントの数だけオーバーラップしてるか調べる
    // エージェントの数だけループを回せば問題なし
    int n = agentCount;
    for (int i = 0; i < n; i++) {
      print('i=$i, _countUnknownAgentAction: ${_countUnknownAgentAction()}');
      print('actionTargets: $actionTargets}');
      if (_countUnknownAgentAction() == 0) {
        break;
      }
      actionTargets.checkMulti(); // ターゲットがかぶっているActionを処理していく
    }

    print('loop end');
    print('actionTargets: $actionTargets}');

    // ターゲットが１つだけのやつにValidフラグをつけていき確定させる
    actionTargets.setValidSingle();

    _applyActions();

    // 次のターンへ
    turn++;

    // actionsへ登録する
    actionsPool.forEach((agentID, action) {
      actions.add(action);
    });

    actionsPool.clear();
  }

  /// applyが未処理のアクションの数を得る
  int _countUnknownAgentAction() {
    int count = 0;
    actionsPool.forEach((agentID, action) {
      if (action.apply == AgentActionApply.Unknown) count++;
    });
    return count;
  }

  @override
  Map<String, dynamic> asMap() => {
        'width': width,
        'height': height,
        'points': field.getPointsArray(),
        'startedAtUnixTime': startedAtUnixTime,
        'turn': turn,
        'tiled': field.getTiledArray(),
        'teams': _asMapTeamInfo(),
        'actions': actions
      };

  dynamic toJson() => asMap();

  List<Map<String, dynamic>> _asMapTeamInfo() {
    var t1 = teams[0].asMap();
    var t2 = teams[1].asMap();

    t1['tilePoint'] = field.getTilePoint(teams[0].teamID);
    t1['areaPoint'] = field.getAreaPoint(teams[0].teamID);

    t2['tilePoint'] = field.getTilePoint(teams[1].teamID);
    t2['areaPoint'] = field.getAreaPoint(teams[1].teamID);

    return [t1, t2];
  }

  @override
  void readFromMap(Map<String, dynamic> object) {
    field = Field.fromMap(object);
    fieldOrig = field.clone(); // あとで戻せるように初期状態のコピーを保存しておく
    fieldSize.setValue(width, height);

    final ts = object['teams'] as List<dynamic>;
    teams = ts
        .map((t) => Team.fromMap(t as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  String toString() => asMap().toString();

  void printInfo() {
    if (turn != null) {
      print('turn: $turn');
    }
    String s = '    ';
    for (int x = 0; x < width; x++) {
      s += sprintf("  %02d  |", [x]);
    }
    int nw = s.length;
    print(s);

    String sep = '';
    for (int i = 0; i < nw; i++) {
      sep += '-';
    }
    print(sep);

    var areaChar = {
      Tile.Free: ' ',
      Tile.Wall: 'W',
      teams[0].teamID: '#',
      teams[1].teamID: '\$'
    };

    s = '';
    String s2 = '';
    for (int y = 0; y < height; y++) {
      s = sprintf('%02d |', [y]);
      s2 = '   |';
      for (int x = 0; x < width; x++) {
        s += sprintf('%5d |', [field.tile(x, y).score]);
        s2 += ' ${areaChar[field.tile(x, y).state]}${_getAgentNumber(x, y)} |';
      }
      print(s);
      print(s2);
      print(sep);
    }

    print('行動');
    if (actionsPool.length == 0) {
      print('  なし');
    } else {
      actionsPool.forEach((agentID, action) {
        print('  ${action.toString()}');
      });
    }
  }

  String _getAgentNumber(int x, int y) {
    if (field.tile(x, y).state == Tile.Free) return '   ';

    for (var team in teams) {
      for (var agent in team.agents) {
        if (agent.x == x && agent.y == y) {
          return sprintf('%3d', [agent.agentID]);
        }
      }
    }

    return '   ';
  }
}
