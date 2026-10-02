import SwiftUI

/// Picks the audio language and the language meanings are written in. Presented as a sheet so the
/// choices are plain list rows: pop-up menus anchored inside the player are
/// unreliable, because the player rebuilds its body several times a second.
struct TranslationSettingsView: View {
    private let scope: TranslationScope

    @AppStorage private var sourceRaw: String
    @AppStorage private var target: TranslationLanguage

    @Environment(\.dismiss) private var dismiss

    init(scope: TranslationScope) {
        self.scope = scope
        _sourceRaw = AppStorage(wrappedValue: TranslationDefaults.unsetSource, scope.sourceKey)
        _target = AppStorage(wrappedValue: .chinese, scope.targetKey)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Plain rows rather than a Picker: nothing is ticked until a
                    // language is chosen, and a Picker whose selection matches
                    // no row complains at run time.
                    ForEach(TranslationLanguage.allCases) { language in
                        Button {
                            sourceRaw = language.rawValue
                        } label: {
                            HStack {
                                Text(language.label)
                                Spacer()
                                if sourceRaw == language.rawValue {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        // A list tints button labels with the accent colour;
                        // these should read like the picker rows below them.
                        .tint(.primary)
                    }
                } header: {
                    Text("Audio language")
                } footer: {
                    Text("The language spoken in the video. Adding a looped line to your words needs it; meanings work without it.")
                }

                Section {
                    Picker("Meaning language", selection: $target) {
                        ForEach(TranslationLanguage.allCases) { language in
                            Text(language.label).tag(language)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Meaning language")
                } footer: {
                    Text(scopeExplanation)
                }
            }
            .navigationTitle("Languages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    /// Say out loud how far this choice reaches, since it is per playlist.
    private var scopeExplanation: String {
        if let name = scope.name {
            return "Words are translated into this language. These languages apply to every video in “\(name)”, so other playlists keep their own."
        }
        return "Words are translated into this language. These languages apply to videos that aren't in a playlist."
    }
}

/// "日本語 → 中文", for the row that opens the sheet.
func translationPairSummary(sourceRaw: String, target: TranslationLanguage) -> String {
    let from = TranslationLanguage(rawValue: sourceRaw)?.label ?? "Not set"
    return "\(from) → \(target.label)"
}
