//
//  BookSelectionButtonsState.h
//

@import Foundation;

typedef NS_ENUM(NSInteger, BookSelectionButtonsState) {
  BookSelectionButtonsStateCanSelect,
  BookSelectionButtonsStateCanUnselect
};

@class TPPBook;

BookSelectionButtonsState
BookSelectionButtonsViewStateWithBook(TPPBook* book);
