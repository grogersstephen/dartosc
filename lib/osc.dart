import 'dart:core';
import 'dart:io';
import 'package:udp/udp.dart';
import 'message.dart';

class Conn {
	String remoteHost;
	int remotePort = 10023;
	int localPort = 10023;
	UDP? sender;
	Endpoint? dest;

	Conn(this.remoteHost) {
		if (!initDest()) {
			stdout.write("unable to make remote endpoint");
		}
	}

	bool initDest() {
		try {
			dest = Endpoint.unicast(InternetAddress(remoteHost), port: Port(remotePort));
		} catch(e) {
			return false;
		}
		return true;
	}

	Future<bool> initSender(int port) async {
		// Close sender if one is already open
		try {
			sender!.close();
		} catch(e) {}

		if (port < 0 || port > 65535) {
			return false; // invalid port number
		}

		// Assign sender
		try {
			localPort = port;
			sender = await UDP.bind(Endpoint.any(port: Port(localPort)));
		} catch(e) {
			return false;
		}
		return true;
	}

	Future<bool> send(Message message) async {
		// Make the packet from the message
		message.makePacket();
		// Send the data
		try {
			final dataLength = await sender!.send(message.packet, dest!);
			if (dataLength < 1) {
				return false;
			}
		} catch(e) {
			return false;
		}
		return true;
	}

	Future<(Message, bool)> receive(Duration timeout) async {
		var msg = Message("");
		bool ok = false;
		try {
		sender!.asStream(timeout: timeout).listen((datagram) {
			msg.packet = datagram!.data;
			ok = true;
		});
		} catch(e) {
			return (msg, ok);
		}
  	    await Future.delayed(timeout);
		return (msg, ok);
	}
}
