//
//  AudiobookmarkTests.swift
//  PalaceTests
//
//  Created by Maurice Carrier on 4/26/23.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import XCTest
import PalaceAudiobookToolkit
@testable import Palace

private class FakeDownloadTask: NSObject, DownloadTask {
    func fetch() {}
    func delete() {}
    var downloadProgress: Float = 0
    var key: String = ""
    weak var delegate: DownloadTaskDelegate?
}

private class FakeSpineElement: NSObject, SpineElement {
    let chapter: ChapterLocation
    var key: String { chapter.audiobookID }
    var downloadTask: DownloadTask { FakeDownloadTask() }

    init(index: UInt, title: String, duration: TimeInterval, audiobookID: String) {
        self.chapter = ChapterLocation(
            number: index,
            part: 0,
            duration: duration,
            startOffset: 0,
            playheadOffset: 0,
            title: title,
            audiobookID: audiobookID
        )
    }
}

final class AudiobookmarkTests: XCTestCase {
    private let audiobookID = "urn:uuid:5cb4bb84-a771-4d68-b14b-90b6ad58b15d"

    private func makeMapper() -> AudiobookTrackMapper {
        let manifestJSON: [String: Any] = [
            "readingOrder": [
                ["href": "track1.mp3", "duration": 100],
                ["href": "track2.mp3", "duration": 200],
            ]
        ]
        let spine: [SpineElement] = [
            FakeSpineElement(index: 0, title: "Track 1", duration: 100, audiobookID: audiobookID),
            FakeSpineElement(index: 1, title: "Track 2", duration: 200, audiobookID: audiobookID),
        ]
        return AudiobookTrackMapper(spine: spine, manifestJSON: manifestJSON)!
    }

    func testDecodeV2Bookmark() throws {
        // Wire format written by the Android client.
        let v2JSON = """
        {"@type":"LocatorAudioBookTime","@version":2,"readingOrderItem":"track2.mp3","readingOrderItemOffsetMilliseconds":123000,"audiobookID":"\(audiobookID)","duration":200000}
        """

        let bookmark = try JSONDecoder().decode(AudioBookmark.self, from: v2JSON.data(using: .utf8)!)

        XCTAssertEqual(bookmark.version, 2)
        XCTAssertEqual(bookmark.readingOrderItem, "track2.mp3")
        XCTAssertEqual(bookmark.readingOrderItemOffsetMilliseconds, 123000)
        XCTAssertEqual(bookmark.audiobookID, audiobookID)
        XCTAssertEqual(bookmark.duration, 200000)
    }

    func testDecodeRejectsNonAudioBookTimeLocator() {
        let epubLocatorJSON = """
        {"@type":"LocatorHrefProgression","href":"/chapter1.html","progressWithinChapter":0.5}
        """

        XCTAssertThrowsError(try JSONDecoder().decode(AudioBookmark.self, from: epubLocatorJSON.data(using: .utf8)!))
    }

    func testMapperResolvesV2BookmarkToChapterLocation() throws {
        let v2JSON = """
        {"@type":"LocatorAudioBookTime","@version":2,"readingOrderItem":"track2.mp3","readingOrderItemOffsetMilliseconds":123000,"audiobookID":"\(audiobookID)","duration":200000}
        """
        let bookmark = try JSONDecoder().decode(AudioBookmark.self, from: v2JSON.data(using: .utf8)!)

        let location = try XCTUnwrap(makeMapper().chapterLocation(from: bookmark))

        XCTAssertEqual(location.number, 1)
        XCTAssertEqual(location.part, 0)
        XCTAssertEqual(location.playheadOffset, 123.0)
        XCTAssertEqual(location.title, "Track 2")
        XCTAssertEqual(location.audiobookID, audiobookID)
    }

    func testMapperResolvesUnknownReadingOrderItemToNil() throws {
        let v2JSON = """
        {"@type":"LocatorAudioBookTime","@version":2,"readingOrderItem":"unknown.mp3","readingOrderItemOffsetMilliseconds":0}
        """
        let bookmark = try JSONDecoder().decode(AudioBookmark.self, from: v2JSON.data(using: .utf8)!)

        XCTAssertNil(makeMapper().chapterLocation(from: bookmark))
    }

    func testMapperWritesV2SelectorValue() throws {
        let location = ChapterLocation(
            number: 1,
            part: 0,
            duration: 200,
            startOffset: 0,
            playheadOffset: 123,
            title: "Track 2",
            audiobookID: audiobookID
        )

        let selectorString = try XCTUnwrap(makeMapper().v2SelectorString(for: location))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: selectorString.data(using: .utf8)!) as? [String: Any])

        XCTAssertEqual(json["@type"] as? String, "LocatorAudioBookTime")
        XCTAssertEqual(json["@version"] as? Int, 2)
        XCTAssertEqual(json["readingOrderItem"] as? String, "track2.mp3")
        XCTAssertEqual(json["readingOrderItemOffsetMilliseconds"] as? Int, 123000)
        XCTAssertEqual(json["audiobookID"] as? String, audiobookID)
        XCTAssertEqual(json["duration"] as? Int, 200000)
    }

    func testMapperRoundTrip() throws {
        let mapper = makeMapper()
        let original = ChapterLocation(
            number: 0,
            part: 0,
            duration: 100,
            startOffset: 0,
            playheadOffset: 42.5,
            title: "Track 1",
            audiobookID: audiobookID
        )

        let selectorString = try XCTUnwrap(mapper.v2SelectorString(for: original))
        let bookmark = try JSONDecoder().decode(AudioBookmark.self, from: selectorString.data(using: .utf8)!)
        let restored = try XCTUnwrap(mapper.chapterLocation(from: bookmark))

        XCTAssertEqual(restored.number, original.number)
        XCTAssertEqual(restored.part, original.part)
        XCTAssertEqual(restored.playheadOffset, original.playheadOffset)
        XCTAssertEqual(restored.audiobookID, original.audiobookID)
    }
    func testDecodeEarlyBookmark() throws {
        let earlyBookmarkJSON = """
        {"time":2199000,"@type":"LocatorAudioBookTime","audiobookID":"urn:librarysimplified.org/terms/id/Overdrive ID/faf182e5-2f05-4729-b2cd-139d6bb0b19e","title":"Track 1","part":0,"duration":3659000,"chapter":0}
        """

        let decoder = JSONDecoder()
        let bookmark = try decoder.decode(AudioBookmark.self, from: earlyBookmarkJSON.data(using: .utf8)!)

        XCTAssertEqual(bookmark.time, 2199000)
        XCTAssertEqual(bookmark.type, "LocatorAudioBookTime")
        XCTAssertEqual(bookmark.audiobookID, "urn:librarysimplified.org/terms/id/Overdrive ID/faf182e5-2f05-4729-b2cd-139d6bb0b19e")
        XCTAssertEqual(bookmark.title, "Track 1")
        XCTAssertEqual(bookmark.part, 0)
        XCTAssertEqual(bookmark.duration, 3659000)
        XCTAssertEqual(bookmark.chapter, 0)
        XCTAssertNil(bookmark.startOffset)
    }

    func testDecodeNewerBookmark() throws {
        let newerBookmarkJSON = """
        {"time":2199000,"@type":"LocatorAudioBookTime","audiobookID":"urn:librarysimplified.org/terms/id/Overdrive ID/faf182e5-2f05-4729-b2cd-139d6bb0b19e","title":"Track 1","part":0,"duration":3659000,"chapter":0,"startOffset":0}
        """

        let decoder = JSONDecoder()
        let bookmark = try decoder.decode(AudioBookmark.self, from: newerBookmarkJSON.data(using: .utf8)!)

        XCTAssertEqual(bookmark.time, 2199000)
        XCTAssertEqual(bookmark.type, "LocatorAudioBookTime")
        XCTAssertEqual(bookmark.audiobookID, "urn:librarysimplified.org/terms/id/Overdrive ID/faf182e5-2f05-4729-b2cd-139d6bb0b19e")
        XCTAssertEqual(bookmark.title, "Track 1")
        XCTAssertEqual(bookmark.part, 0)
        XCTAssertEqual(bookmark.duration, 3659000)
        XCTAssertEqual(bookmark.chapter, 0)
        XCTAssertEqual(bookmark.startOffset, 0)
    }
}
