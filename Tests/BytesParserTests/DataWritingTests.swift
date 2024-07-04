
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

	func testWritingFloatValues() throws {
		do {
			let value: Float32 = 1234.5678
			let w = try BytesWriter()
			try w.writeFloat32(value, .big)

			let r = BytesParser(data: try w.data())
			let rv = try r.readFloat32(.big)
			XCTAssertEqual(value, rv)
		}

		do {
			let value: Float64 = 1234.5678
			let w = try BytesWriter()
			try w.writeFloat64(value, .big)

			let r = BytesParser(data: try w.data())
			let rv = try r.readFloat64(.big)
			XCTAssertEqual(value, rv)
		}

		do {
			let value1: Float64 = 1234.5678
			let value2: Float64 = 8765.4321
			let w = try BytesWriter()
			try w.writeFloat64(value1, .big)
			try w.writeFloat64(value2, .big)

			let r = BytesParser(data: try w.data())
			let rv1 = try r.readFloat64(.big)
			let rv2 = try r.readFloat64(.big)
			XCTAssertEqual(value1, rv1)
			XCTAssertEqual(value2, rv2)
		}

		do {
			let value1: Float64 = 1234.5678
			let value2: Float64 = 8765.4321
			let w = try BytesWriter()
			try w.writeFloat64(value1, .big)
			try w.writeFloat64(value2, .little)

			let r = BytesParser(data: try w.data())
			let rv1 = try r.readFloat64(.big)
			let rv2 = try r.readFloat64(.little)
			XCTAssertEqual(value1, rv1)
			XCTAssertEqual(value2, rv2)
		}

		do {
			let value1: [Float32] = [1234.5678, 8765.4321]
			let w = try BytesWriter()
			try w.writeFloat32(value1, .big)
			let r = BytesParser(data: try w.data())
			let rv1 = try r.readFloat32(.big, count: 2)
			XCTAssertEqual(value1, rv1)
		}
	}

	func testWritingFloat32ArrayValues() throws {
		let vals: [Float32] = [1451.2224, 1.2, 9999.9]
		let data = try BytesWriter.assemble() { writer in
			try writer.writeFloat32(vals, .big)
			try writer.writeFloat32(vals, .little)
		}

		try BytesParser.parse(data: data) { parser in
			let v1 = try parser.readFloat32(.big, count: vals.count)
			let v2 = try parser.readFloat32(.little, count: vals.count)

			XCTAssertEqual(vals, v1)
			XCTAssertEqual(vals, v2)
		}
	}

	func testWritingFloat64ArrayValues() throws {
		let vals: [Float64] = [
			51.43243344285539,
			51.92791316776663,
			45.04754409242326,
			28.77642913403846,
			58.21730813384373
		]
		let data = try BytesWriter.assemble() { writer in
			try writer.writeFloat64(vals, .big)
			try writer.writeFloat64(vals, .little)
		}

		try BytesParser.parse(data: data) { parser in
			let v1 = try parser.readFloat64(.big, count: vals.count)
			let v2 = try parser.readFloat64(.little, count: vals.count)

			XCTAssertEqual(vals, v1)
			XCTAssertEqual(vals, v2)
		}

		try BytesParser.parse(data: data) { parser in
			let v1 = try parser.readFloat64(.little, count: vals.count)
			let v2 = try parser.readFloat64(.big, count: vals.count)

			XCTAssertNotEqual(vals, v1)
			XCTAssertNotEqual(vals, v2)
		}
	}

	func testWriteDataChunks() throws {
		let raw: [UInt8] = (0 ..< 1_000_000).map { index in
			return UInt8(index % 256)
		}

		let data = try BytesWriter.assemble { w in
			try w.writeBytes(raw)
			try w.writeInt16(123, .little)
		}

		try BytesParser.parse(data: data) { r in
			let rw = try r.readBytes(count: raw.count)
			XCTAssertEqual(raw, rw)

			let i = try r.readInt16(.little)
			XCTAssertEqual(123, i)

			// Should not have any more data
			XCTAssertThrowsError(try r.readByte())
		}
	}
}
