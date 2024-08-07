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
public class BytesReader {
	/// Is there more data to read?
	public var hasMoreData: Bool { self.inputStream.hasBytesAvailable }

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
	/// - Parameter fileURL: The file URL to read
	public init(fileURL: URL) throws {
		guard
			fileURL.isFileURL,
			let inputStream = InputStream(url: fileURL)
		else {
			throw BytesReader.ParseError.invalidFile
		}
		self.inputStream = inputStream
		inputStream.open()
	}

	/// The current read offset within the input data
	public func readOffset() -> Int { self.offset }

	// private
	
	let readBuffer = ByteBuffer()

	/// The current read offset within the source
	var offset: Int = 0

	// The stream containing the data to be parsed
	let inputStream: InputStream
}

// MARK: - Convenience readers

public extension BytesReader {
	/// Parse the contents of a `Data` object
	/// - Parameters:
	///   - data: The data object to parse
	///   - block: The block containing the parsing calls
	@inlinable static func read(data: Data, _ block: (BytesReader) throws -> Void) throws {
		let parser = BytesReader(data: data)
		try block(parser)
	}

	/// Parse the contents of a byte array
	/// - Parameters:
	///   - bytes: An array of bytes to parse
	///   - block: The block containing the parsing calls
	@inlinable static func read(bytes: [UInt8], _ block: (BytesReader) throws -> Void) throws {
		let parser = BytesReader(content: bytes)
		try block(parser)
	}

	/// Parse the contents of a local file
	/// - Parameters:
	///   - fileURL: The local file URL to read from
	///   - block: The block containing the parsing calls
	@inlinable static func read<ResultType>(fileURL: URL, _ block: (BytesReader) throws -> ResultType) throws -> ResultType {
		let parser = try BytesReader(fileURL: fileURL)
		return try block(parser)
	}

	/// Parse the contents of an input stream
	/// - Parameters:
	///   - inputStream: The stream to read from
	///   - block: The block containing the parsing calls
	@inlinable static func read(inputStream: InputStream, _ block: (BytesReader) throws -> Void) throws {
		let parser = BytesReader(inputStream: inputStream)
		try block(parser)
	}

	/// Read all remaining data in the input stream
	/// - Parameter inputStream: The inputstream to read from
	/// - Returns: A data object containing the read data
	@inlinable static func data(inputStream: InputStream) throws -> Data {
		try BytesReader(inputStream: inputStream).readAllRemainingData()
	}
}
