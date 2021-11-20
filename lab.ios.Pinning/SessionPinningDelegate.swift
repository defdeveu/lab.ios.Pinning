import Foundation

class SessionPinningDelegate: NSObject, URLSessionDelegate {
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Adapted from OWASP https://www.owasp.org/index.php/Certificate_and_Public_Key_Pinning#iOS
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              SecTrustEvaluateWithError(serverTrust, nil),
              let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
        else {
            // Pinning failed
            completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
            return
        }
        
        let serverCertificateData = SecCertificateCopyData(serverCertificate)
        let data = CFDataGetBytePtr(serverCertificateData);
        let size = CFDataGetLength(serverCertificateData);
        let cert1 = NSData(bytes: data, length: size)
        
        guard let file_der = Bundle.main.path(forResource: "certificate", ofType: "der"),
              let cert2 = NSData(contentsOfFile: file_der),
              cert1.isEqual(to: cert2 as Data)
        else {
            // Pinning failed
            completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Pin is ok
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust:serverTrust))
    }
}
