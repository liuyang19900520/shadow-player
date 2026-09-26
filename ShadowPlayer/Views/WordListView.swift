import SwiftUI
import UIKit

/// Inline word-list editor shown below the video. Each row is a standard
/// two-line cell — the word on top, its meaning underneath — with
/// swipe-to-delete rather than a permanent delete button on every row.
struct WordListEditor: View {
    @ObservedObject var store: WordListStore
    private let scope: TranslationScope

    @AppStorage(TranslationDefaults.enabledKey) private var showMeanings = false
    @AppStorage private var sourceRaw: String
    @AppStorage private var target: TranslationLanguage

    @FocusState private var focused: Field?
    @State private var job: TranslationJob?
    @State private var showLanguages = false
    /// The row last edited, so finishing input can return to it instead of
    /// letting the list jump to the top.
    @State private var lastEditedID: UUID?

    /// Anchor at the end of the list, used to park the list at the bottom.
    private let bottomAnchor = "wordListBottom"

    private enum Field: Hashable {
        case word(UUID)
        case meaning(UUID)

        var entryID: UUID {
            switch self {
            case .word(let id), .meaning(let id): return id
            }
        }
    }

    init(store: WordListStore, scope: TranslationScope) {
        self.store = store
        self.scope = scope
        _sourceRaw = AppStorage(wrappedValue: TranslationDefaults.autoSource, scope.sourceKey)
        _target = AppStorage(wrappedValue: .chinese, scope.targetKey)
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                if isTranslationAvailable {
                    Section {
                        translationControls
                    }
                }

                Section {
                    ForEach($store.entries) { $entry in
                        row($entry)
                    }
                    .onDelete { store.remove(atOffsets: $0) }

                    addWordRow
                } header: {
                    wordsHeader
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                // Finishing input translates what was just typed and keeps the
                // list where the user was working.
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

    // MARK: - Pieces

    /// The progress spinner lives here rather than in a footer: a footer that
    /// appears and disappears changes the section's height and knocks the list
    /// out of position.
    private var wordsHeader: some View {
        HStack {
            Text("Words")
            Spacer()
            if job != nil {
                ProgressView().controlSize(.mini)
            }
        }
    }

    /// Settings-style rows rather than a compact header control: a full-width
    /// row gives the switch a large hit target and reads like the Settings app.
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

    private func row(_ entry: Binding<WordEntry>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField("Word", text: entry.text)
                .font(.body)
                .autocorrectionDisabled()
                .focused($focused, equals: .word(entry.wrappedValue.id))
                .onSubmit { backfill() }

            if showMeanings && isTranslationAvailable {
                // The placeholder names the language the meaning will be in.
                TextField(target.label, text: Binding(
                    get: { entry.wrappedValue.translation ?? "" },
                    set: { entry.wrappedValue.translation = $0.isEmpty ? nil : $0 }
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .autocorrectionDisabled()
                .focused($focused, equals: .meaning(entry.wrappedValue.id))
            }
        }
        .padding(.vertical, 2)
    }

    /// One blank row at a time — a second tap would only leave stray empty
    /// entries behind, so the button stays disabled until this one is filled in.
    private var hasBlankRow: Bool {
        store.entries.contains { $0.trimmedText.isEmpty }
    }

    private var addWordRow: some View {
        Button {
            let id = store.addEmpty()
            lastEditedID = id
            focused = .word(id)
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

    /// Put the row the user was editing back in view once the keyboard has gone.
    /// Editing the last row parks the list at the bottom, which is where a
    /// freshly added word lives.
    private func restoreScroll(_ proxy: ScrollViewProxy) {
        guard let id = lastEditedID else { return }
        let editingLast = store.entries.last?.id == id
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

    /// Translate every row that has a word but no meaning yet.
    private func backfill() {
        // Deliberately not guarded on "a job is already running": the task can
        // be cancelled when the view updates, and a run that never reports back
        // would then lock out every later attempt. Re-issuing is harmless —
        // meanings are only filled into rows that still lack one.
        guard showMeanings, isTranslationAvailable else { return }
        let items = store.untranslated
        guard !items.isEmpty else { return }
        job = TranslationJob(
            items: items,
            sourceIdentifier: sourceRaw.isEmpty ? nil : sourceRaw,
            targetIdentifier: target.rawValue
        )
    }
}
