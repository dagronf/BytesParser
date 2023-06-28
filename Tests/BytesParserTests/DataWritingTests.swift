
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
		let data = try BytesWriter.generate { writer in
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

	func testNumbers() throws {

		let out = try BytesWriter.generate { writer in
			try writer.writeUInt16Value(101, isBigEndian: false)
			try writer.writeUInt32Value(77688, isBigEndian: true)
			try writer.writeUInt16Value(2987, isBigEndian: false)
			try writer.writeAsciiNoTerminator("abcd")
			try writer.writeBool(true)
			try writer.writeFloat64(12345.12345)
			try writer.writeBool(false)
			try writer.writeUInt8Value(254)
		}

		let p = BytesParser(data: out)
		let v1: UInt16 = try p.readLittleEndian()
		XCTAssertEqual(101, v1)
		let v2: UInt32 = try p.readBigEndian()
		XCTAssertEqual(77688, v2)
		let v3: UInt16 = try p.readLittleEndian()
		XCTAssertEqual(2987, v3)
		XCTAssertEqual("abcd", try p.readAsciiString(length: 4))

		XCTAssertEqual(true, try p.readBool())
		XCTAssertEqual(12345.12345, try p.readFloat64())
		XCTAssertEqual(false, try p.readBool())

		let v4: UInt8 = try p.readByte()
		XCTAssertEqual(254, v4)
	}
}
