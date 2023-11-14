library osc;

import 'dart:core';
import 'dart:io';
import 'package:udp/udp.dart';
import 'message.dart';

// abstract interface class Sender {
//   Future<int> send(List<int> data, Endpoint remoteEndpoint);
//   Stream<Datagram?> asStream({Duration? timeout});
//   close();
// }

class Conn {
  late final Endpoint _dest;
  late final UDP _sender;

  Conn({required Endpoint dest, required UDP sender})
      : _dest = dest,
        _sender = sender;

  factory Conn.withUDP({required Endpoint dest, required UDP sender}) {
    return Conn(dest: dest, sender: sender);
  }

  static Future<Conn> initUDP(
      {required remoteHost, remotePort = 10023, localPort = 10023}) async {
    final dest =
        Endpoint.unicast(InternetAddress(remoteHost), port: Port(remotePort));
    final sender = await UDP.bind(Endpoint.any(port: Port(localPort)));

    return Conn.withUDP(dest: dest, sender: sender);
  }

  get sender => _sender;

  Stream<Datagram?> receive(Duration timeout) {
    try {
      return _sender.asStream(timeout: timeout);
    } catch (e) {
      print("receive: $e");
      rethrow;
    }
  }

  void close() {
    _sender.close();
  }

  Future send(Message message) async {
    // Make the packet from the message
    message.makePacket();

    // Send the data
    try {
      final dataLength = await _sender.send(message.packet, _dest);
      print("dataLength: $dataLength");
      if (dataLength == 0) throw Error.safeToString("too short");
    } catch (e) {
      print("send: $e");
      rethrow;
    }
  }
}
