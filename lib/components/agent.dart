// エージェントの状態
import 'package:aqueduct/aqueduct.dart';
import 'package:server/components/agent_action.dart';
import 'package:server/components/point.dart';
import 'package:server/components/team.dart';

class Agent extends Serializable {
  Team team;
  int agentID;
  Point position = Point();

  int get x => position.x;

  set x(int value) => position.x = value;

  int get y => position.y;

  set y(int value) => position.y = value;

  /// AgentActionを適用する
  /// @param action
  void apply(AgentAction action) {
    if (action.agentID == agentID &&
        action.apply == AgentActionApply.Valid &&
        action.type == AgentActionType.Move) {
      position += action.dposition;
    }
  }

  Agent() : super();

  Agent.fromMap(Map<String, dynamic> object) : super() {
    readFromMap(object);
  }

  @override
  String toString() => asMap().toString();

  @override
  Map<String, dynamic> asMap() => {'agentID': agentID, 'x': x, 'y': y};

  dynamic toJson() => asMap();

  @override
  void readFromMap(Map<String, dynamic> object) {
    agentID = object['agentID'] as int;
    x = object['x'] as int;
    y = object['y'] as int;
  }
}
