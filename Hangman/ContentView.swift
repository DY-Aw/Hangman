//
//  ContentView.swift
//  Hangman
//
//  Created by Ling on 8/27/25.
//

import SwiftUI

var username: String? = nil
var userID: Int? = nil
var word: String? = nil
var isCustomWord: Bool = false

struct wordStats: Identifiable {
    let id = UUID()
    
    let word: String
    let played: Int
    let won: Int
    let lost: Int
}

// Window switching
enum GameState {
    case home
    case playing
    case won
    case lost
    case login
    case newAccount
    case difficultySelect
    case customWord
    case stats
}

// Case handling for fetching user stats
enum UserStats {
    case loading
    case empty
    case notempty
    case fail
}

// Error messages for logging in
enum LoginErrorHandler {
    case noError
    case loginError
    case blankFields
}

// Error messages when creating a new username
enum NewUsernameHandler {
    case noError
    case usernameExists
    case blankFields
    case otherError
}

// Error messages when selecting a password
enum NewPasswordHandler {
    case noError
    case passwordsDontMatch
    case blankFields
    case failsRequirements
    case otherError
}

// Username creation or password creation
enum NewUserCreation {
    case userCreation
    case passwordCreation
}

// Screen: Home
struct HomeView: View {
    @Binding var gameState: GameState
    var body: some View {
        VStack {
            Text("Hangman").font(.system(size: 50)).padding(.top, 30)
            Spacer()
            Image("state0")
            Button("Log In") {
                gameState = .login
            }.font(.system(size: 30)).padding(.vertical, 10)
            Button("New Account") {
                gameState = .newAccount
            }.font(.system(size: 20))
            Spacer()
        }
    }
}

// Screen: Login
struct LoginView: View {
    @Binding var gameState: GameState
    @State var loginErrorHandler: LoginErrorHandler = .noError
    @State private var usernameInput: String = ""
    @State private var passwordInput: String = ""
    var body: some View {
        VStack {
            Text("Welcome Back!").font(.system(size: 40)).padding(.top, 30)
            Spacer()
            TextField("Enter username", text: $usernameInput).multilineTextAlignment(.center).font(.largeTitle).autocorrectionDisabled(true).autocapitalization(.none).onChange(of: usernameInput) {
                oldValue, newValue in
                let regex = "^[a-zA-Z0-9_]+$"
                if !newValue.textFieldRegex(regex: regex) && !newValue.isEmpty {
                    usernameInput = oldValue
                }
            }
            SecureField("Enter password", text: $passwordInput).multilineTextAlignment(.center).font(.largeTitle).autocorrectionDisabled(true).autocapitalization(.none).onChange(of: passwordInput) {
                oldValue, newValue in
                let regex = "^[a-zA-Z0-9~!@#$%^&*()_+-=\\[\\]{}|;:,.<>?]+$"
                if !newValue.textFieldRegex(regex: regex) && !newValue.isEmpty {
                    passwordInput = oldValue
                }
            }
            switch loginErrorHandler {
            case .noError:
                Text("")
            case .loginError:
                Text("Incorrect username or password").foregroundColor(.red)
            case .blankFields:
                Text("Make sure all fields are filled in").foregroundColor(.red)
            }
            Button("Submit") {
                if !usernameInput.isEmpty && !passwordInput.isEmpty {
                    Task {
                        do {
                            let result = try await APIFunctions.functions.login(username: usernameInput, password: passwordInput)
                            username = result.username
                            userID = result.userid
                            print("Logged in as:", username!, userID!)
                            gameState = .difficultySelect
                        } catch {
                            print("Login failed:", error)
                            loginErrorHandler = .loginError
                        }
                        
                    }
                } else {
                    loginErrorHandler = .blankFields
                }
            }.font(.title)
            Spacer()
        }
    }
}

// Screen: Creating a new account
struct NewAccountView: View {
    @Binding var gameState: GameState
    @State var newUserCreation: NewUserCreation = .userCreation
    @State var newUsernameHandler: NewUsernameHandler = .noError
    @State var newPasswordHandler: NewPasswordHandler = .noError
    @State private var usernameInput: String = ""
    @State private var passwordInput: String = ""
    @State private var passwordConfirmation: String = ""
    @State private var newUsername: String? = nil
    @State private var newPassword: String? = nil
    var body: some View {
        switch newUserCreation {
        case .userCreation:
            VStack {
                Text("Welcome!").font(.system(size: 40)).padding(.top, 30)
                Text("Choose a username").font(.system(size: 30)).padding(.top, 30)
                Spacer()
                TextField("Enter username", text: $usernameInput).multilineTextAlignment(.center).font(.largeTitle).autocorrectionDisabled(true).autocapitalization(.none).onChange(of: usernameInput) {
                    oldValue, newValue in
                    let regex = "^[a-zA-Z0-9_]+$"
                    if !newValue.textFieldRegex(regex: regex) && !newValue.isEmpty {
                        usernameInput = oldValue
                    }
                }
                switch newUsernameHandler {
                case .noError:
                    Text("")
                case .usernameExists:
                    Text("Username already exists").foregroundColor(.red)
                case .blankFields:
                    Text("Enter a username").foregroundColor(.red)
                case .otherError:
                    Text("Error occurred").foregroundColor(.red)
                }
                Button("Submit") {
                    if !usernameInput.isEmpty {
                        newUsername = usernameInput
                        Task {
                            do {
                                try await APIFunctions.functions.validateNewUsername(username: newUsername!)
                                print("Username is valid")
                                newUserCreation = .passwordCreation
                            } catch UserCreationError.duplicateUsername {
                                print("Username already exists")
                                newUsernameHandler = .usernameExists
                            } catch {
                                print("Failed to validate username", error)
                                newUsernameHandler = .otherError
                            }
                        }
                    } else {
                        newUsernameHandler = .blankFields
                    }
                }.font(.title)
                Spacer()
            }
        case .passwordCreation:
            VStack {
                Text("Welcome!").font(.system(size: 40)).padding(.top, 30)
                Text("Choose a password").font(.system(size: 30)).padding(.top, 30)
                Spacer()
                SecureField("Enter password", text: $passwordInput).multilineTextAlignment(.center).font(.largeTitle).autocorrectionDisabled(true).autocapitalization(.none).onChange(of: passwordInput) {
                    oldValue, newValue in
                    let regex = "^[a-zA-Z0-9~!@#$%^&*()_+-=\\[\\]{}|;:,.<>?]+$"
                    if !newValue.textFieldRegex(regex: regex) && !newValue.isEmpty {
                        passwordInput = oldValue
                    }
                }
                SecureField("Confirm password", text: $passwordConfirmation).multilineTextAlignment(.center).font(.largeTitle).autocorrectionDisabled(true).autocapitalization(.none).onChange(of: passwordConfirmation) {
                    oldValue, newValue in
                    let regex = "^[a-zA-Z0-9~!@#$%^&*()_+-=\\[\\]{}|;:,.<>?]+$"
                    if !newValue.textFieldRegex(regex: regex) && !newValue.isEmpty {
                        passwordConfirmation = oldValue
                    }
                }
                switch newPasswordHandler {
                case .noError:
                    Text("")
                case .passwordsDontMatch:
                    Text("Passwords must match").foregroundColor(.red)
                case .blankFields:
                    Text("Fill in all fields").foregroundColor(.red)
                case .failsRequirements:
                    Text("Password must meet requirements").foregroundColor(.red)
                case .otherError:
                    Text("Error occurred").foregroundColor(.red)
                }
                
                // Password requirements:
                let (lowerText, lowerColor, lowerValid) = displayRequirement(regex: "[a-z]", text: "Must contain a lowercase letter")
                let (capitalText, capitalColor, capitalValid) = displayRequirement(regex: "[A-Z]", text: "Must contain a capital letter", currentlyValid: lowerValid)
                let (numberText, numberColor, numberValid) = displayRequirement(regex: "[0-9]", text: "Must contain a number", currentlyValid: capitalValid)
                let (specialText, specialColor, specialValid) = displayRequirement(regex: "[ ~!@#$%^&*()_+-=\\[\\]{}|;:,.<>?]", text: "Must contain a special character", currentlyValid: numberValid)
                
                let lengthRequirement = passwordInput.count >= 8 && passwordInput.count <= 15
                
                Button("Submit") {
                    print("Button pressed")
                    if specialValid && lengthRequirement {
                        if !passwordInput.isEmpty && !passwordConfirmation.isEmpty {
                            if passwordInput != passwordConfirmation {
                                newPasswordHandler = .passwordsDontMatch
                            } else {
                                print("Submitted")
                                newPassword = passwordInput
                                print(newUsername!, passwordInput)
                                Task {
                                    do {
                                        try await APIFunctions.functions.newUser(username: newUsername!, password: newPassword!)
                                        print("User created successfully")
                                        do {
                                            let result = try await APIFunctions.functions.login(username: newUsername!, password: newPassword!)
                                            username = result.username
                                            userID = result.userid
                                            gameState = .difficultySelect
                                        } catch {
                                            print("Failed to log in", error)
                                        }
                                    } catch {
                                        print("Failed to create user", error)
                                        newPasswordHandler = .otherError
                                        
                                    }
                                }
                            }
                        } else {
                            newPasswordHandler = .blankFields
                        }
                    } else {
                        newPasswordHandler = .failsRequirements
                    }
                }.font(.title).padding(.vertical, 30)
                
                VStack {
                    if lengthRequirement {
                        Text("✓ Must be between 8 and 15 characters long").foregroundColor(.green)
                    } else {
                        Text("✗ Must be between 8 and 15 characters long").foregroundColor(.red)
                    }
                    Text(lowerText).foregroundColor(lowerColor)
                    Text(capitalText).foregroundColor(capitalColor)
                    Text(numberText).foregroundColor(numberColor)
                    Text(specialText).foregroundColor(specialColor)
                }
        
                Spacer()
            }
        }
    }
    
    func displayRequirement(regex: String, text: String, currentlyValid: Bool = true) -> (String, Color, Bool){
        var symbol: String = "✓"
        var color: Color = .green
        var valid = currentlyValid
        if (passwordInput.range(of: regex, options: .regularExpression) == nil) {
            symbol = "✗"
            color = .red
            valid = false
        }
        return (symbol + " " + text, color, valid)
    }
}

// Screen: Selecting a difficulty
struct DifficultySelectView: View {
    @Binding var gameState: GameState
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Button("Log out") {
                    gameState = .home
                    username = nil
                    userID = nil
                }.foregroundColor(.red)
            }
            VStack {
                Text("Choose a difficulty:").font(.custom("Arial", size: 40))
                Button("Normal") {
                    isCustomWord = false
                    word = WordFunctions.wordfunctions.randomMediumWord()
                    if word != "-1" {
                        gameState = .playing
                    }
                }.font(.largeTitle).padding(.vertical)
                Button("Hard") {
                    isCustomWord = false
                    word = WordFunctions.wordfunctions.randomLongWord()
                    if word != "-1" {
                        gameState = .playing
                    }
                }.font(.largeTitle).padding(.vertical)
                Button("Custom") {
                    isCustomWord = true
                    gameState = .customWord
                }.font(.largeTitle).padding(.vertical)
                Button("View Stats") {
                    gameState = .stats
                }
            }
        }
    }
}

// Screen: Selecting a custom word to play
struct CustomWordView: View {
    @Binding var gameState: GameState
    @State private var customword: String = ""
    var body: some View {
        VStack {
            TextField("Enter custom word", text: $customword).font(.largeTitle).multilineTextAlignment(.center).onChange(of: customword) {
                oldValue, newValue in
                let regex = "^[a-zA-Z ]+$"
                if !newValue.textFieldRegex(regex: regex) && !newValue.isEmpty {
                    customword = oldValue
                }
                customword = customword.uppercased()
            }.onSubmit {
                word = customword
                gameState = .playing
            }
        }
    }
}

// Screen: Main gameplay
struct GameView: View {
    @Binding var gameState: GameState
    @State private var guess: String = ""
    @State var guessedLetters: Set<Character> = []
    @State var incorrectLetters: String = ""
    @State var mistakeCount: Int = 0
    @FocusState private var isTextFieldFocused: Bool
    var body: some View {
        let (displayedWord, charactersLeft) = displayWord(word: word!, letters: guessedLetters)
        VStack {
            Text("Hangman")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Logged in as: " + username!)
            Spacer()
            let imageID = "state" + String(mistakeCount)
            Image(imageID)
            Spacer()
            Text(displayedWord)
                .font(.title)
            Text(incorrectLetters).font(.headline).foregroundColor(.red)
            Spacer()
            TextField("Guess", text: $guess).multilineTextAlignment(.center).font(.title2).autocorrectionDisabled(true).focused($isTextFieldFocused).onChange(of: guess) {
                oldValue, newValue in
                if newValue.count > 1 {
                    guess = String(newValue.prefix(1))
                }
            }.onAppear {
                isTextFieldFocused = true
            }.onSubmit {
                if guess.count == 1 {
                    let guessedLetter = Character(guess)
                    guessedLetters.insert(guessedLetter)
                    if !word!.contains(guessedLetter) {
                        if !incorrectLetters.contains(guessedLetter) {
                            incorrectLetters.append(guessedLetter)
                            incorrectLetters.append(" ")
                            mistakeCount += 1
                        }
                    }
                }
                guess = ""
                isTextFieldFocused = true
            }
            
            Spacer()
            Text(String(charactersLeft))
            Button("Give Up") {
                gameState = .lost
            }.foregroundColor(.red)
        }
        .onChange(of: charactersLeft) {
            if charactersLeft == 0 {
                gameState = .won
            }
        }
        .onChange(of: mistakeCount) {
            if mistakeCount > 6 {
                gameState = .lost
            }
        }
    }
    
    func displayWord(word: String, letters: Set<Character>) -> (String, Int) {
        var charactersLeft = 0
        var displayedWord: String = " "
        for letter in word {
            if letters.contains(letter) {
                displayedWord.append(letter)
            } else if letter == " " {
                displayedWord.append(" ")
            } else {
                displayedWord.append("_")
                charactersLeft += 1
            }
            displayedWord.append(" ")
        }
        return (displayedWord, charactersLeft)
    }
    func letterSet(word: String) -> Set<Character> {
        var correctLetters: Set<Character> = []
        for character in word {
            correctLetters.insert(character)
        }
        return correctLetters
    }
}

// Screen: Won the game
struct WinView: View {
    @Binding var gameState: GameState
    
    var body: some View {
        VStack {
            Spacer()
            Text("You Won!").font(.largeTitle)
            Text("The word was: " + word!).font(.title)
            Spacer()
            Button("Play Again") {
                gameState = .difficultySelect
            }
            Button("Log Out") {
                gameState = .login
            }
            Spacer()
        }
        .onAppear() {
            if !isCustomWord {
                APIFunctions.functions.update(word: word!, win: 1)
                APIFunctions.functions.updateStats(userid: userID!, word: word!, win: 1)
            }
        }
    }
    
}

// Screen: Lost the game
struct LossView: View {
    @Binding var gameState: GameState
    
    var body: some View {
        VStack {
            Text("You Lost").font(.largeTitle)
            Text("The word was: " + word!).font(.title)
            Button("Play Again") {
                gameState = .difficultySelect
            }
            Button("Log Out") {
                gameState = .login
            }
        }
        .onAppear() {
            if !isCustomWord {
                APIFunctions.functions.update(word: word!, win: 0)
                APIFunctions.functions.updateStats(userid: userID!, word: word!, win: 0)
            }
        }
    }
}

// Screen: User stats
struct StatsView: View {
    @Binding var gameState: GameState
    @State var userStats: UserStats = .loading
    @State private var wordstats: [WordStats] = []
    
    var body: some View {
        switch userStats {
        case .loading:
            Text("Loading").task {
                do {
                    let stats = try await APIFunctions.functions.fetchStats(userid: userID!)
                    wordstats = stats
                } catch {
                    print("Error fetching stats:", error)
                    userStats = .fail
                }
                if wordstats.isEmpty {
                    userStats = .empty
                } else {
                    userStats = .notempty
                }
            }
        case .notempty:
            ZStack {
                Text("Stats for \(username!):").font(.largeTitle)
                HStack {
                    Spacer()
                    ZStack {
                        Rectangle().frame(width: 35, height: 25).foregroundColor(.white)
                        Button("Exit") {
                            gameState = .difficultySelect
                        }.padding(.horizontal, 20.0).foregroundColor(.red)
                    }
                }
            }
            List {
                HStack {
                    Text("Word").fontWeight(.bold).frame(width: 120, alignment: .leading)
                    Spacer()
                    Text("Played").fontWeight(.bold).frame(width: 55, alignment: .trailing)
                    Text("Won").fontWeight(.bold).frame(width: 40, alignment: .trailing)
                    Text("Lost").fontWeight(.bold).frame(width: 40, alignment: .trailing)
                }
                ForEach(wordstats) { stat in
                    HStack {
                        Text(stat.word).frame(width: 120, alignment: .leading)
                        Spacer()
                        Text("\(stat.played)").frame(width: 55, alignment: .trailing)
                        Text("\(stat.won)").frame(width: 40, alignment: .trailing)
                        Text("\(stat.lost)").frame(width:40, alignment: .trailing)
                    }
                }.listRowBackground(Color.gray.opacity(0.025))
                HStack {
                    Text("TOTAL:").fontWeight(.bold).frame(width: 120, alignment: .leading)
                    Spacer()
                    Text("\(wordstats.totalPlayed)").frame(width: 55, alignment: .trailing).fontWeight(.bold)
                    Text("\(wordstats.totalWon)").frame(width: 40, alignment: .trailing).fontWeight(.bold)
                    Text("\(wordstats.totalLost)").frame(width: 40, alignment: .trailing).fontWeight(.bold)
                }
            }.scrollContentBackground(.hidden).background(Color.gray.opacity(0.1))
        case .empty:
            VStack {
                ZStack {
                    Text("Stats for \(username!):").font(.largeTitle)
                    HStack {
                        Spacer()
                        ZStack {
                            Rectangle().frame(width: 35, height: 25).foregroundColor(.white)
                            Button("Exit") {
                                gameState = .difficultySelect
                            }.padding(.horizontal, 20.0).foregroundColor(.red)
                        }
                    }
                }.padding(.bottom, 10).background(.white)
                VStack {
                    Spacer()
                    Text("Nothing to display").font(.largeTitle).foregroundColor(.gray).padding(.vertical, 5)
                    Text("Play some games to see your stats!").font(.title3).foregroundColor(.gray).multilineTextAlignment(.center)
                    Spacer()
                }
            }.background(Color.gray.opacity(0.1))
        case .fail:
            VStack {
                ZStack {
                    Text("Stats for \(username!):").font(.largeTitle)
                    HStack {
                        Spacer()
                        ZStack {
                            Rectangle().frame(width: 35, height: 25).foregroundColor(.white)
                            Button("Exit") {
                                gameState = .difficultySelect
                            }.padding(.horizontal, 20.0).foregroundColor(.red)
                        }
                    }
                }.padding(.bottom, 10).background(.white)
                VStack {
                    Spacer()
                    Text("Error displaying stats").font(.largeTitle).foregroundColor(.gray).padding(.vertical, 5)
                    Text("Try reloading the page").font(.title3).foregroundColor(.gray).multilineTextAlignment(.center)
                    Spacer()
                }
            }.background(Color.gray.opacity(0.1))
        }
    }
}

// Screen switcher
struct ContentView: View {
    @State var gameState: GameState = .home
    
    var body: some View {
        switch gameState {
        case .home:
            HomeView(gameState: $gameState)
        case .login:
            LoginView(gameState: $gameState)
        case .newAccount:
            NewAccountView(gameState: $gameState)
        case .playing:
            GameView(gameState: $gameState)
        case .won:
            WinView(gameState: $gameState)
        case .lost:
            LossView(gameState: $gameState)
        case .difficultySelect:
            DifficultySelectView(gameState: $gameState)
        case .customWord:
            CustomWordView(gameState: $gameState)
        case .stats:
            StatsView(gameState: $gameState)
        }
    }
}

// Handles valid characters in text fields
extension String {
    func textFieldRegex(regex: String) -> Bool {
        return (self.range(of: regex, options: .regularExpression) != nil)
    }
}

// Calculate user stat totals
extension Array where Element == WordStats {
    var totalPlayed: Int {
        self.reduce(0) { $0 + $1.played }
    }
    var totalWon: Int {
        self.reduce(0) { $0 + $1.won }
    }
    var totalLost: Int {
        self.reduce(0) { $0 + $1.lost }
    }
}

#Preview {
    ContentView()
}
