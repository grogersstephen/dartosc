import 'dart:typed_data';
import 'package:typed_data/typed_buffers.dart';

class Message {
	Uint8List _packet;
	String _address;
	String _tags;
	List<dynamic> _arguments;

	Message([address = ""])
			: _packet = Uint8List(0),
			  _address = address,
			  _tags = "",
			  _arguments = <dynamic>[] {
		_packet = _makePacket();
	}

	Message.fromPacket(Uint8List packet)
			: _packet = packet,
			  _address = "",
			  _tags = "",
			  _arguments = <dynamic>[] {
		_parse();
	}

	// List of characters not allowed in an osc address
	//     The delimiter of containers in an address is the '/' with ascii code 47
	static Uint8List forbiddenCharacters = Uint8List.fromList([32, 35, 42, 44, 63, 91, 93, 123, 125]); // [space]#*,?[]{}
	// List of characters allowed in osc tags
	static Uint8List tagAllowedCharacters = Uint8List.fromList([102,105,115]); // fis

	Uint8List get packet => _packet;
	String get address => _address;
	String get tags => _tags;
	List<dynamic> get arguments => _arguments;

	set address(String address) {
		// data validation
		if (address[0] != "/") {
		  throw Exception("osc addresses must begin with root /");
		}
		_address = address;
	}
	set packet(Uint8List packet) {
		_packet = packet;
	}
	set tags(String tags) {
		// tags will be a string of 'i', 'f', and 's' representing the osc arguments which follow
		// tags will NOT contain a comma here
		// data validation
		// If the first character is a comma, remove it
		if (tags.startsWith(",")) {
		  tags = tags.substring(1);
		}
		// Make sure only allowed characters are in the list of tags
		for (final r in tags.runes) {
			if (!tagAllowedCharacters.contains(r)) {
				throw Exception("not a valid tag: '${String.fromCharCode(r)}'");
			}
		}
		_tags = tags;
	}

	@override
	String toString() {
		var sb = StringBuffer();
		for (final r in packet) {
			if (r == 0) {
				sb.write("~");
				continue;
			}
			sb.writeCharCode(r);
		}
		return sb.toString();
	}

	void addString(String s) {
		tags = "${tags}s";
		_arguments.add(s);
	}
	void addFloat(double value) {
		tags = "${tags}f";
		_arguments.add(value);
	}
	void addInt(int value) {
		tags = "${tags}i";
		_arguments.add(value);
	}

	void makePacket() {
		_packet = _makePacket();
	}

	Uint8List _makePacket() {
		/// Make the packet from the given osc address, tags, and arguments
		var b = BytesBuilder();

		// Append the appropriate zero bytes to the osc address
		//     before writing it to the buffer
		b.add(Uint8List.fromList(appendZeroBytes(address).codeUnits));

		// Prepend a comma to the osc tags
		//    and append the appropriate count of zero bytes
		//    before writing them to the buffer
		b.add(Uint8List.fromList(appendZeroBytes(",$tags").codeUnits));

		// Encode the arguments before writing them to the buffer
		b.add(encodeArguments());
		return b.toBytes();
	}

	void _parse() {
		// Clone to a new packet to work with it
		Uint8Buffer packetB = Uint8Buffer(0);
		packetB.addAll(packet);

		//     the osc message must begin with '/'
		if (packetB.first != '/'.codeUnitAt(0)) {
			throw Exception("osc address must begin with '/'");
		}
		
		// If there are no zero bytes, throw error
		if (!packetB.contains(0)) throw Exception("osc address not terminated by zero byte");

		// The osc address will be the part leading the first zero byte
		final String addressToWrite = String.fromCharCodes(packetB.sublist(0, packetB.indexOf(0)));
		// data validation
		for (final r in addressToWrite.runes) {
			if (forbiddenCharacters.contains(r)) {
				throw Exception("osc address contains forbidden character");
			}
		}

		// write address
		address = addressToWrite;

		// address + zeros length
		final int addressLength = appendZeroBytes(address).length;

		// if packetB.length only contains an address, return, writing only to the address property
		if (packetB.length == addressLength) return;

		// if the osc address is not followed by the appropriate count of zero bytes, throw error
		//     the address will still be written
		if (packetB.length < addressLength) {
			throw Exception("osc address is not correctly terminated");
		}

		// Remove the address and trailing zeros
		packetB.removeRange(0, addressLength);

		// If there is no comma, return only writing to the address property
		if (packetB.first != ",".codeUnitAt(0)) return;
		// Remove the comma
		packetB.removeAt(0);

		// If there are no zero bytes, throw error
		if (!packetB.contains(0)) throw Exception("osc address not terminated by zero byte");

		// the tags will be the portion before the first zero byte
		final String tagsToWrite = String.fromCharCodes(packetB.sublist(0, packetB.indexOf(0)));
		// data validation
		final invalidChars = <int>[];
		for (final r in tagsToWrite.runes) {
			if (!tagAllowedCharacters.contains(r)) {
				invalidChars.add(r);
			}
		}
		if (invalidChars.isNotEmpty) {
			throw Exception("invalid characters: '${String.fromCharCodes(invalidChars)}' in osc tags");
		}
		tags = tagsToWrite;

		// tags + zeros length
		// the comma has already been removed, so 1 must be subtracted from the tags portion
		final int tagsLength = appendZeroBytes(",$tags").length - 1;

		// if the osc tags is not followed by appropriate count of zero bytes, throw error
		//     the tags will still be written
		if (packetB.length < tagsLength) {
			throw Exception("osc tags is not correctly terminated");
		}

		// Remove the tags and trailing zeros
		packetB.removeRange(0, tagsLength);

		for (int t = 0; t < tags.length; t++) {
			// If there's not enough bytes, throw error
			if (packetB.length < 4) {
				throw Exception("end of packet");
			}
			switch (tags[t]) {
				case "f":
					// read next four bytes
					_arguments.add(decodeFloat32(Uint8List.fromList(packetB.sublist(0, 4))));
					// Remove bytes from packet
					packetB.removeRange(0, 4);
					break;
				case "i":
					// read next four bytes
					_arguments.add(decodeInt32(Uint8List.fromList(packetB.sublist(0, 4))));
					// Remove bytes from packet
					packetB.removeRange(0, 4);
					break;
				case "s":
					// read portion before the next zerobyte
					//     ensure the string is followed by a zero byte
					// if no zero byte is found, throw exception
					if (!packetB.contains(0)) {
						throw Exception("string osc argument is not correctly terminated");
					}
					final stringToAdd = String.fromCharCodes(packetB.sublist(0, packetB.indexOf(0)));
					_arguments.add(stringToAdd);
					
					// If the length of the string + zero bytes is gt than the remaining packet lenth,
					//     throw error, but the argument will still be written
					final int stringLength = appendZeroBytes(stringToAdd).length;
					if (packetB.length < stringLength) {
						throw Exception("string osc argument is not correctly terminated");
					}
					// Remove string and trailing zeros from packetB
					packetB.removeRange(0, stringLength);
					break;
			}
		}
	}

	Uint8List encodeArguments() {
		var argBytes = BytesBuilder();
		// iterate according to arguments
		for (int i = 0; i < _arguments.length; i++) {
			// If the argument is a string, append the appropriate zero bytes, convert to List<int> and add to argBytes buffer
			if (arguments[i] is String) {
				argBytes.add(appendZeroBytes(arguments[i].toString()).codeUnits);
				continue;
			}
			if (arguments[i] is int) {
				// If the argument is an int, convert to four bytes representing an int32 and add those bytes to argBytes buffer
				try {
					argBytes.add(encodeInt32(arguments[i]));
				} catch(e) {
					// if conversion fails, add 4 dummy bytes
					argBytes.add(Uint8List(4));
				}
				continue;
			}
			if (arguments[i] is double) {
				// If the argument is an double, convert to four bytes representing an float32 and add those bytes to argBytes buffer
				try {
					argBytes.add(encodeFloat32(arguments[i]));
				} catch(e) {
					// if conversion fails, add 4 dummy bytes
					argBytes.add(Uint8List(4));
				}
			}
		}
		return argBytes.toBytes();
	}
}

String appendZeroBytes(String s) {
  return s + ("\u0000" * zerosToAdd(s));
}

int zerosToAdd(String s) {
  return 4 - (s.length % 4);
}

double decodeFloat32(Uint8List data) {
	return ByteData.sublistView(data).getFloat32(0);
}

int decodeInt32(Uint8List data) {
	return ByteData.sublistView(data).getInt32(0);
}

Uint8List encodeInt32(int value) {
	var bdata = ByteData(4);
	bdata.setInt32(0, value);
	return bdata.buffer.asUint8List(0);
}

Uint8List encodeFloat32(double value) {
	var bdata = ByteData(4);
	bdata.setFloat32(0, value);
	return bdata.buffer.asUint8List(0);
}
