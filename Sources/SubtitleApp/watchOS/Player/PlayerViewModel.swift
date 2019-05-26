import Common
import Foundation
import RxSwift
import SubtitlePlayer

public typealias PlayerViewModelInput = (
    awakeWithContext: (Any?) -> Void,
    didAppear: () -> Void,
    willDisappear: () -> Void,
    didDeactivate: () -> Void,
    willActivate: () -> Void,
    rewindButtonTap: () -> Void,
    playToggleButtonTap: () -> Void,
    forwardButtonTap: () -> Void,
    crownRotate: (Double) -> Void,
    crownRotationEnded: () -> Void
)

public typealias PlayerViewModelOutput = (
    subtitle: (String) -> Void,
    playingToggleText: (String) -> Void,
    rewindButtonHidden: (Bool) -> Void,
    forwardButtonHidden: (Bool) -> Void,
    progress: (Double) -> Void,
    hapticClick: () -> Void
)

private struct PlayingDetails {
    let triggerStart: Date
    let offset: OffsetType

    enum OffsetType {
        // case time(DispatchTimeInterval)
        case lines(Int)
    }
}

public func playerViewModel(router: Router, subtitle: Subtitle) -> (PlayerViewModelOutput) -> PlayerViewModelInput {
    return { output in
        var disposableExecution: Disposable? = nil
        var playingDetails: PlayingDetails?
        let lastLine = subtitle.lastSequence
        var currentLine = -1 {
            didSet {
                guard currentLine != oldValue else { return }
                output.progress(progress(currentLine, lastLine))
            }
        }
        var crownAccumulation: Double = 0

        return (
            awakeWithContext: { _ in output.subtitle("") },
            didAppear: {
                currentLine = 0
                setPlaying(playingDetails != nil, output: output)
            },
            willDisappear: { },
            didDeactivate: {
                disposableExecution?.dispose()
                disposableExecution = nil
            },
            willActivate: {
                let now = Date()
                setPlaying(playingDetails != nil, output: output)
                output.subtitle("")
                guard let playingDetails = playingDetails, case let .lines(startingLine) = playingDetails.offset else { return }
                disposableExecution = SubtitlePlayer
                    .play(subtitle: subtitle,
                          triggerTime: playingDetails.triggerStart,
                          startingLine: startingLine,
                          now: now)
                    .subscribe(onNext: { lines in
                        DispatchQueue.main.async {
                            currentLine = lines.last?.sequence ?? currentLine
                            let text = lines.map(^\.text).joined(separator: "\n")
                            output.subtitle(text)
                        }
                    })
            },
            rewindButtonTap: {
                currentLine = max(currentLine - 1, 0)
                output.subtitle(subtitle.line(sequence: currentLine)?.text ?? "")
                output.hapticClick()
            },
            playToggleButtonTap: {
                let now = Date()
                currentLine = currentLine > lastLine ? 0 : currentLine
                playingDetails = playingDetails != nil ? nil : PlayingDetails(triggerStart: now, offset: .lines(currentLine))
                setPlaying(playingDetails != nil, output: output)

                if let playingDetails = playingDetails {
                    disposableExecution = SubtitlePlayer
                        .play(subtitle: subtitle,
                              triggerTime: playingDetails.triggerStart,
                              startingLine: currentLine,
                              now: now)
                        .subscribe(onNext: { lines in
                            DispatchQueue.main.async {
                                currentLine = lines.last?.sequence ?? currentLine
                                let text = lines.map(^\.text).joined(separator: "\n")
                                output.subtitle(text)
                            }
                        })
                } else {
                    disposableExecution?.dispose()
                    disposableExecution = nil
                    output.subtitle(subtitle.line(sequence: currentLine)?.text ?? "")
                }
                output.hapticClick()
            },
            forwardButtonTap: {
                currentLine = min(currentLine + 1, lastLine)
                output.subtitle(subtitle.line(sequence: currentLine)?.text ?? "")
                output.hapticClick()
            },
            crownRotate: { delta in
                guard playingDetails == nil else { return }
                let threshold = 0.1
                crownAccumulation += delta
                guard abs(crownAccumulation) > threshold else { return }

                let newLine = crownAccumulation > 0
                    ? min(currentLine + 1, lastLine)
                    : max(currentLine - 1, 0)

                crownAccumulation = 0
                guard newLine != currentLine else { return }
                currentLine = newLine
                output.subtitle(subtitle.line(sequence: currentLine)?.text ?? "")
                output.hapticClick()
            },
            crownRotationEnded: {
                crownAccumulation = 0
            }
        )
    }
}

private func setPlaying(_ playing: Bool, output: PlayerViewModelOutput) {
    output.forwardButtonHidden(playing ? true : false)
    output.rewindButtonHidden(playing ? true : false)
    output.playingToggleText(playing ? "⏸" : "▶️")
}

private func progress(_ current: Int, _ total: Int) -> Double {
    return Double(current) / Double(max(total, 1))
}
