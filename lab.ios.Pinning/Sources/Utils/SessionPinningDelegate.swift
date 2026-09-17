import CryptoKit
import Foundation
import Security

struct SPKIPin: Hashable, Sendable {
    private static let prefix = "sha256/"
    let digest: Data

    init(_ value: String) throws {
        guard value.hasPrefix(Self.prefix),
              let digest = Data(base64Encoded: String(value.dropFirst(Self.prefix.count))),
              digest.count == SHA256.byteCount
        else {
            throw SPKIPinningError.invalidPin(value)
        }
        self.digest = digest
    }

    init(digest: Data) {
        self.digest = digest
    }

    var description: String {
        Self.prefix + digest.base64EncodedString()
    }
}

enum SPKIPinningError: LocalizedError, Equatable {
    case invalidPin(String)
    case unsupportedKey

    var errorDescription: String? {
        switch self {
        case let .invalidPin(value):
            "Invalid SPKI pin: \(value)"
        case .unsupportedKey:
            "The server certificate does not use a supported P-256 public key."
        }
    }
}

enum SPKIHasher {
    // ASN.1 SubjectPublicKeyInfo prefix for an uncompressed P-256 public key.
    private static let p256Header = Data([
        0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86,
        0x48, 0xce, 0x3d, 0x02, 0x01, 0x06, 0x08, 0x2a,
        0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
        0x42, 0x00,
    ])

    static func pin(for certificate: SecCertificate) throws -> SPKIPin {
        guard let publicKey = SecCertificateCopyKey(certificate),
              let attributes = SecKeyCopyAttributes(publicKey) as? [CFString: Any]
        else {
            throw SPKIPinningError.unsupportedKey
        }
        let keyType = attributes[kSecAttrKeyType] as! CFString
        guard CFEqual(keyType, kSecAttrKeyTypeECSECPrimeRandom),
              attributes[kSecAttrKeySizeInBits] as? Int == 256
        else {
            throw SPKIPinningError.unsupportedKey
        }

        var extractionError: Unmanaged<CFError>?
        guard let rawKey = SecKeyCopyExternalRepresentation(publicKey, &extractionError) as Data? else {
            if let extractionError {
                throw extractionError.takeRetainedValue()
            }
            throw SPKIPinningError.unsupportedKey
        }

        return try pin(p256PublicKey: rawKey)
    }

    static func pin(p256PublicKey rawKey: Data) throws -> SPKIPin {
        guard rawKey.count == 65, rawKey.first == 0x04 else {
            throw SPKIPinningError.unsupportedKey
        }
        let digest = SHA256.hash(data: p256Header + rawKey)
        return SPKIPin(digest: Data(digest))
    }
}

final class SessionPinningDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let expectedHost: String
    private let allowedPins: Set<SPKIPin>

    init(expectedHost: String, allowedPins: Set<SPKIPin>) {
        self.expectedHost = expectedHost
        self.allowedPins = allowedPins
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
        guard challenge.protectionSpace.host == expectedHost,
              let trust = challenge.protectionSpace.serverTrust,
              SecTrustEvaluateWithError(trust, nil),
              let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let leaf = chain.first,
              let serverPin = try? SPKIHasher.pin(for: leaf),
              allowedPins.contains(serverPin)
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
