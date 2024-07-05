library osc;

import 'dart:core';
import 'dart:io';
import 'package:universal_io/io.dart';
import 'message.dart';
import 'dart:collection';
import './util.dart';

import 'dart:async';

class Conn {
  final InternetAddress _server;
  final int _serverPort;
  late final RawDatagramSocket _client;
  final _connectionCompleter = Completer<bool>();

  Conn(
      {required InternetAddress serverAddr,
      required int serverPort,
      int clientPort = 0})
      : _server = serverAddr,
        _serverPort = serverPort {
    bindClient(clientPort).then((val) {
      _connectionCompleter.complete(true);
    }).catchError((e) {
      _connectionCompleter.complete(false);
    });
  }

  factory Conn.init(
      {required String remoteHost,
      required int remotePort,
      required int localPort}) {
    if (!isValidPortNumber(remotePort)) {
      throw Exception("invalid port number for remotePort: $remotePort");
    }
    if (!isValidPortNumber(localPort)) {
      throw Exception("invalid port number for localPort: $localPort");
    }
    if (!isValidIPAddress(remoteHost)) {
      throw Exception("invalid ip address for remoteHost: $remoteHost");
    }
    return Conn(
        serverAddr: InternetAddress(remoteHost, type: InternetAddressType.IPv4),
        serverPort: remotePort);
  }

  bindClient(int localPort) async {
    _client = await RawDatagramSocket.bind(InternetAddress.anyIPv4, localPort);
  }

  get client => _client;
  get server => _server;
  get serverPort => _serverPort;
  get connectionMade => _connectionCompleter.future;

  // Connection closed?
  bool _closed = false;

  // Reference to the UDP instance broadcast stream
  Stream<Datagram?>? _udpBroadcastStream;
  // Reference to the socket broadcast stream
  Stream? _socketBroadcastStream;
  // Reference to the internal stream controller
  StreamController? _streamController;
  // Stores the set of internal stream subscriptions
  final HashSet<StreamSubscription> _streamSubscriptions =
      HashSet<StreamSubscription>();

  Stream<Message> messageStream() {
    if (_closed) throw Exception("connection closed");

    _streamController ??= StreamController<Datagram>();
    _udpBroadcastStream ??= (_streamController as StreamController<Datagram?>)
        .stream
        .asBroadcastStream();

    if (_socketBroadcastStream == null) {
      _socketBroadcastStream = client.asBroadcastStream();

      var streamSubscription = _socketBroadcastStream!.listen((event) {
        if (event == RawSocketEvent.read) {
          (_streamController as StreamController<Datagram?>)
              .add(client.receive());
        }
      });

      if (!_streamSubscriptions.contains(streamSubscription)) {
        _streamSubscriptions.add(streamSubscription);
      }
    }

    return _udpBroadcastStream!.map<Message>((Datagram? datagram) {
      try {
        final data = datagram!.data;
        return Message.fromPacket(data);
      } catch (e) {
        // If the packet cannot be parsed as an OSC Message
        //     return empty message
        return Message();
      }
    });
  }

  Future<int> send(Message message) async {
    if (_closed) return -1;

    return Future.microtask(() async {
      return client.send(message.packet, server.address, serverPort);
    });
  }

  close() => client.close();
}
