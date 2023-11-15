import 'dart:io';
import 'package:osc/osc.dart';
import 'package:osc/message.dart';

void main() async {
  final conn = await Conn.initUDP(remoteHost: "45.56.112.149");

  var msg = Message("/ch/01/config/name");
  //msg.addFloat(.18);

  print("Sent message:$msg");

  int bytesSent = -1;
  try {
    bytesSent = await conn.send(msg);
  } catch (e) {
    stdout.write("could not send msg '$msg': $e");
  }
  stdout.write("sent $bytesSent bytes");

  Message reply = await conn.receive(Duration(seconds: 1));

  print("Received message:$reply");

  print("Received args:");
  for (final arg in reply.arguments) {
    print("type:${arg.runtimeType}\narg:$arg");
  }

  conn.sender.close();
}
