library osc;

import 'dart:core';
import 'dart:io';
import 'package:udp/udp.dart';
import 'message.dart';

class Conn {
  late final String _remoteHost;
  late final int _remotePort;
  late final int _localPort;
  // late UDP _sender;
  late Endpoint _dest;

  Conn({required remoteHost, remotePort = 10023, localPort = 10023})
      : _remoteHost = remoteHost,
        _remotePort = remotePort,
        _localPort = localPort {
    try {
      _dest = Endpoint.multicast(InternetAddress(_remoteHost),
          port: Port(_remotePort));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> send(Message message) async {
    final sender = await UDP.bind(Endpoint.any(port: Port(_localPort)));
    // Make the packet from the message
    message.makePacket();
    // Send the data
    try {
      final dataLength = await sender.send(message.packet, _dest);
      if (dataLength == 0) throw Error.safeToString("too short");
    } catch (e) {
      sender.close();
      rethrow;
    }
  }
}
