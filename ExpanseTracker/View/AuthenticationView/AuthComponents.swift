//
//  AuthComponents.swift
//  ExpanseTracker
//
//  Reusable building blocks for the sign in / sign up flow.
//

import SwiftUI

// MARK: - Brand

enum Brand {
    static let primary = Color(red: 0.38, green: 0.33, blue: 0.96)   // indigo
    static let secondary = Color(red: 0.07, green: 0.72, blue: 0.64) // teal

    static let gradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Focus

enum AuthField: Hashable {
    case name, email, password
}

// MARK: - Text Field

struct AuthTextField: View {
    let title: String
    let icon: String
    @Binding var text: String
    let field: AuthField
    var focus: FocusState<AuthField?>.Binding
    var isSecure = false
    var contentType: UITextContentType?
    var keyboard: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .never
    var submitLabel: SubmitLabel = .next
    /// `nil` hides the validation indicator.
    var isValid: Bool?

    @State private var isRevealed = false

    private var isFocused: Bool { focus.wrappedValue == field }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(isFocused ? Brand.primary : .secondary)
                .frame(width: 22)

            Group {
                if isSecure && !isRevealed {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .textContentType(contentType)
            .keyboardType(keyboard)
            .textInputAutocapitalization(capitalization)
            .autocorrectionDisabled()
            .submitLabel(submitLabel)
            .focused(focus, equals: field)

            if let isValid, !text.isEmpty, !isSecure {
                Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(isValid ? .green : .orange)
                    .transition(.scale.combined(with: .opacity))
            }

            if isSecure {
                Button {
                    isRevealed.toggle()
                    // Swapping SecureField <-> TextField drops focus; restore it.
                    DispatchQueue.main.async { focus.wrappedValue = field }
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isFocused ? Brand.primary : .clear, lineWidth: 1.5)
        )
        .animation(.easeOut(duration: 0.15), value: isFocused)
        .animation(.spring(duration: 0.25), value: isValid)
        .contentShape(Rectangle())
        .onTapGesture { focus.wrappedValue = field }
    }
}

// MARK: - Password Strength Meter

struct PasswordStrengthView: View {
    let strength: PasswordStrength

    private var color: Color {
        switch strength {
        case .empty:  return .clear
        case .weak:   return .red
        case .fair:   return .orange
        case .good:   return .yellow
        case .strong: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { index in
                    Capsule()
                        .fill(index <= strength.rawValue ? color : Color(.systemFill))
                        .frame(height: 4)
                }
            }
            Text(strength == .empty
                 ? "Use 8+ characters with a mix of letters, numbers & symbols"
                 : "\(strength.label) password")
                .font(.caption)
                .foregroundStyle(strength == .empty ? .secondary : color)
        }
        .animation(.easeInOut(duration: 0.2), value: strength)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Password strength: \(strength == .empty ? "not set" : strength.label)")
    }
}

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    var isLoading = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(.headline)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(.white)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Brand.gradient)
                    .opacity(isEnabled ? 1 : 0.45)
            )
            .shadow(color: Brand.primary.opacity(isEnabled ? 0.35 : 0), radius: 12, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Mode Picker

struct AuthModePicker: View {
    let selection: AuthMode
    let onSelect: (AuthMode) -> Void
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AuthMode.allCases) { mode in
                Button {
                    onSelect(mode)
                } label: {
                    Text(mode.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selection == mode ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if selection == mode {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                                    .matchedGeometryEffect(id: "pill", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == mode ? .isSelected : [])
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }
}

// MARK: - Saving Goal Chip

struct GoalChip: View {
    let goal: SavingGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(goal.emoji).font(.title2)
                Text(goal.title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Brand.primary.opacity(0.12) : Color(.tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Brand.primary : .clear, lineWidth: 1.5)
            )
            .foregroundStyle(.primary)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(goal.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Error Banner

struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.red)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Orbit Logo
/// The app mark with spending categories orbiting around it — a visual hint at
/// what the app does (auto-categorising your money) before the user signs in.
struct OrbitLogo: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let orbiters: [(icon: String, color: Color)] = [
        ("fork.knife", .orange),
        ("car.fill", .blue),
        ("bag.fill", .purple),
        ("bolt.fill", .red),
        ("film.fill", .pink),
        ("briefcase.fill", .green)
    ]

    private let radius: CGFloat = 64

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate

            ZStack {
                Circle()
                    .stroke(Brand.primary.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                    .frame(width: radius * 2, height: radius * 2)

                ForEach(orbiters.indices, id: \.self) { index in
                    let angle = Double(index) / Double(orbiters.count) * 2 * .pi + time * 0.3
                    Image(systemName: orbiters[index].icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(orbiters[index].color.gradient))
                        .shadow(color: orbiters[index].color.opacity(0.4), radius: 4, y: 2)
                        .offset(x: cos(angle) * radius, y: sin(angle) * radius)
                }

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Brand.gradient)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "indianrupeesign")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: Brand.primary.opacity(0.4), radius: 14, y: 8)
            }
            .frame(width: radius * 2 + 36, height: radius * 2 + 36)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Background

struct AuthBackground: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)

            Circle()
                .fill(Brand.primary.opacity(0.22))
                .frame(width: 360)
                .blur(radius: 90)
                .offset(x: -140, y: -320)

            Circle()
                .fill(Brand.secondary.opacity(0.18))
                .frame(width: 320)
                .blur(radius: 90)
                .offset(x: 160, y: -200)
        }
        .ignoresSafeArea()
    }
}
