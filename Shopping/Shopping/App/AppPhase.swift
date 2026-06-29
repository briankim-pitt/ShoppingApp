enum AppPhase: Equatable {
    case launching
    case signedOut
    case ready
    case configurationError(String)
}
