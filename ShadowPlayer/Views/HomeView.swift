import SwiftUI
import Photos

/// First screen: pick a video + recent-playback list.
struct HomeView: View {
    @StateObject private var recent = RecentStore()
    @State private var showPicker = false
    @State private var showDeniedAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectVideos()
                    } label: {
                        Label("Select Video", systemImage: "plus.circle.fill")
                            .font(.body.weight(.medium))
                    }
                }

                if recent.items.isEmpty {
                    Section {
                        Text("No videos yet. Tap “Select Video” above to start.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Recent") {
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
                VideoPicker(onPicked: { recent.addMany($0) })
                    .ignoresSafeArea()
            }
            .alert("Can’t Access Photos", isPresented: $showDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please allow ShadowPlayer to access your photos in Settings to select and play videos.")
            }
        }
    }

    private func row(_ video: PickedVideo) -> some View {
        HStack(spacing: 12) {
            ThumbnailView(assetID: video.id)
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

    /// Requests photo-library permission, then opens the picker.
    private func selectVideos() {
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if status == .authorized || status == .limited {
                showPicker = true
            } else {
                showDeniedAlert = true
            }
        }
    }
}
