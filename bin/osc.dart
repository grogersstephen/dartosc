import 'dart:io';
import 'dart:typed_data';
import 'package:osc/osc.dart';
import 'package:osc/message.dart';

void main() async {
  final conn = Conn(remoteHost: "45.56.112.149");

  var msg = Message("/ch/01/mix/fader")..addFloat(.29);

  try {
    await conn.send(msg);
  } catch (e) {
    stdout.write("could not send msg");
    return;
  }

  final stream = conn.receive(Duration(seconds: 1));

  // await for (final value in stream) {
  //   Message reply = Message.parse(value?.data ?? Uint8List(0));

  //   print("tags: ${reply.tags}");
  //   print("reply: ${reply.data}");
  // }
  final value = await stream.first;
  Message reply = Message.parse(value?.data ?? Uint8List(0));

  print("tags: ${reply.tags}");
  print("reply: ${reply.data}");
  conn.close();
}
