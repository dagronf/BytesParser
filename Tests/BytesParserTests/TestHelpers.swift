import Foundation
import XCTest

@testable import BytesParser

enum TestErrors: Error {
	case cannotFindResource
}

func resourceURL(forResource name: String, withExtension extn: String) throws -> URL {
	guard let url = Bundle.module.url(forResource: name, withExtension: extn) else {
		throw TestErrors.cannotFindResource
	}
	return url
}

func resourceData(forResource name: String, withExtension extn: String) throws -> Data {
	let url = try resourceURL(forResource: name, withExtension: extn)
	return try Data(contentsOf: url)
}

func resourceInputStream(forResource name: String, withExtension extn: String) throws -> InputStream {
	let url = try resourceURL(forResource: name, withExtension: extn)
	return try XCTUnwrap(InputStream(fileAtPath: url.path))
}

/// Call a block providing a valid temporary URL
func withTemporaryFile<ReturnType>(_ fileExtension: String? = nil, _ block: (URL) throws -> ReturnType) throws -> ReturnType {
	// unique name
	var tempFilename = ProcessInfo.processInfo.globallyUniqueString

	// extension
	if let fileExtension = fileExtension {
		tempFilename += "." + fileExtension
	}

	// create the temporary file url
	let tempURL = try FileManager.default.url(
		for: .itemReplacementDirectory,
		in: .userDomainMask,
		appropriateFor: URL(fileURLWithPath: NSTemporaryDirectory()),
		create: true
	)
	.appendingPathComponent(tempFilename)

	Swift.print("Using temporary file: \(tempURL)")

	return try block(tempURL)
}

func withDataWrittenToTemporaryFile<T>(
	_ data: Data,
	fileExtension: String? = nil,
	deletesWhenComplete: Bool = true,
	_ block: (URL) throws -> T?
) throws -> T? {
	return try withTemporaryFile(fileExtension, { tempURL in
		#if os(Linux)
		try data.write(to: tempURL)
		#else
		try data.write(to: tempURL, options: .atomicWrite)
		#endif
		defer { if deletesWhenComplete { try? FileManager.default.removeItem(at: tempURL) } }
		return try block(tempURL)
	})
}

func withDataWrittenToTemporaryInputStream<T>(
	_ data: Data,
	fileExtension: String? = nil,
	deletesWhenComplete: Bool = true,
	_ block: (InputStream) throws -> T?
) throws -> T? {
	try withDataWrittenToTemporaryFile(data, fileExtension: fileExtension, deletesWhenComplete: deletesWhenComplete, { tempURL in
		let inputStream = InputStream(url: tempURL)!
		inputStream.open()
		defer { inputStream.close() }
		return try block(inputStream)
	})
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

extension Data {
	/// Super-simple hex string for this data
	var hexDescription: String {
		return reduce("") { $0 + String(format: "%02x ", $1) }
	}
}
