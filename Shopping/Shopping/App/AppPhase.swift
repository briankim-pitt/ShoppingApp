enum AppPhase: Equatable {
    case launching
    case signedOut
    case needsCurrency
    case ready
    case configurationError(String)
}
