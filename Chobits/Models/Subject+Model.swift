import Foundation
import OSLog
import SwiftData
import SwiftUI

typealias Subject = SubjectV2

@Model
final class SubjectV2: Searchable, Linkable {
  @Attribute(.unique)
  var subjectId: Int

  var airtime: SubjectAirtime
  var collection: SubjectCollection
  var eps: Int
  var images: SubjectImages?
  var infobox: Infobox
  var locked: Bool
  var metaTags: [String]
  var tags: [Tag]
  var name: String
  var nameCN: String
  var nsfw: Bool
  var platform: SubjectPlatform
  var rating: SubjectRating
  var series: Bool
  var summary: String
  var type: Int
  var volumes: Int
  var info: String = ""
  var alias: String = ""

  var ctype: Int = 0
  var collectedAt: Int = 0
  var interest: SubjectInterest?

  var positions: [SubjectPositionDTO] = []

  var characters: [SubjectCharacterDTO] = []
  var offprints: [SubjectRelationDTO] = []
  var relations: [SubjectRelationDTO] = []
  var recs: [SubjectRecDTO] = []

  var collects: [SubjectCollectDTO] = []
  var reviews: [SubjectReviewDTO] = []
  var topics: [TopicDTO] = []
  var comments: [SubjectCommentDTO] = []

  var typeEnum: SubjectType {
    return SubjectType(type)
  }

  var ctypeEnum: CollectionType {
    return CollectionType(ctype)
  }

  var title: String {
    nameCN.isEmpty ? name : nameCN
  }

  var category: String {
    if platform.typeCN.isEmpty {
      return typeEnum.description
    } else {
      if series {
        return "\(platform.typeCN)系列"
      } else {
        return platform.typeCN
      }
    }
  }

  var epsDesc: String {
    return self.eps > 0 ? "\(self.eps)" : "??"
  }

  var volumesDesc: String {
    return self.volumes > 0 ? "\(self.volumes)" : "??"
  }

  var link: String {
    return "chii://subject/\(subjectId)"
  }

  var slim: SlimSubjectDTO {
    SlimSubjectDTO(self)
  }

  init(_ item: SubjectDTO) {
    self.subjectId = item.id
    self.airtime = item.airtime
    self.collection = item.collection
    self.eps = item.eps
    self.images = item.images
    self.infobox = item.infobox.clean()
    self.info = item.info
    self.locked = item.locked
    self.metaTags = item.metaTags
    self.tags = item.tags
    self.name = item.name
    self.nameCN = item.nameCN
    self.nsfw = item.nsfw
    self.platform = item.platform
    self.rating = item.rating
    self.series = item.series
    self.summary = item.summary
    self.type = item.type.rawValue
    self.volumes = item.volumes
    self.interest = item.interest
    if let interest = item.interest {
      self.ctype = interest.type.rawValue
      self.collectedAt = interest.updatedAt
    }
    self.alias = item.infobox.aliases.joined(separator: " ")
  }

  init(_ item: SlimSubjectDTO) {
    self.subjectId = item.id
    self.airtime = SubjectAirtime(date: "")
    self.collection = [:]
    self.eps = 0
    self.images = item.images
    self.infobox = []
    self.info = item.info ?? ""
    self.locked = item.locked
    self.metaTags = []
    self.tags = []
    self.name = item.name
    self.nameCN = item.nameCN
    self.nsfw = item.nsfw
    self.platform = SubjectPlatform(name: "")
    self.rating = item.rating ?? SubjectRating()
    self.series = false
    self.summary = ""
    self.type = item.type.rawValue
    self.volumes = 0
    self.alias = ""
    self.interest = nil
  }

  func update(_ item: SubjectDTO) {
    if self.airtime != item.airtime { self.airtime = item.airtime }
    if self.collection != item.collection { self.collection = item.collection }
    if self.eps != item.eps { self.eps = item.eps }
    if let images = item.images, self.images != images { self.images = images }
    if self.infobox != item.infobox.clean() { self.infobox = item.infobox.clean() }
    if self.info != item.info { self.info = item.info }
    if self.locked != item.locked { self.locked = item.locked }
    if self.metaTags != item.metaTags { self.metaTags = item.metaTags }
    if self.tags != item.tags { self.tags = item.tags }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.platform != item.platform { self.platform = item.platform }
    if self.rating != item.rating { self.rating = item.rating }
    if self.series != item.series { self.series = item.series }
    if self.summary != item.summary { self.summary = item.summary }
    if self.type != item.type.rawValue { self.type = item.type.rawValue }
    if self.volumes != item.volumes { self.volumes = item.volumes }
    let aliases = item.infobox.aliases.joined(separator: " ")
    if self.alias != aliases { self.alias = aliases }
    if let interest = item.interest {
      if self.ctype != interest.type.rawValue { self.ctype = interest.type.rawValue }
      if self.collectedAt != interest.updatedAt { self.collectedAt = interest.updatedAt }
      if self.interest != interest { self.interest = interest }
    } else {
      if self.ctype != 0 { self.ctype = 0 }
      if self.collectedAt != 0 { self.collectedAt = 0 }
      if self.interest != nil { self.interest = nil }
    }
  }

  func update(_ item: SlimSubjectDTO) {
    if let images = item.images, self.images != images { self.images = images }
    if let info = item.info, self.info != info { self.info = info }
    if let rating = item.rating, self.rating != rating { self.rating = rating }
    if self.locked != item.locked { self.locked = item.locked }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.type != item.type.rawValue { self.type = item.type.rawValue }
  }

  func nextEpisodeDays(context: ModelContext) -> Int {
    guard typeEnum == .anime || typeEnum == .real else {
      return Int.max
    }
    
    do {
      // 查找该条目的第一个未看的主要剧集
      let currentSubjectId = self.subjectId
      let descriptor = FetchDescriptor<Episode>(
        predicate: #Predicate<Episode> {
          $0.subjectId == currentSubjectId && $0.type == 0 && $0.status == 0
        },
        sortBy: [SortDescriptor<Episode>(\.sort, order: .forward)]
      )
      
      let episodes = try context.fetch(descriptor)
      
      // 没有未看的剧集，返回最低优先级
      guard let nextEpisode = episodes.first else { return Int.max }
      // 播出时间未知，返回较低优先级
      if nextEpisode.air.timeIntervalSince1970 == 0 { return Int.max - 1 }
      
      let calendar = Calendar.current
      let now = Date()
      let components = calendar.dateComponents([.day], from: now, to: nextEpisode.air)
      
      if let days = components.day {
        if days < 0 {
          // 已经播出但未看，优先级最高
          return -days
        } else {
          // 还未播出，按天数排序
          return days
        }
      }
      return Int.max
    } catch { return Int.max }
  }
}
