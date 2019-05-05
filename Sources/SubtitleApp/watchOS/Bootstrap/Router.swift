import Foundation
import WatchKit

public enum RouterEvent {
    case startSearch
    case textPicker(parent: InterfaceControllerProtocol, empty: String?, suggestions: [String], selectedIndex: Int?, completion: (Filter<String>?) -> Void)
    case dictation(parent: InterfaceControllerProtocol, empty: String?, suggestions: [String], completion: (Filter<String>?) -> Void)
}

public protocol Router {
    func handle(_ event: RouterEvent)
}