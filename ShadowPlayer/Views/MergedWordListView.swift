import SwiftUI
import UIKit

/// The combined, editable word list for a whole playlist (all videos' words in one).
struct MergedWordListView: View {
    @StateObject private var store: MergedWordListStore
    @Environment(\.dismiss) private var dismiss

    private let hInset: CGFloat = 16

    init(videoIDs: [String]) {
        _store = StateObject(wrappedValue: MergedWordListStore(videoIDs: videoIDs))
    }

    var body: some View {
        NavigationStack {
            List {
                if store.items.isEmpty {
                    Text("No words yet. Add words from each video while playing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(store.items) { item in
                    HStack(spacing: 8) {
                        TextField("Word", text: Binding(
                            get: { item.text },
                            set: { store.setText($0, for: item.id) }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                        .autocorrectionDisabled()

                        Button {
                            store.delete(item.id)
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
                .onDelete { store.delete(atOffsets: $0) }

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
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Combined Words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { dismissKeyboard() }
                }
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
        )
    }
}
