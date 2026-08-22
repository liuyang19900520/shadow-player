import SwiftUI
import UIKit

/// Inline word-list editor shown below the video: an editable 3-column table
/// (kanji / kana / meaning) with per-row delete and an add-row button.
struct WordListEditor: View {
    @ObservedObject var store: WordListStore

    /// Shared horizontal inset so the header and every row's columns line up.
    private let hInset: CGFloat = 16
    private let colSpacing: CGFloat = 8

    var body: some View {
        List {
            ForEach($store.entries) { $entry in
                row($entry)
            }
            .onDelete { store.remove(atOffsets: $0) }

            Button {
                store.addEmpty()
            } label: {
                Label("Add Row", systemImage: "plus.circle.fill")
                    .font(.body.weight(.medium))
            }
            .listRowInsets(EdgeInsets(top: 10, leading: hInset, bottom: 10, trailing: hInset))
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            // "Done" above the keyboard so the user can always dismiss it.
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { dismissKeyboard() }
            }
        }
    }

    private func row(_ entry: Binding<WordEntry>) -> some View {
        HStack(spacing: colSpacing) {
            TextField("Word", text: entry.text)
                .textFieldStyle(.roundedBorder)
                .font(.subheadline)
                .autocorrectionDisabled()
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                store.remove(entry.wrappedValue)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: hInset, bottom: 8, trailing: hInset))
        .listRowBackground(Color.clear)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
        )
    }
}
