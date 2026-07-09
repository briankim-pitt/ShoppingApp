import SwiftUI
import UIKit

@MainActor
struct NavigationBarTopBlurDisabler: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        NavigationBarController(coordinator: context.coordinator)
    }

    func updateUIViewController(
        _ viewController: UIViewController,
        context: Context
    ) {
        context.coordinator.apply(to: viewController.navigationController)
    }

    static func dismantleUIViewController(
        _ viewController: UIViewController,
        coordinator: Coordinator
    ) {
        coordinator.restore()
    }

    @MainActor
    final class Coordinator {
        private weak var navigationBar: UINavigationBar?
        private var standardAppearance: UINavigationBarAppearance?
        private var scrollEdgeAppearance: UINavigationBarAppearance?
        private var compactAppearance: UINavigationBarAppearance?
        private var compactScrollEdgeAppearance: UINavigationBarAppearance?
        private var isTranslucent: Bool?

        func apply(to navigationController: UINavigationController?) {
            guard let navigationBar = navigationController?.navigationBar else {
                return
            }

            if self.navigationBar !== navigationBar {
                restore()
                self.navigationBar = navigationBar
                standardAppearance = navigationBar.standardAppearance
                scrollEdgeAppearance = navigationBar.scrollEdgeAppearance
                compactAppearance = navigationBar.compactAppearance
                compactScrollEdgeAppearance = navigationBar
                    .compactScrollEdgeAppearance
                isTranslucent = navigationBar.isTranslucent
            }

            navigationBar.isTranslucent = true
            navigationBar.standardAppearance = transparentCopy(
                of: navigationBar.standardAppearance
            )
            navigationBar.scrollEdgeAppearance = transparentCopy(
                of: navigationBar.scrollEdgeAppearance
                    ?? navigationBar.standardAppearance
            )
            navigationBar.compactAppearance = transparentCopy(
                of: navigationBar.compactAppearance
                    ?? navigationBar.standardAppearance
            )
            navigationBar.compactScrollEdgeAppearance = transparentCopy(
                of: navigationBar.compactScrollEdgeAppearance
                    ?? navigationBar.standardAppearance
            )
        }

        func restore() {
            guard let navigationBar else { return }

            if let standardAppearance {
                navigationBar.standardAppearance = standardAppearance
            }
            navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
            navigationBar.compactAppearance = compactAppearance
            navigationBar.compactScrollEdgeAppearance =
                compactScrollEdgeAppearance
            if let isTranslucent {
                navigationBar.isTranslucent = isTranslucent
            }

            self.navigationBar = nil
            standardAppearance = nil
            scrollEdgeAppearance = nil
            compactAppearance = nil
            compactScrollEdgeAppearance = nil
            isTranslucent = nil
        }

        private func transparentCopy(
            of appearance: UINavigationBarAppearance
        ) -> UINavigationBarAppearance {
            let copy = appearance.copy()
            copy.backgroundEffect = nil
            copy.backgroundColor = .clear
            copy.shadowColor = .clear
            copy.shadowImage = UIImage()
            return copy
        }
    }

    @MainActor
    private final class NavigationBarController: UIViewController {
        private let coordinator: Coordinator

        init(coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            coordinator.apply(to: navigationController)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            coordinator.apply(to: navigationController)
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            coordinator.restore()
        }
    }
}
