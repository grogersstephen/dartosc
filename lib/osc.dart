library osc;

import 'dart:core';
import 'dart:io';
import 'package:universal_io/io.dart';
import 'message.dart';
import 'dart:collection';
import './util.dart';

import 'dart:async';

class Conn {
  final Endpoint _server;
  late final RawDatagramSocket _client;
  final _connectionCompleter = Completer<bool>();
  final Message? checkConnectionMessage;

  Conn(
      {required InternetAddress serverAddr,
      required int serverPort,
      int clientPort = 0,
      this.checkConnectionMessage})
      : _server = Endpoint(serverAddr, serverPort) {
    connect(clientPort).then((val) {
      _connectionCompleter.complete(val);
    }).catchError((e) {
      _connectionCompleter.complete(false);
    });
  }

  factory Conn.init(
      {required String remoteHost,
      required int remotePort,
      int localPort = 0,
      checkConnectionMessage}) {
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
        serverPort: remotePort,
        clientPort: localPort,
        checkConnectionMessage: checkConnectionMessage);
  }

  Future<bool> connect(int localPort) async {
    Exception? bindException;
    await RawDatagramSocket.bind(InternetAddress.anyIPv4, localPort)
        .then((socket) {
      _client = socket;
    }).catchError((e) {
      bindException = e;
    });
    // if the bind method failed, return false
    if (bindException != null) {
      return false;
    }
    // if there is no checkConnectionMessage provided, return true
    if (checkConnectionMessage == null) {
      return true;
    }
    // send the message
    final reply = await inquire(checkConnectionMessage!);
    // if no reply, return false
    if (reply == null) {
      return false;
    }
    // if any reply, return true
    return true;
  }

  Future<Message?> inquire(Message message,
      {Duration timeout = const Duration(seconds: 3)}) async {
    final reply = Completer<Message?>();
    final subscription = messageStream().listen((message) {
      reply.complete(message);
    });
    final timer = Timer(timeout, () {
      reply.complete();
    });
    await send(message).onError((e, _) {
      reply.complete();
      return -1;
    });
    final result = await reply.future;
    timer.cancel(); // calling cancel more than once is allowed
    subscription.cancel(); // calling cancel more than once is allowed
    return result;
  }

  get client => _client;
  get server => _server;
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
        return Message("");
      }
    });
  }

  Future<int> send(Message message) async {
    if (_closed) return -1;

    return Future.microtask(() async {
      return client.send(message.packet, server.address, server.port);
    });
  }

  Future<Message?> receive() async {
    final datagram = client.receive();
    try {
      final data = datagram!.data;
      return Message.fromPacket(data);
    } catch (e) {
      return null;
    }
  }

  close() {
    client.close();
    _closed = true;
  }
}
