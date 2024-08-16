//
//  DependentsView.swift
//  E-kirjasto
//
//  Created by Kupe, Joona on 25.7.2024.
//

import SwiftUI

struct DependentsView: View {
  typealias tsx = Strings.Settings
  @State private var inputEmail: String = ""
  @State private var isEmailValid: Bool = false
  var dependents = ["Select a Dependent", "No Dependents Found"]
  @State private var selectedDependent = ""
  @State private var circulationToken: String = ""
  @State var authDoc : OPDS2AuthenticationDocument? = nil
  @State private var LoikkaDependents: [String] = []


  @State private var isDependentsFetched: Bool = false

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
      Button{
        var res = getDependents()
      } label: {
        HStack{
          Text(tsx.getDependents)
          Spacer()
          Image("ArrowRight")
            .padding(.leading, 10)
            .foregroundColor(Color(uiColor: .lightGray))
        }
      }
      //TODO: picker here
      if isDependentsFetched { // Once the request to Loikka has been made, this section becomes visible
        VStack{
          Spacer()
          if LoikkaDependents.isEmpty {
            Text(tsx.noDependents).tag(tsx.noDependents)
            
          } else {
            Picker(tsx.select, selection: $selectedDependent) {
              Text(tsx.selectADependent)
                ForEach(LoikkaDependents, id: \.self) { dependent in
                  Text(dependent).tag(dependent)
                  }
            }
          }
        }
        
        if !selectedDependent.isEmpty {
          VStack {
            TextField(
              tsx.enterEmail,
              text: $inputEmail
            )
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .onChange(of: inputEmail) { newValue in isEmailValid = validate(newValue)}
            
            Button {
              print("button pressed")
            } label: {
              HStack {
                Text(tsx.sendButton)
                  .foregroundColor(isEmailValid ? .black : .gray)
                
                Image("ArrowRight")
                  .padding(.leading, 10)
                  .foregroundColor(Color(uiColor: .lightGray))
              }
              .disabled(!isEmailValid)
            }
          }
            
//            Button {
//            } label: {
//                if validate(inputEmail) {
//                    HStack {
//                        Text(tsx.sendButton)
//                        Spacer()
//                        Image("ArrowRight")
//                            .padding(.leading, 10)
//                            .foregroundColor(Color(uiColor: .lightGray))
//                    }
//                } else {
//                  Text("Not a valid email")
//                }
//            } // ends label
//          }
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
  
  func makeGetRequestWithAccessToken(url: String, accessToken: String, completion: @escaping (Result<String, Error>) -> Void) {
    let url = URL(string: url)!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Request error: ", error)
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let responseError = NSError(domain: "HTTP", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
            completion(.failure(responseError))
            return
        }
      print("status code: \(httpResponse.statusCode)")
        if httpResponse.statusCode == 200 {
            guard let data = data else {
                let dataError = NSError(domain: "Data", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid data"])
                completion(.failure(dataError))
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    completion(.success(responseString))
                }
            } else {
                let dataParsingError = NSError(domain: "Data", code: 0, userInfo: [NSLocalizedDescriptionKey: "Data parsing error"])
                completion(.failure(dataParsingError))
            }
        } else {
            let statusCodeError = NSError(domain: "HTTP", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Invalid status code"])
            completion(.failure(statusCodeError))
        }
    }
    task.resume()
  }
  
  func getCirculationToken(accessToken: String, completion: @escaping (Result<String, Error>) -> Void) {
    
    print("Start circulation request: \(accessToken)")
    let url = "https://lib-dev.e-kirjasto.fi/ekirjasto/ekirjasto_token?provider=E-kirjasto+provider+for+circulation+manager"

    makeGetRequestWithAccessToken(url: url, accessToken: accessToken) { result in
      switch result {
      case .success(let response):
        print("Circulation response: \(response)")
        if let data = response.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = json["token"] as? String {
                    completion(.success(token))
                } else {
                    let parsingError = NSError(domain: "JSON", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format or missing 'token'"])
                    completion(.failure(parsingError))
                }
            } catch {
                completion(.failure(error))
            }
        } else {
            let dataError = NSError(domain: "Data", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert response string to data"])
            completion(.failure(dataError))
        }

      case .failure(let error):
        print("Circulation Error: \(error)")
        completion(.failure(error))
      }
    }
  }
  
  
  func getDependentsRequest(accessToken: String, patronPermanantId: String, completion: @escaping (Result<[String], Error>) -> Void) {
   
    print("Start Dependents request: \(accessToken)")
    let url = "\("https://e-kirjasto.loikka.dev/v1/identities/")\(patronPermanantId)\("/relations")"

    makeGetRequestWithAccessToken(url: url, accessToken: accessToken) { result in
      switch result {
      case .success(let response):
        print("Loikka response: \(response)")
        if let data = response.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {
                    let firstNames = items.compactMap { $0["firstName"] as? String }
                    completion(.success(firstNames))
                } else {
                    let parsingError = NSError(domain: "JSON", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format or missing 'items'"])
                    completion(.failure(parsingError))
                }
            } catch {
                completion(.failure(error))
            }
        } else {
            let dataError = NSError(domain: "Data", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert response string to data"])
            completion(.failure(dataError))
        }

      case .failure(let error):
        print("Dependents Error: \(error)")
        completion(.failure(error))
      }
    }
  }
  

  func getDependents(){
    print("Getting dependents...")
    let patronPermanentId = TPPUserAccount.sharedAccount().patronPermantId!
    print("Permanent id: " + patronPermanentId)
    let currentEkirjastoToken = TPPUserAccount.sharedAccount().authToken!
    print("Ekirajsto token: \(currentEkirjastoToken)")
    getCirculationToken(accessToken: currentEkirjastoToken) { circulationResult in
        switch circulationResult {
        case .success(let circulationToken):
            getDependentsRequest(accessToken: circulationToken, patronPermanantId: patronPermanentId) { dependentsResult in
                switch dependentsResult {
                case .success(let dependents):
                    print("Dependents: \(dependents)")
                  self.LoikkaDependents = dependents
                  self.isDependentsFetched = true
                case .failure(let error):
                  print("error: \(error)")
                }
            }
        case .failure(let error):
          print("error: \(error)")
        }
    }

    //TODO: get method to fetch dependents from Loikka
    //TODO: to put in a picker programmatically and
    //TODO: to show user input for dependent email
    
    //TODO: fetch account id
    
    //finally return
  }
  
  func validate(_ inputEmail: String) -> Bool {
    //TODO: validate email adress here
    var email = inputEmail
    print("Validating email given: " + email)
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)  }
}

#Preview {
    DependentsView()
}
