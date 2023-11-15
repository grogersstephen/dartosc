import 'dart:io';
import 'dart:typed_data';

import 'package:osc/message.dart';
import 'package:osc/osc.dart';
import 'package:udp/udp.dart';

void main() async {
  // var conn = await UDP.bind(Endpoint.any(port: Port(65000)));
  var conn = await Conn.initUDP(
      remoteHost: "127.0.0.1", remotePort: 65002, localPort: 65000);
  // // send a simple string to a broadcast endpoint on port 65001.
  // var dataLength = await sender.send(
  //     'Hello World!'.codeUnits, Endpoint.loopback(port: Port(65002)));
  while (true) {
    stdout.write("input: ");
    final val = stdin.readLineSync();
    // Endpoint.loopback(port: Port(65002))
    // Uint8List.fromList(val!.codeUnits)
    final i = await conn.send(Message(val));
    print('bytes written: $i');
    final resp = await conn.receive(Duration(seconds: 30));
    print('resp: $resp');
  }
}
