import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:server/channel.dart';

export 'package:aqueduct/aqueduct.dart';
export 'package:server/server.dart';
export 'package:test/test.dart';

/// A testing harness for server.
///
/// A harness for testing an aqueduct application. Example test file:
///
///         void main() {
///           Harness harness = Harness()..install();
///
///           test("GET /path returns 200", () async {
///             final response = await harness.agent.get("/path");
///             expectResponse(response, 200);
///           });
///         }
///
class Harness extends TestHarness<ServerChannel> {
  @override
  Future onSetUp() async {}

  @override
  Future onTearDown() async {}
}
