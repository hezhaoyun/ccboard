import '../../common/int_x.dart';
import '../../common/x_reader.dart';

class CBL2Move {
  static const rPiecesA = '车马相仕帅炮兵前中后';
  static const bPiecesA = '车马象士将炮卒前中后';

  static const rPiecesB = '一二三四五六七八九车马相仕帅炮兵';
  static const bPiecesB = '１２３４５６７８９车马象士将炮卒';

  static const moveDir = '进退平';

  static const chineseDigits = '一二三四五六七八九';
  static const fullFormedDigits = '１２３４５６７８９';

  late bool redSide;

  /// 前2字节标明该步行棋的序号，序号是用来判断变着结构的唯一标准。中间两个
  /// 字节用来表示坐标。后两个字节为行棋文字表述。

  late Short index;

  /// 中间2字节的坐标表示中，前1字节为棋子移出坐标，后1字节为棋子移入坐标。高4位值+1
  /// 表示X轴坐标值，低4为值+1表示Y轴坐标值。

  late Byte orgFrom, orgTo;

  /// 后两字节为行棋文字表述，文字表述每步棋为4个中文字，如：炮二平五。每个字节分为高4
  /// 位与低4位，共同构成4字表述。（文字行棋表述加入是为了载入棋谱时加快处理速度，但违背了
  /// 唯一性原则和浪费了空间，将会在以后版本的棋库格式中去除。在此版本中，文字棋谱表述是必
  /// 须的，而且要确保其正确性。）
  /// 把这2字节每4位按次序分为4部分，每部分的值相对应的文字为(这儿还要区分红黑方，确定
  /// 红黑方可以通过先行方及当前行棋序数共同组合来判断)：
  /// 红方行棋时：
  /// 1.车、马、相、仕、帅、炮、兵、前、中、后
  /// 2.一、二、三、四、五、六、七、八、九、车、马、相、仕、帅、炮、兵
  /// 3.进、退、平
  /// 4.一、二、三、四、五、六、七、八、九
  /// 黑方行棋时：
  /// 1.车、马、象、士、将、炮、卒、前、中、后
  /// 2.１、２、３、４、５、６、７、８、９、车、马、象、士、将、炮、卒
  /// 3.进、退、平
  /// 4.１、２、３、４、５、６、７、８、９
  /// 上述文字的对应值的基数为0，也就是说第一个字对应的值为0。
  /// 在象棋桥的文字表述中，有一个原则是能不用“前、后”二字的地方就不用“前、后”二字。

  late Short desc;

  String comment = '';

  CBL2Move.loadWithReader(XReader reader) {
    index = reader.readShort(defaultValue: -1)!;

    orgFrom = reader.readByte(defaultValue: -1)!;
    orgTo = reader.readByte(defaultValue: -1)!;

    desc = reader.readShort(defaultValue: -1)!;
  }

  String moveDesc() {
    final bitAB = desc.value & 0xFF, bitCD = desc.value >> 8;
    final idxA = bitAB >> 4, idxB = bitAB & 0x0F, idxC = bitCD >> 4, idxD = bitCD & 0x0F;

    var result = redSide ? rPiecesA[idxA] : bPiecesA[idxA];
    result += redSide ? rPiecesB[idxB] : bPiecesB[idxB];
    result += moveDir[idxC];
    result += redSide ? chineseDigits[idxD] : fullFormedDigits[idxD];

    return result;
  }

  static int crossIndexOf(int coord) {
    final rank = coord & 0x0f, file = coord >> 4;
    return rank * 9 + file;
  }

  int get from => crossIndexOf(orgFrom.value);

  int get to => crossIndexOf(orgTo.value);
}
