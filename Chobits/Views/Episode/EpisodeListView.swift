import OSLog
import SwiftData
import SwiftUI

struct EpisodeListView: View {
  let subjectId: Int

  @Environment(\.modelContext) var modelContext

  @State private var refreshed: Bool = false
  @State private var countMain: Int = 0
  @State private var countOther: Int = 0

  @State private var main: Bool = true
  @State private var filterCollection: Bool = false
  @State private var sortDesc: Bool = false

  func loadCounts() async {
    let mainType = EpisodeType.main.rawValue
    do {
      let mainDesc = FetchDescriptor<Episode>(
        predicate: #Predicate<Episode> {
          $0.subjectId == subjectId && $0.type == mainType
        })
      let countMain = try modelContext.fetchCount(mainDesc)
      self.countMain = countMain

      let otherDesc = FetchDescriptor<Episode>(
        predicate: #Predicate<Episode> {
          $0.subjectId == subjectId && $0.type != mainType
        })
      let countOther = try modelContext.fetchCount(otherDesc)
      self.countOther = countOther
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await Chii.shared.loadEpisodes(subjectId)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    HStack {
      Image(systemName: filterCollection ? "eye.slash.circle.fill" : "eye.circle.fill")
        .foregroundStyle(filterCollection ? .accent : .secondary)
        .font(.title)
        .sensoryFeedback(.selection, trigger: filterCollection)
        .onTapGesture {
          self.filterCollection.toggle()
        }
      Spacer()
      Picker("Episode Type", selection: $main) {
        Text("本篇(\(countMain))").tag(true)
        Text("其他(\(countOther))").tag(false)
      }
      .pickerStyle(.segmented)
      Spacer()
      Image(systemName: sortDesc ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
        .foregroundStyle(sortDesc ? .accent : .secondary)
        .font(.title)
        .sensoryFeedback(.selection, trigger: sortDesc)
        .onTapGesture {
          self.sortDesc.toggle()
        }
    }.padding(.horizontal, 8)
    EpisodeListDetailView(
      subjectId: subjectId, sortDesc: sortDesc,
      main: main, filterCollection: filterCollection
    )
    .navigationTitle("章节列表")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
    .onAppear {
      Task {
        await loadCounts()
        await refresh()
        await loadCounts()
      }
    }
  }
}

struct EpisodeListDetailView: View {
  let subjectId: Int
  let sortDesc: Bool
  let main: Bool
  let filterCollection: Bool

  @Environment(\.modelContext) var modelContext

  @Query private var episodes: [Episode]

  init(subjectId: Int, sortDesc: Bool, main: Bool, filterCollection: Bool) {
    self.subjectId = subjectId
    self.sortDesc = sortDesc
    self.main = main
    self.filterCollection = filterCollection

    let sortBy =
      sortDesc ? SortDescriptor<Episode>(\.sort, order: .reverse) : SortDescriptor<Episode>(\.sort)
    let mainType = EpisodeType.main.rawValue

    // 将复杂的条件从 #Predicate 中移出，按分支选择简单谓词，避免类型检查开销
    let predicate: Predicate<Episode>
    if main && filterCollection {
      predicate = #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == mainType && $0.status == 0
      }
    } else if main {
      predicate = #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == mainType
      }
    } else if filterCollection {
      predicate = #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type != mainType && $0.status == 0
      }
    } else {
      predicate = #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type != mainType
      }
    }

    let descriptor = FetchDescriptor<Episode>(predicate: predicate, sortBy: [sortBy])
    _episodes = Query(descriptor)
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 10) {
        ForEach(episodes) { item in
          EpisodeRowView().environment(item)
        }
      }.padding(.horizontal, 8)
    }.animation(.default, value: episodes)
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)
  let episodes = Episode.previewAnime
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return EpisodeListView(subjectId: subject.subjectId)
    .modelContainer(container)
}
