import 'dart:typed_data';

import '../common/int_x.dart';
import '../common/x_reader.dart';

class XQFHeader {
  late Short signature; // 文件标记 'XQ' = $5158
  late Byte version; // 版本号
  late Byte keyMask; // 加密掩码
  late Short productId; // 产品号(厂商的产品号)
  late Byte keyA;
  late Byte keyB;
  late Byte keyC;
  late Byte keyD;
  late Byte keySum; // 加密的钥匙和
  late Byte keyPos; // 棋子布局位置钥匙
  late Byte keyFrom; // 棋谱起点钥匙
  late Byte keyTo; // 棋谱终点钥匙
  // = 16 Bytes
  Uint8List? board; // 32 Bytes 32个棋子的原始位置
  // = 48 Bytes
  late Short moveNo; // 棋谱文件的开始步数
  late Byte whoPlay; // 该谁下
  late Byte result; // 最终结果
  late Short moveCount; // 本棋谱一共记录了多少步
  late Short startPos; // 对弈树在文件中的起始位置
  Uint8List? reserved1; // 8 Bytes
  // = 64 Bytes
  late Short type; // 对局类型(开,中,残等)
  late Short otherType; // 另外的类型
  // = 80  Bytes
  String titleA = ''; // String[63] 标题
  String titleB = ''; // String[63]
  // = 208 Bytes
  String matchName = ''; // String[63] 比赛名称
  String matchTime = ''; // String[15] 比赛时间
  String matchAddress = ''; // String[15] 比赛地点
  String redPlayer = ''; // String[15] 红方姓名
  String blackPlayer = ''; // String[15] 黑方姓名
  // = 336 Bytes
  String timeRule = ''; // String[63] 开局类型
  String redTime = ''; // String[15]
  String blkTime = ''; // String[15]
  String reserved = ''; // String[31]
  // = 464 Bytes
  String commenter = ''; // String[15] 棋谱评论员
  String author = ''; // String[15] 文件的作者
  // = 496 Bytes
  Uint8List? reserved2; // 16 Bytes
  // = 512 Bytes
  Uint8List? reserved3; // 512 Bytes

  XQFHeader(XReader reader) {
    // pos -> 0
    signature = reader.readShort(defaultValue: -1)!;
    version = reader.readByte(defaultValue: -1)!;
    keyMask = reader.readByte(defaultValue: -1)!;
    productId = reader.readShort(defaultValue: -1)!;
    reader.readShort(defaultValue: -1)!; // skip
    keyA = reader.readByte(defaultValue: -1)!;
    keyB = reader.readByte(defaultValue: -1)!;
    keyC = reader.readByte(defaultValue: -1)!;
    keyD = reader.readByte(defaultValue: -1)!;
    keySum = reader.readByte(defaultValue: -1)!;
    keyPos = reader.readByte(defaultValue: -1)!;
    keyFrom = reader.readByte(defaultValue: -1)!;
    keyTo = reader.readByte(defaultValue: -1)!;
    // pos -> 16
    board = reader.readBytes(32);
    // pos -> 48
    moveNo = reader.readShort(defaultValue: -1)!;
    whoPlay = reader.readByte(defaultValue: -1)!;
    result = reader.readByte(defaultValue: -1)!;
    moveCount = reader.readShort(defaultValue: -1)!;
    startPos = reader.readShort(defaultValue: -1)!;
    reserved1 = reader.readBytes(8);
    // pos -> 64
    type = reader.readShort(defaultValue: -1)!;
    otherType = reader.readShort(defaultValue: -1)!;
    reader.readBytes(12); // for skip
    // pos ->80
    reader.readByte(defaultValue: -1)!;
    titleA = reader.readString(63) ?? '';
    reader.readByte(defaultValue: -1)!;
    titleB = reader.readString(63) ?? '';
    reader.readByte(defaultValue: -1)!;
    matchName = reader.readString(63) ?? '';
    reader.readByte(defaultValue: -1)!;
    matchTime = reader.readString(15) ?? '';
    reader.readByte(defaultValue: -1)!;
    matchAddress = reader.readString(15) ?? '';
    reader.readByte(defaultValue: -1)!;
    redPlayer = reader.readString(15) ?? '';
    reader.readByte(defaultValue: -1)!;
    blackPlayer = reader.readString(15) ?? '';
    reader.readByte(defaultValue: -1)!;
    timeRule = reader.readString(63) ?? '';
    reader.readByte(defaultValue: -1)!;
    redTime = reader.readString(15) ?? '';
    reader.readByte(defaultValue: -1)!;
    blkTime = reader.readString(15) ?? '';
    reader.readByte(defaultValue: -1)!;
    reserved = reader.readString(31) ?? '';
    reader.readByte(defaultValue: -1)!;
    commenter = reader.readString(15) ?? '';
    reader.readByte(defaultValue: -1)!;
    author = reader.readString(15) ?? '';

    reserved2 = reader.readBytes(16);
    reserved3 = reader.readBytes(512);
  }

  void setRandomSecurityKeys() {
    var flag = 0;

    keyPos = Byte(255);
    flag += keyPos.value;

    keyFrom = Byte(255);
    flag += keyFrom.value;

    keyTo = Byte(255);
    flag += keyTo.value;

    keySum = Byte(256 - flag);
  }

  bool get isKeysSumZero {
    return ((keySum.value + keyPos.value + keyFrom.value + keyTo.value) & 0xFF) == 0;
  }

  String get resultDesc {
    switch (result.value) {
      case 1:
        return '红胜';
      case 2:
        return '黑胜';
      case 3:
        return '和棋';
      default:
        return '*';
    }
  }

  String get typeDesc {
    switch (type.value) {
      case 1:
        return '实战全局';
      case 2:
        return '摆谱全局';
      case 3:
        return '实战残局';
      case 4:
        return '摆谱残局';
      default:
        return '未知';
    }
  }

  String get description {
    var info = '';

    if (type.value != 0) {
      info += '棋局类型 $typeDesc\n';
    }
    if (titleA.isNotEmpty) {
      info += '棋局标题 $titleA\n';
    }
    if (titleB.isNotEmpty) {
      info += '棋局标题 $titleB\n';
    }
    if (matchName.isNotEmpty) {
      info += '比赛名称 $matchName\n';
    }
    if (matchTime.isNotEmpty) {
      info += '比赛日期 $matchTime\n';
    }
    if (matchAddress.isNotEmpty) {
      info += '比赛地点 $matchAddress\n';
    }
    if (redPlayer.isNotEmpty) {
      info += '红方棋手 $redPlayer\n';
    }
    if (blackPlayer.isNotEmpty) {
      info += '黑方棋手 $blackPlayer\n';
    }
    if (whoPlay.value != 0) {
      info += '先行 $whoPlay\n';
    }
    if (result.value != 0) {
      info += '比赛结果 $resultDesc\n';
    }
    if (commenter.isNotEmpty) {
      info += '讲评人员 $commenter\n';
    }
    if (author.isNotEmpty) {
      info += '创建人 $author\n';
    }

    return info;
  }
}

class XQFMove {
  late Short moveNo; // 第几步，开局状态为第0步
  late Byte orgFrom, orgTo; // 本步棋的起始、目的位置XY

  late Uint8List board; // 本步棋走后32个子的位置

  late int childTag; // 孩子的标记
  XQFMove? leftChild, rightChild; // 左孩子、右孩子 (实际是兄弟)
  // LParent 和 RParent 必须有一个为 nil, 如果该节点是双亲的左孩子，则 LP 为 nil, 反之, RP 为 nil
  XQFMove? leftParent, rightParent;

  late String comment; // 本步棋的注解
  late XQFMove prevMove; // 上一步棋的节点

  XQFMove.empty() {
    board = Uint8List(32);
  }

  XQFMove(this.board, this.prevMove, this.leftParent, this.rightParent) {
    board = Uint8List(32);
    if (leftParent != null) leftParent!.rightChild = this;
    if (rightParent != null) rightParent!.leftChild = this;
  }

  static int crossIndexOf(int coordinate) {
    final file = coordinate ~/ 10, rank = 9 - (coordinate % 10);
    return rank * 9 + file;
  }

  bool get hasLeftChild => (childTag & 0x80) != 0;

  bool get hasRightChild => (childTag & 0x40) != 0;

  Short get index => moveNo;

  int get from => orgFrom.value;

  int get to => orgTo.value;
}
