library osc;

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:universal_io/io.dart';
import 'message.dart';
import './util.dart';

class Conn {
  final Endpoint _server;
  late final RawDatagramSocket _client;
  bool _connected = false;
  late final Stream<Message?> _messageStream;

  Conn._({required InternetAddress serverAddr, required int serverPort})
      : _server = Endpoint(serverAddr, serverPort);

  InternetAddress get remoteAddress => _server.address;
  int get remotePort => _server.port;
  InternetAddress get localAddress => _client.address;
  int get localPort => _client.port;
  Stream<Message?> get messageStream => _messageStream;

  static Future<Conn> init(
      {required String remoteHost,
      required int remotePort,
      int localPort = 0}) async {
    if (!isValidPortNumber(remotePort)) {
      throw Exception("invalid port number for remotePort: $remotePort");
    }
    if (!isValidPortNumber(localPort)) {
      throw Exception("invalid port number for localPort: $localPort");
    }
    if (!isValidIPAddress(remoteHost)) {
      throw Exception("invalid ip address for remoteHost: $remoteHost");
    }
    final c = Conn._(
        serverAddr: InternetAddress(remoteHost, type: InternetAddressType.IPv4),
        serverPort: remotePort);
    await c._connect(localPort);
    return c;
  }

  Future _connect(localPort) async {
    _client = await RawDatagramSocket.bind(InternetAddress.anyIPv4, localPort);
    _messageStream = _getMessageStream().asBroadcastStream();
    _connected = true;
  }

  Stream<Message> _getMessageStream() async* {
    await for (final event in _client) {
      if (event == RawSocketEvent.closed) {
        _client.close();
        _connected = false;
        return;
      }
      if (event != RawSocketEvent.read) {
        continue;
      }
      final Datagram? datagram = _client.receive();
      if (datagram == null) {
        continue;
      }
      try {
        yield Message.fromPacket(datagram.data);
      } catch (e) {
        continue;
      }
    }
  }

  Future<Message?> request(Message message,
      {Duration timeout = const Duration(seconds: 3)}) async {
    // this will error on timeout
    await Future.doWhile(() async {
      return (await send(message)) == 0;
    }).timeout(const Duration(seconds: 2));
    try {
      return await _messageStream.first
          .timeout(const Duration(milliseconds: 100));
    } on TimeoutException catch (_) {
      return null;
    }
  }

  Future<int> send(Message message) async {
    if (!_connected) {
      throw Exception("connection is closed");
    }

    return _client.send(message.packet, _server.address, _server.port);
  }

  Future<Message?> receive() async {
    if (!_connected) {
      throw Exception("connection is closed");
    }
    final data = _client.receive()?.data;
    if (data == null) {
      return null;
    }
    return Message.fromPacket(data);
  }

  close() {
    _client.close();
    _connected = false;
  }
}
