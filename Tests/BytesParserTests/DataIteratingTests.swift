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
}
