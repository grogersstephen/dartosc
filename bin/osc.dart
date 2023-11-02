import 'dart:io';
import 'dart:typed_data';
import 'package:osc/osc.dart';
import 'package:osc/message.dart';

void main() async {
  print("start");
  final conn = await Conn.initUDP(remoteHost: "45.56.112.149");
  var msg = Message("/ch/01/mix/fader")..addFloat(0.8);

  print("create messsage");
  try {
    await conn.send(msg);
  } catch (e) {
    stdout.write(
      "could not send msg: $e",
    );
    conn.close();
    return;
  }

  final stream = conn.receive(Duration(seconds: 3));

  try {
    stream.listen((event) {
      print("data: ${event?.data}");
    });
  } catch (e) {
    print("$e");
  }
  // await for (final value in stream) {
  //   print("waiting to read");
  //   Message reply = Message.parse(value?.data ?? Uint8List(0));

  //   print("tags: ${reply.tags}");
  //   print("reply: ${reply.data}");
  //   break;
  // }

  conn.close();
}
