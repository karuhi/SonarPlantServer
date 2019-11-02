import 'dart:math';

import 'package:args/args.dart';
import 'package:server/components/field.dart';
import 'package:server/components/field_info.dart';

void main(List<String> arguments) {
  final parser = ArgParser(allowTrailingOptions: true)
    ..addFlag('vertical',
        abbr: 'v',
        defaultsTo: true,
        help: '縦方向に対称のフィールドを生成します。--horizontalと同時に設定することで点対称にフィールドを生成します。')
    ..addFlag('horizontal',
        abbr: 'h',
        defaultsTo: true,
        help: '横方向に対称のフィールドを生成します。--verticalと同時に設定することで点対称にフィールドを生成します。')
    ..addOption('cols', abbr: 'c', defaultsTo: '20', help: 'フィールドの横方向のサイズ')
    ..addOption('rows', abbr: 'r', defaultsTo: '20', help: 'フィールドの縦方向のサイズ')
    ..addOption('agent', abbr: 'a', defaultsTo: '3', help: 'エージェントの数')
    ..addOption('fieldID', abbr: 'i', defaultsTo: '1', help: 'フィールドID')
    ..addFlag('help', abbr: '?', help: 'このヘルプを表示');

  var results = parser.parse(arguments);

  if (results['help'] as bool) {
    print(parser.usage);
    return;
  }

  bool verticalSymmetry = results['vertical'] as bool;
  bool horizontalSymmetry = results['horizontal'] as bool;
  int width = int.parse(results['cols'] as String);
  int height = int.parse(results['rows'] as String);
  int numAgents = int.parse(results['agent'] as String);

  FieldInfo info = FieldInfo();
  info.field.changeSize(width, height);

  createFieldScore(info, horizontalSymmetry, verticalSymmetry);
}

void createFieldScore(
    FieldInfo info, bool horizontalSymmetry, bool verticalSymmetry) {
  var random = Random();

  bool centrosymmetry = verticalSymmetry && horizontalSymmetry;

  int nw = horizontalSymmetry ? (info.width / 2).round() : info.width;
  int nh = verticalSymmetry ? (info.height / 2).round() : info.height;

  for (int y = 0; y < nh; y++) {
    for (int x = 0; x < nw; x++) {
      int s = random.nextInt(33) - 16; // -16 から +16 のスコアを生成
      info.field.tile(x, y)
        ..state = Tile.Free
        ..score = s;
      if (centrosymmetry) {
        info.field.tile(info.width - x - 1, info.height - y - 1)
          ..state = Tile.Free
          ..score = s;
      }
      if (horizontalSymmetry) {
        info.field.tile(info.width - x - 1, y)
          ..state = Tile.Free
          ..score = s;
      }
      if (verticalSymmetry) {
        info.field.tile(x, info.height - y - 1)
          ..state = Tile.Free
          ..score = s;
      }
    }
  }
}
