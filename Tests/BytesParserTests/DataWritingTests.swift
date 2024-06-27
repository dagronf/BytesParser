
import XCTest
@testable import BytesParser

final class DataWritingTests: XCTestCase {

	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testBasic() throws {
		let data = try BytesWriter.assemble { writer in
			try writer.writeByte(0x20)
			try writer.writeByte(0x40)
			try writer.writeByte(0x60)
			try writer.writeByte(0x80)
		}
		XCTAssertEqual(4, data.count)
		let raw: [UInt8] = data.prefix(4).map { $0 }
		XCTAssertEqual([0x20, 0x40, 0x60, 0x80], raw)
	}

	func testBasic2() throws {
		let mem = try BytesWriter()
		let data: [UInt8] = [0x20, 0x40, 0x60, 0x80]
		try mem.writeBytes(data)
		mem.complete()
		XCTAssertEqual(4, data.count)
		let data2 = try mem.data()
		let raw: [UInt8] = data2.prefix(4).map { $0 }
		XCTAssertEqual([0x20, 0x40, 0x60, 0x80], raw)
	}

	func testInt8() throws {
		let data = try BytesWriter.assemble { writer in
			try writer.writeInt8(-10)
			try writer.writeInt8(10)
			try writer.writeUInt8(234)
		}

		XCTAssertEqual(3, data.count)

		try BytesParser.parse(data: data) { parser in
			// Map byte to a Int8
			XCTAssertEqual(-10, try parser.readInt8())
			XCTAssertEqual(10, try parser.readInt8())
			XCTAssertEqual(-22, try parser.readInt8())
		}

		try BytesParser.parse(data: data) { parser in
			XCTAssertEqual(246, try parser.readUInt8())
			XCTAssertEqual(10, try parser.readUInt8())
			XCTAssertEqual(234, try parser.readUInt8())
		}
	}

	func testNumbers() throws {

		let out = try BytesWriter.assemble { writer in
			try writer.writeUInt16(101, .little) // 2
			try writer.writeUInt32(77688, .big)  // 4
			try writer.writeUInt16(2987, .little)  // 2
			try writer.writeByteString("abcd", encoding: .ascii) // 4
			try writer.writeBool(true) // 1
			try writer.writeFloat64(12345.12345, .big) // 8
			try writer.writeBool(false) // 1
			try writer.writeUInt8(254) // 1
		}

		XCTAssertEqual(23, out.count)

		let p = BytesParser(data: out)
		let v1: UInt16 = try p.readInteger(.little)
		XCTAssertEqual(101, v1)
		let v2: UInt32 = try p.readInteger(.big)
		XCTAssertEqual(77688, v2)
		let v3: UInt16 = try p.readInteger(.little)
		XCTAssertEqual(2987, v3)
		XCTAssertEqual("abcd", try p.readString(.ascii, length: 4))

		XCTAssertEqual(true, try p.readBool())
		XCTAssertEqual(12345.12345, try p.readFloat64(.big))
		XCTAssertEqual(false, try p.readBool())

		let v4: UInt8 = try p.readByte()
		XCTAssertEqual(254, v4)
	}

	func testWriteToFile() throws {

		try withTemporaryFile { fileURL in

			let message = "10. 好き 【す・き】 (na-adj) – likable; desirable"

			// Generate the file content
			try BytesWriter.assemble(fileURL: fileURL) { writer in
				try writer.writeUInt16(101, .little)
				try writer.writeUInt32(77688, .big)
				try writer.writeUInt16(2987, .little)
				try writer.writeByteString("abcd", encoding: .ascii)
				try writer.writeBool(true)
				try writer.writeByteStringNullTerminated(message, encoding: .utf8)
				try writer.writeFloat64(12345.12345, .big)
				try writer.writeBool(false)
				try writer.writeUInt8(254)
			}

			// Now, try to read it back in
			try BytesParser.parse(fileURL: fileURL) { parser in
				let v1: UInt16 = try parser.readInteger(.little)
				XCTAssertEqual(101, v1)
				let v2: UInt32 = try parser.readInteger(.big)
				XCTAssertEqual(77688, v2)
				let v3: UInt16 = try parser.readInteger(.little)
				XCTAssertEqual(2987, v3)
				XCTAssertEqual("abcd", try parser.readString(.ascii, length: 4))

				XCTAssertEqual(true, try parser.readBool())

				let msg = try parser.readStringNullTerminated(.utf8)
				XCTAssertEqual(message, msg)

				XCTAssertEqual(12345.12345, try parser.readFloat64(.big))
				XCTAssertEqual(false, try parser.readBool())

				let v4: UInt8 = try parser.readByte()
				XCTAssertEqual(254, v4)
			}
		}
	}

	func testPaddingAddNoPadding() throws {
		// Shouldn't add any padding
		let data = try BytesWriter.assemble() { writer in
			try writer.writeUInt32(22345, .big)
			try writer.padToFourByteBoundary()
		}

		XCTAssertEqual(4, data.count)

		try BytesParser.parse(data: data) { parser in
			XCTAssertEqual(22345, try parser.readUInt32(.big))
			XCTAssertThrowsError(try parser.readByte())
		}
	}

	func testPadding3BytesExpected() throws {
		let data = try BytesWriter.assemble() { writer in
			try writer.writeBool(true)
			try writer.padToFourByteBoundary(using: 0xff)
		}

		XCTAssertEqual(4, data.count)

		try BytesParser.parse(data: data) { parser in
			XCTAssertEqual(true, try parser.readBool())
			XCTAssertEqual(0xff, try parser.readByte())
			XCTAssertEqual(0xff, try parser.readByte())
			XCTAssertEqual(0xff, try parser.readByte())
			XCTAssertThrowsError(try parser.readByte())
		}
	}

	func testPadding2BytesExpected() throws {
		// Generate the file content
		let data = try BytesWriter.assemble() { writer in
			try writer.writeUInt16(22345, .big)
			try writer.padToFourByteBoundary()
		}

		XCTAssertEqual(4, data.count)

		try BytesParser.parse(data: data) { parser in
			XCTAssertEqual(22345, try parser.readInt16(.big))
			XCTAssertEqual(0x0, try parser.readByte())
			XCTAssertEqual(0x0, try parser.readByte())
			XCTAssertThrowsError(try parser.readByte())
		}
	}

	func testPadding1BytesExpected() throws {
		// Generate the file content
		let data = try BytesWriter.assemble() { writer in
			try writer.writeUInt16(22345, .big)
			try writer.writeByte(0xcd)
			try writer.padToFourByteBoundary()
		}

		XCTAssertEqual(4, data.count)

		try BytesParser.parse(data: data) { parser in
			XCTAssertEqual(22345, try parser.readInt16(.big))
			XCTAssertEqual(0xcd, try parser.readByte())
			XCTAssertEqual(0x0, try parser.readByte())
			XCTAssertThrowsError(try parser.readByte())
		}
	}
}
