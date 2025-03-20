import 'package:osc/osc.dart';
import 'package:osc/message.dart';
import 'package:logger/logger.dart';

final logger = Logger(printer: PrettyPrinter(), filter: ProductionFilter());

void main() async {
  final conn = await Conn.init(
    remoteHost: "192.168.1.176",
    remotePort: 10023,
    // localPort: 10023,
  );

  final msgs = <Message>[
    Message("/status"),
    Message("/info"),
    // Message("/ch/02/mix/fader", [OSCFloat(0.5)]),
    Message("/ch/02/mix/fader"),
  ];

  for (final msg in msgs) {
    print("sending message: $msg");
    print("bytes: ${msg.packet}");
    var reply = await conn.request(msg);
    print("receiving reply: $reply");
  }

  print('closing connection');
  conn.close();
}
