import AppKit
import Combine
import SwiftData

@MainActor
final class TestClass: ObservableObject {
    private var modelContext: ModelContext?
    func start(modelContext: ModelContext) {
        self.modelContext = modelContext
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                if let context = self?.modelContext {
                    print(context)
                }
            }
        }
    }
}
