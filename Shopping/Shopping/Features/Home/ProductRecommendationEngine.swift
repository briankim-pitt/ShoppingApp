import Foundation

enum ProductRecommendationEngine {
    static func recommendations(
        from catalog: [Product],
        recentlyViewed: [Product],
        orders: [VirtualOrder],
        limit: Int = 12
    ) -> [Product] {
        let signals = viewSignals(from: recentlyViewed)
            + orderSignals(from: orders)
        guard !signals.isEmpty else { return [] }

        let eligibleOrders = orders.filter { $0.status != .cancelled }
        let excludedIDs = Set(recentlyViewed.map(\.id)).union(
            eligibleOrders.flatMap(\.items).compactMap(\.productID)
        )

        let rankedProducts = catalog
            .filter { !excludedIDs.contains($0.id) }
            .map { product in
                rankedProduct(product, against: signals)
            }
            .filter { $0.score > 0 }
            .sorted { left, right in
                if left.score == right.score {
                    return left.product.lastImportedAt
                        > right.product.lastImportedAt
                }
                return left.score > right.score
            }

        return diversified(rankedProducts, limit: max(limit, 0))
    }

    private static func viewSignals(from products: [Product]) -> [Signal] {
        products.enumerated().map { index, product in
            Signal(
                key: "view:\(product.id)",
                brand: normalized(product.brand),
                sourceDomain: normalized(product.sourceDomain),
                tokens: tokens(for: product),
                price: product.wanderCoinPriceAmount,
                weight: max(1.2, 3.2 - Double(index) * 0.18)
            )
        }
    }

    private static func orderSignals(from orders: [VirtualOrder]) -> [Signal] {
        orders
            .filter { $0.status != .cancelled }
            .enumerated()
            .flatMap { orderIndex, order in
                order.items.map { item in
                    Signal(
                        key: "order:\(item.productID?.uuidString ?? item.title)",
                        brand: nil,
                        sourceDomain: nil,
                        tokens: tokens(in: item.title),
                        price: item.unitPriceAmount,
                        weight: max(2.4, 5.2 - Double(orderIndex) * 0.22)
                            * min(Double(item.quantity), 3)
                    )
                }
            }
    }

    private static func rankedProduct(
        _ product: Product,
        against signals: [Signal]
    ) -> RankedProduct {
        let productTokens = tokens(for: product)
        let productBrand = normalized(product.brand)
        let productDomain = normalized(product.sourceDomain)
        var totalScore = 0.0
        var strongestSignalKey = signals[0].key
        var strongestSignalScore = -Double.infinity

        for signal in signals {
            var match = Double(productTokens.intersection(signal.tokens).count)

            if let productBrand, productBrand == signal.brand {
                match += 7
            } else if let productBrand,
                      tokens(in: productBrand).isSubset(of: signal.tokens) {
                match += 3.5
            }

            if productDomain == signal.sourceDomain {
                match += 1.5
            }

            match += priceSimilarity(
                product.wanderCoinPriceAmount,
                signal.price
            )

            let signalScore = match * signal.weight
            totalScore += signalScore

            if signalScore > strongestSignalScore {
                strongestSignalScore = signalScore
                strongestSignalKey = signal.key
            }
        }

        return RankedProduct(
            product: product,
            score: totalScore + stableJitter(for: product.id),
            diversityKey: strongestSignalKey
        )
    }

    private static func diversified(
        _ rankedProducts: [RankedProduct],
        limit: Int
    ) -> [Product] {
        guard limit > 0 else { return [] }

        var buckets = Dictionary(grouping: rankedProducts, by: \.diversityKey)
        let orderedKeys = buckets.keys.sorted { left, right in
            let leftScore = buckets[left]?.first?.score ?? 0
            let rightScore = buckets[right]?.first?.score ?? 0
            return leftScore > rightScore
        }
        var result: [Product] = []

        while result.count < limit {
            var addedProduct = false

            for key in orderedKeys where result.count < limit {
                guard var bucket = buckets[key], !bucket.isEmpty else {
                    continue
                }

                result.append(bucket.removeFirst().product)
                buckets[key] = bucket
                addedProduct = true
            }

            if !addedProduct {
                break
            }
        }

        return result
    }

    private static func stableJitter(for id: UUID) -> Double {
        let hash = id.uuidString.utf8.reduce(UInt64(2_166_136_261)) {
            ($0 &* 16_777_619) ^ UInt64($1)
        }
        return Double(hash % 1_000) / 1_250
    }

    private static func priceSimilarity(
        _ candidate: Decimal?,
        _ signal: Decimal?
    ) -> Double {
        guard let candidate, let signal, candidate > 0, signal > 0 else {
            return 0
        }

        let candidateValue = NSDecimalNumber(decimal: candidate).doubleValue
        let signalValue = NSDecimalNumber(decimal: signal).doubleValue
        let logarithmicDistance = abs(log(candidateValue / signalValue))
        return max(0, 1.5 - logarithmicDistance)
    }

    private static func tokens(for product: Product) -> Set<String> {
        tokens(
            in: [product.brand, product.title, product.description]
                .compactMap { $0 }
                .joined(separator: " ")
        )
    }

    private static func tokens(in value: String) -> Set<String> {
        Set(
            value
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { token in
                    token.count > 2 && !stopWords.contains(token)
                }
        )
    }

    private static func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let result = value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }

    private static let stopWords: Set<String> = [
        "and", "for", "from", "into", "the", "this", "with", "your",
        "new", "product", "item",
    ]

    private struct Signal {
        let key: String
        let brand: String?
        let sourceDomain: String?
        let tokens: Set<String>
        let price: Decimal?
        let weight: Double
    }

    private struct RankedProduct {
        let product: Product
        let score: Double
        let diversityKey: String
    }
}
