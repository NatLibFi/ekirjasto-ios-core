//
//  BookSelectionButtonsView.h
//

#import "BookSelectionButtonsState.h"
#import "TPPBookButtonsView.h"
#import <UIKit/UIKit.h>

@class TPPBook;

@protocol BookSelectionButtonsDelegate;

@interface BookSelectionButtonsView : UIView

@property (nonatomic, weak) TPPBook *book;
@property (nonatomic, weak) id<TPPBookButtonsDelegate> delegate;
@property (nonatomic) BookSelectionButtonsState selectionState;

- (instancetype _Nonnull )initWithBook:(TPPBook *_Nonnull)book delegate:(id<TPPBookButtonsDelegate>_Nonnull)delegate;

@end

@protocol BookSelectionButtonsDelegate <NSObject>

- (void)didSelectSelectForBook:(TPPBook *_Nonnull)book completion:(void (^ _Nullable)(void))completion;
- (void)didSelectUnselectForBook:(TPPBook * _Nonnull)book completion:(void (^ _Nullable)(void))completion;

@end
