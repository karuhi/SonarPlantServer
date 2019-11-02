import 'package:aqueduct/aqueduct.dart';
import 'package:server/components/agent_action.dart';
import 'package:server/components/field_info.dart';
import 'package:server/components/game.dart';
import 'package:server/server.dart';

class ActionController extends ResourceController {
//  Game game;
//
//  ActionController(this.game) : super();

  /// エージェントの行動をセットする
  /// POST /matches/:matchID/action
  @Operation.post('matchID')
  Future<Response> setActions(@Bind.path('matchID') int matchID,
      @Bind.header('authorization') String token) async {
    Game game = Game();
    print(' body => ${request.body.as() as Map<String, dynamic>}');
    var actionListMap = request.body.as()  as Map<String, dynamic>;
    if(actionListMap == null) {
      return Response(604, {
        'Content-type': 'application/json'
      }, {
        'code': 606,
        'message': 'actions is null'
      });

    }
    if(!actionListMap.containsKey('actions')) {
      return Response(605, {
        'Content-type': 'application/json'
      }, {
        'code': 606,
        'message': 'none actions'
      });
    }
    var alist = actionListMap['actions'] as List<dynamic>;
    var actions = alist
        .map((m) => AgentAction.fromMap(m as Map<String, dynamic>))
        .toList();

    if (token == null || token == "" || !game.checkToken(token)) {
      return Response(401, {'Content-type': 'application/json'},
          {'status': 'InvalidToken', 'msg': 'tokenが指定されていない。または、tokenが一致しない'});
    }

    FieldInfo fieldInfo = game.getFieldInfo(token, matchID);
    if (fieldInfo == null) {
      return Response(400, {
        'Content-type': 'application/json'
      }, {
        'startAtUnixTime': 0,
        'status': 'InvalidMatches',
        'msg': 'matchIDが不正です'
      });
    }

    if (!game.isStarted) {
      return Response(400, {'Content-type': 'application/json'},
          {'status': 'TooEarly', 'msg': '開始時間前です'});
    }

    if (game.isTurnInterval(game.currentTime)) {
      return Response(400, {'Content-type': 'application/json'},
          {'status': 'UnacceptableTime', 'msg': 'ターン間の待ち時間です'});
    }

    final unknownList = actions
        .where((a) => a.type == AgentActionType.Unknown)
        .toList(growable: false);
    if (unknownList.length > 1) {
      return Response(606, {
        'Content-type': 'application/json'
      }, {
        'code': 606,
        'message': 'type in body should be one of [move remove stay]'
      });
    }

    final result = game.setActions(token, actions);
    if (result == null) {
      return Response(400, {'Content-type': 'application/json'},
          {'status': 'UnacceptableTime', 'msg': '開始していないか、ターン間の待ち時間です'});
    }

    game.printInfo();
    return Response.ok({'actions': result});
  }
}
