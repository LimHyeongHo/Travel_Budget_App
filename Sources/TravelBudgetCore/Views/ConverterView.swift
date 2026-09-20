import SwiftUI

struct ConverterView: View {
    @State private var model: ConverterViewModel
    @Environment(\.currencyService) private var service

    init(trip: Trip) {
        _model = State(initialValue: ConverterViewModel(
            localCurrency: trip.destinationCurrency, baseCurrency: trip.baseCurrency
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("금액", text: $model.amountText)
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif
                Text(model.fromCurrency).foregroundStyle(.secondary)
                Button("통화 바꾸기", systemImage: "arrow.left.arrow.right") { model.swap() }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                Text(model.toCurrency).foregroundStyle(.secondary)
            }
            if let converted = model.convertedAmount {
                Text("≈ \(converted.formatted(currency: model.toCurrency))").font(.headline)
            }
            if let error = model.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red)
            }
            Button("환율 새로고침", systemImage: "arrow.clockwise") {
                Task { await model.load(using: service, forceRefresh: true) }
            }
            .buttonStyle(.borderless)
            .font(.footnote)
        }
        .task { await model.load(using: service) }
    }
}
