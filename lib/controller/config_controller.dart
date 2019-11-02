import 'package:aqueduct/aqueduct.dart';
import 'package:server/components/game.dart';
import 'package:server/server.dart';

class ConfigController extends ResourceController {
//  Game game;
//
//  ConfigController(this.game) : super();

  @Operation.get()
  Future<Response> showConfig() async {
    return Response.ok({'status': 'ok'});
  }

  @Operation.post('command')
  Future<Response> setConfig(@Bind.path('command') String command) async {

    Game game = Game();

    print('post command: $command');

    if (command.startsWith('set')) {
      print('body: ${request.body.as()}');
      if (request.body.as() == null) {
        Response.badRequest(body: {'status': 'InvalidParams'});
      }
      game.readConfig(request.body.as());
      game.readPlayers(request.body.as());
      game.readMatchInfos(request.body.as());
      game.readFields(request.body.as());
      game.prepare();
    } else if (command.startsWith('config')) {
      if (request.body.as() == null) {
        Response.badRequest(body: {'status': 'InvalidParams'});
      }
      game.readConfig(request.body.as());
    } else if (command.startsWith('player')) {
      if (request.body.as() == null) {
        Response.badRequest(body: {'status': 'InvalidParams'});
      }
      game.readPlayers(request.body.as());
    } else if (command.startsWith('match')) {
      if (request.body.as() == null) {
        Response.badRequest(body: {'status': 'InvalidParams'});
      }
      game.readMatchInfos(request.body.as());
    } else if (command.startsWith('field')) {
      if (request.body.as() == null) {
        Response.badRequest(body: {'status': 'InvalidParams'});
      }
      game.readFields(request.body.as());
    } else if (command.startsWith('prepare')) {
      game.prepare();
    }

    return Response.ok({'status': 'ok'});
  }
}
