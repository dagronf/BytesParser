
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
		let raw: [UInt8] = data.prefix(4).map { $0 }
		XCTAssertEqual([0x20, 0x40, 0x60, 0x80], raw)
	}

	func testBasic2() throws {
		let mem = try BytesWriter()
		let data: [UInt8] = [0x20, 0x40, 0x60, 0x80]
		try mem.writeBytes(data)
		mem.complete()
		let data2 = try mem.data()
		let raw: [UInt8] = data2.prefix(4).map { $0 }
		XCTAssertEqual([0x20, 0x40, 0x60, 0x80], raw)
	}

	func testInt8() throws {
		let data = try BytesWriter.assemble { writer in
			try writer.writeInt8(-10)
			try writer.writeInt8(10)
		}

		try BytesParser.parse(data: data) { parser in
			// Map byte to a Int8
			XCTAssertEqual(-10, try parser.readInt8())
			XCTAssertEqual(10, try parser.readInt8())
		}

		try BytesParser.parse(data: data) { parser in
			XCTAssertEqual(246, try parser.readUInt8())
			XCTAssertEqual(10, try parser.readUInt8())
		}
	}

	func testNumbers() throws {

		let out = try BytesWriter.assemble { writer in
			try writer.writeUInt16(101, .littleEndian)
			try writer.writeUInt32(77688, .bigEndian)
			try writer.writeUInt16(2987, .littleEndian)
			try writer.writeByteString("abcd", encoding: .ascii)
			try writer.writeBool(true)
			try writer.writeFloat64(12345.12345, .bigEndian)
			try writer.writeBool(false)
			try writer.writeUInt8(254)
		}

		let p = BytesParser(data: out)
		let v1: UInt16 = try p.readInteger(.littleEndian)
		XCTAssertEqual(101, v1)
		let v2: UInt32 = try p.readInteger(.bigEndian)
		XCTAssertEqual(77688, v2)
		let v3: UInt16 = try p.readInteger(.littleEndian)
		XCTAssertEqual(2987, v3)
		XCTAssertEqual("abcd", try p.readString(length: 4, encoding: .ascii))

		XCTAssertEqual(true, try p.readBool())
		XCTAssertEqual(12345.12345, try p.readFloat64(.bigEndian))
		XCTAssertEqual(false, try p.readBool())

		let v4: UInt8 = try p.readByte()
		XCTAssertEqual(254, v4)
	}

	func testWriteToFile() throws {

		try withTemporaryFile { fileURL in

			let message = "10. 好き 【す・き】 (na-adj) – likable; desirable"

			// Generate the file content
			try BytesWriter.assemble(fileURL: fileURL) { writer in
				try writer.writeUInt16(101, .littleEndian)
				try writer.writeUInt32(77688, .bigEndian)
				try writer.writeUInt16(2987, .littleEndian)
				try writer.writeByteString("abcd", encoding: .ascii)
				try writer.writeBool(true)
				try writer.writeByteStringNullTerminated(message, encoding: .utf8)
				try writer.writeFloat64(12345.12345, .bigEndian)
				try writer.writeBool(false)
				try writer.writeUInt8(254)
			}

			// Now, try to read it back in
			try BytesParser.parse(fileURL: fileURL) { parser in
				let v1: UInt16 = try parser.readInteger(.littleEndian)
				XCTAssertEqual(101, v1)
				let v2: UInt32 = try parser.readInteger(.bigEndian)
				XCTAssertEqual(77688, v2)
				let v3: UInt16 = try parser.readInteger(.littleEndian)
				XCTAssertEqual(2987, v3)
				XCTAssertEqual("abcd", try parser.readString(length: 4, encoding: .ascii))

				XCTAssertEqual(true, try parser.readBool())

				let msg = try parser.readStringNullTerminated(encoding: .utf8)
				XCTAssertEqual(message, msg)

				XCTAssertEqual(12345.12345, try parser.readFloat64(.bigEndian))
				XCTAssertEqual(false, try parser.readBool())

				let v4: UInt8 = try parser.readByte()
				XCTAssertEqual(254, v4)
			}
		}
	}
}
