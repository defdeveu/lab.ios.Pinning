import Foundation
import Security

final class SessionPinningDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let expectedHost: String
    private let effectivePin: SPKIPin
    private let audit: PinAudit

    init(expectedHost: String, effectivePin: SPKIPin, audit: PinAudit) {
        self.expectedHost = expectedHost
        self.effectivePin = effectivePin
        self.audit = audit
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        guard challenge.protectionSpace.host == expectedHost else {
            audit.record(.hostMismatch(expected: expectedHost))
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        guard let trust = challenge.protectionSpace.serverTrust,
              SecTrustEvaluateWithError(trust, nil),
              let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let leaf = chain.first
        else {
            audit.record(.trustEvaluationFailed)
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        guard let servedPin = try? SPKIHasher.pin(for: leaf) else {
            audit.record(.unsupportedKey)
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        guard servedPin == effectivePin else {
            audit.record(.pinMismatch)
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
