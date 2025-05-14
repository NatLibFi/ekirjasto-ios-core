//
//  BookSelectionButtonsView.m
//

#import "BookSelectionButtonsView.h"
#import "Palace-Swift.h"
@import PureLayout;

@interface BookSelectionButtonsView ()

@property (nonatomic) UIButton *selectButton;
@property (nonatomic) UIButton *unselectButton;
@property (nonatomic) NSMutableArray *constraints;
@property (nonatomic) NSMutableArray *observers;
@property (nonatomic) NSMutableArray *visibleButtons;

@end

@implementation BookSelectionButtonsView

- (instancetype)initWithBook:(TPPBook *)book delegate:(id<TPPBookButtonsDelegate>)delegate {

  self = [super init];

  if (self) {
    _book = book;
    _delegate = delegate;

    self.constraints = [[NSMutableArray alloc] init];

    [self setupButtons];

    [self.observers addObject:[
      [NSNotificationCenter defaultCenter]
        addObserverForName:NSNotification.TPPBookProcessingDidChange
        object:nil
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *note) {
          if ([note.userInfo[TPPNotificationKeys.bookProcessingBookIDKey] isEqualToString:self.book.identifier]) {
            BOOL isProcessing = [note.userInfo[TPPNotificationKeys.bookProcessingValueKey] boolValue];
            [self updateProcessingState:isProcessing];
          }
        }
    ]];

    [self.observers addObject:[
      [NSNotificationCenter defaultCenter]
        addObserverForName:NSNotification.TPPReachabilityChanged
        object:nil
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification * _Nonnull note) {
          #pragma unused(note)
          [self updateButtons];
        }
    ]];

    [self updateButtons];
  }

  return self;
}

- (void)dealloc {

  for(id const observer in self.observers) {
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
  }

  [self.observers removeAllObjects];
}

- (void)setupButtons {
  self.selectButton = [[UIButton alloc] init];
  self.unselectButton = [[UIButton alloc] init];
  
  UIImage *selectBookImage = [ImageProvidersMyBooksViewObjcClass selectionIconPlus];
  UIImage *unselectBookImage = [ImageProvidersMyBooksViewObjcClass selectionIconCheck];
  
  [self.selectButton
   setImage:selectBookImage
   forState:UIControlStateNormal
  ];
  
  [self.unselectButton
   setImage:unselectBookImage
   forState:UIControlStateNormal
  ];
  
  [self.selectButton
   addTarget:self
   action:@selector(didSelectSelect)
   forControlEvents:UIControlEventTouchUpInside
  ];
  
  [self.unselectButton
   addTarget:self
   action:@selector(didSelectUnselect)
   forControlEvents:UIControlEventTouchUpInside
  ];
  
  self.selectButton.accessibilityLabel = NSLocalizedString(@"Add to favorites", nil);
  self.unselectButton.accessibilityLabel = NSLocalizedString(@"Remove from favorites", nil);
  
  [self addSubview:self.selectButton];
  [self addSubview:self.unselectButton];
}

- (void)didSelectSelect {
  [self updateProcessingState:YES];
  [self.delegate didSelectSelectForBook:self.book completion:nil];
}

- (void)didSelectUnselect {
  [self updateProcessingState:YES];
  [self.delegate didSelectUnselectForBook:self.book completion:nil];
}

- (void)updateButtons {

  [self.visibleButtons removeAllObjects];
  [self updateProcessingState:NO];
  NSMutableArray *visibleButtons = [NSMutableArray array];
  [UIView setAnimationsEnabled:NO];
  self.selectButton.hidden = YES;
  self.unselectButton.hidden = YES;

  switch (self.selectionState) {
    case BookSelectionButtonsStateCanSelect:
      TPPLOG(@"Book selection state is Unregistered or Unselected");
      self.selectButton.hidden = NO;
      [self.selectButton setTitle:NSLocalizedString(@"Select", nil) forState:UIControlStateNormal];
      [self.selectButton layoutIfNeeded];
      [visibleButtons addObject:self.selectButton];
      break;
    case BookSelectionButtonsStateCanUnselect:
      TPPLOG(@"Book selection state is Selected");
      self.unselectButton.hidden = NO;
      [self.unselectButton setTitle:NSLocalizedString(@"Unselect", nil) forState:UIControlStateNormal];
      [self.unselectButton layoutIfNeeded];
      [visibleButtons addObject:self.unselectButton];
      break;
  }

  [UIView setAnimationsEnabled:YES];
  self.visibleButtons = visibleButtons;
  [self updateButtonFrames];

}

- (void)updateProcessingState:(BOOL)isCurrentlyProcessing {

  for (UIButton *button in @[self.selectButton, self.unselectButton]) {
    button.enabled = !isCurrentlyProcessing;
  }

}

- (void)updateButtonFrames {
  [NSLayoutConstraint deactivateConstraints:self.constraints];

  if (self.visibleButtons.count == 0) {
    return;
  }

  [self.constraints removeAllObjects];

  for (UIButton *button in self.visibleButtons) {
    [self.constraints addObject:[button autoPinEdgeToSuperviewEdge:ALEdgeTop]];
    [self.constraints addObject:[button autoPinEdgeToSuperviewEdge:ALEdgeBottom]];
    [self.constraints addObject:[button autoPinEdgeToSuperviewEdge:ALEdgeLeading]];
    [self.constraints addObject:[button autoSetDimension:ALDimensionWidth toSize: 15.0 relation:NSLayoutRelationGreaterThanOrEqual ]];
    [self.constraints addObject:[button autoPinEdgeToSuperviewEdge:ALEdgeTrailing]];
  }

  //[NSLayoutConstraint activateConstraints:self.constraints];
  [self setNeedsLayout];
}

- (void)setBook:(TPPBook *)book {
  _book = book;
  [self updateButtons];
  BOOL isCurrentlyProcessing = [[TPPBookRegistry shared] processingForIdentifier:self.book.identifier];
  [self updateProcessingState:isCurrentlyProcessing];
}

- (void)setSelectionState:(BookSelectionButtonsState const)selectionState {
  _selectionState = selectionState;
  [self updateButtons];
  BOOL isCurrentlyProcessing = [[TPPBookRegistry shared] processingForIdentifier:self.book.identifier];
  [self updateProcessingState:isCurrentlyProcessing];
}

@end
