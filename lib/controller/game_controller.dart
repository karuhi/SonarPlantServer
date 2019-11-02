import 'package:aqueduct/aqueduct.dart';
import 'package:server/components/game.dart';
import 'package:server/server.dart';

class GameController extends ResourceController {
//  Game game;
//
//  GameController(this.game) : super();

  @Operation.get()
  Future<Response> showStatus() async {

    Game game = Game();

    return Response.ok({'players': game.players.toString()});
  }

  @Operation.get('command')
  Future<Response> doCommand() async {

    Game game = Game();

    final command = request.path.variables['command'];

    switch (command) {
      case 'start':
        game.start();
        return Response.ok({'status': 'ok', 'msg': 'start game'});
        break;

//      case 'stop':
//        game.stop();
//        return Response.ok({'status': 'ok', 'msg': 'stop game'});
//        break;

      case 'clear':
        game.clear();
        return Response.ok({'status': 'ok', 'msg': 'clear data'});
        break;

      case 'next_turn':
        game.nextTurn(force: true);
        return Response.ok({'status': 'ok', 'msg': 'turn end'});
        break;

      case 'result':
        return Response.ok(
            {'status': 'ok', 'result': game.getGameResult().toString()});
        break;

      case 'status':
        return Response.ok(
            {'status': 'ok', 'game_status': game.getGameStatus().toString()});
        break;

      default:
        return Response.badRequest(headers: {'status': 'BadRequest'});
    }
  }
}
