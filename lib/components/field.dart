/*
*  フィールド管理のクラス
* ・フィールドのスコア 2darray read / write
* ・フィールドのサイズ int read / write
*/

import 'package:aqueduct/aqueduct.dart';
import 'package:server/components/agent.dart';
import 'package:server/components/agent_action.dart';
import 'package:server/components/point.dart';
import 'package:server/components/tuple.dart';

class Tile {
  static const Free = 0;
  static const Wall = -9999;

  /// 座標（いらんかもね）
  int x, y;

  /// 得点
  int score;

  /// 状態。Free, Wall, teamIDが入る
  int state;

  Tile(this.x, this.y, this.score, this.state);

  void set(Tile t) {
    x = t.x;
    y = t.y;
    score = t.score;
    state = t.state;
  }

  bool get isWall => state == Wall;

  bool get isFree => state == Free;
}

class Field extends Serializable {
  final int wallLength = 2; // 壁の幅

  int fieldID;

  int width; // フィールドの幅

  int height; // フィールドの高さ

  int get dataWidth => width + wallLength;

  int get dataHeight => height + wallLength;

  Point size;

  /// タイル情報（２次元配列やめた）
  List<Tile> tiles = <Tile>[];

  int indexX(int index) => (index / width).floor();

  int indexY(int index) => index % width;

  List<Tuple<Agent, AgentAction>> checkArray = <Tuple<Agent, AgentAction>>[];

  /// タイルの情報をとる
  /// x: よこ
  /// y: たて
  /// return: タイル情報[Tile]
  Tile tile(int x, int y) => tiles[(y + 1) * dataWidth + (x + 1)];

  Tile tileP(Point p) => tiles[(p.y + 1) * dataWidth + (p.x + 1)];

  Tuple<Agent, AgentAction> getCheckArray(int x, int y) =>
      checkArray[(y + 1) * dataWidth + (x + 1)];

  Tuple<Agent, AgentAction> getCheckArrayP(Point p) =>
      checkArray[(p.y + 1) * dataWidth + (p.x + 1)];

  void clearCheckArray() {
    checkArray.forEach((elem) => elem.set(null, null));
  }

  Field() : super();

  Field.create(int width, int height) : super() {
    changeSize(width, height);
  }

  Field.fromMap(Map<String, dynamic> object) : super() {
    readFromMap(object);
  }

  // フィールドサイズを変更
  void changeSize(int width, int height) {
    this.width = width;
    this.height = height;

    size = Point.setValue(width, height);

    print('width=$width');
    print('height=$height');

    _initArray(dataWidth, dataHeight); // 新しいフィールドを1で初期化しておく
  }

  _initArray(int w, int h) {
    // フィールドを初期化する
    tiles.clear();
    checkArray.clear();

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        tiles.add(Tile(x - 1, y - 1, x * y, Tile.Free));
        checkArray.add(Tuple.setValue(null, null));
      }
    }

    // 壁の設定
    for (int x = 0; x < w; x++) {
      tiles[0 * dataWidth + x]
        ..x = -1
        ..y = -1
        ..state = Tile.Wall;
      tiles[(h - 1) * dataWidth + x]
        ..x = -1
        ..y = -1
        ..state = Tile.Wall;
    }

    for (int y = 0; y < h; y++) {
      tiles[y * dataWidth + 0]
        ..x = -1
        ..y = -1
        ..state = Tile.Wall;
      tiles[y * dataWidth + (w - 1)]
        ..x = -1
        ..y = -1
        ..state = Tile.Wall;
    }
  }

  /// 指定した点pがフィールド内かどうか
  bool inside(Point p) {
    return p >= 0 && p < size;
  }

  getPointsArray() => getArray2d<int>((t) => t.score);

  getTiledArray() => getArray2d<int>((t) => t.state);

  /// ２次元配列を得る
  /// @param func 変換のためのラムダ式
  /// @param keelWall 壁部分のデータも保持する
  /// @returns List<List<T>>の２次元配列
  ///
  /// 壁無しのスコアの２次元配列
  /// List<List<int>> score_array = field.getArray2d<int>((tile)=>tile.score);
  ///
  /// 壁無しのboolの２次元配列
  /// List<List<bool>> bool_array = field.getArray2d<bool>((tile)=>false);
  ///
  /// 壁ありの自陣地の２次元配列
  /// List<List<int>> own_array = field.getArray2d<int>((tile)=>tile.state == TileState.Own ? 1 : 0, keepWall: true);
  ///
  /// 得点が10点以上の陣地の２次元配列
  /// List<List<int>> array10 = field.getArray2d<int>((tile)=>tile.score >= 10 ? 1 : 0);
  ///
  List<List<T>> getArray2d<T>(T Function(Tile) func, {bool keepWall: false}) {
    int w = keepWall ? dataWidth : width;
    int h = keepWall ? dataHeight : height;
    int n = keepWall ? 0 : 1;
    List<List<T>> ary = List<List<T>>(h);

    for (int y = 0; y < h; y++) {
      int index = (y + n) * dataWidth + n;
      ary[y] =
          tiles.sublist(index, index + w).map(func).toList(growable: false);
    }

    return ary;
  }

  /// 指定した配列を得る
  List<T> getArray<T>(T Function(Tile) func) {
    return tiles.map(func).toList(growable: false);
  }

  /// ４近傍のタイルを返す
  /// 以下のような使い方ができる素敵な仕様
  /// field.neighborTiles4(2, 3).forEach((t){ print('${t.x},${t.y}'); });
  /// for(var tile in field.neighborTiles4(4, 5)) { ... }
  Iterable<Tile> neighborTiles4(int x, int y) sync* {
    // 上、右、下、左の順
    var nei = [
      [0, 1],
      [1, 0],
      [0, -1],
      [-1, 0]
    ];

    for (var i = 0; i < nei.length; i++) {
      var t = tile(x + nei[i][0], y + nei[i][1]);
      if (t.state != Tile.Wall) yield t;
    }
  }

  /// ８近傍のタイルを返す
  /// 以下のような使い方ができる素敵な仕様
  /// field.neighborTiles8(2, 3).forEach((t){ print('${t.x},${t.y}'); });
  /// for(var tile in field.neighborTiles8(4, 5)) { ... }
  Iterable<Tile> neighborTiles8(int x, int y) sync* {
    // 上、右上、右、右下、下、左下、左、左上の順
    var nei = [
      [0, 1],
      [1, 1],
      [1, 0],
      [1, -1],
      [0, -1],
      [-1, -1],
      [-1, 0],
      [-1, 1]
    ];

    for (var i = 0; i < nei.length; i++) {
      var t = tile(x + nei[i][0], y + nei[i][1]);
      if (t.state != Tile.Wall) yield t;
    }
  }

  /// y行のタイルを返す
  Iterable<Tile> rows(int y) sync* {
    for (var i = 0; i < width; i++) {
      var t = tile(i, y);
      if (t.state != Tile.Wall) yield t;
    }
  }

  /// x列のタイルを返す
  Iterable<Tile> cols(int x) sync* {
    for (var i = 0; i < height; i++) {
      var t = tile(x, i);
      if (t.state != Tile.Wall) yield t;
    }
  }

  /// エリアポイントを得る
  /// @param target teamID
  /// @returns エリアポイント
  int getAreaPoint(int target) {
    var flagary = getArray2d<bool>((t) => false);

    rows(0).forEach((t) => _checkAreaPoint(t, target, flagary));
    rows(height - 1).forEach((t) => _checkAreaPoint(t, target, flagary));

    cols(0).forEach((t) => _checkAreaPoint(t, target, flagary));
    cols(width - 1).forEach((t) => _checkAreaPoint(t, target, flagary));

    int point = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (!flagary[y][x]) {
          var t = tile(x, y);
          point += t.state != target ? t.score.abs() : 0;
        }
      }
    }

    return point;
  }

  /// エリアポイントチェック用
  _checkAreaPoint(Tile t, int target, List<List<bool>> flagary) {
    if (t.state == target || flagary[t.y][t.x]) return;

    flagary[t.y][t.x] = true;
    neighborTiles4(t.x, t.y)
        .forEach((tt) => _checkAreaPoint(tt, target, flagary));
  }

  /// タイルポイントを得る
  /// @param target teamID
  /// @returns タイルポイント
  int getTilePoint(int target) {
    return tiles.where((t) => t.state == target).fold(0, (p, t) => p + t.score);
  }

  /// エリアポイント＋タイルポイントを得る
  /// @param target TileState.OwnまたはTileState.Enemy
  /// @returns エリアポイント＋タイルポイント
  int getPoint(int target) {
    return getAreaPoint(target) + getTilePoint(target);
  }

  List<int> _collectTeamID() {
    var ids = tiles
        .where((t) => t.state != Tile.Free && t.state != Tile.Wall)
        .map((t) => t.state)
        .toSet()
        .toList(growable: false);
    ids.sort();
    return ids;
  }

  ///
  /// @params index 0 for player1, 1 for player2
  int findTeamID(int index) {
    var ids = _collectTeamID();
    if (ids.length != 2) return -1;
    return ids[index];
  }

  void remapTeamID(int player1, int player2) {
    var ids = _collectTeamID();
    print('collected ids: $ids');

    if (ids.length != 2) return;

    Map<int, int> teamIdMap = {
      Tile.Free: Tile.Free,
      Tile.Wall: Tile.Wall,
      ids[0]: player1,
      ids[1]: player2
    };

    print('remapTeamID: ${teamIdMap}');

    tiles.forEach((t) => t.state = teamIdMap[t.state]);
  }

  /// clone Field (deep copy)
  /// @returns field
  Field clone() {
    Field newfield = Field();
    newfield.changeSize(width, height);
    var n = newfield.tiles.length;
    for (var i = 0; i < n; i++) {
      newfield.tiles[i].set(tiles[i]);
    }
    return newfield;
  }

  void setTiles(Field f) {
    var n = tiles.length;
    if (n == f.tiles.length) {
      print("set tiles...");
      for (var i = 0; i < n; i++) {
        tiles[i].set(f.tiles[i]);
      }
    }
  }

  @override
  Map<String, dynamic> asMap() => {
        'fieldID': fieldID,
        'width': width,
        'height': height,
        'points': getPointsArray(),
        'tiled': getTiledArray()
      };

  dynamic toJson() => asMap();

  @override
  void readFromMap(Map<String, dynamic> object) {
    fieldID = object['fieldID'] as int;
    width = object['width'] as int;
    height = object['height'] as int;
    final points = object['points'] as List<dynamic>;
    final tiled = object['tiled'] as List<dynamic>;
    changeSize(width, height);

    for (var y = 0; y < height; y++) {
      final p = points[y]; // as List<int>;
      final s = tiled[y]; // as List<int>;
      rows(y).skip(1).forEach((t) {
        if (t.x != -1) {
          t.score = p[t.x] as int;
          t.state = s[t.x] as int;
        }
      });
    }
  }
}
