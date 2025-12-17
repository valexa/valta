//
//  TransparentDatePicker.swift
//  valtaManager
//
//  A wrapper around NSDatePicker that removes the default background and bezel
//  to allow for custom styling in SwiftUI.
//
//  Created by vlad on 2025-12-17.
//

import SwiftUI
import AppKit

struct TransparentDatePicker: NSViewRepresentable {
    @Binding var selection: Date
    let minDate: Date?
    
    func makeNSView(context: Context) -> NSDatePicker {
        let picker = NSDatePicker()
        picker.datePickerStyle = .textField
        picker.isBezeled = false
        picker.isBordered = false
        picker.drawsBackground = false
        picker.datePickerElements = [.yearMonthDay, .hourMinute]
        if let minDate = minDate {
            picker.minDate = minDate
        }
        picker.target = context.coordinator
        picker.action = #selector(Coordinator.valueChanged(_:))
        return picker
    }

    func updateNSView(_ nsView: NSDatePicker, context: Context) {
        nsView.dateValue = selection
        if let minDate = minDate {
            nsView.minDate = minDate
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: TransparentDatePicker

        init(_ parent: TransparentDatePicker) {
            self.parent = parent
        }

        @objc func valueChanged(_ sender: NSDatePicker) {
            parent.selection = sender.dateValue
        }
    }
}
