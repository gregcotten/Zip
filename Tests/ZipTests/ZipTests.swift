//
//  ZipTests.swift
//  ZipTests
//
//  Created by Roy Marmelstein on 13/12/2015.
//  Copyright © 2015 Roy Marmelstein. All rights reserved.
//

import XCTest
@testable import Zip

class ZipTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    private func url(forResource resource: String, withExtension ext: String? = nil) -> URL? {
        Bundle.module.url(forResource: resource, withExtension: ext)
    }

    private func autoRemovingSandbox() throws -> URL {
        let sandbox = FileManager.default.temporaryDirectory.appendingPathComponent("ZipTests_" + UUID().uuidString, isDirectory: true)
        // We can always create it. UUID should be unique.
        do {
            try FileManager.default.createDirectory(at: sandbox, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("could not create file at \(sandbox.path): \(error)")
            throw error
        }
        // Schedule the teardown block _after_ creating the directory has been created (so that if it fails, no teardown block is registered).
        addTeardownBlock {
            do {
                try FileManager.default.removeItem(at: sandbox)
            } catch {
                print("Could not remove test sandbox at '\(sandbox.path)': \(error)")
            }
        }
        return sandbox
    }
    
    func testUnzip() throws {
        let filePath = url(forResource: "bb8", withExtension: "zip")!
        let destinationPath = try autoRemovingSandbox()

        try Zip.unzipFile(filePath, destination: destinationPath, overwrite: true, password: "password", progress: nil)

        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationPath.path))
    }
    
    #if !os(Windows)
    func testImplicitProgressUnzip() throws {
        let progress = Progress(totalUnitCount: 1)

        let filePath = url(forResource: "bb8", withExtension: "zip")!
        let destinationPath = try autoRemovingSandbox()

        progress.becomeCurrent(withPendingUnitCount: 1)
        try Zip.unzipFile(filePath, destination: destinationPath, overwrite: true, password: "password", progress: nil)
        progress.resignCurrent()

        XCTAssertTrue(progress.totalUnitCount == progress.completedUnitCount)
    }
    
    func testImplicitProgressZip() throws {
        let progress = Progress(totalUnitCount: 1)

        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        let sandboxFolder = try autoRemovingSandbox()
        let zipFilePath = sandboxFolder.appendingPathComponent("archive.zip")

        progress.becomeCurrent(withPendingUnitCount: 1)
        try Zip.zipFiles(paths: [imageURL1, imageURL2], zipFilePath: zipFilePath, password: nil, progress: nil)
        progress.resignCurrent()

        XCTAssertTrue(progress.totalUnitCount == progress.completedUnitCount)
    }
    #endif

    func testZip() throws {
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        let sandboxFolder = try autoRemovingSandbox()
        let zipFilePath = sandboxFolder.appendingPathComponent("archive.zip")
        try Zip.zipFiles(paths: [imageURL1, imageURL2], zipFilePath: zipFilePath, password: nil, progress: nil)
        XCTAssertTrue(FileManager.default.fileExists(atPath: zipFilePath.path))
    }
    
    func testZipUnzipPassword() throws {
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        let zipFilePath = try autoRemovingSandbox().appendingPathComponent("archive.zip")
        try Zip.zipFiles(paths: [imageURL1, imageURL2], zipFilePath: zipFilePath, password: "password", progress: nil)
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: zipFilePath.path))
        let directoryName = zipFilePath.lastPathComponent.replacingOccurrences(of: ".\(zipFilePath.pathExtension)", with: "")
        let destinationUrl = try autoRemovingSandbox().appendingPathComponent(directoryName, isDirectory: true)
        try Zip.unzipFile(zipFilePath, destination: destinationUrl, overwrite: true, password: "password", progress: nil)
        XCTAssertTrue(fileManager.fileExists(atPath: destinationUrl.path))
    }

    func testFileExtensionIsNotInvalidForValidUrl() {
        let fileUrl = URL(string: "file.cbz")
        let result = Zip.fileExtensionIsInvalid(fileUrl?.pathExtension)
        XCTAssertFalse(result)
    }
    
    func testFileExtensionIsInvalidForInvalidUrl() {
        let fileUrl = URL(string: "file.xyz")
        let result = Zip.fileExtensionIsInvalid(fileUrl?.pathExtension)
        XCTAssertTrue(result)
    }
    
    func testAddedCustomFileExtensionIsValid() {
        let fileExtension = "cstm"
        Zip.addCustomFileExtension(fileExtension)
        let result = Zip.isValidFileExtension(fileExtension)
        XCTAssertTrue(result)
        Zip.removeCustomFileExtension(fileExtension)
    }
    
    func testRemovedCustomFileExtensionIsInvalid() {
        let fileExtension = "cstm"
        Zip.addCustomFileExtension(fileExtension)
        Zip.removeCustomFileExtension(fileExtension)
        let result = Zip.isValidFileExtension(fileExtension)
        XCTAssertFalse(result)
    }
    
    func testDefaultFileExtensionsIsValid() {
        XCTAssertTrue(Zip.isValidFileExtension("zip"))
        XCTAssertTrue(Zip.isValidFileExtension("cbz"))
    }
    
    func testDefaultFileExtensionsIsNotRemoved() {
        Zip.removeCustomFileExtension("zip")
        Zip.removeCustomFileExtension("cbz")
        XCTAssertTrue(Zip.isValidFileExtension("zip"))
        XCTAssertTrue(Zip.isValidFileExtension("cbz"))
    }
}
