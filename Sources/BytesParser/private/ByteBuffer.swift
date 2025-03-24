//
//  Copyright © 2025 Darren Ford. All rights reserved.
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

/// A wrapper around a pointer to an array of bytes
internal class ByteBuffer {
	init() {
		self.buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: ByteBuffer.DefaultSize)
	}

	deinit {
		self.buffer.deallocate()
	}

	func requireSize(_ count: Int) {
		if count > self.readBufferSize {
			self.buffer.deallocate()
			self.buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
		}
	}

	// The raw byte buffer
	internal private(set) var buffer: UnsafeMutablePointer<UInt8>

	// Private
	private static let DefaultSize = 1024
	private var readBufferSize = ByteBuffer.DefaultSize
}
