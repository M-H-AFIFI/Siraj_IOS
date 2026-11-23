import SwiftUI
import SirajCore

struct AppIconPickerSheet: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let appState: AppState

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(theme.t("app_icon_sheet_desc"))
                        .font(theme.scaledFont(size: 13.5))
                        .foregroundStyle(theme.onSurfaceVariant)

                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(SirajAppIconCatalog.all) { icon in
                            let selected = appState.settings.selectedAppIcon.caseInsensitiveCompare(icon.id) == .orderedSame
                            Button {
                                applyIcon(icon)
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack(alignment: .topTrailing) {
                                        SirajAppIconBadge(icon: icon, size: 70)
                                            .overlay {
                                                if selected {
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .strokeBorder(theme.primary, lineWidth: 2.5)
                                                }
                                            }
                                        if selected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(theme.primary)
                                                .background(Circle().fill(theme.background))
                                                .offset(x: 6, y: -6)
                                        }
                                    }
                                    Text(theme.t(icon.titleKey))
                                        .font(theme.scaledFont(size: 12.5, weight: selected ? .bold : .medium))
                                        .foregroundStyle(selected ? theme.primary : theme.onSurface)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(theme.t("app_icon_sheet_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(theme.t("hijri_done")) { dismiss() }
                }
            }
        }
    }

    private func applyIcon(_ icon: SirajAppIconDefinition) {
        appState.updateSettings { $0.selectedAppIcon = icon.id }
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(icon.alternateIconName) { _ in }
    }
}
