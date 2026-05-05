import Combine
import Foundation
import CodexRateLimitsCore

@MainActor
final class RateLimitStore: ObservableObject {
    @Published private(set) var snapshot: RateLimitSnapshot?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = true

    let dataFileURL: URL

    private var provider: RateLimitProviding

    init(provider: RateLimitProviding, dataFileURL: URL) {
        self.provider = provider
        self.dataFileURL = dataFileURL

        self.provider.onSnapshot = { [weak self] result in
            switch result {
            case .success(let snapshot):
                Task { @MainActor [weak self] in
                    self?.apply(snapshot: snapshot, errorMessage: nil)
                }
            case .failure(let error):
                let message = (error as NSError).localizedDescription
                Task { @MainActor [weak self] in
                    self?.apply(snapshot: nil, errorMessage: message)
                }
            }
        }
    }

    func start() {
        provider.start()
    }

    func stop() {
        provider.stop()
    }

    func refresh() {
        provider.refreshNow()
    }

    private func apply(snapshot: RateLimitSnapshot?, errorMessage: String?) {
        isLoading = false

        if let snapshot {
            self.snapshot = snapshot
            self.errorMessage = nil
            return
        }

        self.errorMessage = errorMessage
    }
}
