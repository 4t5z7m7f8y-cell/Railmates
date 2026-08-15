import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (TripExpense) -> Void

    @State private var amountText = ""
    @State private var category: BudgetCategory = .food
    @State private var date = Date()
    @State private var note = ""

    private var amount: Double? { Double(amountText.replacingOccurrences(of: ",", with: ".")) }
    private var canSave: Bool { amount != nil && (amount ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text("€")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(BudgetCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                }

                Section("Note (optional)") {
                    TextField("What did you spend on?", text: $note)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let a = amount else { return }
                        onSave(TripExpense(date: date, amount: a, category: category, note: note))
                        dismiss()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
