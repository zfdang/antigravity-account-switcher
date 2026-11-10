import Foundation

/// An opaque Antigravity credential. Raw bytes are never written to logs.
public struct Credential {
    public let json: Data
    public let email: String?
    public let subject: String?

    public enum ParseError: Error { case invalidEncoding, invalidJSON, missingToken }

    public init(raw: Data) throws {
        let prefix = "go-keyring-base64:"
        let data: Data
        if let string = String(data: raw, encoding: .utf8), string.hasPrefix(prefix) {
            guard let decoded = Data(base64Encoded: String(string.dropFirst(prefix.count))) else { throw ParseError.invalidEncoding }
            data = decoded
        } else { data = raw }
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw ParseError.invalidJSON }
        guard let token = object["token"] as? [String: Any], let refresh = token["refresh_token"] as? String, !refresh.isEmpty else { throw ParseError.missingToken }
        var claims: [String: Any] = [:]
        if let jwt = object["id_token"] as? String {
            let parts = jwt.split(separator: ".", omittingEmptySubsequences: false)
            if parts.count == 3 {
                var payload = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
                payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
                if let decoded = Data(base64Encoded: payload), let value = try? JSONSerialization.jsonObject(with: decoded) as? [String: Any] { claims = value }
            }
        }
        self.json = data
        self.email = claims["email"] as? String ?? object["id_token_email"] as? String
        self.subject = claims["sub"] as? String
    }

    public var keychainValue: Data { Data(("go-keyring-base64:" + json.base64EncodedString()).utf8) }
}
