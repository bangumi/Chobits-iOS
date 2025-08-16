import Foundation
import OSLog
import SwiftData
import SwiftUI

extension Chii {
  func loadUser(_ username: String) async throws -> UserDTO {
    let db = try self.getDB()
    let item = try await self.getUser(username)
    try await db.saveUser(item)
    try await db.commit()
    return item
  }

  func loadCalendar() async throws {
    let db = try self.getDB()
    let response = try await self.getCalendar()
    for (weekday, items) in response {
      guard let weekday = Int(weekday) else {
        Logger.api.error("invalid weekday: \(weekday)")
        continue
      }
      try await db.saveCalendarItem(weekday: weekday, items: items)
    }
    try await db.commit()
  }

  func loadTrendingSubjects() async throws {
    let db = try self.getDB()
    for type in SubjectType.allTypes {
      let response = try await self.getTrendingSubjects(type: type)
      try await db.saveTrendingSubjects(type: type.rawValue, items: response.data)
      try await db.commit()
    }
  }

  func loadSubject(_ sid: Int) async throws -> SubjectDTO {
    let db = try self.getDB()
    let item = try await self.getSubject(sid)

    // 对于合并的条目，可能搜索返回的 ID 跟 API 拿到的 ID 不同
    // 我们直接返回 404 防止其他问题
    // 后面可以考虑直接跳转到页面
    if sid != item.id {
      Logger.api.warning("subject id mismatch: \(sid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的条目")
    }

    try await db.saveSubject(item)
    if item.interest != nil {
      await self.index([item.searchable()])
    }
    try await db.commit()
    return item
  }

  func loadSubjectDetails(_ subjectId: Int, offprints: Bool, social: Bool) async throws {
    let collectsModeDefaults = UserDefaults.standard.string(forKey: "subjectCollectsFilterMode")
    let collectsMode = FilterMode(collectsModeDefaults)

    let db = try self.getDB()

    // 并发获取数据，随后顺序保存到数据库，避免 TaskGroup 触发的隔离检查问题
    async let charactersResp = self.getSubjectCharacters(subjectId, limit: 12)
    async let relationsResp = self.getSubjectRelations(subjectId, limit: 10)
    async let recsResp = self.getSubjectRecs(subjectId, limit: 10)

    if offprints {
      async let offprintsResp = self.getSubjectRelations(subjectId, offprint: true, limit: 100)
      let offprintsVal = try await offprintsResp
      try await db.saveSubjectOffprints(subjectId: subjectId, items: offprintsVal.data)
    }

    if social {
      async let collectsResp = self.getSubjectCollects(subjectId, mode: collectsMode, limit: 10)
      async let reviewsResp = self.getSubjectReviews(subjectId, limit: 5)
      async let topicsResp = self.getSubjectTopics(subjectId, limit: 5)
      async let commentsResp = self.getSubjectComments(subjectId, limit: 10)

      let (collectsVal, reviewsVal, topicsVal, commentsVal) = try await (collectsResp, reviewsResp, topicsResp, commentsResp)
      try await db.saveSubjectCollects(subjectId: subjectId, items: collectsVal.data)
      try await db.saveSubjectReviews(subjectId: subjectId, items: reviewsVal.data)
      try await db.saveSubjectTopics(subjectId: subjectId, items: topicsVal.data)
      try await db.saveSubjectComments(subjectId: subjectId, items: commentsVal.data)
    }

    let (charactersVal, relationsVal, recsVal) = try await (charactersResp, relationsResp, recsResp)
    try await db.saveSubjectCharacters(subjectId: subjectId, items: charactersVal.data)
    try await db.saveSubjectRelations(subjectId: subjectId, items: relationsVal.data)
    try await db.saveSubjectRecs(subjectId: subjectId, items: recsVal.data)

    try await db.commit()
  }

  func loadSubjectPositions(_ subjectId: Int) async throws {
    let db = try self.getDB()
    let limit: Int = 100
    var offset: Int = 0
    var items: [SubjectPositionDTO] = []
    while true {
      let response = try await self.getSubjectStaffPositions(
        subjectId, limit: limit, offset: offset)
      if response.data.isEmpty {
        break
      }
      items.append(contentsOf: response.data)
      offset += limit
      if offset > response.total {
        break
      }
    }
    try await db.saveSubjectPositions(subjectId: subjectId, items: items)
    try await db.commit()
  }

  func loadEpisodes(_ subjectId: Int) async throws {
    let db = try self.getDB()
    var offset: Int = 0
    let limit: Int = 1000
    var total: Int = 0
    var items: [EpisodeDTO] = []
    while true {
      let response = try await self.getSubjectEpisodes(
        subjectId, limit: limit, offset: offset)
      total = response.total
      if response.data.isEmpty {
        break
      }
      for item in response.data {
        items.append(item)
      }
      offset += limit
      if offset > total {
        break
      }
    }
    for item in items {
      try await db.saveEpisode(item)
    }
    try await db.commit()
  }

  func loadEpisode(_ episodeId: Int) async throws {
    let db = try self.getDB()
    let item = try await self.getEpisode(episodeId)
    try await db.saveEpisode(item)
    try await db.commit()
  }
}

extension Chii {
  func loadCharacter(_ cid: Int) async throws {
    let db = try self.getDB()
    let item = try await self.getCharacter(cid)
    if cid != item.id {
      Logger.api.warning("character id mismatch: \(cid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的角色")
    }
    try await db.saveCharacter(item)
    if item.collectedAt != nil {
      await self.index([item.searchable()])
    }
    try await db.commit()
  }

  func loadCharacterDetails(_ characterId: Int) async throws {
    let db = try self.getDB()
    // 单一请求无需 TaskGroup，直接获取后保存
    let response = try await self.getCharacterCasts(characterId, limit: 5)
    try await db.saveCharacterCasts(characterId: characterId, items: response.data)
    try await db.commit()
  }

  func loadPerson(_ pid: Int) async throws {
    let db = try self.getDB()
    let item = try await self.getPerson(pid)
    if pid != item.id {
      Logger.api.warning("person id mismatch: \(pid) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的人物")
    }
    try await db.savePerson(item)
    if item.collectedAt != nil {
      await self.index([item.searchable()])
    }
    try await db.commit()
  }

  func loadPersonDetails(_ personId: Int) async throws {
    let db = try self.getDB()

    async let castsResp = self.getPersonCasts(personId, limit: 5)
    async let worksResp = self.getPersonWorks(personId, limit: 5)
    let (castsVal, worksVal) = try await (castsResp, worksResp)

    try await db.savePersonCasts(personId: personId, items: castsVal.data)
    try await db.savePersonWorks(personId: personId, items: worksVal.data)
    try await db.commit()
  }
}

extension Chii {
  func loadGroup(_ name: String) async throws {
    let db = try self.getDB()
    let item = try await self.getGroup(name)
    try await db.saveGroup(item)
    try await db.commit()
  }

  func loadGroupDetails(_ name: String) async throws {
    let db = try self.getDB()

    async let membersResp = self.getGroupMembers(name, role: .member, limit: 10)
    async let moderatorsResp = self.getGroupMembers(name, role: .moderator, limit: 10)
    async let topicsResp = self.getGroupTopics(name, limit: 10)

    let (membersVal, moderatorsVal, topicsVal) = try await (membersResp, moderatorsResp, topicsResp)

    try await db.saveGroupRecentMembers(groupName: name, items: membersVal.data)
    try await db.saveGroupModerators(groupName: name, items: moderatorsVal.data)
    try await db.saveGroupRecentTopics(groupName: name, items: topicsVal.data)

    try await db.commit()
  }
}
