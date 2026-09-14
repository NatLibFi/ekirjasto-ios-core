//
//  SearchViewModel.swift
//  Palace
//
//  Created by Maurice Carrier on 10/11/23.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation
import ReadiumShared
import ReadiumNavigator

protocol EPUBSearchDelegate: AnyObject {
  func didSelect(location: Locator)
}

final class EPUBSearchViewModel: ObservableObject {
  enum State {
    case empty
    case searching
    case idle
    case end
    case failure(Error)

    var isLoadingState: Bool {
      switch self {
        case .searching:
         return true
      default:
        return false
      }
    }
  }

  @Published private(set) var state: State = .empty
  @Published private(set) var results: [Locator] = []

  private var publication: Publication
  private var searchIterator: SearchIterator?
  private var searchTask: Task<Void, Never>?
  weak var delegate: EPUBSearchDelegate?

  init(publication: Publication) {
    self.publication = publication
  }

  func search(with query: String) {
    cancelSearch()
    state = .searching

    searchTask = Task {
      let result = await publication.search(query: query)
      switch result {
      case .success(let iterator):
        self.searchIterator = iterator
        await fetchNextBatch()
      case .failure(let error):
        await MainActor.run {
          self.state = .failure(error)
        }
      }
    }
  }

  func fetchNextBatch() async {
    guard let iterator = searchIterator else { return }

    let result = await iterator.next()
    switch result {
    case .success(let collection):
      if let collection = collection {
        await MainActor.run {
          for locator in collection.locators {
            if !self.results.contains(where: { $0.href == locator.href }) {
              self.results.append(locator)
            }
          }
          self.state = .idle
        }
      } else {
        await MainActor.run {
          self.state = .end
        }
      }
    case .failure(let error):
      await MainActor.run {
        self.state = .failure(error)
      }
    }
  }

  func cancelSearch() {
    searchTask?.cancel()
    searchTask = nil
    searchIterator = nil
    results.removeAll()
    state = .empty
  }

  func userSelected(_ locator: Locator) {
    delegate?.didSelect(location: locator)
  }
}
