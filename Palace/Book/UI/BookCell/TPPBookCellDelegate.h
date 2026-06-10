@import PalaceAudiobookToolkit;

#import "TPPBookDownloadFailedCell.h"
#import "TPPBookDownloadingCell.h"
#import "TPPBookButtonsView.h"

@class AudiobookBookmarkBusinessLogic;

/* This class implements a shared delegate that performs all of its duties via the shared registry,
shared cover registry, shared download center, et cetera. */
@interface TPPBookCellDelegate : NSObject
  <TPPBookButtonsDelegate, TPPBookDownloadFailedCellDelegate, TPPBookDownloadingCellDelegate, AudiobookPlaybackPositionDelegate>

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (instancetype)sharedDelegate;
@property (nonatomic) TPPBook *book;
@property (nonatomic) bool isSyncing;
@property (nonatomic, strong) AudiobookBookmarkBusinessLogic *audiobookBookmarkBusinessLogic;

@end
