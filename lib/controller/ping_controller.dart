import 'package:aqueduct/aqueduct.dart';
import 'package:server/components/game.dart';
import 'package:server/server.dart';

class PingController extends ResourceController {
//  Game game;
//
//  PingController(this.game) : super();

  @Operation.get()
  Future<Response> ping({@Bind.header('Authorization') String token}) async {

    Game game = Game();

    if (token == null) {
      return Response.unauthorized(
          body: {'status': 'InvalidToken', 'msg': 'tokenが指定されていない'});
    }

    if (game.existPlayer(token)) {
      return Response.ok({'status': 'ok'});
    }

    return Response.unauthorized(
        body: {'status': 'InvalidToken', 'msg': 'tokenが一致しない'});
  }
}
