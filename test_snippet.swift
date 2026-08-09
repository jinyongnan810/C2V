import AppKit
import Observation
import SwiftData

@MainActor
@Observable
final class TestClass {
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
