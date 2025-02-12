import '../../common/x_reader.dart';

class CBL3Move {
  bool? isBranch, isLast;
  int? from, to;
  String? comment;

  CBL3Move.load(XReader reader) {
    final mark = reader.readByte()!.value;

    isLast = (mark & 00000001 != 0);
    isBranch = (mark & 00000010 != 0);
    final hasComment = (mark & 00000100 != 0);

    // skip branchCount
    reader.readByte();

    if (reader.isEnd) return;

    from = reader.readByte()!.value;
    to = reader.readByte()!.value;

    if (hasComment) {
      final length = reader.readInt();
      comment = reader.readUtf16Le(length ?? 0);
    }
  }

  @override
  String toString() {
    var str = '$from => $to';
    if (isBranch ?? false) str += ', isBranch';
    if (isLast ?? false) str += ', isLast';
    if (comment != null) str += ', $comment';
    return str;
  }
}
