//
//  DependentsView.swift
//  E-kirjasto
//
//  Created by Kupe, Joona on 25.7.2024.
//

import SwiftUI

/**
 A model representing a dependent.
 
 The `Dependent` struct conforms to `Codable`, `Identifiable`, and `Hashable` protocols. It represents a dependent with an ID, first name, and last name. The struct provides custom encoding and decoding to map JSON keys to its properties.
 
 - Properties:
 - id: A unique identifier for the dependent.
 - firstName: The first name of the dependent.
 - lastName: The last name of the dependent.
 */
struct Dependent: Codable, Identifiable, Hashable {
  let id: String
  let firstName: String
  let lastName: String
  
  private enum CodingKeys: String, CodingKey {
    case govId
    case firstName
    case lastName
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .govId) // The API returns govId but we decode it to "id"
    firstName = try container.decode(String.self, forKey: .firstName)
    lastName = try container.decode(String.self, forKey: .lastName)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .govId) // The API expects govId so we encode it back to that
    try container.encode(firstName, forKey: .firstName)
    try container.encode(lastName, forKey: .lastName)
  }
}

/**
 A model representing a response containing a list of dependents.
 
 The `LoikkaResponse` struct conforms to the `Codable` protocol and represents the response structure from an API call that returns a list of dependents.
 
 - Properties:
 - items: An array of `Dependent` objects.
 */
struct LoikkaResponse: Codable {
  let items: [Dependent]
}


// The main view
struct DependentsView: View {
  typealias tsx = Strings.Settings
  typealias tsxgeneric = Strings.Generic
  @State private var inputEmail: String = ""
  @State private var ekirjastoToken: String = ""
  @State var authDoc : OPDS2AuthenticationDocument?
  @State private var fetchedDependents: [Dependent] = []
  @State private var showPicker: Bool = false
  @State private var id = ""
  @State private var alertMessage = ""
  @State private var showAlert = false
  @State private var showSuccess = false
  @State private var isLoading: Bool = false
  @State private var isLoadingSend: Bool = false
  
  
  var body: some View {
    
    List{
      if authDoc != nil {
        
        Section {
          
        } header: {
          HStack{
            Text(tsx.dependents)
            Spacer()
              .aspectRatio(contentMode: .fit)
              .frame(width: 200)
          }
        }
        
        Section {
          VStack {
            // This is where it starts, the user taps the button to get their children/dependents
            Button{
              isLoading = true
              getDependents()
            } label: {
              HStack{
                Text(tsx.getDependents)
                Spacer()
                Image("ArrowRight")
                  .padding(.leading, 10)
                  .foregroundColor(Color(uiColor: .lightGray))
              }
            }
            if isLoading {
              ProgressView()
            }
            
            Section {
              VStack {
                // Once the request to Loikka has been made, this section becomes visible
                if showPicker {
                  
                  // If the user doesn't have any dependents, inform them
                  if fetchedDependents.isEmpty {
                    Text(tsx.noDependents).tag(tsx.noDependents)
                      .padding()
                    
                    // If a list of dependents is returned, show them in a picker
                  } else {
                    Picker(tsx.select, selection: $id) {
                      Text(tsx.selectADependent).tag(tsx.selectADependent)
                      // Show the name of the fetched dependents and store their id
                      ForEach(fetchedDependents, id: \.id) { dependent in
                        Text(dependent.firstName).tag(dependent.id)
                      }
                    }
                    
                  }
                }
              }
              // Show an alert if the requests were unsuccessful
              .alert(isPresented: $showAlert) {
                Alert(title: Text(tsxgeneric.error), message: Text(alertMessage), dismissButton: .default(Text(tsxgeneric.ok)))
              }
            }
          }
        }
        
        // If the user has selected a dependent, we show them an email text field
        if id != "" {
          VStack {
            Text(tsx.guideText)
              .foregroundStyle(Color(uiColor: .lightGray))
              .font(.subheadline)
              .padding()
              .frame(maxWidth: .infinity, alignment: .leading)
            TextField(tsx.enterEmail, text: $inputEmail)
              .padding()
              .border(Color(uiColor: .lightGray), width: 1)
              .cornerRadius(3)
              .disableAutocorrection(true)
              .autocapitalization(.none)
              .keyboardType(.emailAddress)
            Spacer()
            
            // Tapping this button will send out the invite
            Button {
              sendInviteToDependent(dependentId: id)
            } label: {
              HStack {
                Text(tsx.sendButton)
                Image("ArrowRight")
                  .padding(.leading, 10)
                  .foregroundColor(Color(uiColor: .lightGray))
              }
              .padding(10)
            }
            
          }
          // Show an error message if any problems occur, otherwise show a success message
          .alert(isPresented: $showAlert) {
            Alert(title: Text(tsxgeneric.error), message: Text(alertMessage), dismissButton: .default(Text(tsxgeneric.ok)))
          }
          .alert(isPresented: $showSuccess) {
            Alert(title: Text(tsx.successButton), message: Text(alertMessage), dismissButton: .default(Text(tsxgeneric.ok)))
          }
          
          // It's nice to show the user some progress until the request has been executed
          if isLoadingSend {
            VStack {
              ProgressView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
        }
      }
    }
    .onAppear {
      fetchAuthDoc { doc in
        self.authDoc = doc
      }
    }
  }
  

  /**
   Fetches the authentication document for the current account or the first available account.
   
   This function attempts to retrieve the `OPDS2AuthenticationDocument` for the current account managed by `AccountsManager`. If the current account does not have an authentication document loaded, it will attempt to load it asynchronously. If there is no current account, it will try to load the authentication document for the first available account. The result is returned via a completion handler.
   
   - Parameter completion: A closure that is called with the fetched `OPDS2AuthenticationDocument` or `nil` if no document could be fetched. The closure takes a single parameter:
   - `doc`: An optional `OPDS2AuthenticationDocument` representing the fetched authentication document.
   - Note: The completion handler is called on the main thread.
   */
  func fetchAuthDoc(completion: @escaping (_ doc: (OPDS2AuthenticationDocument?))->Void){
    if let currentAccount = AccountsManager.shared.currentAccount {
      // If the current account already has an authentication document, return it
      if let doc = currentAccount.authenticationDocument {
        completion(doc)
      }else{
        // Otherwise, load the authentication document asynchronously
        currentAccount.loadAuthenticationDocument(completion: { Bool in
          DispatchQueue.main.async {
            completion(currentAccount.authenticationDocument)
          }
        })
      }
    }else if let account = AccountsManager.shared.accounts().first {
      // Load the authentication document for the first available account asynchronously
      account.loadAuthenticationDocument(completion: { Bool in
        DispatchQueue.main.async {
          completion(account.authenticationDocument!)
        }
      })
    }else{
      completion(nil)
    }
  }
  
  /**
   Fetches the link for a given relation (rel) from the authentication object.
   - Parameters:
   - rel: The relation (rel) to search for in the links.
   - Returns: The found link as a string, or `nil` if no matching link is found.
   */
  func getLink(forRel rel: String) -> String? {
    
    // Find the authentication object of ekirjasto type
    let authentication = self.authDoc?.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto" })
    
    // Find the link with the specified relation (rel)
    let link = authentication?.links?.first(where: { $0.rel == rel })?.href
    
    return link
  }
  
  /**
   Fetches the dependents for the current user.
   This function first uses the stored delegate token to get a valid e-kirjasto token. Once the e-kirjasto token is obtained, it uses it to fetch the user's dependents. The result is stored in properties for later use and updates the UI accordingly.
   */
  func getDependents(){
    print("Getting dependents...")
    
    // Get the permanent ID of the signed in user
    let patronPermanentId = TPPUserAccount.sharedAccount().patronPermantId!
    
    // First get a valid e-kirjasto token
    getEkirjastoToken() { result in
      switch result {
      case .success(let ekirjastoToken):
        // Store the e-kirjasto token to properties for later use.
        self.ekirjastoToken = ekirjastoToken
        
        // Get the user's dependents now that we have an e-kirjasto token
        getDependentsRequest(accessToken: ekirjastoToken, patronPermanantId: patronPermanentId) { dependentsResult in
          switch dependentsResult {
          case .success(let dependents):
            // Update UI properties with the fetched dependents
            self.showPicker = true
            self.fetchedDependents = dependents
            if let firstDependent = fetchedDependents.first {
              print(firstDependent.firstName)
              // Store the first dependent's id to be used in the view's picker
              self.id = firstDependent.id
              self.isLoading = false
            } else {
              // fetchedDependents on tyhjä
              print("No dependents available")
              self.isLoading = false
            }
          case .failure(let error):
            // Handle error in fetching dependents
            self.isLoading = false
            print("error: \(error)")
          }
        }
      case .failure(let error):
        // Handle error in getting the e-kirjasto token
        self.isLoading = false
        print("error: \(error)")
      }
    }
  }
  
  /**
   Function that fetches a user's e-kirjasto token from e-kirjasto circulation backend.
   - Parameters:
   - accessToken: The access token to use for authentication in the HTTP request.
   - completion: A closure that is called with the result of the token fetch request. The closure takes a single parameter:
   - result: A `Result<String, Error>` containing the token on success or an `Error` on failure.
   */
  func getEkirjastoToken(completion: @escaping (Result<String, Error>) -> Void) {
    print("Starting getEkirjastoToken...")
    
    // Get the stored delegate token of the user
    let delegateToken = TPPUserAccount.sharedAccount().authToken!
    let link = getLink(forRel: "ekirjasto_token")
    
    // Create and execute the HTTP request to fetch the token
    createHTTPRequest(httpMethod: "GET", url: link!, accessToken: delegateToken) { result in
      switch result {
      case .success(let data):
        do {
          // Parse the JSON response to extract the token
          if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
             let token = jsonResponse["token"] as? String {
            print("We got this token from circulation: \(token)")
            completion(.success(token))
          } else {
            // Handle the case where the JSON response does not contain the expected data
            let parsingError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "JSON response does not contain the expected data"])
            completion(.failure(parsingError))
          }
        } catch {
          // Handle JSON parsing errors
          print("Decoding error: \(error)")
          completion(.failure(error))
        }
      case .failure(let error):
        // Handle HTTP request errors
        completion(.failure(error))
      }
    }
  }
  
  /**
   Fetches the list of dependents for a given patron using their permanent ID. The data is fetched from the authentication service API.
   - Parameters:
   - accessToken: The access token to use for authentication in the HTTP request.
   - patronPermanantId: The permanent ID of the patron for whom to fetch dependents.
   - completion: A closure that is called with the result of the dependents fetch request. The closure takes a single parameter:
   - result: A `Result<[Dependent], Error>` containing the list of dependents on success or an `Error` on failure.
   */
  func getDependentsRequest(accessToken: String, patronPermanantId: String, completion: @escaping (Result<[Dependent], Error>) -> Void) {
    print("Start Dependents request: \(accessToken)")
    
    // Get the relations link and replace "patron" with the provided patron permanent ID
    let relationsString = getLink(forRel: "relations")
    let patronUrl = relationsString?.replacingOccurrences(of: "patron", with: patronPermanantId)
    
    createHTTPRequest(httpMethod: "GET", url: patronUrl!, accessToken: accessToken) { result in
      switch result {
      case .success(let response):
        do {
          // Decode the json reponse into Depenedent objects and return them as a list
          let decodedData = try JSONDecoder().decode(LoikkaResponse.self, from: response)
          print("Dependents: \(decodedData.items)")
          completion(.success(decodedData.items))
        } catch {
          let parsingError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "JSON response does not contain the expected data"])
          completion(.failure(parsingError))
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  
  /**
   Function that encodes the selected dependent's information to a JSON request body and makes a post request to the authentication service invite endpoint.
   - Parameters:
   - dependentId: The user's selected id of the dependent
   */
  func sendInviteToDependent(dependentId: String) {
    print("Start Dependent invite function")
    
    // Check here that the typed in email is valid and proceed if it's valid. Otherwise, show an alert.
    let emailValid = validate(self.inputEmail)
    if !emailValid {
      self.alertMessage = tsx.incorrectEmail
      self.showAlert = true
    } else {
      
      // Get the locale of the current user. We assume the dependent most likely will prefer the same language for the invite.
      let langCode = Locale.current.languageCode
      
      var jsonData: Data?
      // Find the Dependent with the matching id (user selected it in the picker)
      if let dependentObject = self.fetchedDependents.first(where: { $0.id == dependentId }) {
        print("Found dependent: \(dependentObject)")
        
        // Map the Dependent's properties to a dictionary. Role is always "customer".
        let dictionary: [String: String] = [
          "firstName": dependentObject.firstName,
          "lastName": dependentObject.lastName,
          "govId": dependentObject.id,
          "email": self.inputEmail,
          "locale": langCode!,
          "role": "customer"
        ].compactMapValues { $0 }
        print("data here: \(dictionary)")
        // Encode the dictionary to JSON
        do {
          let encodedData = try JSONEncoder().encode(dictionary)
          jsonData = encodedData
        } catch {
          print("Error encoding dictionary to JSON: \(error)")
        }
        // Shouldn't happen, but just in case, print the id if there's no matching Dependent
      } else {
        print("No matching dependent: \(dependentId)!")
      }
      
      let inviteUrl = getLink(forRel: "invite")
      
      // Once the request is made, the user should be shown progress
      self.isLoadingSend = true
      
      // Add all needed arguments to to create the post request. Print out the response from the API for success/fail
      createHTTPRequest(httpMethod: "POST", url: inviteUrl!, accessToken: self.ekirjastoToken, jsonRequestBody: jsonData, contentType: "application/json") { result in
        switch result {
          // When the request is made successfully, show the user a message, print the response and update UI properties
        case .success(let response):
          if let responseString = String(data: response, encoding: .utf8) {
            print("response: \(responseString)")
            self.isLoadingSend = false
            self.showSuccess = true
            self.alertMessage = tsx.thanks
            self.inputEmail = ""
          } else {
            let conversionError = NSError(domain: "ConversionErrorDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to string"])
            print("error: \(conversionError)")
          }
        case .failure(let error):
          // Handle reqeust errors
          self.isLoadingSend = false
          print("fail: \(error)")
        }
      }
    }
  }
  

  // HTTP errors mapped to specific messages
  enum HTTPError: Error {
    case serverError
    case unknown
    
    func errorMessage() -> String {
      switch self {
      case .serverError:
        return tsx.errorFromServer
      case .unknown:
        return tsx.errorInCreation
      }
    }
  }
  
  /**
   Creates and executes an HTTP request.
   
   This function sets up an HTTP request with the specified method, URL, access token, and optional request body and content type. It then executes the request and handles the response, returning the result via a completion handler.
   
   - Parameters:
   - httpMethod: The HTTP method to use for the request (e.g., "GET", "POST").
   - url: The URL string for the request.
   - accessToken: The access token to include in the `Authorization` header.
   - jsonRequestBody: Optional. The JSON request body to include in the request.
   - contentType: Optional. The content type to include in the `Content-Type` header.
   - completion: A closure that is called with the result of the request. The closure takes a single parameter:
   - result: A `Result<Data, HTTPError>` containing the response data on success or an `HTTPError` on failure.
   */
  func createHTTPRequest(httpMethod: String, url: String, accessToken: String, jsonRequestBody: Data? = nil, contentType: String? = nil, completion: @escaping (Result<Data, HTTPError>) -> Void) {
    print("Starting createHTTPRequest...")
    
    // Set up the http request with given arguments
    let url = URL(string: url)!
    var request = URLRequest(url: url)
    request.httpMethod = httpMethod
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    // Set the Content-Type header if provided
    if let contentTypeString = contentType {
      request.setValue(contentTypeString, forHTTPHeaderField: "Content-Type")
    }
    
    // Set the request body if provided
    if let requestBody = jsonRequestBody {
      request.httpBody = requestBody
    }
    
    // Execute the request and handle errors based on the response status code.
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      print("HTTP request to: \(request)")
      
      // Handle any request error
      if let error = error {
        self.showAlert = true
        self.alertMessage = HTTPError.unknown.errorMessage()
        print("Request error: \(error)")
        completion(.failure(.unknown))
        return
      }
      
      // Ensure the response is an HTTP response. Show an alert if not.
      guard let httpResponse = response as? HTTPURLResponse else {
        self.showAlert = true
        self.alertMessage = HTTPError.unknown.errorMessage()
        completion(.failure(.unknown))
        return
      }
      
      // Handle the HTTP status codes
      switch httpResponse.statusCode {
      case 200...299:
        if let data = data {
          // Successful response returns the data
          completion(.success(data))
        } else {
          // If data is nil, return an appropriate error and show an alert
          self.showAlert = true
          self.alertMessage = HTTPError.unknown.errorMessage()
          completion(.failure(.unknown))
        }
      default:
        // Handle non-2xx status codes and show an alert
        self.showAlert = true
        self.alertMessage = HTTPError.serverError.errorMessage()
        print("HTTP status code: \(httpResponse.statusCode)")
        // Use a default error for non-2xx status codes
        completion(.failure(.serverError))
      }
    }
    task.resume()
  }
  
  /**
   Validates a given string for email validity.
   - Parameter inputEmail: A string to be checked
   - Returns: Boolean
   */
  func validate(_ inputEmail: String) -> Bool {
    let email = inputEmail
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)  }
}

#Preview {
  DependentsView()
}
