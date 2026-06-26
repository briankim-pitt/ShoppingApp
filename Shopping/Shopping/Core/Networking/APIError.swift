import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case message(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The server returned an unexpected response."
        case .message(let message):
            message
        }
    }
}
