import 'package:aqueduct/aqueduct.dart';
import 'package:server/components/agent.dart';
import 'package:server/components/point.dart';

enum AgentActionType {
  Unknown,

  /// 移動
  Move,

  /// 除去
  Remove,

  /// 停留
  Stay,
}

/// 行動の適応状況
enum AgentActionApply {
  Unknown,

  /// 無効
  Invalid,

  /// 競合
  Conflict,

  /// 有効
  Valid,
}

class AgentAction extends Serializable {
  /// エージェントID
  int agentID;

  /// エージェント
  /// AgentActionを登録したときにAgentがセットされる
  Agent agent = null;

  /// ターン処理の際にセットされる
  String token = "";

  Point dposition = Point();

  /// 方向
  int get dx => dposition.x;

  set dx(int value) => dposition.x = value;

  int get dy => dposition.y;

  set dy(int value) => dposition.y = value;

  /// 行動の種類
  AgentActionType type;

  /// 行動のターン数
  int turn;

  /// 行動の適応状況
  AgentActionApply apply = AgentActionApply.Unknown;

  bool dummy = false;

  AgentAction() : super();

  AgentAction.fromMap(Map<String, dynamic> object) : super() {
    readFromMap(object);
  }

  AgentAction.createDummy(this.agentID, this.type) : super() {
    dummy = true;
  }

  setValid() => apply = AgentActionApply.Valid;

  setInvalid() => apply = AgentActionApply.Invalid;

  setConflict() => apply = AgentActionApply.Conflict;

  Point get target => _getTarget();

  Point _getTarget() {
    Point result = Point();

    if (agent == null) {
      result.x = -1;
      result.y = -1;
      return result;
    }

    switch (type) {
      case AgentActionType.Move:
        result = agent.position + dposition;
        break;
      case AgentActionType.Remove:
        result = agent.position + dposition;
        break;
      case AgentActionType.Stay:
        result = Point.setPoint(agent.position);
        break;
      default:
        result = Point.setPoint(agent.position);
    }
    return result;
  }

  /// ActionTypeの変換(JSONから)
  AgentActionType _agentActionTypeFromJson(String val) {
    if (val == 'move') return AgentActionType.Move;
    if (val == 'remove') return AgentActionType.Remove;
    if (val == 'stay') return AgentActionType.Stay;
    return AgentActionType.Unknown;
  }

  /// ActionTypeの変換(JSONへ)
  String _agentActionTypeToJson(AgentActionType type) {
    if (type == AgentActionType.Move) return 'move';
    if (type == AgentActionType.Remove) return 'remove';
    if (type == AgentActionType.Stay) return 'stay';
    return 'unknown';
  }

  /// ActionApplyの変換(JSONから)
  AgentActionApply _agentActionApplyFromJson(int val) {
    if (val == -1) return AgentActionApply.Invalid;
    if (val == 0) return AgentActionApply.Conflict;
    return AgentActionApply.Valid;
  }

  /// ActionApplyの変換(JSONへ)
  int _agentActionApplyToJson(AgentActionApply apply) {
    if (apply == AgentActionApply.Invalid) return -1;
    if (apply == AgentActionApply.Conflict) return 0;
    return 1;
  }

  @override
  Map<String, dynamic> asMap() {
    Map<String, dynamic> result = {
      'agentID': agentID,
      'dx': dx,
      'dy': dy,
      'type': _agentActionTypeToJson(type),
    };

    if (turn != null && turn > 0) {
      result['turn'] = turn;
    }

    if (apply != null && apply != AgentActionApply.Unknown) {
      result['apply'] = _agentActionApplyToJson(apply);
    }

    return result;
  }

  dynamic toJson() => asMap();

  @override
  void readFromMap(Map<String, dynamic> object) {
    agentID = object['agentID'] as int;
    type = _agentActionTypeFromJson(object['type'] as String);
    dx = object.containsKey('dx') ? object['dx'] as int : 0;
    dy = object.containsKey('dy') ? object['dy'] as int : 0;
    if (object.containsKey('turn')) {
      turn = object['turn'] as int;
    }
    if (object.containsKey('apply')) {
      apply = _agentActionApplyFromJson(object['apply'] as int);
    }
  }

  @override
  String toString() => asMap().toString();

  AgentAction clone() {
    AgentAction action = AgentAction();
    action
      ..agentID = agentID
      ..dposition = dposition.clone()
      ..type = type
      ..turn = turn
      ..apply = apply;
    return action;
  }
}

class ActionTarget {
  Agent agent;
  AgentAction action;
  Point target;

  ActionTarget(this.agent, this.action) {
    switch (action.type) {
      case AgentActionType.Move:
        target = agent.position + action.dposition;
        break;

      case AgentActionType.Remove:
        target = agent.position + action.dposition;
        break;

      case AgentActionType.Stay:
        target = Point.setPoint(agent.position);
        break;

      default:
        target = Point.setPoint(agent.position);
    }
  }
}

class ActionTargets {
  Map<Point, List<ActionTarget>> targets = {};

  bool _contains(Point p) => targets.containsKey(p);

  void _prepare(Point p) {
    if (!_contains(p)) {
      targets[p] = <ActionTarget>[];
    }
  }

  void add(Agent agent, AgentAction action) {
    ActionTarget t = ActionTarget(agent, action);
    print('ActionTargets.add: t=$t, ${agent.agentID}, ${action}');
    _prepare(t.target);
    targets[t.target].add(t);
  }

  @override
  String toString() {
    String s = "";
    targets.forEach((p, list) => s += "$p : ${list.length}");
    return s;
  }

  void addDummy(Agent agent) {
    var action = AgentAction.createDummy(agent.agentID, AgentActionType.Stay);
    add(agent, action);
  }

  void checkMulti() {
    List<ActionTarget> newlist = [];
    targets.values.where((list) => list.length >= 2).forEach((list) {
      print('list = $list');
      list.forEach((a) {
        print(a);
        if (a.action.apply == AgentActionApply.Unknown) {
          // 未処理のアクションだけ対象とする

          if (a.action.type == AgentActionType.Move) {
            // Conflictフラグをたてて、動けないので元いた場所を登録するためにリストに保存しておく
            a.action.setConflict();
            newlist.add(a);
          } else if (a.action.type == AgentActionType.Remove) {
            // RemoveできないのでConflictフラグをたてるだけで終了
            a.action.setConflict();
          }
        }
      });
    });

    // 動けなくて元いた場所に戻る分を登録する
    newlist.forEach((a) {
      addDummy(a.agent);
    });
  }

  void setValidSingle() {
    /// １つしかターゲットがないやつはValidフラグをたてる
    targets.values.where((list) => list.length == 1).forEach((list) {
      list.forEach((a) {
        if (a.action.apply == AgentActionApply.Unknown) {
          a.action.setValid();
        }
      });
    });
  }
}
