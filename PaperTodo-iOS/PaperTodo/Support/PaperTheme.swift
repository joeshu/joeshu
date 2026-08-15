import SwiftUI

enum PaperColorScheme: String, CaseIterable, Identifiable {
    case warm = "暖纸"
    case ink = "墨"
    case forest = "林"
    case rose = "霞"

    var id: String { rawValue }
}

struct PaperPalette {
    let paper: Color
    let paperBorder: Color
    let text: Color
    let weakText: Color
    let active: Color
    let code: Color
    let quoteBorder: Color
    let link: Color
    let checkBox: Color
    let tint: Color
    let danger: Color
    let canvas: Color
    let accent: Color
    let timeColor: Color

    static func scheme(_ name: PaperColorScheme, dark: Bool) -> PaperPalette {
        switch name {
        case .warm:
            if dark {
                return PaperPalette(
                    paper: Color(red: 33/255, green: 31/255, blue: 28/255),
                    paperBorder: Color(red: 76/255, green: 69/255, blue: 61/255),
                    text: Color(red: 231/255, green: 224/255, blue: 212/255),
                    weakText: Color(red: 146/255, green: 137/255, blue: 123/255),
                    active: Color(red: 168/255, green: 142/255, blue: 106/255),
                    code: Color(red: 45/255, green: 42/255, blue: 38/255),
                    quoteBorder: Color(red: 94/255, green: 86/255, blue: 75/255),
                    link: Color(red: 214/255, green: 150/255, blue: 120/255),
                    checkBox: Color(red: 110/255, green: 100/255, blue: 85/255),
                    tint: Color(red: 230/255, green: 223/255, blue: 211/255),
                    danger: Color(red: 230/255, green: 110/255, blue: 90/255),
                    canvas: Color(red: 30/255, green: 28/255, blue: 25/255),
                    accent: Color(red: 217/255, green: 176/255, blue: 122/255),
                    timeColor: Color(red: 147/255, green: 169/255, blue: 201/255)
                )
            } else {
                return PaperPalette(
                    paper: Color(red: 255/255, green: 249/255, blue: 234/255),
                    paperBorder: Color(red: 224/255, green: 206/255, blue: 167/255),
                    text: Color(red: 51/255, green: 41/255, blue: 30/255),
                    weakText: Color(red: 138/255, green: 122/255, blue: 99/255),
                    active: Color(red: 140/255, green: 115/255, blue: 80/255),
                    code: Color(red: 247/255, green: 237/255, blue: 210/255),
                    quoteBorder: Color(red: 212/255, green: 190/255, blue: 146/255),
                    link: Color(red: 176/255, green: 98/255, blue: 66/255),
                    checkBox: Color(red: 180/255, green: 160/255, blue: 120/255),
                    tint: Color(red: 120/255, green: 92/255, blue: 48/255),
                    danger: Color(red: 176/255, green: 90/255, blue: 70/255),
                    canvas: Color(red: 250/255, green: 246/255, blue: 236/255),
                    accent: Color(red: 217/255, green: 160/255, blue: 91/255),
                    timeColor: Color(red: 124/255, green: 147/255, blue: 184/255)
                )
            }
        case .ink:
            if dark {
                return PaperPalette(
                    paper: Color(red: 26/255, green: 28/255, blue: 32/255),
                    paperBorder: Color(red: 60/255, green: 66/255, blue: 76/255),
                    text: Color(red: 222/255, green: 227/255, blue: 234/255),
                    weakText: Color(red: 138/255, green: 146/255, blue: 158/255),
                    active: Color(red: 132/255, green: 156/255, blue: 188/255),
                    code: Color(red: 38/255, green: 41/255, blue: 47/255),
                    quoteBorder: Color(red: 78/255, green: 86/255, blue: 98/255),
                    link: Color(red: 132/255, green: 170/255, blue: 214/255),
                    checkBox: Color(red: 96/255, green: 106/255, blue: 120/255),
                    tint: Color(red: 180/255, green: 200/255, blue: 228/255),
                    danger: Color(red: 224/255, green: 116/255, blue: 108/255),
                    canvas: Color(red: 23/255, green: 26/255, blue: 30/255),
                    accent: Color(red: 108/255, green: 147/255, blue: 232/255),
                    timeColor: Color(red: 127/255, green: 176/255, blue: 232/255)
                )
            } else {
                return PaperPalette(
                    paper: Color(red: 246/255, green: 247/255, blue: 249/255),
                    paperBorder: Color(red: 208/255, green: 214/255, blue: 222/255),
                    text: Color(red: 38/255, green: 44/255, blue: 54/255),
                    weakText: Color(red: 118/255, green: 126/255, blue: 138/255),
                    active: Color(red: 90/255, green: 108/255, blue: 134/255),
                    code: Color(red: 236/255, green: 239/255, blue: 243/255),
                    quoteBorder: Color(red: 198/255, green: 206/255, blue: 216/255),
                    link: Color(red: 66/255, green: 104/255, blue: 156/255),
                    checkBox: Color(red: 170/255, green: 180/255, blue: 194/255),
                    tint: Color(red: 70/255, green: 90/255, blue: 120/255),
                    danger: Color(red: 188/255, green: 84/255, blue: 80/255),
                    canvas: Color(red: 232/255, green: 238/255, blue: 245/255),
                    accent: Color(red: 74/255, green: 123/255, blue: 247/255),
                    timeColor: Color(red: 91/255, green: 155/255, blue: 213/255)
                )
            }
        case .forest:
            if dark {
                return PaperPalette(
                    paper: Color(red: 26/255, green: 30/255, blue: 27/255),
                    paperBorder: Color(red: 58/255, green: 70/255, blue: 60/255),
                    text: Color(red: 220/255, green: 228/255, blue: 220/255),
                    weakText: Color(red: 134/255, green: 148/255, blue: 136/255),
                    active: Color(red: 124/255, green: 168/255, blue: 134/255),
                    code: Color(red: 37/255, green: 42/255, blue: 38/255),
                    quoteBorder: Color(red: 74/255, green: 90/255, blue: 76/255),
                    link: Color(red: 128/255, green: 190/255, blue: 150/255),
                    checkBox: Color(red: 92/255, green: 110/255, blue: 94/255),
                    tint: Color(red: 180/255, green: 208/255, blue: 186/255),
                    danger: Color(red: 222/255, green: 124/255, blue: 104/255),
                    canvas: Color(red: 24/255, green: 31/255, blue: 26/255),
                    accent: Color(red: 111/255, green: 190/255, blue: 133/255),
                    timeColor: Color(red: 132/255, green: 192/255, blue: 160/255)
                )
            } else {
                return PaperPalette(
                    paper: Color(red: 243/255, green: 248/255, blue: 241/255),
                    paperBorder: Color(red: 200/255, green: 218/255, blue: 198/255),
                    text: Color(red: 38/255, green: 50/255, blue: 42/255),
                    weakText: Color(red: 110/255, green: 128/255, blue: 112/255),
                    active: Color(red: 88/255, green: 130/255, blue: 96/255),
                    code: Color(red: 233/255, green: 242/255, blue: 231/255),
                    quoteBorder: Color(red: 192/255, green: 214/255, blue: 192/255),
                    link: Color(red: 60/255, green: 130/255, blue: 96/255),
                    checkBox: Color(red: 168/255, green: 192/255, blue: 168/255),
                    tint: Color(red: 70/255, green: 110/255, blue: 80/255),
                    danger: Color(red: 188/255, green: 96/255, blue: 76/255),
                    canvas: Color(red: 238/255, green: 245/255, blue: 236/255),
                    accent: Color(red: 74/255, green: 159/255, blue: 99/255),
                    timeColor: Color(red: 91/255, green: 168/255, blue: 127/255)
                )
            }
        case .rose:
            if dark {
                return PaperPalette(
                    paper: Color(red: 33/255, green: 28/255, blue: 30/255),
                    paperBorder: Color(red: 78/255, green: 64/255, blue: 68/255),
                    text: Color(red: 232/255, green: 220/255, blue: 223/255),
                    weakText: Color(red: 152/255, green: 132/255, blue: 137/255),
                    active: Color(red: 190/255, green: 134/255, blue: 148/255),
                    code: Color(red: 44/255, green: 38/255, blue: 40/255),
                    quoteBorder: Color(red: 92/255, green: 76/255, blue: 80/255),
                    link: Color(red: 224/255, green: 148/255, blue: 170/255),
                    checkBox: Color(red: 96/255, green: 78/255, blue: 82/255),
                    tint: Color(red: 224/255, green: 180/255, blue: 190/255),
                    danger: Color(red: 222/255, green: 110/255, blue: 100/255),
                    canvas: Color(red: 34/255, green: 27/255, blue: 30/255),
                    accent: Color(red: 232/255, green: 138/255, blue: 162/255),
                    timeColor: Color(red: 187/255, green: 159/255, blue: 201/255)
                )
            } else {
                return PaperPalette(
                    paper: Color(red: 253/255, green: 245/255, blue: 246/255),
                    paperBorder: Color(red: 228/255, green: 205/255, blue: 210/255),
                    text: Color(red: 54/255, green: 38/255, blue: 42/255),
                    weakText: Color(red: 140/255, green: 114/255, blue: 120/255),
                    active: Color(red: 158/255, green: 104/255, blue: 118/255),
                    code: Color(red: 248/255, green: 236/255, blue: 238/255),
                    quoteBorder: Color(red: 224/255, green: 198/255, blue: 204/255),
                    link: Color(red: 178/255, green: 84/255, blue: 110/255),
                    checkBox: Color(red: 216/255, green: 184/255, blue: 192/255),
                    tint: Color(red: 150/255, green: 80/255, blue: 96/255),
                    danger: Color(red: 188/255, green: 82/255, blue: 78/255),
                    canvas: Color(red: 250/255, green: 239/255, blue: 241/255),
                    accent: Color(red: 217/255, green: 112/255, blue: 140/255),
                    timeColor: Color(red: 168/255, green: 138/255, blue: 181/255)
                )
            }
        }
    }
}

struct PaperThemeKey: EnvironmentKey {
    static let defaultValue = PaperPalette.scheme(.warm, dark: false)
}

extension EnvironmentValues {
    var paperTheme: PaperPalette {
        get { self[PaperThemeKey.self] }
        set { self[PaperThemeKey.self] = newValue }
    }
}

extension PaperPalette {
    var brandAction: Color { accent }

    var onAccent: Color { Color.black.opacity(0.82) }

    var accentGradient: LinearGradient {
        LinearGradient(colors: [tint, active], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var activeGradient: LinearGradient {
        LinearGradient(colors: [active.opacity(0.96), active.opacity(0.78)], startPoint: .top, endPoint: .bottom)
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [canvas.opacity(0.9), canvas.opacity(0.45)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
