import 'dart:io';
import 'dart:typed_data';

class Message {
  List<int> packet = [];
  String address;
  String tags = "";
  List<List<int>> rawdata =
      <List<int>>[]; // each argument will be a list of int
  List<Object> data = <Object>[]; // each argument decoded

  Message(this.address);

  factory Message.parse(Uint8List data) {
    return Message("")
      ..data = data
      ..parse();
  }

  void addString(String s) {
    tags = "${tags}s";
    data.add(s);
  }

  void addFloat(double value) {
    tags = "${tags}f";
    data.add(value);
  }

  void addInt(int value) {
    tags = "${tags}i";
    data.add(value);
  }

  void makePacket() {
    // encode the data
    encode();

    // Append the appropriate zero bytes
    //     and merge the osc address with comma + osc tags
    packet = [
      appendZeroBytes(address).codeUnits,
      appendZeroBytes(",$tags").codeUnits,
      rawdata.expand((x) => x).toList(),
    ].expand((x) => x).toList();
  }

  void parse() {
    // Convert packet to string to work with it
    var packetS = String.fromCharCodes(packet);

    // clear the other properties first
    clearProperties();

    // the address will be the part leading the first zero byte
    address = packetS.split("\u0000")[0];

    // find the comma; the tags will follow
    final commasplit = packetS.split(",");
    if (commasplit.length < 2) {
      // if there is no comma
      return; // return only saving into our address field
    }

    // This will return the sub string trailing the first comma
    String aftercomma = commasplit.sublist(1).join();

    // This will split the aftercomma string by zero byte delimiters
    final zerosplit = aftercomma.split("\u0000");

    // if there were no zero bytes following the tag structure
    //     the message is not formatted properly
    if (zerosplit.length < 2) {
      return; // return without writing the tags
    }

    // assign the tags to the portion between comma and zero byte NOT inclusive
    tags = zerosplit[0];

    // get the data after the tag portion
    String dataS = aftercomma.substring(tags.length + zerosToAdd(",$tags"));

    //for (var t in tags.runes) {
    for (int i = 0; i < tags.length; i++) {
      switch (tags[i]) {
        case "f":
          // next four bytes
          rawdata.add(dataS.substring(0, 4).codeUnits);
          dataS = dataS.substring(4);
          break;
        case "i":
          // next four bytes
          rawdata.add(dataS.substring(0, 4).codeUnits);
          dataS = dataS.substring(4);
          break;
        case "s":
          // portion before the next zerobyte
          final stringToAdd = dataS.split("\u0000")[0];
          rawdata.add(stringToAdd.codeUnits);
          dataS = dataS.substring(stringToAdd.length + zerosToAdd(stringToAdd));
          break;
      }
    }

    //decode
    decode();
  }

  void decode() {
    // clear anything in data
    data = <Object>[];

    for (int i = 0; i < tags.length; i++) {
      switch (tags[i]) {
        case "f":
          data.add(decodeFloat32(rawdata[i]));
        case "i":
          data.add(decodeInt32(rawdata[i]));
        case "s":
          data.add(String.fromCharCodes(rawdata[i]));
      }
    }

    return;
  }

  void encode() {
    // clear anything in raw data
    rawdata = <List<int>>[];
    // iterate according to tags
    for (int i = 0; i < tags.length; i++) {
      List<int> byt;
      bool ok;
      switch (tags[i]) {
        case "f": // float32
          (byt, ok) = encodeFloat32(data[i]);
          if (!ok) {
            // add placeholding 4 zero bytes
            byt = ("\u0000" * 4).codeUnits;
          }
          rawdata.add(byt);
        case "i": // int32
          (byt, ok) = encodeInt32(data[i]);
          if (!ok) {
            // add placeholding 4 zero bytes
            byt = ("\u0000" * 4).codeUnits;
          }
          rawdata.add(byt);
        case "s": // string
          byt = data[i].toString().codeUnits;
          rawdata.add(byt);
      }
    }
  }

  void clearProperties() {
    // clears the properties of the message except the packet
    address = "";
    tags = "";
    rawdata = <List<int>>[];
    return;
  }
}

String appendZeroBytes(String s) {
  return s + ("\u0000" * zerosToAdd(s));
}

int zerosToAdd(String s) {
  return 4 - (s.length % 4);
}

ByteData getByteData(List<int> data) {
  return ByteData.sublistView(Uint8List.fromList(data));
}

double decodeFloat32(List<int> data) {
  return getByteData(data).getFloat32(0);
}

int decodeInt32(List<int> data) {
  return getByteData(data).getInt32(0);
}

(List<int>, bool) encodeInt32(Object value) {
  int x = -1;
  try {
    x = value as int;
  } catch (e) {
    stdout.write("cannot parse int");
    return (<int>[], false);
  }
  var bdata = ByteData(4);
  bdata.setInt32(0, x);
  return (bdata.buffer.asUint8List(0), true);
}

(List<int>, bool) encodeFloat32(Object value) {
  double x = -1;
  try {
    x = value as double;
  } catch (e) {
    stdout.write("cannot parse double");
    return (<int>[], false);
  }
  var bdata = ByteData(4);
  bdata.setFloat32(0, x);
  return (bdata.buffer.asUint8List(0), true);
}
