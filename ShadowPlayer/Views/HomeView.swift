import SwiftUI

/// 第一页：选择视频 + 最近播放列表。
struct HomeView: View {
    @StateObject private var recent = RecentStore()
    @State private var showPicker = false
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showPicker = true
                    } label: {
                        Label("选择视频", systemImage: "plus.circle.fill")
                            .font(.body.weight(.medium))
                    }
                }

                if recent.items.isEmpty {
                    Section {
                        Text("还没有播放记录，点上面「选择视频」开始。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("最近播放") {
                        ForEach(recent.items) { video in
                            NavigationLink(value: video) {
                                row(video)
                            }
                        }
                        .onDelete { recent.remove(atOffsets: $0) }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("ShadowPlayer")
            .navigationDestination(for: PickedVideo.self) { video in
                PlayerView(video: video, onStart: { recent.bump(video) })
            }
            .sheet(isPresented: $showPicker) {
                VideoPicker(
                    onBegin: { isImporting = true },
                    onPicked: { added in
                        recent.addMany(added)
                        isImporting = false
                    }
                )
                .ignoresSafeArea()
            }
            .overlay {
                if isImporting { importingOverlay }
            }
        }
    }

    private func row(_ video: PickedVideo) -> some View {
        HStack(spacing: 12) {
            ThumbnailView(url: video.url)
                .frame(width: 72, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(formatTime(video.duration))
                .font(.body.monospacedDigit())
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(.tint)
        }
        .padding(.vertical, 4)
    }

    private var importingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                Text("正在导入…")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
