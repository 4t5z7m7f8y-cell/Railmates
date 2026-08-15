import SwiftUI

struct AddEditTripStopView: View {
    @Environment(\.dismiss) private var dismiss

    var existingStop: TripStop?
    var stopOrder: Int
    var onSave: (TripStop) -> Void

    @State private var city = ""
    @State private var country = ""
    @State private var hasArrival = false
    @State private var arrivalDate = Date()
    @State private var hasDeparture = false
    @State private var departureDate = Date()
    @State private var budgetText = ""
    @State private var accommodationNotes = ""
    @State private var notes = ""
    @State private var transportToNext: TransportType = .train

    var isEditing: Bool { existingStop != nil }

    var canSave: Bool {
        !city.trimmingCharacters(in: .whitespaces).isEmpty &&
        !country.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    TextField("City", text: $city)
                        .autocorrectionDisabled()
                    TextField("Country", text: $country)
                        .autocorrectionDisabled()
                }

                Section("Dates") {
                    Toggle("Set arrival date", isOn: $hasArrival.animation())
                    if hasArrival {
                        DatePicker("Arrival", selection: $arrivalDate, displayedComponents: .date)
                    }
                    Toggle("Set departure date", isOn: $hasDeparture.animation())
                    if hasDeparture {
                        DatePicker("Departure", selection: $departureDate, displayedComponents: .date)
                    }
                    if hasArrival && hasDeparture {
                        let nights = max(0, Calendar.current.dateComponents([.day], from: arrivalDate, to: departureDate).day ?? 0)
                        if nights > 0 {
                            LabeledContent("Nights", value: "\(nights)")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Budget") {
                    HStack {
                        Text("€").foregroundColor(.secondary)
                        TextField("Estimated spend", text: $budgetText)
                            .keyboardType(.numberPad)
                    }
                }

                Section("Accommodation") {
                    TextField("Hostel, hotel, Couchsurfing...", text: $accommodationNotes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Notes") {
                    TextField("Things to do, see, eat...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Transport to next stop") {
                    Picker("Transport", selection: $transportToNext) {
                        ForEach(TransportType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            .navigationTitle(isEditing ? "Edit Stop" : "Add Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        guard let stop = existingStop else { return }
        city = stop.city
        country = stop.country
        if let d = stop.arrivalDate   { hasArrival = true;   arrivalDate   = d }
        if let d = stop.departureDate { hasDeparture = true; departureDate = d }
        budgetText = stop.budgetEUR.map { "\($0)" } ?? ""
        accommodationNotes = stop.accommodationNotes
        notes = stop.notes
        transportToNext = stop.transportToNext
    }

    private func save() {
        var stop = existingStop ?? TripStop(city: "", country: "", order: stopOrder)
        stop.city = city.trimmingCharacters(in: .whitespaces)
        stop.country = country.trimmingCharacters(in: .whitespaces)
        stop.arrivalDate   = hasArrival   ? arrivalDate   : nil
        stop.departureDate = hasDeparture ? departureDate : nil
        stop.budgetEUR = Int(budgetText)
        stop.accommodationNotes = accommodationNotes
        stop.notes = notes
        stop.transportToNext = transportToNext
        stop.order = stopOrder
        onSave(stop)
        dismiss()
    }
}
