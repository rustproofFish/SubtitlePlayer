import Foundation

enum PlayArgument {
    case file(String)
    case initialLine(Int)
    case encoding(String.Encoding)
    case debug(Bool)

    static func parse(_ argument: String) -> PlayArgument? {
        let components = argument.components(separatedBy: "=")
        switch components.first {
        case "file":
            return components[safe: 1].map(PlayArgument.file)
        case "from-line":
            return components[safe: 1].flatMap(Int.init).map(PlayArgument.initialLine)
        case "encoding":
            return components[safe: 1].flatMap(String.Encoding.init(string:)).map(PlayArgument.encoding)
        case "debug":
            return components[safe: 1].flatMap(Bool.init).map(PlayArgument.debug)
        default:
            return nil
        }
    }
}

extension PlayArgument {
    var file: String? {
        guard case let .file(file) = self else { return nil }
        return file
    }

    var line: Int? {
        guard case let .initialLine(line) = self else { return nil }
        return line
    }

    var encoding: String.Encoding? {
        guard case let .encoding(encoding) = self else { return nil }
        return encoding
    }

    var debug: Bool? {
        guard case let .debug(debug) = self else { return nil }
        return debug
    }
}

extension Array where Element == PlayArgument {
    static func parse(_ arguments: [String]) -> [PlayArgument] {
        return arguments.compactMap(PlayArgument.parse)
    }
}
