import SwiftUI

/// A rename prompt driven by an optional subject: non-nil shows it, saving or
/// cancelling clears it. Lives in its own modifier so the alert's builders stay
/// out of the host view's `body` — inlining several of these pushed both the
/// home and playlist screens past the type-checker's time limit.
struct RenameAlert<Subject>: ViewModifier {
    let title: String
    let footnote: String?
    @Binding var subject: Subject?
    @Binding var text: String
    let onSave: (Subject) -> Void

    private var isPresented: Binding<Bool> {
        Binding(get: { subject != nil }, set: { if !$0 { subject = nil } })
    }

    func body(content: Content) -> some View {
        content.alert(title, isPresented: isPresented) {
            TextField("Name", text: $text)
            Button("Save") {
                if let subject { onSave(subject) }
                subject = nil
            }
            Button("Cancel", role: .cancel) { subject = nil }
        } message: {
            if let footnote { Text(footnote) }
        }
    }
}

extension View {
    /// Prefill `text` before setting `subject`, so the user edits the name they
    /// can already see rather than starting from a blank field.
    func renameAlert<Subject>(
        _ title: String,
        footnote: String? = nil,
        subject: Binding<Subject?>,
        text: Binding<String>,
        onSave: @escaping (Subject) -> Void
    ) -> some View {
        modifier(
            RenameAlert(
                title: title,
                footnote: footnote,
                subject: subject,
                text: text,
                onSave: onSave
            )
        )
    }
}
