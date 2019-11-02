import 'package:server/components/game.dart';
import 'package:server/controller/action_controller.dart';
import 'package:server/controller/config_controller.dart';
import 'package:server/controller/game_controller.dart';
import 'package:server/controller/match_controller.dart';
import 'package:server/controller/ping_controller.dart';

import 'server.dart';

class ServerChannel extends ApplicationChannel {
  Game game = Game();

  @override
  Future prepare() async {
    logger.onRecord.listen(
        (rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
  }

  @override
  Controller get entryPoint {
    final router = Router();

    router.route("/ping").link(() => PingController());

    router.route('/config/[:command]').link(() => ConfigController());

    router.route('/game/[:command]').link(() => GameController());

    router.route('/matches/[:matchID]').link(() => MatchController());

    router.route('/matches/:matchID/action').link(() => ActionController());

    return router;
  }
}
