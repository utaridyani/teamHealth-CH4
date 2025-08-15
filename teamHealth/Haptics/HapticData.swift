//
//  HapticData.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 12/08/25.
//
import SwiftUI

class HapticData: ObservableObject {
    @Published var selectedHapticName: String?
    @Published var selectedColor: Color?
}

class SelectedHaptic: ObservableObject {
    @Published var selectedCircle: String?
    @Published var selectedColor: Color?
}
