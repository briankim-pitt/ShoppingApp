import Testing
@testable import Shopping

struct ProductSearchCategoryTests {
    @Test
    func categoriesUseUsefulSearchQueries() {
        #expect(ProductSearchCategory.all.searchQuery == "iphone")
        #expect(ProductSearchCategory.fashion.searchQuery == "fashion")
        #expect(ProductSearchCategory.tech.searchQuery == "electronics")
        #expect(ProductSearchCategory.home.searchQuery == "home decor")
        #expect(ProductSearchCategory.beauty.searchQuery == "beauty")
    }
}
