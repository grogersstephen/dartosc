import 'dart:core';
import 'dart:io';
import 'package:udp/udp.dart';
import 'message.dart';
import 'dart:typed_data';

class Conn {
	final Endpoint _dest;
	final UDP _sender;

	Conn({required Endpoint dest, required UDP sender})
			: _dest = dest,
			_sender = sender;

	static Future<Conn> initUDP({required remoteHost, int remotePort = 10023, int localPort = 10023}) async {
		final dest = Endpoint.unicast(InternetAddress(remoteHost), port: Port(remotePort));
		final sender = await UDP.bind(Endpoint.any(port: Port(localPort)));
		return Conn(dest: dest, sender: sender);
	}

	get sender => _sender;

	Future<Message> receive(Duration timeout) async {
		var msg = Message();
		try {
			await for (final event in _sender.asStream(timeout: timeout)) {
				var data = event?.data ?? Uint8List(0);
				if (data.isEmpty) throw Exception("empty packet");
				msg = Message.fromPacket(data);
			}
		} catch(e) {
			rethrow;
		}
		return msg;
	}
	
	Future send(Message message) async {
		// Make the packet from the message
		message.makePacket();

		// Send the data
		try {
			await _sender.send(message.packet, _dest);
		} catch(e) {
			rethrow;
		}
	}

	void close() {
		_sender.close();
	}
}
