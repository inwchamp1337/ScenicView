import Foundation

struct Photo: Codable {
    let image_url: [String]
    let name: String
    let description: String
    let positive_votes_count: Int
}

struct PhotoResponse: Codable {
    let photos: [Photo]
}
