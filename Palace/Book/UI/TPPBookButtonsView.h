#import "TPPBookButtonsState.h"

@class TPPBook;
@class TPPBookButtonsView;
@class TPPBookDetailDownloadFailedView;

@protocol TPPBookButtonsDelegate

- (void)didSelectReturnForBook:(TPPBook *_Null_unspecified)book completion:(void (^ _Nullable)(void))completion;
- (void)didSelectDownloadForBook:(TPPBook *_Null_unspecified)book;
- (void)didSelectReadForBook:(TPPBook *_Null_unspecified)book;
- (void)didSelectPlaySample:(TPPBook *_Null_unspecified)book;

@end

@protocol TPPBookButtonsSampleDelegate

- (void)didSelectPlaySample:(TPPBook *_Null_unspecified)book;

@end

@protocol TPPBookDownloadCancellationDelegate

- (void)didSelectCancelForBookDetailDownloadingView:(TPPBookButtonsView *_Null_unspecified)view;
- (void)didSelectCancelForBookDetailDownloadFailedView:(TPPBookButtonsView *_Null_unspecified)failedView;

@end

/// This view class handles the buttons for managing a book all in one place,
/// because that's always identical and used in book cells and book detail views.
@interface TPPBookButtonsView : UIView

@property (nonatomic, weak) TPPBook *_Null_unspecified book;
@property (nonatomic) TPPBookButtonsState state;
@property (nonatomic, weak) id<TPPBookButtonsDelegate> _Null_unspecified delegate;
@property (nonatomic, weak) id<TPPBookDownloadCancellationDelegate> _Null_unspecified downloadingDelegate;
@property (nonatomic, weak) id<TPPBookButtonsSampleDelegate> _Null_unspecified sampleDelegate;
@property (nonatomic) BOOL showReturnButtonIfApplicable;

- (instancetype _Null_unspecified )initWithSamplesEnabled:(BOOL)samplesEnabled;
- (void)configureForBookDetailsContext;

@end
