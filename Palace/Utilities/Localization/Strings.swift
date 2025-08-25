//
//  DisplayStrings.swift
//  Palace
//
//  Created by Maurice Carrier on 12/4/21.
//  Copyright © 2021 The Palace Project. All rights reserved.
//

import Foundation

struct Strings {

  struct AgeCheck {
    static let title = NSLocalizedString("Age Verification", comment: "Title for Age Verification")
    static let titleLabel = NSLocalizedString("Please enter your birth year", comment: "Caption for asking user to enter their birth year")
    static let done = NSLocalizedString("Done", comment: "Button title for hiding picker view")
    static let placeholderString = NSLocalizedString("Select Year", comment: "Placeholder for birth year textfield")
    static let rightBarButtonItem = NSLocalizedString("Next", comment: "Button title for completing age verification")
  }
  
  struct Announcments {
    static let alertTitle = NSLocalizedString("Announcement", comment: "")
    static let ok = NSLocalizedString("Announcement", comment: "")
  }

  struct Error {
    static let loginFailedErrorTitle = NSLocalizedString("Login Failed", comment: "")
    static let loadFailedError = NSLocalizedString("The page could not load due to a conection error.", comment: "")
    static let invalidCredentialsErrorTitle = NSLocalizedString("Invalid Credentials", comment: "")
    static let invalidCredentialsErrorMessage = NSLocalizedString("Please check your username and password and try again.", comment: "")
    static let unknownRequestError = NSLocalizedString("An unknown error occurred. Please check your connection or try again later.", comment: "A generic error message for when a network request fails")
    static let connectionFailed = NSLocalizedString("Connection Failed", comment: "Title for alert that explains that the page could not download the information")
    static let syncSettingChangeErrorTitle = NSLocalizedString("Error Changing Sync Setting", comment: "")
    static let syncSettingsChangeErrorBody = NSLocalizedString("There was a problem contacting the server.\nPlease make sure you are connected to the internet, or try again later.", comment: "")
    static let invalidBookError = NSLocalizedString("The book you were trying to open is invalid.", comment: "Error message used when trying to import a publication that is not valid")
    static let openFailedError = NSLocalizedString("An error was encountered while trying to open this book.", comment: "Error message used when a low-level error occured while opening a publication")
    static let formatNotSupportedError = NSLocalizedString("The book you were trying to read is in an unsupported format.", comment: "Error message when trying to read a publication with a unsupported format")
    static let epubNotValidError = NSLocalizedString("The book you were trying to read is corrupted. Please try downloading it again.", comment: "Error message when trying to read an EPUB that is invalid")
    static let pageLoadFailedError = NSLocalizedString("The page could not load due to a connection error.", comment: "")
    static let serverConnectionErrorDescription = NSLocalizedString("Unable to contact the server because the URL for signing in is missing.", comment: "Error message for when the library profile url is missing from the authentication document the server provided.")
    static let serverConnectionErrorSuggestion = NSLocalizedString("Try force-quitting the app and repeat the sign-in process.", comment: "Recovery instructions for when the URL to sign in is missing")
    static let cardCreationError = NSLocalizedString("We're sorry. Currently we do not support signups for new patrons via the app.", comment: "Message describing the fact that new patron sign up is not supported by the current selected library")
    static let signInErrorTitle = NSLocalizedString("Sign In Error", comment: "Title for sign in error alert")
    static let signInErrorDescription = NSLocalizedString("The DRM Library is taking longer than expected. Please wait and try again later.\n\nIf the problem persists, try to sign out and back in again from the Library Settings menu.", comment: "Message for sign-in error alert caused by failed DRM authorization")
    static let loginErrorTitle = NSLocalizedString("Login Failed", comment: "Title for login error alert")
    static let loginErrorDescription = NSLocalizedString("An error occurred during the authentication process", comment: "Generic error message while handling sign-in redirection during authentication")
    static let userDeniedLocationAccess = NSLocalizedString("User denied location access. Go to system settings to enable location access for E-kirjasto.", comment: "Error message shown to user when location services are denied.")
    static let uknownLocationError = NSLocalizedString("Unkown error occurred. Please try again.", comment: "Error message shown to user when an unknown location error occurs.")
    static let locationFetchFailed = NSLocalizedString("Failed to get current location. Please try again.", comment: "Error message shown to user when CoreLocation does not return the current location.")
    static let bookFavoriteActionFailedNotificationAlertTitle = NSLocalizedString("Favorites update failed", comment: "The title in a notification alert informing the user that the there was an error in adding the book to favorites or removing the book from favorites")
    static let bookFavoriteActionFailedNotificationAlertMessage = NSLocalizedString("We were unable to save the changes to your Favorites list with book\n \"%@\".\n\n Please try again soon.", comment: "The message in a notification alert informing the user that the there was an error in adding the book to favorites or removing the book from favorites")
  }
  
  struct Generic {
    static let back = NSLocalizedString("Back", comment: "Text for Back button")
    static let more = NSLocalizedString("More...", comment: "")
    static let error = NSLocalizedString("Error", comment: "")
    static let ok = NSLocalizedString("OK", comment: "")
    static let cancel = NSLocalizedString("Cancel", comment: "Button that says to cancel and go back to the last screen.")
    static let reload = NSLocalizedString("Reload", comment: "Button that says to try again")
    static let delete = NSLocalizedString("Delete", comment: "")
    static let wait = NSLocalizedString("Wait", comment: "button title")
    static let reject = NSLocalizedString("Reject", comment: "Title for a Reject button")
    static let accept = NSLocalizedString("Accept", comment: "Title for a Accept button")
    static let signin = NSLocalizedString("Sign in", comment: "")
    static let close = NSLocalizedString("Close", comment: "Title for close button")
    static let search = NSLocalizedString("Search", comment: "Placeholder for Search Field")
    static let done = NSLocalizedString("Done", comment: "Title for Done button")
  }
  
  struct OETutorialChoiceViewController {
    static let loginMessage = NSLocalizedString("You need to login to access the collection.", comment: "")
    static let requestNewCodes = NSLocalizedString("Request New Codes", comment: "")
  }
  
  struct OETutorialEligibilityViewController {
    static let description = NSLocalizedString("Open eBooks provides free books to the children who need them the most.\n\nThe collection includes thousands of popular and award-winning titles as well as hundreds of public domain works.", comment: "Description of Open eBooks app displayed during 1st launch tutorial")
  }
  
  struct OETutorialWelcomeViewController {
    static let description = NSLocalizedString("Welcome to Open eBooks", comment: "Welcome text")
  }
  
  struct ProblemReportEmail {
    static let noAccountSetupTitle = NSLocalizedString("No email account is set for this device.", comment: "Alert title")
    static let reportSentTitle = NSLocalizedString("Thank You", comment: "Alert title")
    static let reportSentBody = NSLocalizedString("Your report will be reviewed as soon as possible.", comment: "Alert message")
  }
  
  struct ReturnPromptHelper {
    static let audiobookPromptTitle = NSLocalizedString("Your Audiobook Has Finished", comment: "")
    static let audiobookPromptMessage = NSLocalizedString("Would you like to return it?", comment: "")
    static let keepActionAlertTitle = NSLocalizedString("Keep", comment: "Button title for keeping an audiobook")
    static let returnActionTitle = NSLocalizedString("Return", comment: "Button title for keeping an audiobook")
  }
  
  struct Search {
    static let startSearchInstructionMessage = NSLocalizedString("You can search for a book or an author using the search bar above.\n\nIf you want to search through all books, ensure you are on the Browse Books tab with 'All' selected.", comment: "Instructions for users on how to perform a search. Visible in the view before the first search. Keep the newlines to preserve paragraph formatting in the UI.")
  }
  
  struct Settings {
    static let settings = NSLocalizedString("Settings", comment: "")
    static let settingsNavTitle = NSLocalizedString("Settings", comment: "Tab title for settings view")
    static let libraries = NSLocalizedString("Libraries", comment: "A title for a list of libraries the user may select or add to.")
    static let addLibrary = NSLocalizedString("Add Library", comment: "Title of button to add a new library")
    static let aboutApp = NSLocalizedString("About App", comment: "")
    static let feedback = NSLocalizedString("Feedback", comment: "")
    static let accessibility = NSLocalizedString("Accessibility Statement", comment: "")
    static let softwareLicenses = NSLocalizedString("Software Licenses", comment: "")
    static let privacyPolicy = NSLocalizedString("Privacy Policy", comment: "")
    static let eula = NSLocalizedString("User Agreement", comment: "")
    static let developerSettings = NSLocalizedString("Testing", comment: "Developer Settings")
    static let advancedSettings = NSLocalizedString("Advanced", comment: "")
    static let reportIssue = NSLocalizedString("Report an Issue", comment: "")
    static let syncBookmarks = NSLocalizedString("Sync Bookmarks", comment: "")
    static let loginPasskey = NSLocalizedString("Sign in with a passkey", comment: "")
    static let registerPasskey = NSLocalizedString("Register a passkey", comment: "")
    static let loginSuomiFi = NSLocalizedString("Sign in with suomi.fi", comment: "")
    static let continueWithoutSigning = NSLocalizedString("Continue without signing in", comment: "")
    static let signOut = NSLocalizedString("Sign out", comment: "")
    static let signOutConfirmationBookSync = NSLocalizedString("If you sign out without enabling Sync, your books and any saved bookmarks will be removed.", comment: "Message that is shown to user on logout when bookmark sync is available")
    static let signOutConfirmationNoBookSync = NSLocalizedString("If you sign out, your books and any saved bookmarks will be removed.", comment: "Message that is shown to user on logout when bookmark sync is not available")
    static let loginFooterUserAgreementText = NSLocalizedString("By signing in, you agree the End User License Agreement", comment: "")
    static let faq = NSLocalizedString("FAQ", comment: "")
    static let instructions = NSLocalizedString("User instructions", comment: "Title of a button that links to a HTML resource containing E-library user instructions")
    
    // dependents
    static let dependentsButton = NSLocalizedString("Invite a Dependent", comment: "")
    static let dependents = NSLocalizedString("Dependents", comment: "")
    static let getDependents = NSLocalizedString("Get Dependents", comment: "")
    static let select = NSLocalizedString("Select:", comment: "")
    static let selected = NSLocalizedString("Selected Dependent is: ", comment: "")
    static let enterEmail = NSLocalizedString("Enter email: ", comment: "")
    static let incorrectEmail = NSLocalizedString("Incorrect email", comment: "")
    static let sendButton = NSLocalizedString("Send invite", comment: "")
    static let selectADependent = NSLocalizedString("Select a dependent", comment: "")
    static let noDependents = NSLocalizedString("No dependents or children found.", comment: "")
    static let errorFromServer = NSLocalizedString("Something went wrong. Try signing out and back in, and try again.", comment: "")
    static let errorInCreation = NSLocalizedString("Could not finish request. Check your internet connection and try again.", comment: "")
    static let thanks = NSLocalizedString("Your dependent should receive the invitation soon.\n\nAdvise them to open the link in the email on their device and create a passkey. This will make logging in easier.", comment: "")
    static let guideText = NSLocalizedString("Fill in an email where the invitation should be sent. Make sure to type it correctly before sending.", comment: "")
    static let successButton = NSLocalizedString("Invite sent!", comment: "")
  }
  
  struct Preferences {
    static let preferencesButton = NSLocalizedString("Preferences", comment: "")
    static let langButton = NSLocalizedString("Language preferences", comment: "")
    static let fontSizeButton = NSLocalizedString("Text size", comment: "")
    static let togglePref = NSLocalizedString("Enable preferences", comment: "")
    static let en = NSLocalizedString("English", comment: "")
    static let fi = NSLocalizedString("Finnish", comment: "")
    static let sv = NSLocalizedString("Swedish", comment: "")
    static let hundred = NSLocalizedString("100%", comment: "")
    static let oneTwentyFive = NSLocalizedString("125%", comment: "")
    static let oneFifty = NSLocalizedString("150%", comment: "")
    static let oneSeventyFive = NSLocalizedString("175%", comment: "")
    static let twoHundred = NSLocalizedString("200%", comment: "")
    static let selectL = NSLocalizedString("Select language", comment: "")
    static let selectS = NSLocalizedString("Select text size", comment: "")
    static let selectEnable = NSLocalizedString("Enable preferences", comment: "")
    static let restartTitle = NSLocalizedString("Ekirjasto needs to restart", comment: "")
    static let restartText = NSLocalizedString("Preferred language saved. It will be available the next time you open the app.", comment: "")
  }
  
  struct TPPAccountListDataSource {
    static let addLibrary = NSLocalizedString("Add Library", comment: "Title that also informs the user that they should choose a library from the list.")
  }
  
  struct TPPBaseReaderViewController {
    static let tocAndBookmarks = NSLocalizedString("Table of contents and bookmarks", comment: "Table of contents and bookmarks")
    static let removeBookmark = NSLocalizedString("Remove Bookmark", comment: "Accessibility label for button to remove a bookmark")
    static let addBookmark = NSLocalizedString("Add Bookmark", comment: "Accessibility label for button to add a bookmark")
    static let previousChapter = NSLocalizedString("Previous Chapter", comment: "Accessibility label to go backward in the publication")
    static let nextChapter = NSLocalizedString("Next Chapter", comment: "Accessibility label to go forward in the publication")
    static let read = NSLocalizedString("Read", comment: "Accessibility label to read current chapter")
    static let pageOf = NSLocalizedString("Page %d of ", value: "Page %d of ", comment: "States the page count out of total pages, i.e. `Page 1 of 20`")
  }
  
  struct TPPBarCode {
    static let cameraAccessDisabledTitle = NSLocalizedString("Camera Access Disabled", comment: "An alert title stating the user has disallowed the app to access the user's location")
    static let cameraAccessDisabledBody = NSLocalizedString(
      ("You must enable camera access for this application " + "in order to sign up for a library card."), comment: "An alert message informing the user that camera access is required")
    static let openSettings = NSLocalizedString("Open Settings", comment: "A title for a button that will open the Settings app")
  }
  
  struct TPPBook {
    static let epubContentType = NSLocalizedString("ePub", comment: "ePub")
    static let pdfContentType = NSLocalizedString("PDF", comment: "PDF")
    static let audiobookContentType = NSLocalizedString("Audiobook", comment: "Audiobook")
    static let unsupportedContentType = NSLocalizedString("Unsupported format", comment: "Unsupported format")
    static let bookFormatForAudiobooks = NSLocalizedString("Audiobook", comment: "Common book format name for all audiobooks.")
    static let bookFormatForEBooks = NSLocalizedString("eBook", comment: "Common book format name for all eBooks.")
  }
  
  struct TPPPDFNavigation {
    static let resume = NSLocalizedString("Resume", comment: "A button to continue reading title.")
  }
  
  struct TPPDeveloperSettingsTableViewController {
    static let developerSettingsTitle = NSLocalizedString("Testing", comment: "Developer Settings")
  }
  
  struct TPPEPUBViewController {
    static let readerSettings = NSLocalizedString("Reader settings", comment: "Reader settings")
    static let emptySearchView = NSLocalizedString("There are no results", comment: "No search results available.")
    static let endOfResults = NSLocalizedString("Reached the end of the results.", comment: "Reached the end of the results.")
  }
  
  struct TPPLastReadPositionSynchronizer {
    static let syncReadingPositionAlertTitle = NSLocalizedString("Sync Reading Position", comment: "An alert title notifying the user the reading position has been synced")
    static let syncReadingPositionAlertBody = NSLocalizedString("Do you want to move to the page on which you left off?", comment: "An alert message asking the user to perform navigation to the synced reading position or not")
    static let stay = NSLocalizedString("Stay", comment: "Do not perform navigation")
    static let move = NSLocalizedString("Move", comment: "Perform navigation")
  }

  struct TPPLastListenedPositionSynchronizer {
    static let syncListeningPositionAlertTitle = NSLocalizedString("Sync Listening Position", comment: "An alert title notifying the user the listening position has been synced")
    static let syncListeningPositionAlertBody = NSLocalizedString("Do you want to move to the time on which you left off?", comment: "An alert message asking the user to perform navigation to the synced listening position or not")
  }

  struct TPPProblemDocument {
    static let authenticationExpiredTitle = NSLocalizedString("Authentication Expired", comment: "Title for an error related to expired credentials")
    static let authenticationExpiredBody = NSLocalizedString("Your authentication details have expired. Please sign in again.", comment: "Message to prompt user to re-authenticate")
    static let authenticationRequiredTitle = NSLocalizedString("Authentication Required", comment: "Title for an error related to credentials being required")
    static let authenticationRequireBody = NSLocalizedString("Your authentication details have expired. Please sign in again.", comment: "Message to prompt user to re-authenticate")
  }
  
  struct TPPReaderAppearance {
    static let blackOnWhiteText = NSLocalizedString("Open dyslexic font", comment: "OpenDyslexicFont")
    static let blackOnSepiaText = NSLocalizedString("Black on sepia text", comment: "BlackOnSepiaText")
    static let whiteOnBlackText = NSLocalizedString("White on black text", comment: "WhiteOnBlackText")
  }
  
  struct TPPReaderBookmarksBusinessLogic {
    static let noBookmarks = NSLocalizedString("There are no bookmarks for this book.", comment: "Text showing in bookmarks view when there are no bookmarks")
  }
  
  struct TPPReaderFont {
    static let original = NSLocalizedString("Default book font", comment: "OriginalFont")
    static let sans = NSLocalizedString("Sans font", comment: "SansFont")
    static let serif = NSLocalizedString("Serif font", comment: "SerifFont")
    static let dyslexic = NSLocalizedString("Open dyslexic font", comment: "OpenDyslexicFont")
  }
  
  struct TPPReaderPositionsVC {
    static let contents = NSLocalizedString("Contents", comment: "")
    static let bookmarks = NSLocalizedString("Bookmarks", comment: "")
  }
  
  struct TPPReaderTOCBusinessLogic {
    static let tocDisplayTitle = NSLocalizedString("Table of Contents",comment: "Title for Table of Contents in eReader")
  }
  
  struct TPPSettingsAdvancedViewController {
    static let advanced = NSLocalizedString("Advanced", comment: "")
    static let pleaseWait = NSLocalizedString("Please wait...", comment: "Generic Wait message")
    static let deleteServerData = NSLocalizedString("Delete Server Data", comment: "")
  }
  
  struct TPPSettingsSplitViewController {
    static let account = NSLocalizedString("Account", comment: "Title for account section")
    static let acknowledgements = NSLocalizedString("Acknowledgements", comment: "Title for acknowledgements section")
    static let eula = NSLocalizedString("User Agreement", comment: "Title for User Agreement section")
    static let privacyPolicy = NSLocalizedString("Privacy Policy", comment: "Title for Privacy Policy section")
  }
  
  struct TPPSigninBusinessLogic {
    static let ecard = NSLocalizedString("eCard", comment: "Title for web-based card creator page")
    static let ecardErrorMessage = NSLocalizedString("We're sorry. Our sign up system is currently down. Please try again later.", comment: "Message for error loading the web-based card creator")
    static let signout = NSLocalizedString("Sign out", comment: "Title for sign out action")
    static let annotationSyncMessage = NSLocalizedString("Your bookmarks and reading positions are in the process of being saved to the server. Would you like to stop that and continue logging out?", comment: "Warning message offering the user the choice of interrupting book registry syncing to log out immediately, or waiting until that finishes.")
    static let pendingDownloadMessage = NSLocalizedString("It looks like you may have a book download or return in progress. Would you like to stop that and continue logging out?", comment: "Warning message offering the user the choice of interrupting the download or return of a book to log out immediately, or waiting until that finishes.")
  }
  
  struct TPPWelcomeScreenViewController {
    static let findYourLibrary = NSLocalizedString("Find Your Library", comment: "Button that lets user know they can select a library they have a card for")
  }
  
  struct UserNotifications {
    static let checkoutTitle = NSLocalizedString("Check Out", comment: "")
    static let readyForDownloadTitle = NSLocalizedString("Ready for Download", comment: "The title for a notification banner informing the user that a reserved book is now available for download")
    static let readyForDownloadBody = NSLocalizedString("The title you reserved %@ is available.", comment: "The body text for a notification banner informing the user that a reserved book is now available for download")
    static let bookAddedToFavoritesNotificationBannerTitle = NSLocalizedString("Book added to Favorites", comment: "The title in a notification banner informing the user that the book is added to user's favorite books")
    static let bookAddedToFavoritesNotificationBannerMessage = NSLocalizedString("\"%@\" has been added to your Favorites.", comment: "The message in a notification banner informing the user that the book is added to user's favorite books")
    static let bookRemovedFromFavoritesNotificationBannerTitle = NSLocalizedString("Book removed from Favorites", comment: "The title in a notification banner informing the user that the book is removed from user's favorite books")
    static let bookRemovedFromFavoritesNotificationBannerMessage = NSLocalizedString("\"%@\" has been removed from your Favorites.", comment: "The message in a notification banner informing the user that the book is removed from user's favorite books")
  }
  
  struct TPPCatalogLaneCell {
    static let audioDescriptionEbook = NSLocalizedString("%@ by %@, ebook", comment: "BookCover cell accessibility label for ebook")
    static let audioDescriptionPdf = NSLocalizedString("%@ by %@, pdf", comment: "BookCover cell accessibility label for pdf")
    static let audioDescriptionAudiobook = NSLocalizedString("%@ by %@, audiobook", comment: "BookCover cell accessibility label for audiobook")
    static let audioDescriptionUnknownFormat = NSLocalizedString("%@ by %@", comment: "BookCover cell accessibility label for unknown format")
    static let audioDescriptionAction = NSLocalizedString("Show book's page", comment: "Describes what happens when the user taps the book cover")
  }
  
  struct TPPCatalogGroupedViewController {
    static let laneDescription = NSLocalizedString("%@ -lane", comment: "Audio description for lane title")
  }
  
  struct MyBooksView {
    static let loansAndHoldsNavTitle = NSLocalizedString("My Books", comment: "Tab title for loans and holds view")
    static let favoritesAndReadNavTitle = NSLocalizedString("Favorites", comment: "Tab title for favorites and read books view")
    static let loansNavTitle = NSLocalizedString("Loans", comment: "Tab title for loans view")
    static let holdsNavTitle = NSLocalizedString("Holds", comment: "Tab title for holds view")
    static let sortBy = NSLocalizedString("Sort By:", comment: "")
    static let searchBooks = NSLocalizedString("Search My Books", comment: "")
    static let emptyViewMessage = NSLocalizedString("Visit the Catalog to\nadd books to My Books.", comment: "")
    static let findYourLibrary = NSLocalizedString("Find Your Library", comment: "Button that lets user know they can select a library they have a card for")
    static let addLibrary = NSLocalizedString("Add Library", comment: "Title of button to add a new library")
    static let accountSyncingAlertTitle = NSLocalizedString("Please wait", comment: "")
    static let accountSyncingAlertMessage = NSLocalizedString("Please wait a moment before switching library accounts", comment: "")
    static let accessibilityShowAndReloadCatalogTab = NSLocalizedString("accessibilityShowAndReloadCatalogTab", comment: "")
    static let loansEmptyViewMessage = NSLocalizedString("Visit the Catalog to add books to My Books.\n Number of loans is limited to 5.\n Ensure good internet connection when downloading a book and make sure there is enough space on your device.", comment: "Text shown for logged in user when they have no books on loan")
    static let loansNotLoggedInViewMessage = NSLocalizedString("Sign in to see your books.", comment: "Text shown for non-logged in user in loans view")
    static let holdsEmptyViewMessage = NSLocalizedString("When you reserve a book from the catalog, it will show up here.\n Look here from time to time to see if your book is available to download.\n Number of reservations is limited to 5.", comment: "Text shown for logged in user when they have no books on hold")
    static let holdsNotLoggedInViewMessage = NSLocalizedString("Sign in to see your reservations.", comment: "Text shown for non-logged in user in holds view")
    static let favoritesEmptyViewMessage = NSLocalizedString("Visit the Catalog to add books to your Favorites.", comment: "Text shown for logged in user when they have no favorite books")
    static let favoritesNotLoggedInViewMessage = NSLocalizedString("Sign in to see your favorites.", comment: "Text shown for non-logged in user in favorites view")
  }
  
  struct FacetView {
    static let author = NSLocalizedString("Author", comment: "")
    static let title = NSLocalizedString("Title", comment: "")
    static let facetHint = NSLocalizedString("Change %@ choice", comment: "Read out hint when a facet is possibly selected")
  }
  
  struct BookCell {
    static let delete = NSLocalizedString("Delete", comment: "")
    static let `return` = NSLocalizedString("Return", comment: "")
    static let remove = NSLocalizedString("Remove", comment: "")
    static let deleteMessage = NSLocalizedString("Are you sure you want to delete \"%@\"?", comment: "Message shown in an alert to the user prior to deleting a title")
    static let returnMessage = NSLocalizedString("Are you sure you want to return \"%@\"?", comment: "Message shown in an alert to the user prior to returning a title")
    static let removeReservation = NSLocalizedString("Remove Reservation", comment: "")
    static let removeReservationMessage = NSLocalizedString("Are you sure you want to remove \"%@\" from your reservations? You will no longer be in line for this book.", comment: "Message shown in an alert to the user prior to returning a reserved title.")
    static let downloading = NSLocalizedString("Downloading", comment: "")
    static let downloadFailedMessage = NSLocalizedString("The download could not be completed.", comment: "")
    static let loanTimeNotAvailable = NSLocalizedString("Remaining loan time is not available.", comment: "Text informing the user that the remaining loan time could not be determined.")
    static let loanTimeRemaining = NSLocalizedString("You have this book on loan for %@.", comment: "Text that tells the user how much time they have left to read the book.")
    static let bookIsOnHoldForUser = NSLocalizedString("You have this book on hold.", comment: "Text that informs the user that the book is held for the user.")
    static let bookHoldPosition = NSLocalizedString("You are at position %@ in the queue for this book.", comment: "Text that informs the user of their position on the hold list.")
    static let bookIsAvailableToBorrow = NSLocalizedString("This book is available to borrow.", comment: "Text that informs that the book the user queued for is now ready to borrow.")
    static let addToFavoritesButtonLabel = NSLocalizedString("Add to favorites", comment: "Accessiblity label for a button that adds a book to the user's favorite books.")
    static let removeFromFavoritesButtonLabel = NSLocalizedString("Remove from favorites", comment: "Accessiblity label for a button that removes a book from the user's favorite books.")
    static let accessModeLabel = NSLocalizedString("Access mode", comment: "Name for the access mode field in the book details view")
    static let accessibilityFeaturesLabel = NSLocalizedString("Accessibility features", comment: "Name for the accesibility features field in the book details view")
    static let accessibilitySummaryLabel = NSLocalizedString("Accessibility summary", comment: "Name for the accesibility summary field in the book details view")
    static let accessibilityDataNotYetAvailable = NSLocalizedString("Not yet available", comment: "Placeholder text shown when accessibility data for a book is not yet available.")
  }
  
  struct TPPAccountRegistration {
    static let doesUserHaveLibraryCard = NSLocalizedString("Don't have a library card?", comment: "Title for registration. Asking the user if they already have a library card.")
    static let geolocationInstructions = NSLocalizedString("E-kirjasto requires a one-time location check in order to verify your library service area. Once you choose \"Create Card\", please select \"Allow Once\" in the popup so we can verify this information.", comment: "Body for registration. Explaining the reason for requesting the user's location and instructions for how to provide permission.")
    static let createCard = NSLocalizedString("Create Card", comment: "")
    static let deniedLocationAccessMessage = NSLocalizedString("E-kirjasto requires a one-time location check in order to verify your library service area. You have disabled location services for this app. To enable, please select the 'Open Settings' button below then continue with card creation.", comment: "Registration message shown to user when location access has been denied.")
    static let deniedLocationAccessMessageBoldText = NSLocalizedString("You have disabled location services for this app.", comment: "Registration message shown to user when location access has been denied.")
    static let openSettings = NSLocalizedString("Open Settings", comment: "")
  }
  
  struct MyDownloadCenter {
    static let borrowFailed = NSLocalizedString("Borrow Failed", comment: "")
    static let borrowFailedMessage = NSLocalizedString("Borrowing %@ could not be completed.", comment: "")
    static let loanAlreadyExistsAlertMessage = NSLocalizedString("You have already checked out this loan. You may need to refresh your My Books list to download the title.", comment: "")
  }
  
  struct TimeAndDuration {
    static let hour = NSLocalizedString("hour", comment: "Hour (in singular), used for example when audiobook duration is displayed for user, '1 hour'.")
    static let hours = NSLocalizedString("hours", comment: "Hours (in plural), used for example when audiobook duration is displayed for user, '3 hours'.")
    static let minute = NSLocalizedString("minute", comment: "Minute (in singular), used for example when audiobook duration is displayed for user, '1 minute'.")
    static let minutes = NSLocalizedString("minutes", comment: "Minutes (in plural), used for example when audiobook duration is displayed for user, '3 minutes'.")
    static let second = NSLocalizedString("second", comment: "Second (in singular), used for example when audiobook duration is displayed for user, '1 second'.")
    static let seconds = NSLocalizedString("seconds", comment: "Seconds (in plural), used for example when audiobook duration is displayed for user, '3 seconds'.")
  }
    
}
