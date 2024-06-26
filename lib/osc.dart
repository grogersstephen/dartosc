library osc;

import 'dart:core';
import 'package:universal_io/io.dart';
import 'package:dartudp/udp.dart';
import 'message.dart';
import 'dart:typed_data';
import './util.dart';

class Conn {
  final Endpoint _dest;
  final UDP _sender;

  Conn({required Endpoint dest, required UDP sender})
      : _dest = dest,
        _sender = sender;

  static Future<Conn> initUDP(
      {required String remoteHost,
      required int remotePort,
      required int localPort}) async {
    // Data validation
    if (!isValidIPAddress(remoteHost)) {
      throw Exception("invalid IPv4 address for remoteHost");
    }
    if (!isValidPortNumber(remotePort)) {
      throw Exception("invalid port number for remotePort");
    }
    if (!isValidPortNumber(localPort)) {
      throw Exception("invalid port number for localPort");
    }

    final dest =
        Endpoint.unicast(InternetAddress(remoteHost), port: Port(remotePort));
    final sender = await UDP.bind(Endpoint.any(port: Port(localPort)));
    return Conn(dest: dest, sender: sender);
  }

  get sender => _sender;
  get dest => _dest;

  Stream<Message> messageStream() {
    return sender.asStream().map<Message>((Datagram datagram) {
      try {
        return Message.fromPacket(datagram.data);
      } catch (e) {
        // If the packet cannot be parsed as an OSC Message
        //     return empty message
        return Message();
      }
    });
  }

  Future<Message> receive(Duration timeout) async {
    var msg = Message();
    try {
      await for (final event in sender.asStream(timeout: timeout)) {
        var data = event?.data ?? Uint8List(0);
        if (data.isEmpty) throw Exception("empty packet");
        msg = Message.fromPacket(data);
        break; // once data is received, break out of the loop
      }
    } catch (e) {
      rethrow;
    }
    return msg;
  }

  Future<int> send(Message message) async {
    // Make the packet from the message

    // Send the data
    try {
      return await _sender.send(message.packet, _dest);
    } catch (e) {
      rethrow;
    }
  }

  close() => _sender.close();
}
