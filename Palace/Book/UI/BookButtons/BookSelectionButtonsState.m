//
//  BookSelectionButtonsState.m
//

#import "BookSelectionButtonsState.h"
#import "Palace-Swift.h"

BookSelectionButtonsState
BookSelectionButtonsViewStateWithBook(TPPBook* book)
{

  __block BookSelectionButtonsState bookSelectionButtonsState = BookSelectionButtonsStateCanSelect;

  BookSelectionState bookSelectionState = [[TPPBookRegistry shared] selectionStateFor:book.identifier];

  switch(bookSelectionState) {
    case BookSelectionStateSelected:
      bookSelectionButtonsState = BookSelectionButtonsStateCanUnselect;
      break;
    case BookSelectionStateUnselected:
      bookSelectionButtonsState = BookSelectionButtonsStateCanSelect;
      break;
    case BookSelectionStateSelectionUnregistered:
      bookSelectionButtonsState = BookSelectionButtonsStateCanSelect;
      break;
  }

  return bookSelectionButtonsState;
}
