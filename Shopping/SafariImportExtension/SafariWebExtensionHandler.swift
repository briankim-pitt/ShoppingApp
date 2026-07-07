import SafariServices

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let response = NSExtensionItem()
        response.userInfo = [
            SFExtensionMessageKey: ["acknowledged": true],
        ]
        context.completeRequest(returningItems: [response])
    }
}
