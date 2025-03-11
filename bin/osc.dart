import 'package:osc/osc.dart';
import 'package:osc/message.dart';
import 'package:logger/logger.dart';

final logger = Logger(printer: PrettyPrinter(), filter: ProductionFilter());

void main() async {
  final conn = Conn.init(
    remoteHost: "45.56.112.149",
    remotePort: 10023,
    localPort: 10023,
    checkConnectionMessage: Message("/status"),
  );

  print("connection made?: ${await conn.connectionMade}");

  final msgs = <Message>[
    Message("/status"),
    Message("/info"),
    Message("/ch/02/mix/fader", [OSCFloat(0.5)]),
  ];

  for (final msg in msgs) {
    print("sending message: $msg");
    print("bytes: ${msg.packet}");
    var reply = await conn.inquire(msg);
    print("receiving reply: $reply");
  }

  print('closing connection');
  conn.close();
}
