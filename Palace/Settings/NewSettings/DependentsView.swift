//
//  DependentsView.swift
//  E-kirjasto
//
//  Created by Kupe, Joona on 25.7.2024.
//

import SwiftUI

struct DependentsView: View {
  typealias tsx = Strings.Settings
  @State private var username: String = ""
  var dependents = ["Select a Dependent", "No Dependents Found"]
  @State private var selectedDependents = "Select a Dependent"
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
          Text(tsx.getD)
          Spacer()
          Image("ArrowRight")
            .padding(.leading, 10)
            .foregroundColor(Color(uiColor: .lightGray))
        }
      }
      //TODO: picker here
      VStack{
        Spacer()
        Picker(tsx.choose, selection: $selectedDependents){
          ForEach(dependents, id: \.self){
            Text($0)
          }
        }
      }
      Text(tsx.selected + "\n\n\n\(selectedDependents)")
      TextField(
              tsx.enterEmail,
              text: $username
              
          )
      Button{
        var valid = validate(username)
        print("Result of validating " + username + "is: ")
        if valid {
          //stuff
          print("Yes, valid")
        }
        else{
          //some other stuff, genious right?
          print("No, not valid")
          username = tsx.incorrectEmail
        }
      } label: {
        HStack{
          Text(tsx.sendButton)
          Spacer()
          Image("ArrowRight")
            .padding(.leading, 10)
            .foregroundColor(Color(uiColor: .lightGray))
        }
      }
    }
  }
}

func getDependents(){
    print("getDependents function was called!")
    //TODO: get method to fetch dependents from Loikka
    //TODO: to put in a picker programmatically and
    //TODO: to show user input for dependent email
    
    //TODO: fetch account id
  
    //finally return
}

func validate(_ username: String) -> Bool {
    //TODO: validate email adress here
  var email = username
  print("Validating email given: " + email)
  let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
  let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
  return emailPred.evaluate(with: email)  }

#Preview {
    DependentsView()
}
