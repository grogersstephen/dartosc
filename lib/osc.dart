library osc;

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:udp/udp.dart';
import 'message.dart';
import 'dart:typed_data';

abstract interface class IConn {
  Future<Message> receive({Duration? timeout});

  Future<int> send(Message message);

  StreamSubscription<Message> listen();

  void close();
}

class Conn implements IConn {
  final Endpoint _dest;
  final UDP _sender;
  final StreamController<Message> _streamController = StreamController();

  Conn({required Endpoint dest, required UDP sender})
      : _dest = dest,
        _sender = sender;

  static Future<Conn> initUDP(
      {required remoteHost,
      int remotePort = 10023,
      int localPort = 10023}) async {
    final dest =
        Endpoint.unicast(InternetAddress(remoteHost), port: Port(remotePort));
    final sender = await UDP.bind(Endpoint.any(port: Port(localPort)));
    final conn = Conn(dest: dest, sender: sender);

// stream stuff....
    final messages = sender
        .asStream()
        .map((event) => Message.fromPacket(event?.data ?? Uint8List(0)));

    conn._streamController.addStream(messages);

    return conn;
  }

  get sender => _sender;
  get dest => _dest;

  @override
  Future<Message> receive({Duration? timeout}) async {
    // Create a possibly disposable receiver using the same port as the sender's port
    // if no timeout is sent it wont close.
    try {
      final event = await _sender.asStream(timeout: timeout).first;
      var data = event?.data ?? Uint8List(0);

      return Message.fromPacket(data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  StreamSubscription<Message> listen() {
    return _streamController.stream.listen(null);
  }

  @override
  Future<int> send(Message message) async {
    // Send the data
    try {
      return await _sender.send(message.packet, _dest);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void close() {
    if (!_sender.closed) {
      _sender.close();
    }
  }
}
