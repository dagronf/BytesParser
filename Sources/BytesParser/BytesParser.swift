//
//  Copyright © 2024 Darren Ford. All rights reserved.
//
//  MIT license
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial
//  portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//  WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
//  OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//  OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

/// An object that can iterate through raw byte data and extract parsable data (eg. integers, floats etc)
public class BytesParser {
	/// Errors thrown by the parser
	public enum ParseError: Error {
		case invalidFile
		case endOfData
		case invalidStringEncoding
	}

	/// Is there more data to read?
	public var hasMoreData: Bool { self.inputStream.hasBytesAvailable }

	/// The current read offset within the source
	public internal(set) var offset: Int = 0

	/// Create a byte parser from a data object
	public init(data: Data) {
		self.inputStream = InputStream(data: data)
		self.inputStream.open()
	}

	/// Create a byte parser from an array of bytes
	public init(content: [UInt8]) {
		self.inputStream = InputStream(data: Data(content))
		self.inputStream.open()
	}

	/// Create a byte parser with an opened input stream
	public init(inputStream: InputStream) {
		self.inputStream = inputStream
		self.inputStream.open()
	}

	/// Create a byte parser from the contents of a local file
	public init(fileURL: URL) throws {
		guard
			fileURL.isFileURL,
			let inputStream = InputStream(url: fileURL)
		else {
			throw ParseError.invalidFile
		}
		self.inputStream = inputStream
		inputStream.open()
	}

	// private
	let readBuffer = ByteBuffer()

	// The stream containing the data to be parsed
	let inputStream: InputStream
}

// MARK: - Convenience readers

public extension BytesParser {
	/// Parse the contents of a `Data` object
	/// - Parameters:
	///   - data: The data object to parse
	///   - block: The block containing the parsing calls
	@inlinable static func parse(data: Data, _ block: (BytesParser) throws -> Void) throws {
		let parser = BytesParser(data: data)
		try block(parser)
	}

	/// Parse the contents of a byte array
	/// - Parameters:
	///   - bytes: An array of bytes to parse
	///   - block: The block containing the parsing calls
	@inlinable static func parse(bytes: [UInt8], _ block: (BytesParser) throws -> Void) throws {
		let parser = BytesParser(content: bytes)
		try block(parser)
	}

	/// Parse the contents of a local file
	/// - Parameters:
	///   - fileURL: The local file URL to read from
	///   - block: The block containing the parsing calls
	@inlinable static func parse<ResultType>(fileURL: URL, _ block: (BytesParser) throws -> ResultType) throws -> ResultType {
		let parser = try BytesParser(fileURL: fileURL)
		return try block(parser)
	}

	/// Parse the contents of an input stream
	/// - Parameters:
	///   - inputStream: The stream to read from
	///   - block: The block containing the parsing calls
	@inlinable static func parse(inputStream: InputStream, _ block: (BytesParser) throws -> Void) throws {
		let parser = BytesParser(inputStream: inputStream)
		try block(parser)
	}

	/// Read all remaining data in the input stream
	/// - Parameter inputStream: The inputstream to read from
	/// - Returns: A data object containing the read data
	@inlinable static func data(inputStream: InputStream) throws -> Data {
		try BytesParser(inputStream: inputStream).readAllRemainingData()
	}
}
