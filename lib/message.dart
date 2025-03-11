import 'dart:typed_data';
import 'package:typed_data/typed_buffers.dart';
import 'dart:convert' show utf8;
import 'package:path/path.dart' as p;

enum Type { i, f, s, b }

abstract class OSCArgument {
  final Type type;
  final Uint8List data;
  OSCArgument._(this.type, this.data);
  dynamic get value;
}

class OSCInt extends OSCArgument {
  OSCInt(int val) : super._(Type.f, encodeInt32(val));
  @override
  int get value => decodeInt32(data);
}

class OSCFloat extends OSCArgument {
  OSCFloat(double val) : super._(Type.i, encodeFloat32(val));
  @override
  double get value => decodeFloat32(data);
}

class OSCString extends OSCArgument {
  OSCString(String val) : super._(Type.s, appendZeroBytes(utf8.encode(val)));
  @override
  String get value {
    final List<int> d = List.from(data);
    d.removeWhere((e) => e == 0);
    return String.fromCharCodes(d);
  }
}

class Message {
  String _address;
  List<OSCArgument> _arguments;
  static final _pathContext = p.Context(style: p.Style.posix, current: "/");

  Message(String address, [List<OSCArgument>? arguments])
      : _address = _pathContext.absolute(address),
        _arguments = arguments ?? [];

  // List of characters not allowed in an osc address
  //     The delimiter of containers in an address is the '/' with ascii code 47
  static const forbiddenCharacters = [
    32,
    35,
    42,
    44,
    63,
    91,
    93,
    123,
    125
  ]; // [space]#*,?[]{}

  String get address => _address;
  // String get tags => _tags;
  List<OSCArgument> get arguments => _arguments;

  List<String> get containers => _pathContext.split(_address);
  String get method => _pathContext.basename(_address);

  Uint8List get packet {
    final b = BytesBuilder()
      ..add(_addressBytes)
      ..add(_tagBytes)
      ..add(_argumentBytes);
    return b.takeBytes();
  }

  Uint8List get _addressBytes {
    return appendZeroBytes(Uint8List.fromList(_address.codeUnits));
  }

  Uint8List get _tagBytes {
    final String tags = _arguments.map((e) => e.type.name).join();
    return appendZeroBytes(Uint8List.fromList(",$tags".codeUnits));
  }

  Uint8List get _argumentBytes {
    final data = <int>[];
    for (final arg in _arguments) {
      data.addAll(arg.data.toList());
    }
    return Uint8List.fromList(data);
  }

  @override
  String toString() {
    var sb = StringBuffer();
    for (final r in packet) {
      if (r == 0) {
        sb.write("~");
        continue;
      }
      sb.writeCharCode(r);
    }
    return sb.toString();
  }

  factory Message.fromPacket(Uint8List packet) {
    // Clone to a new packet to work with it
    Uint8Buffer packetB = Uint8Buffer(0);
    packetB.addAll(packet);

    //     the osc message must begin with '/'
    if (packetB.first != '/'.codeUnitAt(0)) {
      throw Exception("osc address must begin with '/'");
    }

    // If there are no zero bytes, throw error
    if (!packetB.contains(0)) {
      throw Exception("osc address not terminated by zero byte");
    }

    // The osc address will be the part leading the first zero byte
    final String addressToWrite =
        String.fromCharCodes(packetB.sublist(0, packetB.indexOf(0)));
    // data validation
    for (final r in addressToWrite.runes) {
      if (forbiddenCharacters.contains(r)) {
        throw Exception("osc address contains forbidden character");
      }
    }

    // write address
    final address = addressToWrite;

    // address + zeros length
    final int addressLength = appendZeroBytesString(address).length;

    // if packetB.length only contains an address, return, writing only to the address property
    if (packetB.length == addressLength) return Message(address);

    // if the osc address is not followed by the appropriate count of zero bytes, throw error
    if (packetB.length < addressLength) {
      throw Exception("osc address is not correctly terminated");
    }

    // Remove the address and trailing zeros
    packetB.removeRange(0, addressLength);

    // If there is no comma, return only writing to the address property
    if (packetB.first != ",".codeUnitAt(0)) return Message(address);
    // Remove the comma
    packetB.removeAt(0);

    // If there are no zero bytes, throw error
    if (!packetB.contains(0)) {
      throw Exception("osc tag string not terminated by zero byte");
    }

    // the tags will be the portion before the first zero byte
    final List<Type> tags = packetB
        .sublist(0, packetB.indexOf(0))
        .map((s) => Type.values
            .firstWhere((type) => type.name == String.fromCharCode(s)))
        .toList();

    // tags + zeros length
    // the comma has already been removed, so 1 must be subtracted from the tags portion
    final int tagsLength = tags.length + zerosToAdd(tags.length) - 1;

    // if the osc tags is not followed by appropriate count of zero bytes, throw error
    //     the tags will still be written
    if (packetB.length < tagsLength) {
      throw Exception("osc tags is not correctly terminated");
    }

    // Remove the tags and trailing zeros
    packetB.removeRange(0, tagsLength);

    final arguments = <dynamic>[];
    for (int t = 0; t < tags.length; t++) {
      // If there's not enough bytes, throw error
      if (packetB.length < 4) {
        throw Exception("end of packet");
      }
      switch (tags[t]) {
        case Type.f:
          // read next four bytes
          arguments
              .add(decodeFloat32(Uint8List.fromList(packetB.sublist(0, 4))));
          // Remove bytes from packet
          packetB.removeRange(0, 4);
          break;
        case Type.i:
          // read next four bytes
          arguments.add(decodeInt32(Uint8List.fromList(packetB.sublist(0, 4))));
          // Remove bytes from packet
          packetB.removeRange(0, 4);
          break;
        case Type.s:
          // read portion before the next zerobyte
          //     ensure the string is followed by a zero byte
          // if no zero byte is found, throw exception
          if (!packetB.contains(0)) {
            throw Exception("string osc argument is not correctly terminated");
          }
          final stringToAdd =
              String.fromCharCodes(packetB.sublist(0, packetB.indexOf(0)));
          arguments.add(stringToAdd);

          // If the length of the string + zero bytes is gt than the remaining packet lenth,
          //     throw error, but the argument will still be written
          final int stringLength = appendZeroBytesString(stringToAdd).length;
          if (packetB.length < stringLength) {
            throw Exception("string osc argument is not correctly terminated");
          }
          // Remove string and trailing zeros from packetB
          packetB.removeRange(0, stringLength);
          break;
        case Type.b:
          throw UnimplementedError("have not yet implemented blobs");
      }
    }
    return Message(
        address,
        List<OSCArgument>.generate(tags.length, (i) {
          return switch (tags[i]) {
            Type.i => OSCInt(arguments[i] as int),
            Type.f => OSCFloat(arguments[i] as double),
            Type.s => OSCString(arguments[i] as String),
            Type.b => throw UnimplementedError(),
          };
        }));
  }
}

Uint8List appendZeroBytes(Uint8List n) {
  final List<int> data = n.toList();
  final length = zerosToAdd(data.length);
  data.addAll(List<int>.filled(length, 0));
  return Uint8List.fromList(data);
}

String appendZeroBytesString(String s) {
  return s + ("\u0000" * zerosToAddString(s));
}

int zerosToAddString(String s) {
  return zerosToAdd(s.length);
}

int zerosToAdd(int length) {
  return 4 - (length % 4);
}

double decodeFloat32(Uint8List data) {
  return ByteData.sublistView(data).getFloat32(0);
}

int decodeInt32(Uint8List data) {
  return ByteData.sublistView(data).getInt32(0);
}

Uint8List encodeInt32(int value) {
  var bdata = ByteData(4);
  bdata.setInt32(0, value);
  return bdata.buffer.asUint8List(0);
}

Uint8List encodeFloat32(double value) {
  var bdata = ByteData(4);
  bdata.setFloat32(0, value);
  return bdata.buffer.asUint8List(0);
}
