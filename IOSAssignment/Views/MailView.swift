import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentation
    @Binding var result: Result<MFMailComposeResult, Error>? // To get the result back
    var recipients: [String]
    var subject: String
    var body: String
    var isHTML: Bool = false
    // You can add properties for CC, BCC, attachments if needed

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView

        init(_ parent: MailView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer { // Ensure presentation mode is dismissed after handling
                parent.presentation.wrappedValue.dismiss()
            }

            if let error = error {
                self.parent.result = .failure(error)
                return
            }
            self.parent.result = .success(result)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: isHTML)
        // Add more configurations here (e.g., attachments, CC, BCC)
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed for this simple mail view
    }
}


