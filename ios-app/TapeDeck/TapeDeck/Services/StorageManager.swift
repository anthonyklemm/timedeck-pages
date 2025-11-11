import Foundation

class StorageManager: ObservableObject {
    private let defaults = UserDefaults.standard
    private let keychainService = "com.tapedecktimemachine.app"

    // MARK: - User IDs

    var anonUserId: String {
        get {
            if let existing = defaults.string(forKey: "tdtm_uid_v1") {
                return existing
            }
            let new = UUID().uuidString
            defaults.set(new, forKey: "tdtm_uid_v1")
            return new
        }
    }

    var sessionId: String {
        get {
            let key = "tdtm_sid_v1"
            let ttlMs: TimeInterval = 30 * 60 * 1000

            if let stored = defaults.dictionary(forKey: key) as? [String: Any],
               let id = stored["id"] as? String,
               let lastTimestamp = stored["last"] as? TimeInterval {
                let now = Date().timeIntervalSince1970 * 1000
                if now - lastTimestamp < ttlMs {
                    return id
                }
            }

            let new = UUID().uuidString
            let now = Date().timeIntervalSince1970 * 1000
            defaults.set(["id": new, "last": now], forKey: key)
            return new
        }
    }

    // MARK: - Auth Tokens

    var appleMusicUserToken: String? {
        get { getFromKeychain("appleMusicUserToken") }
        set {
            if let value = newValue {
                setInKeychain(value, key: "appleMusicUserToken")
            } else {
                deleteFromKeychain("appleMusicUserToken")
            }
        }
    }

    var spotifyAccessToken: String? {
        get { getFromKeychain("spotifyAccessToken") }
        set {
            if let value = newValue {
                setInKeychain(value, key: "spotifyAccessToken")
            } else {
                deleteFromKeychain("spotifyAccessToken")
            }
        }
    }

    // MARK: - Form State

    func getFormState() -> [String: Any] {
        defaults.dictionary(forKey: "td_form") ?? [:]
    }

    func setFormState(_ state: [String: Any]) {
        defaults.set(state, forKey: "td_form")
    }

    func clearFormState() {
        defaults.removeObject(forKey: "td_form")
    }

    // MARK: - Last Tracks

    func getLastTracks() -> [[String: String]]? {
        defaults.array(forKey: "td_lastTracks") as? [[String: String]]
    }

    func setLastTracks(_ tracks: [[String: String]]) {
        defaults.set(tracks, forKey: "td_lastTracks")
    }

    // MARK: - Analytics Opt-Out

    @Published var analyticsOptOut: Bool {
        didSet {
            defaults.set(analyticsOptOut, forKey: "analytics_opt_out")
        }
    }

    // MARK: - Init

    override init() {
        self.analyticsOptOut = defaults.bool(forKey: "analytics_opt_out")
        super.init()
    }

    // MARK: - Keychain Helpers

    private func setInKeychain(_ value: String, key: String) {
        let data = value.data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing
        SecItemDelete(query as CFDictionary)

        // Add new
        SecItemAdd(query as CFDictionary, nil)
    }

    private func getFromKeychain(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private func deleteFromKeychain(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
