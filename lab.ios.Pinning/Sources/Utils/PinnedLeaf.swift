import CryptoKit
import Foundation
import Security

struct SPKIPin: Hashable, Sendable {
    private static let prefix = "sha256/"
    private static let digestByteCount = 32

    let digest: Data

    init(_ value: String) throws {
        guard value.hasPrefix(Self.prefix),
              let digest = Data(base64Encoded: String(value.dropFirst(Self.prefix.count))),
              digest.count == Self.digestByteCount
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

enum LeafPinSimulator {
    static let brokenCharacterCount = 7

    static func broken(_ pin: String, using generator: inout some RandomNumberGenerator) -> String {
        guard let separator = pin.firstIndex(of: "/") else {
            return pin
        }
        let prefix = pin[...separator]
        var payload = Array(pin[pin.index(after: separator)...])
        var mutablePositions = payload.indices.filter { payload[$0] != "=" }
        guard mutablePositions.count > brokenCharacterCount else {
            return pin
        }
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
        mutablePositions.shuffle(using: &generator)
        for index in mutablePositions.prefix(brokenCharacterCount) {
            var replacement = payload[index]
            while replacement == payload[index] {
                replacement = alphabet.randomElement(using: &generator) ?? "A"
            }
            payload[index] = replacement
        }
        return prefix + String(payload)
    }
}

struct PinnedLeafStore: @unchecked Sendable {
    static let defaultsKey = "lab.ios.pinning.effectiveLeafPin"

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func effectivePin(baseline: String) -> String {
        defaults.string(forKey: Self.defaultsKey) ?? baseline
    }

    func store(_ pin: String) {
        defaults.set(pin, forKey: Self.defaultsKey)
    }

    func restore() {
        defaults.removeObject(forKey: Self.defaultsKey)
    }
}

enum PinRejection: Equatable, Sendable {
    case hostMismatch(expected: String)
    case trustEvaluationFailed
    case unsupportedKey
    case pinMismatch
}

final class PinAudit: @unchecked Sendable {
    private let lock = NSLock()
    private var rejection: PinRejection?

    func record(_ rejection: PinRejection) {
        lock.lock()
        defer { lock.unlock() }
        self.rejection = rejection
    }

    func take() -> PinRejection? {
        lock.lock()
        defer { lock.unlock() }
        let value = rejection
        rejection = nil
        return value
    }
}
