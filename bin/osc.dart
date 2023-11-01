import 'dart:io';
import 'package:osc/osc.dart';
import 'package:osc/message.dart';


void main() async {
  bool ok;
  Message reply;
  var conn = Conn("45.56.112.149");
  await conn.initSender(10023);

  var msg = Message("/ch/01/mix/fader");
  msg.addFloat(.29);

  ok = await conn.send(msg);
  if (!ok) {
	  stdout.write("could not send msg");
	  return;
  }

  (reply, ok) = await conn.receive(Duration(seconds:1));

  reply.parse();

  print("tags: ${reply.tags}");
  print("reply: ${reply.data}");

  conn.sender!.close();
}


