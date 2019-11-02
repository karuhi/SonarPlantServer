import 'package:aqueduct/aqueduct.dart';
import 'package:server/components/agent.dart';
import 'package:server/components/match_info.dart';

class Team extends Serializable {
  Player player = Player();

  int teamID;
  List<Agent> agents = <Agent>[];

  Team() : super();

  Team.fromMap(Map<String, dynamic> object) : super() {
    readFromMap(object);
  }

  Agent getAgent(int agentID) {
    try {
      return agents.firstWhere((a) => a.agentID == agentID);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() => asMap().toString();

  @override
  Map<String, dynamic> asMap() => {'teamID': teamID, 'agents': agents};

  dynamic toJson() => asMap();

  @override
  void readFromMap(Map<String, dynamic> object) {
    teamID = object['teamID'] as int;
    agents = _readAgents(object['agents'] as List<dynamic>);
    agents.forEach((a) => a.team = this);
  }

  List<Agent> _readAgents(List<dynamic> object) => object
      .map((a) => Agent.fromMap(a as Map<String, dynamic>))
      .toList(growable: false);
}
