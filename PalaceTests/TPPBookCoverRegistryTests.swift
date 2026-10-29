//
//  TPPBookCoverRegistryTests.swift
//  PalaceTests
//
//  Tests for book cover fallback behavior.
//

import XCTest
@testable import Palace

final class TPPBookCoverRegistryTests: XCTestCase {
    func testThumbnailImageForBookWithoutThumbnailUsesPlaceholder() {
        let book = TPPBook(
            acquisitions: [],
            authors: nil,
            bookAccessibility: nil,
            categoryStrings: [],
            distributor: nil,
            identifier: UUID().uuidString,
            imageURL: nil,
            imageThumbnailURL: nil,
            published: nil,
            publisher: nil,
            subtitle: nil,
            summary: nil,
            title: "Book without a cover",
            updated: Date(),
            annotationsURL: nil,
            analyticsURL: nil,
            alternateURL: nil,
            relatedWorksURL: nil,
            previewLink: nil,
            seriesURL: nil,
            revokeURL: nil,
            reportURL: nil,
            timeTrackingURL: nil,
            contributors: nil,
            bookDuration: nil,
            language: nil
        )
        let expectedPlaceholder = ImageProviders.MyBooksView.bookPlaceholder
        let expectation = expectation(description: "Placeholder image is returned")

        TPPBookCoverRegistry().thumbnailImageForBook(book) { image in
            XCTAssertEqual(image?.pngData(), expectedPlaceholder?.pngData())
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
