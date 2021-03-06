import Foundation
import OpenSubtitlesDownloader
import SubtitlePlayer

#if os(watchOS)
import WatchKit
public enum RouterEvent {
    case startSearch(parent: Controller, searchParameters: SearchParameters)
    case textPicker(parent: Controller, empty: String?, suggestions: [String], selectedIndex: Int?, completion: (Filter<String>?) -> Void)
    case dictation(parent: Controller, empty: String?, suggestions: [String], completion: (Filter<String>?) -> Void)
    case play(parent: Controller, subtitle: Subtitle)
    case searchForm
}
#endif

#if os(iOS)
import UIKit
public enum RouterEvent {
    case startSearch(parent: Controller, searchParameters: SearchParameters)
    case textPicker(parent: Controller, empty: String?, suggestions: [String], selectedIndex: Int?, completion: (Filter<String>?) -> Void)
    case play(parent: Controller, subtitle: Subtitle)
    case searchForm
}
#endif

public protocol Router {
    func handle(_ event: RouterEvent)
}
