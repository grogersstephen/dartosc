import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:osc/message.dart';
import 'package:osc/osc.dart';

void main() async {
  final p = ReceivePort();
  await Isolate.spawn(_receive, p.sendPort);
  late SendPort sendPort;
  // The first message from the spawned isolate is a SendPort. This port is
  // used to communicate with the spawned isolate.

  sendPort = await p.first;

  var conn = await Conn.initUDP(
      remoteHost: "127.0.0.1", remotePort: 65002, localPort: 65000);

  final sub = conn.listen();

  sub.onData((data) {
    sendPort.send(data);
  });

  while (true) {
    stdout.write("input: ");
    final val = stdin.readLineSync();
    // Endpoint.loopback(port: Port(65002))
    // Uint8List.fromList(val!.codeUnits)
    final i = await conn.send(Message(val));
    print('bytes written: $i');
    final resp = await conn.receive();
    print('received: $resp');
  }
}

Future<void> _receive(SendPort p) async {
  final commandPort = ReceivePort();
  p.send(commandPort.sendPort);

  // Wait for messages from the main isolate.
  await for (final message in commandPort) {
    if (message is Message) {
      // Read and decode the file.

      print('Isolate resp: $message');
    } else if (message == null) {
      // Exit if the main isolate sends a null message, indicating there are no
      // more files to read and parse.
      break;
    }
  }
  Isolate.exit();
}
