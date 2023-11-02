import 'dart:io';
import 'package:osc/osc.dart';
import 'package:osc/message.dart';

void main() async {
  // print("start");
  final conn = await Conn.initUDP(remoteHost: "45.56.112.149");
  var msg = Message("/info");

  msg.makePacket();

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

  // conn.close();
}
