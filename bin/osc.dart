import 'dart:io';
import 'package:osc/osc.dart';
import 'package:osc/message.dart';

void main() async {
  bool ok;
  Message reply;
  var conn = Conn(remoteHost: "45.56.112.149");

  var msg = Message("/ch/01/mix/fader");
  msg.addFloat(.29);

  try {
    await conn.send(msg);
  } catch (e) {
    stdout.write("could not send msg");
    return;
  }

  (reply, ok) = await conn.receive(Duration(seconds: 1));

  reply.parse();

  print("tags: ${reply.tags}");
  print("reply: ${reply.data}");

  conn.sender!.close();
}
