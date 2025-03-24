import XCTest
@testable import BytesParser

// Check values https://cryptii.com/pipes/integer-encoder

final class RandomAccessParsingTests: XCTestCase {

	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testDataParsingInteger8() throws {
		do {
			let parser = BytesReader(bytes: [0x11])
			let u = try parser.readUInt8()
			XCTAssertEqual(0x11, u)
			try parser.rewind()
			let i = try parser.readInt8()
			XCTAssertEqual(0x11, i)
		}

		do {
			let parser = BytesReader(bytes: [0xAA])
			let u = try parser.readUInt8()
			XCTAssertEqual(0xAA, u)
			try parser.rewind()
			let i = try parser.readInt8()
			XCTAssertEqual(-86, i)
		}
	}

	func testDataParsingInteger16BE() throws {
		// 2-byte integers, big endian
		do {
			let parser = BytesReader(bytes: [0x11, 0x22])    // 0x1122 -> u:4386 i:4386
			let u = try parser.readUInt16(.big)
			XCTAssertEqual(4386, u)
			XCTAssertFalse(parser.hasMoreData)

			try parser.rewind()

			let i = try parser.readInt16(.big)
			XCTAssertEqual(4386, i)
			XCTAssertFalse(parser.hasMoreData)
		}

		do {
			let parser = BytesReader(bytes: [0xAA, 0xBB])    // 0xAABB -> u:43707 i:-21829

			let u = try parser.readUInt16(.big)
			XCTAssertEqual(43707, u)
			XCTAssertFalse(parser.hasMoreData)

			try parser.rewind()

			let i = try parser.readInt16(.big)
			XCTAssertEqual(-21829, i)
			XCTAssertFalse(parser.hasMoreData)
		}
	}

	func testDataParsingInteger16LE() throws {
		// 2-byte integers, little endian
		do {
			let parser = BytesReader(bytes: [0x11, 0x22])    // 0x2211 -> u:8721 i:8721
			let u = try parser.readUInt16(.little)
			XCTAssertEqual(8721, u)
			XCTAssertFalse(parser.hasMoreData)

			try parser.rewind()

			let i = try parser.readInt16(.little)
			XCTAssertEqual(8721, i)
			XCTAssertFalse(parser.hasMoreData)
		}

		do {
			let parser = BytesReader(bytes: [0xAA, 0xBB])   	 // 0xBBAA -> u:48042 i:-17494

			let u = try parser.readUInt16(.little)
			XCTAssertEqual(48042, u)
			XCTAssertFalse(parser.hasMoreData)

			try parser.rewind()

			let i = try parser.readInt16(.little)
			XCTAssertEqual(-17494, i)
			XCTAssertFalse(parser.hasMoreData)
		}
	}

	func testDataParsing() throws {

		do {
			let data = Data([0xAE])
			let parser = BytesReader(data: data)

			// Should not be able to seek beyond the end of the data
			XCTAssertThrowsError(try parser.seek(1, .current))
			XCTAssertThrowsError(try parser.seek(1, .end))
			XCTAssertThrowsError(try parser.seek(1, .start))


			let value: UInt8 = try parser.readUInt8()
			XCTAssertEqual(0xAE, value)
			XCTAssertFalse(parser.hasMoreData)

			try parser.seekSet(0)
			let value2: Int8 = try parser.readInt8()

			// https://simonv.fr/TypesConvert/?integers
			XCTAssertEqual(-82, value2)
		}


		do {
			let data = Data([0x11, 0x22, 0x33, 0x44])
			let parser = BytesReader(data: data)
			let value: UInt32 = try parser.readInteger(.big)
			XCTAssertEqual(0x11223344, value)
			XCTAssertFalse(parser.hasMoreData)
			try parser.seekSet(0)
			let value2: UInt32 = try parser.readInteger(.little)
			XCTAssertEqual(0x44332211, value2)
			XCTAssertFalse(parser.hasMoreData)
			XCTAssertThrowsError(try parser.readByte())

			try parser.seekSet(2)
			XCTAssertEqual(0x33, try parser.readByte())
			XCTAssertEqual(0x44, try parser.readByte())
			XCTAssertFalse(parser.hasMoreData)
		}

		do {
			let data2 = Data([0x11, 0x22, 0x33, 0x44])
			let parser2 = BytesReader(data: data2)
			XCTAssertEqual(0x11, try parser2.readByte())
			XCTAssertEqual(0x22, try parser2.readByte())
			XCTAssertEqual(0x33, try parser2.readByte())
			XCTAssertEqual(0x44, try parser2.readByte())
			XCTAssertFalse(parser2.hasMoreData)
		}

		do {
			let data3 = Data([0x11, 0x22, 0x33, 0x44])
			let parser3 = BytesReader(data: data3)
			let datar = try parser3.readData(count: 4)
			XCTAssertEqual([0x11, 0x22, 0x33, 0x44], Array(datar))
			XCTAssertFalse(parser3.hasMoreData)
			XCTAssertThrowsError(try parser3.readByte())
		}

		do {
			let data3 = Data([0x11, 0x22, 0x33, 0x44])
			let parser3 = BytesReader(data: data3)
			let data1 = try parser3.readData(count: 2)
			let data2 = try parser3.readData(count: 2)
			XCTAssertFalse(parser3.hasMoreData)
			XCTAssertThrowsError(try parser3.readByte())

			XCTAssertEqual([0x11, 0x22], Array(data1))
			XCTAssertEqual([0x33, 0x44], Array(data2))
		}

		do {
			let data3 = Data([0x11, 0x22, 0x33, 0x44])
			let parser3 = BytesReader(data: data3)
			let data1 = try parser3.readData(count: 1)
			let data2 = try parser3.readAllRemainingData()
			XCTAssertFalse(parser3.hasMoreData)
			XCTAssertThrowsError(try parser3.readByte())

			XCTAssertEqual([0x11], Array(data1))
			XCTAssertEqual([0x22, 0x33, 0x44], Array(data2))
		}
	}

	func testReadToEndOfData() throws {
		let data = BytesReader(bytes: [0x11, 0x22, 0x33, 0x44])
		XCTAssertEqual(0x11, try data.readByte())
		XCTAssertEqual(Data([0x22, 0x33, 0x44]), try data.readAllRemainingData())
		XCTAssertFalse(data.hasMoreData)
	}

	func testMultipleUInts() throws {

		let values: [UInt16] = [12345, 54321, 33221]

		do {
			let d = try BytesWriter()
			try d.writeIntegers(values, .big)
			let data = try d.data()
			XCTAssertEqual(data.count, values.count * 2)

			let p = BytesReader(data: data)
			let ints: [UInt16] = try p.readIntegers(.big, count: 3)
			XCTAssertEqual(ints, values)
		}

		do {
			let d = try BytesWriter()
			try d.writeIntegers(values, .little)
			let data = try d.data()
			XCTAssertEqual(d.count, values.count * 2)

			let p = BytesReader(data: data)
			let ints: [UInt16] = try p.readIntegers(.little, count: 3)
			XCTAssertEqual(ints, values)
		}
	}

	func testMultipleInts() throws {

		let values: [Int16] = [12345, -200, -9]

		do {
			let d = try BytesWriter()
			try d.writeIntegers(values, .big)
			let data = try d.data()
			XCTAssertEqual(data.count, values.count * 2)

			let p = BytesReader(data: data)
			let ints: [Int16] = try p.readIntegers(.big, count: 3)
			XCTAssertEqual(ints, values)
		}

		do {
			let d = try BytesWriter()
			try d.writeIntegers(values, .little)
			let data = try d.data()

			XCTAssertEqual(data.count, values.count * 2)

			let p = BytesReader(data: data)
			let ints: [Int16] = try p.readIntegers(.little, count: 3)
			XCTAssertEqual(ints, values)
		}
	}

	func testWritePadding() throws {
		do {
			let d = try BytesWriter()
			try d.writeByte(0x11)
			try d.padToFourByteBoundary()
			XCTAssertEqual([0x11, 0x00, 0x00, 0x00], try d.rawBytes())
		}

		do {
			let d = try BytesWriter()
			try d.writeBytes([0x11, 0x22, 0x33])
			try d.padToFourByteBoundary(using: 0xFF)
			XCTAssertEqual([0x11, 0x22, 0x33, 0xFF], try d.rawBytes())
		}
	}

	func testWriteString() throws {
		do {
			let msg = "© Hello There"
			let d = try BytesWriter()
			let l = try d.writeStringByte(msg, encoding: .isoLatin1)
			XCTAssertEqual(13, l)

			let p = BytesReader(data: try d.data())
			let str = try p.readStringSingleByteEncoding(.isoLatin1, length: 13)
			XCTAssertEqual(msg, str)
		}
	}

	func testMixedEndian() throws {
		let writer = try BytesWriter()
		try writer.writeInt16(10101, .big)
		try writer.writeUInt16(40000, .big)
		try writer.writeInt16(-10101, .little)
		try writer.writeUInt16(65535, .little)

		try writer.writeFloat64(12345.67890, .little)
		try writer.writeByte(0x01)
		try writer.writeByte(0x00)

		XCTAssertEqual(18, writer.count)

		let parser = BytesReader(data: try writer.data())
		XCTAssertEqual(10101, try parser.readInt16(.big))
		XCTAssertEqual(40000, try parser.readUInt16(.big))
		XCTAssertEqual(-10101, try parser.readInt16(.little))
		XCTAssertEqual(65535, try parser.readUInt16(.little))
		XCTAssertEqual(12345.67890, try parser.readFloat64(.little))
		XCTAssertEqual(0x01, try parser.readByte())
		XCTAssertEqual(0x00, try parser.readByte())
	}

	func test32BitString() throws {
		let message = "10. 好き 【す・き】 (na-adj) – likable; desirable"
		let msgcount = message.count

		let writer = try BytesWriter()
		try writer.writeStringUTF32(message, endianness: .big)
		try writer.writeByte(0x78)
		try writer.writeStringUTF32(message, endianness: .little)
		XCTAssertEqual((msgcount * 4) * 2 + 1, writer.count)

		let parser = BytesReader(data: try writer.data())
		let str1 = try parser.readStringUTF32(.big, length: message.count)
		XCTAssertEqual(message, str1)
		XCTAssertEqual(0x78, try parser.readByte())
		let str2 = try parser.readStringUTF32(.little, length: message.count)
		XCTAssertEqual(message, str2)
	}
}
