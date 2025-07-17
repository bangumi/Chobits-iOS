import OSLog
import SwiftData
import SwiftUI

struct ProgressListView: View {
  let subjectType: SubjectType
  let search: String

  @AppStorage("progressLimit") var progressLimit: Int = 50

  @Environment(\.modelContext) var modelContext

  @Query var subjects: [Subject]

  init(subjectType: SubjectType, search: String) {
    self.subjectType = subjectType
    self.search = search

    let stype = subjectType.rawValue
    let doingType = CollectionType.doing.rawValue
    var descriptor = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        (stype == 0 || $0.type == stype) && $0.ctype == doingType
          && (search == "" || $0.name.localizedStandardContains(search)
            || $0.alias.localizedStandardContains(search))
      },
      sortBy: [
        SortDescriptor(\.collectedAt, order: .reverse)
      ])
    if progressLimit > 0 {
      descriptor.fetchLimit = progressLimit
    }
    self._subjects = Query(descriptor)
  }

  var sortedSubjects: [Subject] {
    return subjects.sorted { subject1, subject2 in
      let days1 = subject1.nextEpisodeDays(context: modelContext)
      let days2 = subject2.nextEpisodeDays(context: modelContext)
      
      // 优先显示已播出但未看的剧集 (负数天数)
      if days1 < 0 && days2 >= 0 {
        return true
      } else if days1 >= 0 && days2 < 0 {
        return false
      } else if days1 < 0 && days2 < 0 {
        // 两个都是已播出，按绝对值排序（播出时间越近越优先）
        return abs(days1) < abs(days2)
      } else {
        // 两个都是未播出或没有剧集信息，按天数排序
        return days1 < days2
      }
    }
  }

  var body: some View {
    LazyVStack(alignment: .leading) {
      ForEach(sortedSubjects) { subject in
        CardView {
          ProgressListItemView(subjectId: subject.subjectId)
            .environment(subject)
        }
      }
    }
    .padding(.horizontal, 8)
    .animation(.default, value: sortedSubjects.map(\.subjectId))
  }
}

struct ProgressListItemView: View {
  let subjectId: Int

  @Environment(Subject.self) var subject

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        ImageView(img: subject.images?.resize(.r200))
          .imageStyle(width: 72, height: 72)
          .imageType(.subject)
          .imageBadge(show: subject.interest?.private ?? false) {
            Image(systemName: "lock")
          }
          .imageLink(subject.link)
        VStack(alignment: .leading) {
          NavigationLink(value: NavDestination.subject(subjectId)) {
            VStack(alignment: .leading) {
              Text(subject.name)
                .font(.headline)
                .lineLimit(1)
              Text(subject.nameCN)
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .lineLimit(1)
            }
          }.buttonStyle(.scale)

          Spacer()

          switch subject.typeEnum {
          case .anime, .real:
            EpisodeRecentView(subjectId: subjectId, mode: .list)
              .environment(subject)

          case .book:
            SubjectBookChaptersView(mode: .row)
              .environment(subject)

          default:
            Label(
              subject.typeEnum.description,
              systemImage: subject.typeEnum.icon
            )
            .foregroundStyle(.accent)
            .font(.callout)
          }
        }
      }

      Section {
        switch subject.typeEnum {
        case .book:
          VStack(spacing: 1) {
            ProgressView(
              value: Float(min(subject.eps, subject.interest?.epStatus ?? 0)),
              total: Float(subject.eps))
            ProgressView(
              value: Float(min(subject.volumes, subject.interest?.volStatus ?? 0)),
              total: Float(subject.volumes))
          }.progressViewStyle(.linear)

        case .anime, .real:
          ProgressView(
            value: Float(min(subject.eps, subject.interest?.epStatus ?? 0)),
            total: Float(subject.eps)
          )
          .progressViewStyle(.linear)

        default:
          ProgressView(value: 0, total: 0)
            .progressViewStyle(.linear)
        }
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  let episodes = Episode.previewAnime
  container.mainContext.insert(subject)
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      ProgressListItemView(subjectId: subject.subjectId)
        .environment(subject)
        .modelContainer(container)
    }.padding()
  }
}
