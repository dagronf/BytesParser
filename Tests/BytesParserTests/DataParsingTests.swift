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
			let str1 = try parser.readString(length: 5, encoding: .ascii, lengthIncludesTerminator: true)
			XCTAssertEqual(str1, "fish")
			let str2 = try parser.readString(length: 4, encoding: .ascii, lengthIncludesTerminator: true)
			XCTAssertEqual(str2, "and")
			XCTAssertThrowsError(try parser.readByte())
		}

		do {
			let data = BytesParser(content: d)
			let str1 = try data.readString(length: 5, encoding: .ascii, lengthIncludesTerminator: true)
			XCTAssertEqual(str1, "fish")
			let str2 = try data.readString(length: 4, encoding: .ascii, lengthIncludesTerminator: true)
			XCTAssertEqual(str2, "and")
			XCTAssertThrowsError(try data.readByte())
		}

		do {
			let data = BytesParser(content: d)
			let str1 = try data.readString(length: 4, encoding: .ascii, lengthIncludesTerminator: false)
			XCTAssertEqual(str1, "fish")
			XCTAssertEqual(0x00, try data.readByte())
			let str2 = try data.readString(length: 3, encoding: .ascii, lengthIncludesTerminator: false)
			XCTAssertEqual(str2, "and")
			XCTAssertEqual(0x00, try data.readByte())
			XCTAssertThrowsError(try data.readByte())
		}
	}

	func testWindowsWideStringRead() throws {
		// https://onlineutf8tools.com/convert-utf8-to-utf16
		let rawData: [UInt8] = [0x1f,0x04, 0x40,0x04, 0x38,0x04, 0x32,0x04, 0x35,0x04, 0x42,0x04, 0x00,0x00, 0x80, 0x99]
		try BytesParser.parse(bytes: rawData) { parser in
			let msg = try parser.readWide16StringNullTerminated(encoding: .utf16LittleEndian)
			XCTAssertEqual(msg, "Привет")
			XCTAssertEqual(0x80, try parser.readByte())
			XCTAssertEqual(0x99, try parser.readByte())
			XCTAssertThrowsError(try parser.readByte())
		}

		// Whitespace at the end
		let rawData2: [UInt8] = [0x1f,0x04, 0x40,0x04, 0x38,0x04, 0x32,0x04, 0x35,0x04, 0x42,0x04, 0x00, 0x00]
		try BytesParser.parse(bytes: rawData2) { parser in
			let msg = try parser.readWide16StringNullTerminated(encoding: .utf16LittleEndian)
			XCTAssertEqual(msg, "Привет")
			XCTAssertThrowsError(try parser.readByte())
		}
	}

	func testAsciiRead() throws {
		// fish and\0chips
		let d: [UInt8] = [0x66,0x69,0x73,0x68,0x20,0x61,0x6E,0x64,0x00,0x63,0x68,0x69,0x70,0x73,0x00,0x99]
		let data = BytesParser(content: d)
		let str1 = try data.readStringNullTerminated(encoding: .ascii)
		XCTAssertEqual("fish and", str1)

		let str2 = try data.readStringNullTerminated(encoding: .ascii)
		XCTAssertEqual("chips", str2)

		XCTAssertTrue(data.hasMoreData)
		let b = try data.readByte()
		XCTAssertEqual(0x99, b)

		XCTAssertFalse(data.hasMoreData)

		try withDataWrittenToTemporaryInputStream(Data(d)) { inputStream in
			try BytesParser.parse(inputStream: inputStream) { parser in
				let str1 = try parser.readStringNullTerminated(encoding: .ascii)
				XCTAssertEqual("fish and", str1)

				let str2 = try parser.readStringNullTerminated(encoding: .ascii)
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
			try writer.writeInt16(10101, .bigEndian)
			try writer.writeUInt16(40000, .bigEndian)
			try writer.writeInt16(-10101, .littleEndian)
			try writer.writeUInt16(65535, .littleEndian)

			try writer.writeFloat64(12345.67890, .littleEndian)
			try writer.writeBool(true)
			try writer.writeBool(false)
		}

		try BytesParser.parse(data: data) { parser in
			XCTAssertEqual(10101, try parser.readInt16(.bigEndian))
			XCTAssertEqual(40000, try parser.readUInt16(.bigEndian))
			XCTAssertEqual(-10101, try parser.readInt16(.littleEndian))
			XCTAssertEqual(65535, try parser.readUInt16(.littleEndian))
			XCTAssertEqual(12345.67890, try parser.readFloat64(.littleEndian))
			XCTAssertEqual(true, try parser.readBool())
			XCTAssertEqual(false, try parser.readBool())
		}
	}

	func test32BitString() throws {
		let message = "10. 好き 【す・き】 (na-adj) – likable; desirable"
		let data = try BytesWriter.generate { writer in
			try writer.writeWide32String(message, encoding: .utf32BigEndian)
			try writer.writeByte(0x78)
			try writer.writeWide32String(message, encoding: .utf32LittleEndian)
		}
		try BytesParser.parse(data: data) { parser in
			let str1 = try parser.readWide32String(length: message.count, encoding: .utf32BigEndian)
			XCTAssertEqual(message, str1)
			XCTAssertEqual(0x78, try parser.readByte())
			let str2 = try parser.readWide32String(length: message.count, encoding: .utf32LittleEndian)
			XCTAssertEqual(message, str2)
		}
	}

	func testReadRealCrosswordFile() throws {
		// Parse a binary crossword file

		let url = Bundle.module.url(forResource: "May0612", withExtension: "puz")!

		try BytesParser.parse(fileURL: url) { parser in
			let /*checksum*/ _: Int16 = try parser.readInteger(.littleEndian)
			let magic = try parser.readString(length: 12, encoding: .ascii, lengthIncludesTerminator: true)
			XCTAssertEqual(magic, "ACROSS&DOWN")

			let /*cksum_cib*/ _: Int16 = try parser.readInteger(.littleEndian)
			let /*magic10*/ _ = try parser.readBytes(count: 4)
			let /*magic14*/ _ = try parser.readBytes(count: 4)
			let /*magic18*/ _ = try parser.readBytes(count: 4)

			let /*noise_1c*/ _: Int16 = try parser.readInteger(.littleEndian)
			let /*scrambled_tag*/ _: Int16 = try parser.readInteger(.littleEndian)

			let /*noise_20*/ _: Int16 = try parser.readInteger(.littleEndian)
			let /*noise_22*/ _: Int16 = try parser.readInteger(.littleEndian)
			let /*noise_24*/ _: Int16 = try parser.readInteger(.littleEndian)
			let /*noise_26*/ _: Int16 = try parser.readInteger(.littleEndian)
			let /*noise_28*/ _: Int16 = try parser.readInteger(.littleEndian)
			let /*noise_2a*/ _: Int16 = try parser.readInteger(.littleEndian)

			let width = Int(try parser.readByte())
			XCTAssertEqual(21, width)
			let height = Int(try parser.readByte())
			XCTAssertEqual(21, height)

			let clue_count: UInt16 = try parser.readInteger(.littleEndian)
			XCTAssertEqual(142, clue_count)
			let /*grid_type*/ _: UInt16 = try parser.readInteger(.littleEndian)
			let /*grid_flag*/ _: UInt16 = try parser.readInteger(.littleEndian)

			let solution = try parser.readBytes(count: width * height)
			XCTAssertEqual(441, solution.count)
			let text = try parser.readBytes(count: width * height)
			XCTAssertEqual(441, text.count)

			let title = try parser.readStringNullTerminated(encoding: .ascii)
			XCTAssertEqual("NY Times, Sunday, May 6, 2012 A-v Club", title)
			let author = try parser.readStringNullTerminated(encoding: .ascii)
			XCTAssertEqual("Alex Vratsanos / Will Shortz", author)
			let copyright = try parser.readStringNullTerminated(encoding: .ascii)
			XCTAssertEqual("© 2012, The New York Times", copyright)

			var c = [String]()
			for _ in 0 ..< clue_count {
				c.append(try parser.readStringNullTerminated(encoding: .ascii))
			}
			XCTAssertEqual("Something you willingly part with?", c[0])
			XCTAssertEqual("Got in the end", c[141])
		}
	}

	func testParseACB() throws {
		// ACB integers are all big endian

		let url = Bundle.module.url(forResource: "HKS E (LAB)", withExtension: "acb")!

		// Function to read Adobe-style pascal strings
		func readPascalStyleWideString(_ parser: BytesParser) throws -> String {
			// The length of title
			let titleLength = try parser.readUInt32(.bigEndian)
			return try parser.readUTF16String(length: Int(titleLength))
		}

		try BytesParser.parse(fileURL: url) { parser in
			let magic = try parser.readString(length: 4, encoding: .ascii)
			XCTAssertEqual("8BCB", magic)

			let version = try parser.readUInt16(.bigEndian)
			XCTAssertEqual(1, version)

			let identifier = try parser.readUInt16(.bigEndian)
			XCTAssertEqual(3008, identifier)

			// title is a wide string of 'titleLength' characters
			let title = try readPascalStyleWideString(parser)
			XCTAssertEqual("$$$/colorbook/HKSE/title=HKS E", title)

			let prefix = try readPascalStyleWideString(parser)
			XCTAssertEqual("$$$/colorbook/HKSE/prefix=HKS ", prefix)
			let suffix = try readPascalStyleWideString(parser)
			XCTAssertEqual("$$$/colorbook/HKSE/postfix= E", suffix)
			let description = try readPascalStyleWideString(parser)
			XCTAssertEqual(description, "$$$/colorbook/HKSE/description=Copyright^C 2001, HKS (Hostmann-Steinberg, K+E, Schmincke) - Warenzeichenverband e.V.")

			let colorCount = try parser.readUInt16(.bigEndian)
			XCTAssertEqual(98, colorCount)

			let pageSize = try parser.readUInt16(.bigEndian)
			XCTAssertEqual(5, pageSize)
			let pageSelectorOffset = try parser.readUInt16(.bigEndian)
			XCTAssertEqual(1, pageSelectorOffset)

			let colorSpace = try parser.readUInt16(.bigEndian)
			let componentCount: Int = {
				switch colorSpace {
				case 0: return 3  // rgb
				case 2: return 4  // cmyk
				case 7: return 3  // lab
				case 8: return 1  // grayscale
				default:
					fatalError()
				}
			}()

			for _ in 0 ..< colorCount {
				let /*colorName*/ _ = try readPascalStyleWideString(parser)
				let /*colorCode*/ _ = try parser.readString(length: 6, encoding: .ascii)
				let /*channels*/ _  = try parser.readData(count: componentCount)
			}

			// Last thing in the file should be the spot identifier (as ascii), providing
			// we have read all the other data correctly!
			let spotIdentifier = try parser.readString(length: 8, encoding: .ascii)
			XCTAssertEqual("spflspot", spotIdentifier)

			// Paste the end of file -- should throw an error
			XCTAssertThrowsError(try parser.readByte())
		}
	}
}


extension Data {
	struct HexEncodingOptions: OptionSet {
		let rawValue: Int
		static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
	}

	func hexEncodedString(options: HexEncodingOptions = []) -> String {
		let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
		return self.map { String(format: format, $0) }.joined()
	}
}
