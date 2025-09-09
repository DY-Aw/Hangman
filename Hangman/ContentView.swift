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

enum GameState {
    case playing
    case won
    case lost
    case login
    case difficultySelect
    case customWord
    case stats
}

enum UserStats {
    case loading
    case empty
    case notempty
    case fail
}

struct LoginView: View{
    @Binding var gameState: GameState
    @State private var usernameInput: String = ""
    @State private var passwordInput: String = ""
    @State private var passwordDisplay: String = ""
    var body: some View {
        VStack {
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
            Button("Submit") {
                if !usernameInput.isEmpty && !passwordInput.isEmpty {
                    username = usernameInput
                    Task {
                        do {
                            let result = try await APIFunctions.functions.login(username: usernameInput, password: passwordInput)
                            username = result.username
                            userID = result.userid
                            print("Logged in as:", username!, userID!)
                            gameState = .difficultySelect
                        } catch {
                            print("Login failed:", error)
                        }
                        
                    }
                }
            }.font(.title)
        }
    }
}

struct DifficultySelectView: View {
    @Binding var gameState: GameState
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Button("Log out") {
                    gameState = .login
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

struct ContentView: View {
    @State var gameState: GameState = .login
    
    var body: some View {
        switch gameState {
        case .login:
            LoginView(gameState: $gameState)
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

extension String {
    func textFieldRegex(regex: String) -> Bool {
        return (self.range(of: regex, options: .regularExpression) != nil)
    }
}

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
