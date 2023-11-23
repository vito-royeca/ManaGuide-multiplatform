//
//  CardPricingInfoView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/8/23.
//

import SwiftUI
import ManaKit

struct CardPricingInfoView: View {
    @State var isPricingExpanded = false
    var prices: [MGCardPrice]
    
    var body: some View {
        CardPricingRowView(title: "Market Price",
                           normal: prices.filter({ !$0.isFoil }).map{ $0.market}.first ?? 0,
                           foil: prices.filter({ $0.isFoil }).map{ $0.market}.first ?? 0)
        DisclosureGroup("All TCGPlayer Prices", isExpanded: $isPricingExpanded) {
            CardPricingRowView(title: "Direct Low",
                               normal: prices.filter({ !$0.isFoil }).map{ $0.directLow}.first ?? 0,
                               foil: prices.filter({ $0.isFoil }).map{ $0.directLow}.first ?? 0)
            CardPricingRowView(title: "Low",
                               normal: prices.filter({ !$0.isFoil }).map{ $0.low}.first ?? 0,
                               foil: prices.filter({ $0.isFoil }).map{ $0.low}.first ?? 0)
            CardPricingRowView(title: "Median",
                               normal: prices.filter({ !$0.isFoil }).map{ $0.median}.first ?? 0,
                               foil: prices.filter({ $0.isFoil }).map{ $0.median}.first ?? 0)
            CardPricingRowView(title: "High",
                               normal: prices.filter({ !$0.isFoil }).map{ $0.high}.first ?? 0,
                               foil: prices.filter({ $0.isFoil }).map{ $0.high}.first ?? 0)
        }
    }
}

struct CardPricingRowView: View {
    var title: String
    var normal: Double
    var foil: Double
    
    var body: some View {
        LabeledContent {
            VStack(alignment: .trailing) {
                Text("Normal \(normal > 0 ? String(format: "$%.2f", normal) : String.emdash)")
                    .foregroundColor(Color.blue)
                Text("Foil \(foil > 0 ? String(format: "$%.2f", foil) : String.emdash)")
                    .foregroundColor(Color.green)
            }
        } label: {
            Text(title)
        }
    }
}

#Preview {
    CardPricingInfoView(prices: [])
}
