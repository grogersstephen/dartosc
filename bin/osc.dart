import 'package:osc/osc.dart';
import 'package:osc/message.dart';
import 'package:logger/logger.dart';
import 'dart:async';

final logger = Logger(printer: PrettyPrinter(), filter: ProductionFilter());

void main() async {
  final conn = Conn.init(
    remoteHost: "45.56.112.149",
    remotePort: 10023,
    localPort: 10023,
    checkConnectionMessage: Message("/status"),
  );

  print("connection made?: ${await conn.connectionMade}");

  final msgs = [
    "/status",
    "/info",
    "/ch/01/mix/fader",
    "/ch/01/on",
  ];

  for (final msg in msgs) {
    var request = Message(msg);
    var reply = await conn.inquire(request);
    print("$request: $reply");
  }

  print('closing connection');
  conn.close();
}
