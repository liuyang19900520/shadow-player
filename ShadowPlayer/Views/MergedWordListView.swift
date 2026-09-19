import SwiftUI
import UIKit

/// The combined, editable word list for a whole playlist (all videos' words in
/// one). Mirrors the player's word list: two-line rows and the same meanings
/// switch, which is shared app-wide.
struct MergedWordListView: View {
    @StateObject private var store: MergedWordListStore
    private let scope: TranslationScope

    @AppStorage(TranslationDefaults.enabledKey) private var showMeanings = false
    @AppStorage private var sourceRaw: String
    @AppStorage private var target: TranslationLanguage

    @Environment(\.dismiss) private var dismiss

    @FocusState private var focused: Field?
    @State private var job: TranslationJob?
    @State private var isTranslating = false
    @State private var showLanguages = false
    /// The row last edited, so finishing input can return to it.
    @State private var lastEditedID: UUID?

    /// Anchor at the end of the list, used to park the list at the bottom.
    private let bottomAnchor = "mergedWordListBottom"

    private enum Field: Hashable {
        case word(UUID)
        case meaning(UUID)

        var entryID: UUID {
            switch self {
            case .word(let id), .meaning(let id): return id
            }
        }
    }

    init(videoIDs: [String], scope: TranslationScope) {
        _store = StateObject(wrappedValue: MergedWordListStore(videoIDs: videoIDs))
        self.scope = scope
        _sourceRaw = AppStorage(wrappedValue: TranslationDefaults.autoSource, scope.sourceKey)
        _target = AppStorage(wrappedValue: .chinese, scope.targetKey)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    if isTranslationAvailable {
                        Section {
                            translationControls
                        }
                    }

                    Section {
                        ForEach(store.items) { item in
                            row(item)
                        }
                        .onDelete { store.delete(atOffsets: $0) }

                        addWordRow
                    } header: {
                        wordsHeader
                    } footer: {
                        if store.items.isEmpty {
                            Text("Words you add while watching each video show up here.")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollDismissesKeyboard(.interactively)
                .navigationTitle("Combined Words")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                    // Finishing input translates what was just typed and keeps
                    // the list where the user was working.
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { finishEditing(proxy) }
                    }
                }
                .sheet(isPresented: $showLanguages) {
                    TranslationSettingsView(scope: scope)
                }
                .translationBackfill(job: job) { results in
                    store.applyTranslations(results)
                    job = nil
                    isTranslating = false
                    restoreScroll(proxy)
                }
                .onAppear { backfill() }
                .onChange(of: showMeanings) { enabled in
                    if enabled { backfill() }
                }
                .onChange(of: sourceRaw) { _ in backfill() }
                .onChange(of: target) { _ in backfill() }
                .onChange(of: focused) { field in
                    if let field { lastEditedID = field.entryID }
                }
            }
        }
    }

    // MARK: - Pieces

    /// The spinner sits in the header rather than a footer, which would change
    /// the section's height and knock the list out of position.
    private var wordsHeader: some View {
        HStack {
            Text("Words")
            Spacer()
            if isTranslating {
                ProgressView().controlSize(.mini)
            }
        }
    }

    /// Settings-style rows, matching the player's word list.
    @ViewBuilder
    private var translationControls: some View {
        Toggle("Show meanings", isOn: $showMeanings)

        if showMeanings {
            Button {
                showLanguages = true
            } label: {
                HStack {
                    Text("Languages")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(translationPairSummary(sourceRaw: sourceRaw, target: target))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func row(_ item: MergedWord) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField("Word", text: Binding(
                get: { item.text },
                set: { store.setText($0, for: item.id) }
            ))
            .font(.body)
            .autocorrectionDisabled()
            .focused($focused, equals: .word(item.id))
            .onSubmit { backfill() }

            if showMeanings && isTranslationAvailable {
                // The placeholder names the language the meaning will be in.
                TextField(target.label, text: Binding(
                    get: { item.translation ?? "" },
                    set: { store.setTranslation($0, for: item.id) }
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .autocorrectionDisabled()
                .focused($focused, equals: .meaning(item.id))
            }
        }
        .padding(.vertical, 2)
    }

    /// One blank row at a time, so repeated taps can't leave stray empties.
    private var hasBlankRow: Bool {
        store.items.contains { $0.trimmedText.isEmpty }
    }

    private var addWordRow: some View {
        Button {
            if let id = store.addEmpty() {
                lastEditedID = id
                focused = .word(id)
            }
        } label: {
            Label("Add word", systemImage: "plus")
        }
        .disabled(hasBlankRow)
        .id(bottomAnchor)
    }

    // MARK: - Editing

    private func finishEditing(_ proxy: ScrollViewProxy) {
        focused = nil
        backfill()
        restoreScroll(proxy)
    }

    /// Editing the last row parks the list at the bottom, which is where a
    /// freshly added word lives.
    private func restoreScroll(_ proxy: ScrollViewProxy) {
        guard let id = lastEditedID else { return }
        let editingLast = store.items.last?.id == id
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                if editingLast {
                    proxy.scrollTo(bottomAnchor, anchor: .bottom)
                } else {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }

    // MARK: - Translation

    private func backfill() {
        guard showMeanings, isTranslationAvailable, !isTranslating else { return }
        let items = store.untranslated
        guard !items.isEmpty else { return }
        isTranslating = true
        job = TranslationJob(
            items: items,
            sourceIdentifier: sourceRaw.isEmpty ? nil : sourceRaw,
            targetIdentifier: target.rawValue
        )
    }
}
