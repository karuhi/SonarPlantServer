import 'package:aqueduct/aqueduct.dart';
import 'package:server/components/field_info.dart';
import 'package:server/components/game.dart';
import 'package:server/server.dart';

class MatchController extends ResourceController {
//  Game game;
//
//  MatchController(this.game) : super();

  int get matchID => int.parse(request.path.variables['matchID']);

  /// 対戦リストを取得する
  /// GET /matches
  @Operation.get()
  Future<Response> getMatchList(
      @Bind.header('authorization') String token) async {

    Game game = Game();

    if (token == null || token == "") {
      return Response(401, {'Content-type': 'application/json'},
          {'status': 'InvalidToken', 'msg': 'tokenが指定されていない'});
    }

    if (!game.existPlayer(token)) {
      return Response(401, {'Content-type': 'application/json'},
          {'status': 'InvalidToken', 'msg': 'tokenが一致しない'});
    }

    return Response.ok(game.getMatchInfos(token));
  }

  /// 現在のフィールド情報を取得する
  /// GET /matches/:matchID
  @Operation.get('matchID')
  Future<Response> getField(@Bind.header('authorization') String token) async {

    Game game = Game();
    
    print('MatchController.getField');
    print('  matchID: $matchID');
    print('  token: $token');
    
    if (token == null || token == "") {
      return Response(401, {'Content-type': 'application/json'},
          {'status': 'InvalidToken', 'msg': 'tokenが指定されていない'});
    }

    if (!game.existPlayer(token)) {
      return Response(401, {'Content-type': 'application/json'},
          {'status': 'InvalidToken', 'msg': 'tokenが一致しない'});
    }

    FieldInfo fieldInfo = game.getFieldInfo(token, matchID);
    if (fieldInfo == null) {
      return Response(400, {
        'Content-type': 'application/json'
      }, {
        'startAtUnixTime': 0,
        'status': 'InvalidMatches',
        'msg': 'matchIDが不正です。Field情報が見つからない'
      });
    }

    if (!game.isStarted) {
      return Response(400, {'Content-type': 'application/json'},
          {'status': 'TooEarly', 'msg': '開始時間前です'});
    }

//    if(game.isTurnInterval(game.currentTime)) {
//      return Response(400, {'Content-type': 'application/json'},
//          {'status': 'UnacceptableTime', 'msg': 'ターン間の待ち時間前です'});
//    }

    return Response.ok(fieldInfo.asMap());
  }
}
