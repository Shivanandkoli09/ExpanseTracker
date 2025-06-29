  Form {
            TextField("Title", text: $title)
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
            Picker("Type", selection: $type) {
                ForEach(TransactionType.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            DatePicker("Date", selection: $date, displayedComponents: .date)