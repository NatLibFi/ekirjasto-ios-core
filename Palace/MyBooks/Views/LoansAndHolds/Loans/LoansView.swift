//
//  LoansView.swift
//

import Combine
import SwiftUI

struct LoansView: View {

  @ObservedObject var loansViewModel: LoansViewModel
  @State var showDetailForBook: TPPBook?
  let backgroundColor: Color = Color(TPPConfiguration.backgroundColor())

  var body: some View {

    NavigationLink(
      destination: searchView,
      isActive: $loansViewModel.showSearchSheet
    ) {}

    //TODO: This is a workaround for an apparent bug in iOS14 that prevents us from wrapping
    // the body in a NavigationView. Once iOS14 support is dropped, this can be removed/replaced
    // with a NavigationView
    EmptyView()
      .alert(item: $loansViewModel.alert) { alert in
        Alert(
          title: Text(alert.title),
          message: Text(alert.message),
          dismissButton: .cancel()
        )
      }

    ZStack {
      VStack(alignment: .leading) {
        facetView
        content
      }
      .background(backgroundColor)
      .navigationBarItems(trailing: searchButton)
      loadingView
    }
    .background(backgroundColor)

  }

  @ViewBuilder private var facetView: some View {
    FacetView(
      facetViewModel: loansViewModel.facetViewModel
    )
  }

  @ViewBuilder private var loadingView: some View {
    if loansViewModel.isLoading {
      ProgressView()
        .scaleEffect(x: 2, y: 2, anchor: .center)
        .horizontallyCentered()
    }
  }

  @ViewBuilder private var content: some View {

    GeometryReader { geometry in

      if loansViewModel.userIsLoggedIn {
        if loansViewModel.userHasBooksOnLoan {
          // user is logged in and has books on loan
          // show list of lent books
          BookListView
            .refreshable {
              loansViewModel.reloadData()
            }
        } else {
          VStack {
            // user is logged in and has no books on loan
            // show instructions how to borrow books
            EmptyHoldsView
          }
          .frame(minHeight: geometry.size.height)
          .refreshable {
            loansViewModel.reloadData()
          }
        }
      } else {
        VStack {
          // user has not logged in
          // remind user to log in to see the books on loan
          LogInInstructionsView
        }
        .frame(minHeight: geometry.size.height)
        .refreshable {
          loansViewModel.reloadData()
        }

      }
    }
  }

  @ViewBuilder private var BookListView: some View {

    AdaptableGridLayout {

      ForEach(0..<loansViewModel.books.count, id: \.self) { i in
        ZStack(alignment: .leading) {
          bookCell(for: loansViewModel.books[i])
        }
        .opacity(loansViewModel.isLoading ? 0.5 : 1.0)
        .disabled(loansViewModel.isLoading)
      }

    }
    .padding(.bottom, 20)
    .onAppear { loansViewModel.loadData() }

  }

  @ViewBuilder private var EmptyHoldsView: some View {
    Text(Strings.MyBooksView.loansEmptyViewMessage)
      .multilineTextAlignment(.center)
      .foregroundColor(.gray)
      .horizontallyCentered()
      .verticallyCentered()
  }

  @ViewBuilder private var LogInInstructionsView: some View {
    Text(Strings.MyBooksView.loansNotLoggedInViewMessage)
      .multilineTextAlignment(.center)
      .foregroundColor(.gray)
      .horizontallyCentered()
      .verticallyCentered()
  }

  private func bookCell(for book: TPPBook) -> some View {

    let bookCellModel = BookCellModel(book: book)

    bookCellModel
      .statePublisher.assign(to: \.isLoading, on: self.loansViewModel)
      .store(in: &self.loansViewModel.observers)

    if self.loansViewModel.isPad {

      return Button {
        showDetailForBook = book
      } label: {
        BookCell(model: bookCellModel)
      }
      .sheet(item: $showDetailForBook) { item in
        UIViewControllerWrapper(
          TPPBookDetailViewController(book: item), updater: { _ in }
        ).anyView()
      }
      .anyView()

    } else {

      return NavigationLink(
        destination: UIViewControllerWrapper(
          TPPBookDetailViewController(book: book), updater: { _ in })
      ) {
        BookCell(model: bookCellModel)
          .padding(.leading, -25)
          .padding(.vertical, 15)
          .border(width: 1, edges: [.bottom ], color: Color("ColorEkirjastoLightestGreen"))
          .padding(.top, -25)
          .padding(.bottom, 10)
          .padding(.leading, 20)
          .padding(.trailing, 20)
      }
      .anyView()

    }

  }

  @ViewBuilder private var searchButton: some View {

    Button {
      loansViewModel.showSearchSheet.toggle()
    } label: {
      ImageProviders.MyBooksView.search
    }

  }

  private var searchView: some View {

    let searchDescription = TPPOpenSearchDescription(
      title: Strings.MyBooksView.searchBooks,
      books: loansViewModel.books
    )

    let navController = UINavigationController(
      rootViewController: TPPCatalogSearchViewController(
        openSearchDescription: searchDescription
      )
    )

    return UIViewControllerWrapper(navController, updater: { _ in })
  }

}
