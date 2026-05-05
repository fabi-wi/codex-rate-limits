import Foundation

public typealias RateLimitProviderHandler = (Result<RateLimitSnapshot, Error>) -> Void

public protocol RateLimitProviding: AnyObject {
    var onSnapshot: RateLimitProviderHandler? { get set }

    func start()
    func stop()
    func refreshNow()
}
