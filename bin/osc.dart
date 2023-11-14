import 'package:osc/osc.dart';
import 'package:osc/message.dart';


void main() async {
  var conn = await Conn.initUDP(remoteHost: "45.56.112.149");

  var msg = Message("/ch/03/mix/fader");
  //msg.addFloat(.22);

  print("Sent message:$msg}");

  await conn.send(msg);

  Message reply = await conn.receive(Duration(seconds:1));

  print("Received message:$reply");

  print("Received args:");
  for (final arg in reply.arguments) {
	  print(arg);
  }

  conn.sender.close();
}


