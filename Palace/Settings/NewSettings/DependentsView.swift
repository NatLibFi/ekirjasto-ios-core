//
//  DependentsView.swift
//  E-kirjasto
//
//  Created by Kupe, Joona on 25.7.2024.
//

import SwiftUI

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
      id = try container.decode(String.self, forKey: .govId)
      firstName = try container.decode(String.self, forKey: .firstName)
      lastName = try container.decode(String.self, forKey: .lastName)
  }
  
  func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .govId)
      try container.encode(firstName, forKey: .firstName)
      try container.encode(lastName, forKey: .lastName)
  }
}

struct LoikkaResponse: Codable {
    let items: [Dependent]
}


struct DependentsView: View {
  typealias tsx = Strings.Settings
  typealias tsxgeneric = Strings.Generic
  @State private var inputEmail: String = ""
  @State private var isEmailValid: Bool = false
  @State private var ekirjastoToken: String = ""
  @State var authDoc : OPDS2AuthenticationDocument? = nil
  @State private var fetchedDependents: [Dependent] = []
  @State private var showPicker: Bool = false
  @State private var delegateToken = TPPUserAccount.sharedAccount().authToken!
  @State private var id = ""
  @State private var alertMessage = ""
  @State private var showAlert = false
  @State private var showSuccess = false
  @State private var isLoading: Bool = false
  @State private var isLoadingSend: Bool = false

  
  var body: some View {
    List{
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
                
                if fetchedDependents.isEmpty {
                  Text(tsx.noDependents).tag(tsx.noDependents)
                  
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
            .alert(isPresented: $showAlert) {
              Alert(title: Text(tsxgeneric.error), message: Text(alertMessage), dismissButton: .default(Text(tsxgeneric.ok)))
            }
            .alert(isPresented: $showSuccess) {
              Alert(title: Text(tsx.successButton), message: Text(alertMessage), dismissButton: .default(Text(tsxgeneric.ok)))
            }
          
          if isLoadingSend {
            VStack {
              ProgressView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
        }
      }
  }
  

  
  func fetchAuthDoc(completion: @escaping (_ doc: (OPDS2AuthenticationDocument?))->Void){
    if let currentAccount = AccountsManager.shared.currentAccount {
      if let doc = currentAccount.authenticationDocument {
        completion(doc)
      }else{
        currentAccount.loadAuthenticationDocument(completion: { Bool in
          DispatchQueue.main.async {
            completion(currentAccount.authenticationDocument)
          }
        })
      }
    }else if let account = AccountsManager.shared.accounts().first {
      account.loadAuthenticationDocument(completion: { Bool in
        DispatchQueue.main.async {
          completion(account.authenticationDocument!)
        }
      })
    }else{
      completion(nil)
    }
  }
  
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

  
  /// A general http request function that returns the response when the request has been successful and handles different unsuccessful responses.
  /// - Parameters:
  ///   - httpMethod: String: Http method to be used, e.g. "GET"
  ///   - url: String: The URL of the request
  ///   - accessToken: String: Bearer token to be used for the request
  ///   - jsonRequestBody: Optional JSON data: For POST requests, a JSON request body
  ///   - completion: Returns the response
  func createHTTPRequest(httpMethod: String, url: String, accessToken: String, jsonRequestBody: Data? = nil, contentType: String? = nil, completion: @escaping (Result<Data, HTTPError>) -> Void) {
      // Set up the http request
      let url = URL(string: url)!
      var request = URLRequest(url: url)
      request.httpMethod = httpMethod
      request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
      
      if let contentTypeString = contentType {
        request.setValue(contentTypeString, forHTTPHeaderField: "Content-Type")
    }
      if let requestBody = jsonRequestBody {
        request.httpBody = requestBody
    }
      // Execute the request and handle errors based on the response status code.
      let task = URLSession.shared.dataTask(with: request) { data, response, error in
        print("HTTP request to: \(request)")
          if let error = error {
            self.showAlert = true
            self.alertMessage = HTTPError.unknown.errorMessage()
              print("Request error: \(error)")
            completion(.failure(.unknown))
              return
          }
          
          guard let httpResponse = response as? HTTPURLResponse else {
            self.showAlert = true
            self.alertMessage = HTTPError.unknown.errorMessage()
            print("alerts: \(self.alertMessage), \(self.showAlert)")
            completion(.failure(.unknown))
            return
          }
          
          switch httpResponse.statusCode {
          case 200...299:
              if let data = data {
                // Successful response returns the data
                  completion(.success(data))
              } else {
                // If data is nil, return an appropriate error
                self.showAlert = true
                self.alertMessage = HTTPError.unknown.errorMessage()
                print("alerts: \(self.alertMessage), \(self.showAlert)")
                completion(.failure(.unknown))
              }
          default:
            self.showAlert = true
            self.alertMessage = HTTPError.serverError.errorMessage()
            print("alerts: \(self.alertMessage), \(self.showAlert)")
            print("HTTP status code: \(httpResponse.statusCode)")
            // Use a default error for non-2xx status codes
            completion(.failure(.serverError))
          }
      }
      task.resume()
  }

  
/// Function that fetches a user's e-kirjasto token from e-kirjasto circulation backend. A successful request returns the token.
/// - Parameters:
///   - accessToken: String: A delegate token that allows making requests to e-kirjasto backend.
  func getEkirjastoToken(accessToken: String, completion: @escaping (Result<String, Error>) -> Void) {
    
    let delegateToken = self.delegateToken
    print("Start circulation request with: \(delegateToken)")
    let url = "https://lib-dev.e-kirjasto.fi/ekirjasto/ekirjasto_token?provider=E-kirjasto+provider+for+circulation+manager"
    
      createHTTPRequest(httpMethod: "GET", url: url, accessToken: delegateToken) { result in
          switch result {
          case .success(let data):
              do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = jsonResponse["token"] as? String {
                    print("We got this token from circulation: \(token)")
                    completion(.success(token))
                } else {
                  let parsingError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "JSON response does not contain the expected data"])
                  completion(.failure(parsingError))
                }
              } catch {
                  print("Decoding error: \(error)")
                completion(.failure(error))
              }
          case .failure(let error):
              completion(.failure(error))
          }
      }
  }
  
  /// Function that makes a request to e-kirjasto authentication service using a valid e-kirjasto token and the user's (patron's) permanent id in e-kirjasto services. A successful request returns a list of dependents.
  /// - Parameters:
  ///   - accessToken: String: A valid e-kirjasto token
  ///   - patronPermanantId:  String: The user's permanent id in the e-kirjasto services.
  ///   - completion: List: A list of decoded Depenedent objects is returned.
  func getDependentsRequest(accessToken: String, patronPermanantId: String, completion: @escaping (Result<[Dependent], Error>) -> Void) {
   
    print("Start Dependents request: \(accessToken)")
    let url = "\("https://e-kirjasto.loikka.dev/v1/identities/")\(patronPermanantId)\("/relations")"
  
    createHTTPRequest(httpMethod: "GET", url: url, accessToken: accessToken) { result in
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
  
  
  /// Function that takes the signed in user's stored delegate token (=circulation token) to make a request to circulation backend to fetch the latest e-kirjasto token. Using the fetched e-kirjasto token, a new request is made to the authentication servive to get a list of the user's dependents. If a user does not have any dependents, an empty list is returned.
  func getDependents(){
    print("Getting dependents...")
    let patronPermanentId = TPPUserAccount.sharedAccount().patronPermantId!
    print("Permanent id: " + patronPermanentId)
    print("E-kirjasto token: \(self.delegateToken)")
    
    // First use the stored delegate token to get a valid e-kirjasto token
    getEkirjastoToken(accessToken: self.delegateToken) { circulationResult in
        switch circulationResult {
        case .success(let ekirjastoToken):
          // store the e-kirjasto token to properties for later use.
          self.ekirjastoToken = ekirjastoToken
            
            // Get the user's dependents now that we have an e-kirjasto token
          getDependentsRequest(accessToken: ekirjastoToken, patronPermanantId: patronPermanentId) { dependentsResult in
                  switch dependentsResult {
                    case .success(let dependents):
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
                    }
                    case .failure(let error):
                      print("error: \(error)")
                  }
            }
        case .failure(let error):
          print("error: \(error)")
        }
    }
  }
  
  /// Function that encodes the selected dependent's information to a JSON request body and makes a post request to the authentication service invite endpoint.
  /// - Parameter dependentId: String: Selected dependent's id
  func sendInviteToDependent(dependentId: String) {
    print("Start Dependent invite function")
    
    // Check here that the typed in email is valid
    let emailValid = validate(self.inputEmail)
    if !emailValid {
      self.alertMessage = tsx.incorrectEmail
      self.showAlert = true
    } else {
      
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
          "locale": "fi",
          "role": "customer"
        ].compactMapValues { $0 }
        
        // Encode the dictionary to JSON
        do {
          let encodedData = try JSONEncoder().encode(dictionary)
          jsonData = encodedData
        } catch {
          print("Error encoding dictionary to JSON: \(error)")
        }
      } else {
        print("No matching dependent: \(dependentId)!")
      }
      
      let url = "https://e-kirjasto.loikka.dev/v1/identities/invite"
      let appJson = "application/json"
      self.isLoadingSend = true
      
      // Add all needed arguments to to create the post request. Print out the response from the API for success/fail
      createHTTPRequest(httpMethod: "POST", url: url, accessToken: self.ekirjastoToken, jsonRequestBody: jsonData, contentType: appJson) { result in
        switch result {
        case .success(let response):
          if let responseString = String(data: response, encoding: .utf8) {
            print("response: \(responseString)")
            self.isLoadingSend = false
            self.showSuccess = true
            self.alertMessage = tsx.thanks
          } else {
            let conversionError = NSError(domain: "ConversionErrorDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to string"])
            print("error: \(conversionError)")
          }
        case .failure(let error):
          self.isLoadingSend = false
          print("fail: \(error)")
        }
      }
    }
  }
  
  
  /// Validates a given string for email validity.
  /// - Parameter inputEmail: String: A string to be checked
  /// - Returns: Boolean
  func validate(_ inputEmail: String) -> Bool {
    //TODO: validate email adress here
    let email = inputEmail
    print("Validating email given: " + email)
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)  }
}

#Preview {
    DependentsView()
}
