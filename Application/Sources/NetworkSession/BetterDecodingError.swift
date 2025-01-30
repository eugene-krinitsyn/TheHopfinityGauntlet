import Foundation

public enum BetterDecodingError: CustomStringConvertible {
  case dataCorrupted(_ message: String)
  case keyNotFound(_ message: String)
  case typeMismatch(_ message: String)
  case valueNotFound(_ message: String)
  case any(_ error: Error)

  public init(with error: Error) {
    guard let decodingError = error as? DecodingError else {
      self = .any(error)
      return
    }

    switch decodingError {
    case let .dataCorrupted(context):
      let debugDescription = (context.underlyingError as NSError?)?.userInfo["NSDebugDescription"] ?? ""
      self = .dataCorrupted("Data corrupted. \(context.debugDescription) \(debugDescription)")
    case let .keyNotFound(key, context):
      self = .keyNotFound("Key not found. Expected '\(key.stringValue)' at: \(context.prettyPath())")
    case let .typeMismatch(_, context):
      self = .typeMismatch("Type mismatch. \(context.debugDescription), at: \(context.prettyPath())")
    case let .valueNotFound(_, context):
      self = .valueNotFound("Value not found. '\(context.prettyPath())' \(context.debugDescription)")
    @unknown default:
      self = .any(error)
    }
  }

  public var description: String {
    switch self {
    case let .dataCorrupted(message), let .keyNotFound(message), let .typeMismatch(message), let .valueNotFound(message):
      return message
    case let .any(error):
      return error.localizedDescription
    }
  }
}

// MARK: LocalizedError

extension BetterDecodingError: LocalizedError {
  public var errorDescription: String? {
    description
  }
}

extension DecodingError.Context {
  func prettyPath(separatedBy _: String = ".") -> String {
    codingPath
      .map {
        let key = $0.stringValue
        if key.starts(with: "Index") {
          return "[\(key.replacingOccurrences(of: "Index ", with: ""))]"
        } else {
          return key
        }
      }
      .joined(separator: ".")
  }
}

// https://gist.github.com/nunogoncalves/4852077f4e576872f72b70d9e79942f3

// Type mismatch. Expected to decode Int but found a string/data instead., at: job.boss.age
//
// vs
//
// typeMismatch(Swift.Int, Swift.DecodingError.Context(codingPath: [CodingKeys(stringValue: "job",
// intValue: nil), CodingKeys(stringValue: "boss", intValue: nil), CodingKeys(stringValue: "age",
// intValue: nil)], debugDescription: "Expected to decode Int but // found a string/data instead.",
// underlyingError: nil))
//
// ----------------------------------
//
// Data currupted. The given data was not valid JSON. No value for key in object around character 14.
//
// vs
//
// dataCorrupted(Swift.DecodingError.Context(codingPath: [], debugDescription: "The given data was not
// valid JSON.", underlyingError: Optional(Error Domain=NSCocoaErrorDomain Code=3840 "No value for key
// in object around character 14." UserInfo={NSDebugDescription=No // value for key in object around
// character 14.})))
//
// ----------------------------------
//
// Value not found. -> job.boss.name <- Expected String value but found null instead.
//
// vs
//
// valueNotFound(Swift.String, Swift.DecodingError.Context(codingPath: [CodingKeys(stringValue: "job",
// intValue: nil), CodingKeys(stringValue: "boss", intValue: nil), CodingKeys(stringValue: "name",
// intValue: nil)], debugDescription: "Expected String value but // found null instead.", underlyingError: nil))
//
// ----------------------------------
//
// Value not found. -> job.boss.name <- Expected String value but found null instead.
//
// vs
//
// valueNotFound(Swift.String, Swift.DecodingError.Context(codingPath: [CodingKeys(stringValue: "job",
// intValue: nil), CodingKeys(stringValue: "boss", intValue: nil), CodingKeys(stringValue: "name",
// intValue: nil)], debugDescription: "Expected String value but // found null instead.",
// underlyingError: nil))
//
// ----------------------------------
