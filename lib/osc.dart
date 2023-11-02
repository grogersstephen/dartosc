library osc;

import 'dart:core';
import 'dart:io';
import 'package:udp/udp.dart';
import 'message.dart';

class Conn {
  late final String _remoteHost;
  late final int _remotePort;
  late final int _localPort;
  late final Endpoint _dest;
  late UDP _sender;

  Conn({required remoteHost, remotePort = 10023, localPort = 10023})
      : _remoteHost = remoteHost,
        _remotePort = remotePort,
        _localPort = localPort {
    _init();
  }

  Future _init() async {
    _dest = Endpoint.multicast(InternetAddress(_remoteHost),
        port: Port(_remotePort));
    _sender = await UDP.bind(Endpoint.any(port: Port(_localPort)));
  }

  Stream<Datagram?> recieve(Duration timeout) {
    return _sender.asStream(timeout: timeout);
  }

  void close() {
    _sender.close();
  }

  Future<void> send(Message message) async {
    // Make the packet from the message
    message.makePacket();
    // Send the data
    try {
      final dataLength = await _sender.send(message.packet, _dest);
      if (dataLength == 0) throw Error.safeToString("too short");
    } catch (e) {
      rethrow;
    }
  }
}
