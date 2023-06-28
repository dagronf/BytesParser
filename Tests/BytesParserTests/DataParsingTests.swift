import XCTest
@testable import BytesParser

final class ByteIterableTests: XCTestCase {
	func testReadToEnd() throws {
		let d = Data([0x66, 0x69, 0x73, 0x68, 0x20, 0x61, 0x6E, 0x64, 0x20, 0x63, 0x68, 0x69, 0x70, 0x73, 0x0A])

		do {
			let data = BytesParser(data: d)
			let r = try data.readUpToNextNullByte()
			XCTAssertEqual(r, d)
			Swift.print(r)
		}

		do {
			let data = BytesParser(data: d)
			let r = try data.readUpToNextInstanceOfByte(byte: 0x20)
			XCTAssertEqual(r, Data([0x66, 0x69, 0x73, 0x68, 0x20]))
			Swift.print(r)
		}
	}

	func testAsciiReadInclTerminator() throws {
		let d: [UInt8] = [0x66,0x69,0x73,0x68,0x00,0x61,0x6E,0x64,0x00]

		try BytesParser.parse(bytes: d) { parser in
			let str1 = try parser.readAsciiString(length: 5, lengthIncludesTerminator: true)
			XCTAssertEqual(str1, "fish")
			let str2 = try parser.readAsciiString(length: 4, lengthIncludesTerminator: true)
			XCTAssertEqual(str2, "and")
			XCTAssertThrowsError(try parser.readByte())
		}

		do {
			let data = BytesParser(content: d)
			let str1 = try data.readAsciiString(length: 5, lengthIncludesTerminator: true)
			XCTAssertEqual(str1, "fish")
			let str2 = try data.readAsciiString(length: 4, lengthIncludesTerminator: true)
			XCTAssertEqual(str2, "and")
			XCTAssertThrowsError(try data.readByte())
		}

		do {
			let data = BytesParser(content: d)
			let str1 = try data.readAsciiString(length: 4, lengthIncludesTerminator: false)
			XCTAssertEqual(str1, "fish")
			XCTAssertEqual(0x00, try data.readByte())
			let str2 = try data.readAsciiString(length: 3, lengthIncludesTerminator: false)
			XCTAssertEqual(str2, "and")
			XCTAssertEqual(0x00, try data.readByte())
			XCTAssertThrowsError(try data.readByte())
		}
	}

	func testAsciiRead() throws {
		// fish and\0chips
		let d: [UInt8] = [0x66,0x69,0x73,0x68,0x20,0x61,0x6E,0x64,0x00,0x63,0x68,0x69,0x70,0x73,0x00,0x99]
		let data = BytesParser(content: d)
		let str1 = try data.readAsciiNullTerminatedString()
		XCTAssertEqual("fish and", str1)

		let str2 = try data.readAsciiNullTerminatedString()
		XCTAssertEqual("chips", str2)

		XCTAssertTrue(data.hasMoreData)
		let b = try data.readByte()
		XCTAssertEqual(0x99, b)

		XCTAssertFalse(data.hasMoreData)

		try withDataWrittenToTemporaryInputStream(Data(d)) { inputStream in
			try BytesParser.parse(inputStream: inputStream) { parser in
				let str1 = try parser.readAsciiNullTerminatedString()
				XCTAssertEqual("fish and", str1)

				let str2 = try parser.readAsciiNullTerminatedString()
				XCTAssertEqual("chips", str2)

				XCTAssertTrue(parser.hasMoreData)
				let b = try parser.readByte()
				XCTAssertEqual(0x99, b)
			}
		}
	}

	func testUTF16Read() throws {

		do {
			let d: [UInt8] = [0x61, 0x00, 0x62, 0x00, 0x00, 0x00, 0x80]
			let data = BytesParser(content: d)
			let str = try data.readUTF16NullTerminatedString(isBigEndian: false)
			XCTAssertEqual("ab", str)

			let b = try data.readByte()
			XCTAssertEqual(0x80, b)

			XCTAssertFalse(data.hasMoreData)
		}

		do {
			let d: [UInt8] = [0x00, 0x61, 0x00, 0x62, 0x00, 0x00, 0x80]
			let data = BytesParser(content: d)
			let str = try data.readUTF16NullTerminatedString(isBigEndian: true)
			XCTAssertEqual("ab", str)

			let b = try data.readByte()
			XCTAssertEqual(0x80, b)

			XCTAssertFalse(data.hasMoreData)

			try withDataWrittenToTemporaryInputStream(Data(d)) { inputStream in
				let parser = BytesParser(inputStream: inputStream)
				let str = try parser.readUTF16NullTerminatedString(isBigEndian: true)
				XCTAssertEqual("ab", str)
				let b = try parser.readByte()
				XCTAssertEqual(0x80, b)
				XCTAssertThrowsError(try parser.readByte())
			}
		}

		do {
			let d: [UInt8] = [0x61, 0x00, 0x62, 0x00, 0x00, 0x00, 0x80]
			let data = BytesParser(content: d)
			let str = try data.readUTF16String(length: 2, isBigEndian: false)
			XCTAssertEqual("ab", str)
			XCTAssertTrue(data.hasMoreData)
			XCTAssertEqual(0x00, try data.readByte())
			XCTAssertEqual(0x00, try data.readByte())
			XCTAssertEqual(0x80, try data.readByte())

			XCTAssertFalse(data.hasMoreData)

			// Try the same with an input stream
			try withDataWrittenToTemporaryInputStream(Data(d)) { inputStream in
				let parser = BytesParser(inputStream: inputStream)
				let str = try parser.readUTF16String(length: 2, isBigEndian: false)
				XCTAssertEqual("ab", str)
				XCTAssertTrue(parser.hasMoreData)
				XCTAssertEqual(0x00, try parser.readByte())
				XCTAssertEqual(0x00, try parser.readByte())
				XCTAssertEqual(0x80, try parser.readByte())
			}
		}
	}

	func testLengthC() throws {
		let d: [UInt8] = [0x61, 0x00, 0x62, 0x00, 0x00, 0x00, 0x80]
		do {
			let data = BytesParser(content: d)
			let r = try data.readBytes(count: d.count)
			XCTAssertEqual(r, d)
			XCTAssertFalse(data.hasMoreData)
		}

		do {
			let data = BytesParser(content: d)
			XCTAssertThrowsError(try data.readBytes(count: 8))
			try withDataWrittenToTemporaryInputStream(Data(d)) { inputStream in
				let parser = BytesParser(inputStream: inputStream)
				// Should fail -- there is not enough data in the input stream
				XCTAssertThrowsError(try parser.readBytes(count: 8))
			}
		}

		// Try the same with an input stream
		try withDataWrittenToTemporaryInputStream(Data(d)) { inputStream in
			let data = BytesParser(inputStream: inputStream)
			let r = try data.readBytes(count: d.count)
			XCTAssertEqual(r, d)
			XCTAssertThrowsError(try data.readByte())
			XCTAssertFalse(data.hasMoreData)
		}
	}

	func testReadIntegersAndStuff() throws {
		let data = try BytesWriter.generate { writer in
			try writer.writeInt16Value(10101, isBigEndian: true)
			try writer.writeUInt16Value(40000, isBigEndian: true)
			try writer.writeInt16Value(-10101, isBigEndian: false)
			try writer.writeUInt16Value(65535, isBigEndian: false)

			try writer.writeFloat64(12345.67890, isBigEndian: false)
			try writer.writeBool(true)
			try writer.writeBool(false)
		}

		try BytesParser.parse(data: data) { parser in
			XCTAssertEqual(10101, try parser.readInt16(isBigEndian: true))
			XCTAssertEqual(40000, try parser.readUInt16(isBigEndian: true))
			XCTAssertEqual(-10101, try parser.readInt16(isBigEndian: false))
			XCTAssertEqual(65535, try parser.readUInt16(isBigEndian: false))
			XCTAssertEqual(12345.67890, try parser.readFloat64(isBigEndian: false))
			XCTAssertEqual(true, try parser.readBool())
			XCTAssertEqual(false, try parser.readBool())
		}
	}

	func testReadRealCrosswordFile() throws {
		// Parse a binary crossword file

		let url = Bundle.module.url(forResource: "May0612", withExtension: "puz")!

		try BytesParser.parse(fileURL: url) { parser in
			let /*checksum*/ _: Int16 = try parser.readLittleEndian()
			let magic = try parser.readAsciiString(length: 12, lengthIncludesTerminator: true)
			XCTAssertEqual(magic, "ACROSS&DOWN")

			let /*cksum_cib*/ _: Int16 = try parser.readLittleEndian()
			let /*magic10*/ _ = try parser.readBytes(count: 4)
			let /*magic14*/ _ = try parser.readBytes(count: 4)
			let /*magic18*/ _ = try parser.readBytes(count: 4)

			let /*noise_1c*/ _: Int16 = try parser.readLittleEndian()
			let /*scrambled_tag*/ _: Int16 = try parser.readLittleEndian()

			let /*noise_20*/ _: Int16 = try parser.readLittleEndian()
			let /*noise_22*/ _: Int16 = try parser.readLittleEndian()
			let /*noise_24*/ _: Int16 = try parser.readLittleEndian()
			let /*noise_26*/ _: Int16 = try parser.readLittleEndian()
			let /*noise_28*/ _: Int16 = try parser.readLittleEndian()
			let /*noise_2a*/ _: Int16 = try parser.readLittleEndian()

			let width = Int(try parser.readByte())
			XCTAssertEqual(21, width)
			let height = Int(try parser.readByte())
			XCTAssertEqual(21, height)

			let clue_count: UInt16 = try parser.readLittleEndian()
			XCTAssertEqual(142, clue_count)
			let /*grid_type*/ _: UInt16 = try parser.readLittleEndian()
			let /*grid_flag*/ _: UInt16 = try parser.readLittleEndian()

			let solution = try parser.readBytes(count: width * height)
			XCTAssertEqual(441, solution.count)
			let text = try parser.readBytes(count: width * height)
			XCTAssertEqual(441, text.count)

			let title = try parser.readAsciiNullTerminatedString()
			XCTAssertEqual("NY Times, Sunday, May 6, 2012 A-v Club", title)
			let author = try parser.readAsciiNullTerminatedString()
			XCTAssertEqual("Alex Vratsanos / Will Shortz", author)
			let copyright = try parser.readAsciiNullTerminatedString()
			XCTAssertEqual("© 2012, The New York Times", copyright)

			var c = [String]()
			for _ in 0 ..< clue_count {
				c.append(try parser.readAsciiNullTerminatedString())
			}
			XCTAssertEqual("Something you willingly part with?", c[0])
			XCTAssertEqual("Got in the end", c[141])
		}
	}
}
