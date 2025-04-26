#import "TPPBookCell.h"
#import "TPPBookButtonsState.h"
#import "BookSelectionButtonsState.h"
#import "Palace-Swift.h"

@class TPPBookNormalCell;
@class TPPBook;

@protocol TPPBookButtonsDelegate;

@interface TPPBookNormalCell : TPPBookCell

@property (nonatomic) TPPBook *book;
@property (nonatomic) TPPBookButtonsState state;
@property (nonatomic) BookSelectionButtonsState selectionState;
@property (nonatomic, weak) id<TPPBookButtonsDelegate> delegate;
@property (nonatomic) UIImageView *cover;

@end
