import UniformTypeIdentifiers
import UIKit

final class ShareViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Task {
            await importSharedProductURL()
        }
    }

    private func importSharedProductURL() async {
        guard let url = await sharedProductURL(),
              let callbackURL = callbackURL(for: url)
        else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }

        _ = await extensionContext?.open(callbackURL)
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func sharedProductURL() async -> URL? {
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return nil
        }

        for item in inputItems {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                if let url = await loadURL(from: provider) {
                    return url
                }
            }
        }

        return nil
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
           let url = await loadURLItem(from: provider) {
            return url
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
           let url = await loadTextURL(from: provider) {
            return url
        }

        return nil
    }

    private func loadURLItem(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(
                forTypeIdentifier: UTType.url.identifier,
                options: nil
            ) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let string = item as? String {
                    continuation.resume(returning: URL(string: string))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func loadTextURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(
                forTypeIdentifier: UTType.plainText.identifier,
                options: nil
            ) { item, _ in
                let text = item as? String
                let url = text.flatMap(Self.firstURL(in:))
                continuation.resume(returning: url)
            }
        }
    }

    nonisolated private static func firstURL(in text: String) -> URL? {
        text
            .split(whereSeparator: \.isWhitespace)
            .lazy
            .compactMap { URL(string: String($0)) }
            .first { $0.scheme == "http" || $0.scheme == "https" }
    }

    private func callbackURL(for productURL: URL) -> URL? {
        var components = URLComponents()
        components.scheme = "shopping"
        components.host = "import-product"
        components.queryItems = [
            URLQueryItem(name: "url", value: productURL.absoluteString),
        ]
        return components.url
    }
}
