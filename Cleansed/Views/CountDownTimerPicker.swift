import SwiftUI
import UIKit

/// Wraps UIDatePicker in .countDownTimer mode — the native hours/minutes drum picker.
/// `duration` is in seconds (TimeInterval).
struct CountDownTimerPicker: UIViewRepresentable {
    @Binding var duration: TimeInterval

    func makeCoordinator() -> Coordinator {
        Coordinator(duration: $duration)
    }

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .countDownTimer
        picker.minuteInterval = 1
        picker.countDownDuration = duration
        picker.addTarget(
            context.coordinator,
            action: #selector(Coordinator.durationChanged(_:)),
            for: .valueChanged
        )
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        // Only sync outward if not actively editing to prevent feedback loop
        if abs(uiView.countDownDuration - duration) > 1 {
            uiView.countDownDuration = duration
        }
    }

    final class Coordinator: NSObject {
        var duration: Binding<TimeInterval>

        init(duration: Binding<TimeInterval>) {
            self.duration = duration
        }

        @objc func durationChanged(_ picker: UIDatePicker) {
            duration.wrappedValue = picker.countDownDuration
        }
    }
}
