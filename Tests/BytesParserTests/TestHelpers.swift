//
//  File.swift
//  
//
//  Created by Darren Ford on 26/6/2023.
//

import Foundation
@testable import BytesParser

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
