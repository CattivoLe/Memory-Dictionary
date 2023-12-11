import SwiftUI
import AVKit

struct ItemView: View {
  @State private var audioSession: AVAudioSession?
  @State private var recorder: AVAudioRecorder?
  @State private var audioPlayer: AVAudioPlayer?
  
  @State private var toShowEditView = false
  @State private var isRecord = false
  @State private var record: URL?
  
  @State var recordData: Data?
  
  let element: Element
  let language: Language
  let onEditTap: (Element) -> Void
  let onSaveRecord: (Data) -> Void
  
  // MARK: - Body
  
  var body: some View {
    VStack {
      var text: String {
        switch language {
        case .eng: return element.russian
        case .rus: return element.english
        }
      }
      Text(text)
        .multilineTextAlignment(.center)
        .font(.largeTitle)
      
      HStack(spacing: 50) {
        Text("Right: \(element.right)")
          .foregroundColor(.green)
        Text("Wrong: \(element.wrong)")
          .foregroundColor(.red)
      }
      .font(.title3)
      .padding(.top, 20)
      
      if let time = element.answerTime, element.answer {
        Text("Answer time: \(time)")
          .padding(.top, 10)
      }
      
      HStack(spacing: 50) {
        Button {
          recording()
        } label: {
          ZStack {
            let color: Color = isRecord ? .red : .white
            Text("REC")
              .foregroundStyle(.red)
            Circle()
              .stroke(color)
              .frame(width: 50)
          }
        }
        
        if record != nil || recordData != nil {
          Button {
            playRecord()
          } label: {
            ZStack {
              Text("PLAY")
                .foregroundStyle(.green)
              Circle()
                .stroke(.green)
                .frame(width: 50)
            }
          }
        }
      }
      .padding(.top, 50)
    }
    .padding()
    .toolbar {
      ToolbarItem {
        Button(
          action: {
            toShowEditView.toggle()
          },
          label: {
            Text("Change")
          }
        )
        .sheet(isPresented: $toShowEditView) {
          ItemEditView(
            title: "Change",
            buttonTitle: "Save",
            englishValue: element.english,
            russianValue: element.russian
          ) { result in
            onEditTap(result)
            toShowEditView.toggle()
          }
          .presentationDetents([.medium])
        }
      }
    }
    .onAppear {
      setupRecorder()
    }
  }
  
  // MARK: - SetupRecorder
  
  private func setupRecorder() {
    do {
      audioSession = AVAudioSession.sharedInstance()
      try audioSession?.setCategory(.playAndRecord, options: .defaultToSpeaker)
      try audioSession?.setActive(true)
      try audioSession?.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
      Task {
        await AVAudioApplication.requestRecordPermission()
      }
    } catch {
      print(error.localizedDescription)
    }
  }
  
  // MARK: - Record
  
  private func recording() {
    if isRecord {
      recorder?.stop()
      isRecord.toggle()
      getAudio()
    } else {
      do {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileName = url.appendingPathComponent("\(element.english).m4a")
        let settings = [
          AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
          AVSampleRateKey: 12000,
          AVNumberOfChannelsKey: 1,
          AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try AVAudioRecorder(url: fileName, settings: settings)
        recorder?.record()
        isRecord.toggle()
      } catch {
        print(error.localizedDescription)
      }
    }
  }
  
  // MARK: - GetAudio
  
  private func getAudio() {
    do {
      guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
      let result = try FileManager.default.contentsOfDirectory(
        at: url,
        includingPropertiesForKeys: nil,
        options: .producesRelativePathURLs
      )
      recordData = nil
      record = result.first(where: { url in
        url.relativeString == "\(element.english).m4a"
      })
      guard let recordUrl = record, let data = try? Data(contentsOf: recordUrl) else { return }
      onSaveRecord(data)
    } catch {
      print(error.localizedDescription)
    }
  }
  
  // MARK: - Play
  
  private func playRecord() {
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileName = url.appendingPathComponent("\(element.english).m4a")
    do {
      if let data = recordData {
        audioPlayer = try AVAudioPlayer(data: data)
      } else {
        audioPlayer = try AVAudioPlayer(contentsOf: fileName)
      }
      guard let player = audioPlayer else { return }
      player.play()
    } catch let error {
      print("Cannot play sound. \(error.localizedDescription)")
    }
  }
}

// MARK: - Preview

#Preview {
  ItemView(
    recordData: nil,
    element: Element(
      english: "Cat",
      russian: "Кот",
      answer: true,
      right: 10,
      wrong: 0,
      answerTime: "1 sec"
    ),
    language: .eng,
    onEditTap: { _ in },
    onSaveRecord: { _ in }
  )
}
