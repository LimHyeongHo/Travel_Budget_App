import SwiftUI

struct ExpenseFormView: View {
    let trip: Trip
    @State private var model: ExpenseFormViewModel
    @State private var showingScanner = false
    @Environment(\.modelContext) private var context
    @Environment(\.currencyService) private var service
    @Environment(\.dismiss) private var dismiss

    init(trip: Trip) {
        self.trip = trip
        _model = State(initialValue: ExpenseFormViewModel(trip: trip))
    }

    private var participants: [Participant] { trip.participants ?? [] }

    var body: some View {
        NavigationStack {
            Form {
                #if os(iOS)
                Section {
                    Button("영수증 스캔", systemImage: "doc.viewfinder") { showingScanner = true }
                    if model.isScanning { ProgressView("영수증 분석 중…") }
                }
                #endif
                Section {
                    TextField("내용", text: $model.title)
                    TextField("금액", text: $model.amountText)
                    #if os(iOS)
                        .keyboardType(.decimalPad)
                    #endif
                    Picker("통화", selection: $model.currencyCode) {
                        ForEach(CommonCurrencies.options(including: model.currencyCode), id: \.self, content: Text.init)
                    }
                    Picker("카테고리", selection: $model.category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { Text($0.displayName) }
                    }
                    DatePicker("날짜", selection: $model.date, displayedComponents: .date)
                }
                Section("결제자") {
                    Picker("결제자", selection: $model.payerID) {
                        ForEach(participants) { Text($0.name).tag(Optional($0.id)) }
                    }
                }
                Section("분담자") {
                    ForEach(participants) { participant in
                        Toggle(participant.name, isOn: Binding(
                            get: { model.sharerIDs.contains(participant.id) },
                            set: { model.setSharer(participant.id, isOn: $0) }
                        ))
                    }
                }
                if let error = model.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
            }
            .navigationTitle("지출 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task { if await model.save(service: service, context: context) { dismiss() } }
                    }
                    .disabled(!model.canSave)
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showingScanner) {
                ReceiptScannerView(
                    onScan: { images in
                        showingScanner = false
                        Task { await model.applyScan(images) }
                    },
                    onCancel: { showingScanner = false }
                )
            }
            #endif
        }
    }
}
