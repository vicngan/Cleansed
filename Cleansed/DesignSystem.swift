//
//  DesignSystem.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/14/26.
//

import SwiftUI

struct MinimalistCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 16) {
                // Checkbox Circle
                Image(systemName: configuration.isOn ? "circle.inset.filled" : "circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.primary)

                configuration.label
                    .foregroundStyle(configuration.isOn ? Color.secondary : Color.primary)
                    .strikethrough(configuration.isOn, color: Color.secondary)

                Spacer()  // Ensure it takes full width for tap target
            }
            .contentShape(Rectangle())  // Make entire row tappable
        }
        .buttonStyle(.plain)
    }
}

struct FAB: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color(.systemBackground))  // Inverse of background
                .frame(width: 56, height: 56)
                .background(Color.primary)  // Black in Light, White in Dark
                .clipShape(Circle())
                .shadow(color: Color.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

// Custom View Modifier for hiding list separators
struct HideListSeparators: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
    }
}

extension View {
    func hideListSeparators() -> some View {
        modifier(HideListSeparators())
    }
}

// MARK: - Shared Icon List

enum AppIcons {
    static let all: [String] = [
        "flame.fill", "moon.fill", "sun.max.fill", "book.fill",
        "heart.fill", "bolt.fill", "leaf.fill", "star.fill",
        "figure.walk", "music.note", "paintbrush.fill", "drop.fill",
        "pencil", "dumbbell.fill", "brain.head.profile", "bed.double.fill",
        "airplane", "car.fill", "bicycle", "tram.fill",
        "cart.fill", "bag.fill", "creditcard.fill", "banknote.fill",
        "cross.case.fill", "pills.fill", "stethoscope", "syringe.fill",
        "cup.and.saucer.fill", "wineglass.fill", "fork.knife", "takeoutbag.and.cup.and.straw.fill",
        "gamecontroller.fill", "tv.fill", "headphones", "pianokeys",
        "pawprint.fill", "tortoise.fill", "ladybug.fill", "ant.fill",
        "house.fill", "building.2.fill", "tent.fill", "tree.fill",
        "graduationcap.fill", "briefcase.fill", "display", "laptopcomputer",
        "hammer.fill", "wrench.and.screwdriver.fill", "gearshape.fill", "scissors",
        "magnifyingglass", "lightbulb.fill", "camera.fill", "video.fill",
        "mic.fill", "message.fill", "phone.fill", "envelope.fill",
        "mappin.and.ellipse", "map.fill", "clock.fill", "alarm.fill",
        "timer", "stopwatch.fill", "calendar", "list.bullet",
        "checklist", "rosette", "trophy.fill", "medal.fill",
        "gift.fill", "balloon.2.fill", "party.popper.fill", "sparkles",
        "smiley.fill", "hand.thumbsup.fill", "figure.run", "figure.yoga",
        "water.waves", "flame", "drop", "cloud.rain.fill",
    ]
}

// MARK: - Shared Focus Group Colors

enum FocusGroupColors {
    static let all: [(String, String)] = [
        ("#5E5CE6", "Indigo"),
        ("#FF6B6B", "Red"),
        ("#FFB347", "Orange"),
        ("#48C774", "Green"),
        ("#3B82F6", "Blue"),
        ("#A855F7", "Purple"),
        ("#EC4899", "Pink"),
        ("#14B8A6", "Teal"),
        ("#F59E0B", "Amber"),
        ("#6B7280", "Gray"),
    ]
}

// MARK: - Icon Picker

struct IconPickerView: View {
    @Binding var selection: String
    let accentColor: Color
    var columns: Int = 8
    var itemSize: CGFloat = 36

    @State private var searchText = ""

    private var filteredIcons: [String] {
        searchText.isEmpty
            ? AppIcons.all
            : AppIcons.all.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search icons...", text: $searchText)
                    .disableAutocorrection(true)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)

            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: columns),
                    spacing: 10
                ) {
                    ForEach(filteredIcons, id: \.self) { icon in
                        let isSelected = selection == icon
                        Button {
                            selection = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: itemSize, height: itemSize)
                                .foregroundColor(isSelected ? accentColor : .primary)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isSelected ? accentColor.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSelected ? accentColor : .clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 200)
        }
    }
}

// MARK: - Color Chip Picker

struct ColorChipPicker: View {
    let colors: [(String, String)]
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 5),
                spacing: 10
            ) {
                ForEach(colors, id: \.0) { hex, _ in
                    let chipColor = Color(hex: hex) ?? .gray
                    let isSelected = selection == hex
                    Button {
                        selection = hex
                    } label: {
                        Circle()
                            .fill(chipColor)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: isSelected ? 3 : 0)
                            )
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .opacity(isSelected ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Weekday Picker

struct WeekdayPickerView: View {
    @Binding var selection: Set<Int>
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repeat on")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { day in
                    let symbol = Calendar.current.shortWeekdaySymbols[day - 1]
                    let isSelected = selection.contains(day)
                    Button {
                        if isSelected {
                            selection.remove(day)
                        } else {
                            selection.insert(day)
                        }
                    } label: {
                        Text(String(symbol.prefix(2)))
                            .font(.caption.bold())
                            .frame(width: 36, height: 36)
                            .background(isSelected ? accentColor : Color(.tertiarySystemFill))
                            .foregroundStyle(isSelected ? .white : Color.primary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
