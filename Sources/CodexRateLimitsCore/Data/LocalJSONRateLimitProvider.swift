import Foundation

public final class LocalJSONRateLimitProvider: RateLimitProviding, @unchecked Sendable {
    public var onSnapshot: RateLimitProviderHandler?

    private let fileURL: URL
    private let pollInterval: TimeInterval
    private let queue = DispatchQueue(label: "com.codexratelimits.local-json-provider")
    private var timer: DispatchSourceTimer?
    private var lastFingerprint: FileFingerprint?

    public init(fileURL: URL, pollInterval: TimeInterval = 2) {
        self.fileURL = fileURL
        self.pollInterval = pollInterval
    }

    deinit {
        stop()
    }

    public func start() {
        queue.async { [weak self] in
            guard let self, self.timer == nil else { return }

            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(deadline: .now(), repeating: self.pollInterval)
            timer.setEventHandler { [weak self] in
                self?.loadIfChanged()
            }

            self.timer = timer
            timer.resume()
        }
    }

    public func stop() {
        queue.async { [weak self] in
            self?.timer?.cancel()
            self?.timer = nil
        }
    }

    public func refreshNow() {
        queue.async { [weak self] in
            self?.load(force: true)
        }
    }

    public func readSnapshot() throws -> RateLimitSnapshot {
        let data = try Data(contentsOf: fileURL)
        let snapshot = try Self.decode(data)
        return snapshot.replacingSourceDescription(fileURL.path)
    }

    public static func decode(_ data: Data) throws -> RateLimitSnapshot {
        try RateLimitJSON.decoder().decode(RateLimitSnapshot.self, from: data)
    }

    private func loadIfChanged() {
        do {
            let fingerprint = try makeFingerprint()
            guard fingerprint != lastFingerprint else { return }
            load(force: true)
        } catch {
            emit(.failure(error))
        }
    }

    private func load(force: Bool) {
        do {
            let fingerprint = try makeFingerprint()
            if !force, fingerprint == lastFingerprint {
                return
            }

            let snapshot = try readSnapshot()
            lastFingerprint = fingerprint
            emit(.success(snapshot))
        } catch {
            emit(.failure(error))
        }
    }

    private func emit(_ result: Result<RateLimitSnapshot, Error>) {
        onSnapshot?(result)
    }

    private func makeFingerprint() throws -> FileFingerprint {
        let values = try fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
        return FileFingerprint(
            modifiedAt: values.contentModificationDate,
            fileSize: values.fileSize
        )
    }
}

private struct FileFingerprint: Equatable {
    var modifiedAt: Date?
    var fileSize: Int?
}
