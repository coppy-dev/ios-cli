import Foundation

struct Coppy {
    static func loadConfig(configUrl: URL) throws -> CoppyConfig {
        guard let config = NSDictionary(contentsOf: configUrl) as? [String: Any] else {
            throw CoppyError.incorrectConfigFile
        }
        
        guard let contentKey = config["ContentKey"] as? String else { throw CoppyError.missingConfigKey }
        
        return CoppyConfig(contentKey: contentKey)
    }
    
    static func download(config: CoppyConfig) async throws -> [String:Any] {
        guard let url = URL(string: String(format: "https://content.coppy.app/%@/content", config.contentKey)) else {
            print(config.contentKey)
            throw CoppyError.invalidContentKey
        }
        
        // Send a request to the URL and download the JSON file
        let session = URLSession.shared
        let (data, _) = try await session.data(from: url)
        
        let result = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        
        guard let result = result as? [String: Any] else { throw CoppyError.contentHasWrongFormatOrMissing }
        
        return result
    }
}

enum CoppyError: Error {
    case incorrectConfigFile
    case missingConfigKey
    case invalidContentKey
    case errorDownloadingContentData
    case missingContentData
    case errorWritingContentDataToFile
    case contentHasWrongFormatOrMissing
}

struct CoppyConfig {
    let contentKey: String
}
