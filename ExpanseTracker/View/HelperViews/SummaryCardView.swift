//
//  SummaryCardView.swift
//  ExpanseTracker
//
//  Created by KPIT on 14/06/25.
//

import SwiftUI

struct SummaryCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Toatl Balance")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    SummaryCardView()
}
