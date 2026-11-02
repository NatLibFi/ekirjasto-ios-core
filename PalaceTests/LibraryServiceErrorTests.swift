import Foundation
import XCTest
@testable import Palace

final class LibraryServiceErrorTests: XCTestCase {

  func testInvalidBookProvidesLocalizedErrorDescription() {
    let error = LibraryServiceError.invalidBook

    XCTAssertEqual(
      error.errorDescription,
      Strings.Error.invalidBookError
    )
  }

  func testOpenFailedProvidesGenericLocalizedErrorDescriptionForUnknownError() {
    let underlyingError = NSError(
      domain: "LibraryServiceErrorTests",
      code: 1
    )
    let error = LibraryServiceError.openFailed(underlyingError)

    XCTAssertEqual(
      error.errorDescription,
      Strings.Error.openFailedError
    )
  }
}
