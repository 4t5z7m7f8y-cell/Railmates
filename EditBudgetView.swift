import SwiftUI

struct EditBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    var existing: [String: Double]
    var onSave: ([String: Double]) -> Void

    @State private var amounts: [BudgetCategory: String] = [:]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(BudgetCategory.allCases, id: \.self) { cat in
                        HStack {
                            Label(cat.rawValue, systemImage: cat.icon)
                                .foregroundColor(cat.color)
                            Spacer()
                            Text("€").foregroundColor(.secondary)
                            TextField("0", text: binding(for: cat))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }
                } header: {
                    Text("Planned amounts")
                } footer: {
                    Text("Set how much you plan to spend in each category.")
                }
            }
            .navigationTitle("Plan Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var result: [String: Double] = [:]
                        for cat in BudgetCategory.allCases {
                            let raw = amounts[cat] ?? ""
                            let value = Double(raw.replacingOccurrences(of: ",", with: ".")) ?? 0
                            if value > 0 { result[cat.rawValue] = value }
                        }
                        onSave(result)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                for cat in BudgetCategory.allCases {
                    if let v = existing[cat.rawValue], v > 0 {
                        amounts[cat] = String(format: "%.0f", v)
                    }
                }
            }
        }
    }

    private func binding(for cat: BudgetCategory) -> Binding<String> {
        Binding(
            get: { amounts[cat] ?? "" },
            set: { amounts[cat] = $0 }
        )
    }
}
