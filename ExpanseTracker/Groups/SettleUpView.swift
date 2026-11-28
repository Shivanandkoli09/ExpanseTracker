//
//  SettleUpView.swift
//  ExpanseTracker
//
//  Fewest payments to settle a group, with UPI QR codes and share messages.
//

import SwiftUI

struct SettleUpView: View {
    let groupID: String

    @EnvironmentObject private var store: GroupsStore
    @EnvironmentObject private var profileStore: UserProfileStore
    @EnvironmentObject private var authViewModel: SignInViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var qrTransfer: GroupLedger.Transfer?
    @State private var transferToConfirm: GroupLedger.Transfer?
    @State private var upiDraft = ""

    var body: some View {
        NavigationStack {
            Group {
                if let group = store.group(withID: groupID) {
                    content(group)
                } else {
                    ContentUnavailableView("Group not found", systemImage: "person.3")
                }
            }
            .navigationTitle("Settle Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Content

    private func content(_ group: ExpenseGroup) -> some View {
        let ledger = GroupLedger(group: group)
        let names = SettleNames(group: group, myName: myName)
        let someoneOwesMe = ledger.transfers.contains { $0.to == GroupMember.meID }

        return List {
            if ledger.isSettled {
                Section {
                    VStack(spacing: 10) {
                        Text("🎉")
                            .font(.system(size: 56))
                        Text("All settled!")
                            .font(.title2.weight(.bold))
                        Text(group.expenses.isEmpty
                             ? "Add some expenses first."
                             : "Everyone in \(group.name) is square. Nice work.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    Text("\(ledger.transfers.count) \(ledger.transfers.count == 1 ? "payment settles" : "payments settle") everything in \(group.name).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                }

                if someoneOwesMe && profileStore.upiID == nil {
                    upiPrompt
                }

                Section("Payments") {
                    ForEach(ledger.transfers) { transfer in
                        transferRow(transfer, group: group, names: names)
                    }
                }

                Section {
                    ShareLink(item: names.summary(ledger: ledger, upiID: profileStore.upiID)) {
                        Label("Share Summary", systemImage: "square.and.arrow.up")
                    }
                } footer: {
                    Text("Send who-owes-whom to your group chat on WhatsApp or anywhere else.")
                }
            }

            if !group.payments.isEmpty {
                Section {
                    ForEach(group.payments.sorted { $0.date > $1.date }) { payment in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("\(names[payment.from]) paid \(names[payment.to])")
                            Spacer()
                            Text(Currency.string(payment.amount))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        .swipeActions {
                            Button("Undo", role: .destructive) {
                                store.deletePayment(payment, in: groupID)
                            }
                        }
                    }
                } header: {
                    Text("Recorded payments")
                } footer: {
                    Text("Swipe left to undo a payment marked by mistake.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: ledger.transfers)
        .sensoryFeedback(.success, trigger: ledger.isSettled) { _, settled in settled }
        .sheet(item: $qrTransfer) { transfer in
            if let upiID = profileStore.upiID {
                PaymentQRSheet(
                    transfer: transfer,
                    payerName: names[transfer.from],
                    payeeName: myName,
                    upiID: upiID,
                    groupTitle: "\(group.name) \(group.emoji)"
                ) {
                    markPaid(transfer)
                }
            }
        }
        .confirmationDialog(
            transferToConfirm.map { "\(names[$0.from]) paid \(names[$0.to]) \(Currency.string($0.amount))?" } ?? "",
            isPresented: Binding(get: { transferToConfirm != nil }, set: { if !$0 { transferToConfirm = nil } }),
            titleVisibility: .visible
        ) {
            Button("Mark as Paid") {
                if let transfer = transferToConfirm { markPaid(transfer) }
            }
        }
    }

    private func transferRow(_ transfer: GroupLedger.Transfer, group: ExpenseGroup, names: SettleNames) -> some View {
        let toMe = transfer.to == GroupMember.meID
        let fromMe = transfer.from == GroupMember.meID
        let from = group.members.first { $0.id == transfer.from } ?? GroupMember(id: transfer.from, name: names[transfer.from])
        let to = group.members.first { $0.id == transfer.to } ?? GroupMember(id: transfer.to, name: names[transfer.to])

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                MemberAvatar(member: from, size: 34)
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                MemberAvatar(member: to, size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text(fromMe ? "You pay \(names[transfer.to])"
                         : toMe ? "\(names[transfer.from]) pays you"
                         : "\(names[transfer.from]) pays \(names[transfer.to])")
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    Text(Currency.string(transfer.amount))
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(toMe ? Color.green : fromMe ? Color.orange : Color.primary)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                if toMe, let upiID = profileStore.upiID {
                    Button {
                        qrTransfer = transfer
                    } label: {
                        Label("QR", systemImage: "qrcode")
                    }
                    ShareLink(item: names.request(transfer, groupTitle: "\(group.name) \(group.emoji)", upiID: upiID, payeeName: myName)) {
                        Label("Request", systemImage: "paperplane")
                    }
                }
                Spacer(minLength: 0)
                Button {
                    transferToConfirm = transfer
                } label: {
                    Label("Mark Paid", systemImage: "checkmark")
                }
                .tint(.green)
            }
            .font(.footnote.weight(.semibold))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .padding(.vertical, 4)
    }

    private var upiPrompt: some View {
        Section {
            HStack {
                TextField("yourname@okbank", text: $upiDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                Button("Save") {
                    profileStore.setUPIID(upiDraft)
                }
                .fontWeight(.semibold)
                .disabled(!UPIPayment.isValidID(upiDraft))
            }
        } header: {
            Text("Get paid by UPI")
        } footer: {
            Text("Add your UPI ID to show friends a QR code with the exact amount. Find it in GPay or PhonePe under your profile.")
        }
    }

    // MARK: - Helpers

    private var myName: String {
        authViewModel.displayName?.split(separator: " ").first.map(String.init) ?? "Me"
    }

    private func markPaid(_ transfer: GroupLedger.Transfer) {
        store.recordPayment(GroupPayment(from: transfer.from, to: transfer.to, amount: transfer.amount), in: groupID)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Names & messages

/// Display names for sharing. Inside the app it's "You"; in messages it's the user's name.
private struct SettleNames {
    let group: ExpenseGroup
    let myName: String

    subscript(id: String) -> String {
        id == GroupMember.meID ? "You" : group.name(of: id)
    }

    private func shareName(_ id: String) -> String {
        id == GroupMember.meID ? myName : group.name(of: id)
    }

    func summary(ledger: GroupLedger, upiID: String?) -> String {
        var lines = ["\(group.name) \(group.emoji) — settle up",
                     "Total spent: \(Currency.string(ledger.totalSpent)) · \(group.members.count) people",
                     ""]
        for transfer in ledger.transfers {
            lines.append("• \(shareName(transfer.from)) → \(shareName(transfer.to)): \(Currency.string(transfer.amount))")
        }
        if let upiID, ledger.transfers.contains(where: { $0.to == GroupMember.meID }) {
            lines += ["", "Pay \(myName) by UPI: \(upiID)"]
        }
        lines += ["", "Split with MyMoney"]
        return lines.joined(separator: "\n")
    }

    func request(_ transfer: GroupLedger.Transfer, groupTitle: String, upiID: String, payeeName: String) -> String {
        var message = "Hi \(shareName(transfer.from))! Your share for \(groupTitle) comes to \(Currency.string(transfer.amount)).\n\nPlease pay \(payeeName) on UPI: \(upiID)"
        if let link = UPIPayment.link(payeeID: upiID, payeeName: payeeName, amount: transfer.amount, note: groupTitle) {
            message += "\n\nTap to pay: \(link.absoluteString)"
        }
        return message
    }
}

// MARK: - QR Sheet

struct PaymentQRSheet: View {
    let transfer: GroupLedger.Transfer
    let payerName: String
    let payeeName: String
    let upiID: String
    let groupTitle: String
    let onMarkPaid: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let card = PaymentQRCard(payeeName: payeeName, upiID: upiID, amount: transfer.amount,
                                 groupTitle: groupTitle, payerName: payerName)

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    card
                        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)

                    Text("Show this to \(payerName), or send it. They scan it with any UPI app and the amount is filled in.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let image = renderedCard(card) {
                        ShareLink(
                            item: Image(uiImage: image),
                            message: Text("Your share for \(groupTitle): \(Currency.string(transfer.amount)). Scan to pay \(payeeName) on UPI."),
                            preview: SharePreview("Pay \(payeeName) \(Currency.string(transfer.amount))", image: Image(uiImage: image))
                        ) {
                            Label("Send QR", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle(radius: 14))
                    }

                    PrimaryButton(title: "\(payerName) has paid") {
                        onMarkPaid()
                        dismiss()
                    }
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Payment QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @MainActor
    private func renderedCard(_ card: PaymentQRCard) -> UIImage? {
        let renderer = ImageRenderer(content: card.frame(width: 340).environment(\.colorScheme, .light))
        renderer.scale = 3
        return renderer.uiImage
    }
}

/// Always light so it scans reliably, and looks good when shared as an image.
struct PaymentQRCard: View {
    let payeeName: String
    let upiID: String
    let amount: Double
    let groupTitle: String
    let payerName: String

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 2) {
                Text("Pay \(payeeName)")
                    .font(.headline)
                Text(Currency.string(amount))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.primary)
                Text("\(payerName)'s share · \(groupTitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let link = UPIPayment.link(payeeID: upiID, payeeName: payeeName, amount: amount, note: groupTitle),
               let qr = UPIPayment.qrImage(for: link.absoluteString) {
                Image(uiImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(12)
                    .background(.white)
                    .accessibilityLabel("UPI payment QR code")
            }

            VStack(spacing: 4) {
                Text(upiID)
                    .font(.subheadline.weight(.semibold))
                    .textSelection(.enabled)
                Text("Scan with GPay, PhonePe, Paytm or any UPI app")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.black)
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
        .environment(\.colorScheme, .light)
    }
}
