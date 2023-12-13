import SwiftUI
import AVKit

struct GameView: View {
  @Environment(\.dismiss) var dismiss
  @ObservedObject private var settingsStorage = SettingsStorage()
  
  @State private var audioSession: AVAudioSession?
  @State private var audioPlayer: AVAudioPlayer?
  
  @State private var isShowTranslation: Bool = false
  @State private var newElement: FetchedResults<Item>.Element?
  @State private var currentElement: FetchedResults<Item>.Element?
  @State private var translationFieldValue: String = String()
  @State private var backgroundColor: Color = Color(UIColor.systemBackground)
  @State private var isVerified: Bool = false
  @State private var startDate = Date.now
  @State private var timeElapsed = String()
  @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  @State private var toShowFinishAlert: Bool = false
  
  let title: String
  let items: [FetchedResults<Item>.Element]
  let onAnswerTap: ((FetchedResults<Item>.Element?, Bool, String) -> Void)
  
  // MARK: - Body
  
  var body: some View {
    VStack(alignment: .center, spacing: .zero) {
      HStack {
        if settingsStorage.isOnlyWrongs {
          HStack {
            Text("Left:")
            Text("\(items.count)")
            Spacer()
          }
          .font(.title)
        } else {
          VStack {
            HStack {
              Text("Всего слов:")
              Text("\(items.count)")
              Spacer()
            }
            HStack {
              Text("Угадано:")
              Text("\(items.filter { $0.shown && $0.answer }.count)")
              Spacer()
            }
            HStack {
              Text("Ошибок:")
              Text("\(items.filter { $0.shown && !$0.answer }.count)")
              Spacer()
            }
          }
          .font(.headline)
        }
        
        Text(timeElapsed)
          .font(.title)
          .onReceive(timer) { firedDate in
            let string = Duration
              .seconds(firedDate.timeIntervalSince(startDate))
              .formatted(.units(
                allowed: [.minutes, .seconds],
                width: .condensedAbbreviated,
                fractionalPart: .show(length: 0)
              ))
            timeElapsed = string
          }
        Spacer()
      }
      
      VStack {
        if let element = currentElement {
          var text: String {
            if settingsStorage.language == .eng {
              isShowTranslation ? element.russian ?? "" : element.english ?? ""
            } else {
              isShowTranslation ? element.english ?? "" : element.russian ?? ""
            }
          }
          Text(text)
            .multilineTextAlignment(.center)
            .font(.largeTitle)
            .padding(.top, 100)
          
          if let voice = element.voiceRecord {
            Button(
              action: {
                playVoice(voice)
              },
              label: {
                Text("Say it")
                  .font(.title2)
              }
            )
          }
        }
        
        Spacer()
        
        VStack(spacing: 50) {
          TextField("Translation", text: $translationFieldValue)
            .textFieldStyle(.roundedBorder)
          
          HStack {
            Button(
              action: {
                checkButtonTap(answer: compare())
              },
              label: {
                Text("Сheck")
                  .font(.title)
                  .frame(width: 100)
              }
            )
            .disabled(translationFieldValue.isEmpty || isVerified)
            
            if !settingsStorage.isNextAfterAnswer {
              Spacer()
              
              Button(
                action: {
                  nextButtonTap(answer: compare())
                },
                label: {
                  Text("Next")
                    .font(.title)
                    .frame(width: 100)
                }
              )
            }
          }
          .buttonStyle(.bordered)
        }
      }
    }
    .padding()
    .background(backgroundColor)
    .navigationTitle(title)
    .alert(isPresented: $toShowFinishAlert, content: {
      Alert(
        title: Text("Finish"),
        dismissButton: .default(Text("Ok")) { dismiss() }
      )
    })
    .onAppear {
      setupAudio()
      random()
    }
    .animation(.easeInOut(duration: 0.3).repeatCount(1, autoreverses: true), value: backgroundColor)
  }
  
  private func nextButtonTap(answer: Bool) {
    guard items.count > 1 else {
      toShowFinishAlert.toggle()
      return
    }
    isShowTranslation = false
    onAnswerTap(currentElement, answer, timeElapsed)
    random()
    isVerified = false
    translationFieldValue = String()
  }
  
  private func checkButtonTap(answer: Bool) {
    timer.upstream.connect().cancel()
    withAnimation {
      backgroundColor = answer ? .green : .red
    }
    backgroundColor = Color(UIColor.systemBackground)
    isShowTranslation = true
    isVerified = true
    onAnswerTap(currentElement, answer, timeElapsed)
    if settingsStorage.isNextAfterAnswer {
      nextButtonTap(answer: answer)
    }
  }
  
  private func compare() -> Bool {
    let original = (
      settingsStorage.language == .eng
      ? currentElement?.russian ?? ""
      : currentElement?.english ?? ""
    )
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
    let translation = translationFieldValue
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
    return translation == original
  }
  
  // MARK: - Random
  
  private func random() {
    newElement = items.randomElement()
    if newElement != currentElement {
      currentElement = newElement
    } else {
      currentElement = items.randomElement()
    }
    startDate = Date.now
    timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  }
  
  // MARK: - SetupAudio
  
  private func setupAudio() {
    do {
      audioSession = AVAudioSession.sharedInstance()
      try audioSession?.setCategory(.playAndRecord, options: .defaultToSpeaker)
      try audioSession?.setActive(true)
      try audioSession?.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
    } catch {
      print(error.localizedDescription)
    }
  }
  
  // MARK: - Play voice
  
  private func playVoice(_ data: Data) {
    do {
      audioPlayer = try AVAudioPlayer(data: data)
      guard let player = audioPlayer else { return }
      player.play()
    } catch let error {
      print("Cannot play sound. \(error.localizedDescription)")
    }
  }
}

// MARK: - Preview

#Preview {
  let item = Item(context: PersistenceController.preview.container.viewContext)
  item.russian = "Rus"
  item.english = "Eng"
  item.voiceRecord = Data()
  return GameView(title: "Title", items: [item], onAnswerTap: { _, _, _ in })
}
