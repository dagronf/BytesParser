//
//  InputStreamIterable.swift
//
//  Copyright © 2023 Darren Ford. All rights reserved.
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

internal class InputStreamIterable: BytesParserIterable {
	let inputStream: InputStream
	
	static let DefaultSize = 1024
	
	var readBufferSize = InputStreamIterable.DefaultSize
	var readBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: InputStreamIterable.DefaultSize)
	
	init(inputStream: InputStream) {
		self.inputStream = inputStream
	}
	
	var hasMoreData: Bool { self.inputStream.hasBytesAvailable }
	
	deinit {
		readBuffer.deallocate()
	}
	
	@inlinable func reconfigureIfNeeded(_ count: Int) {
		if count > self.readBufferSize {
			self.readBuffer.deallocate()
			self.readBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: InputStreamIterable.DefaultSize)
		}
	}
	
	/// Read a single byte from the input stream
	func next() throws -> UInt8 {
		guard self.inputStream.hasBytesAvailable else { throw BytesParser.ParseError.endOfData }
		self.reconfigureIfNeeded(1)
		let readCount = self.inputStream.read(self.readBuffer, maxLength: 1)
		guard readCount == 1 else { throw BytesParser.ParseError.endOfData }
		return self.readBuffer.pointee
	}
	
	/// Read the next `count` bytes from the input stream
	func next(_ count: Int) throws -> Data {
		guard count > 0 else { return Data() }
		guard self.inputStream.hasBytesAvailable else { throw BytesParser.ParseError.endOfData }
		
		self.reconfigureIfNeeded(count)
		
		var result = Data()
		
		// Loop until we've read all the required data
		var read = 0
		while read != count {
			let readCount = self.inputStream.read(self.readBuffer, maxLength: count - read)
			if readCount == 0, !self.inputStream.hasBytesAvailable {
				// If we haven't read anything and there's no more data to read,
				// then we're at the end of file
				throw BytesParser.ParseError.endOfData
			}
			
			if readCount > 0 {
				// Add the read data to the result
				result += Data(bytes: self.readBuffer, count: readCount)
				
				// Move the read header forward
				read += readCount
			}
		}
		
		return result
	}
	
	func nextUpToIncluding(_ byte: UInt8) throws -> Data {
		guard self.inputStream.hasBytesAvailable else { throw BytesParser.ParseError.endOfData }
		
		// We are reading 1 byte at a time (not overly optimal!)
		self.reconfigureIfNeeded(1)
		
		var result = Data()
		
		while true {
			let readCount = self.inputStream.read(self.readBuffer, maxLength: 1)
			if readCount == 0 {
				return result
			}
			result += Data(bytes: self.readBuffer, count: 1)
			if self.readBuffer[0] == byte {
				return result
			}
		}
	}
}
