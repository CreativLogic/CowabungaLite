//
//  ThemingView.swift
//  CowabungaJailed
//
//  Created by lemin on 3/24/23.
//

import SwiftUI

struct ThemingView: View {
    @State private var enableTweak = false
    @StateObject private var dataSingleton = DataSingleton.shared
    @StateObject private var themeManager = ThemingManager.shared
    @State private var easterEgg = false
    private var gridItemLayout = [GridItem(.adaptive(minimum: 160))]
    
    @State private var isAppClips: Bool = false
    @State private var hideAppLabels: Bool = false
    @State private var themeAllApps: Bool = false
    
    @State private var showPicker: Bool = false
        
    var body: some View {
        List {
            Group {
                HStack {
                    Image(systemName: easterEgg ? "doc.badge.gearshape.fill" : "paintbrush")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 35, height: 35).onTapGesture(perform: { easterEgg = !easterEgg })
                    VStack {
                        HStack {
                            Text(easterEgg ? "TrollTools" : "Icon Theming")
                                .bold()
                            Spacer()
                        }
                        HStack {
                            Toggle("Enable", isOn: $enableTweak).onChange(of: enableTweak, perform: {nv in
                                DataSingleton.shared.setTweakEnabled(.themes, isEnabled: nv)
                            }).onAppear(perform: {
                                enableTweak = DataSingleton.shared.isTweakEnabled(.themes)
                            })
                            Spacer()
                        }
                    }
                    Spacer()
                    Button(action: {
                        showPicker.toggle()
                    }) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import")
                    }
                    .padding(.horizontal, 15)
                }
                Divider()
            }
            if true || dataSingleton.deviceAvailable {
                Group {
                    if (themeManager.themes.count == 0) {
                        Text("No themes found.\nDownload themes in the Explore tab or import them using the button in the top right corner.\nThemes have to contain icons in the format of <id>.png.")
                            .padding()
                            .background(Color.cowGray)
                            .multilineTextAlignment(.center)
                            .cornerRadius(16)
                            .font(.footnote)
                            .frame(maxWidth: .infinity)
                    } else {
                        Group {
                            Toggle(isOn: $hideAppLabels) {
                                Text("Hide App Labels")
                            }.onChange(of: hideAppLabels, perform: { nv in
                                try? themeManager.setThemeSettings(hideDisplayNames: nv)
                            })
                            Toggle(isOn: $isAppClips) {
                                Text("As App Clips")
                            }.onChange(of: isAppClips, perform: { nv in
                                try? themeManager.setThemeSettings(appClips: nv)
                            })
//                            Toggle(isOn: $themeAllApps) {
//                                Text("Theme All Apps (Includes apps not included in the selected theme)")
//                            }.onChange(of: themeAllApps, perform: { nv in
//                                try? themeManager.setThemeSettings(themeAllApps: nv)
//                            })
                        }
                        Group {
                            LazyVGrid(columns: gridItemLayout, spacing: 10) {
                                ForEach(themeManager.themes, id: \.name) { theme in
                                    ThemeView(theme: theme)
                                }
                            }
                        }
                    }
                    Divider()
                    HStack {
                        Spacer()
                        VStack {
                            HStack {
                                Text("Current Icons").bold()
                                Spacer()
                                Text("Selecting \"Enabled\" will add a webclip or update an existing one.")
                            }
                            HStack {
                                Spacer()
                                Button("Enable all"){}
                                Button("Disable all"){}
                            }
                        }
                    }
                    VStack {
                        HStack(spacing: 20) {
                            Image(systemName: "app").resizable().frame(width: 50, height: 50)
                            Text("App Store")
                            Text("com.apple.AppStore").foregroundColor(.secondary)
                            Spacer()
                            NiceButton(text: AnyView(Text("Select Icon")), action: {})
                            Toggle("Enabled", isOn: .constant(true))
                        }.padding(20).background(RoundedRectangle(cornerRadius: 20).fill(Color.cowGray))
                        HStack(spacing: 20) {
                            Image(systemName: "app").resizable().frame(width: 50, height: 50)
                            Text("Phone")
                            Text("com.apple.Phone").foregroundColor(.secondary)
                            Spacer()
                            NiceButton(text: AnyView(Text("Remove Icon")), action: {})
                            Toggle("Enabled", isOn: .constant(true))
                        }.padding(20).background(RoundedRectangle(cornerRadius: 20).fill(Color.cowGray))
                    }
                }.disabled(false && !enableTweak)
            }
        }
        .disabled(false && !dataSingleton.deviceAvailable)
        .onAppear {
            themeManager.getThemes()
            hideAppLabels = themeManager.getThemeToggleSetting("HideDisplayNames")
            isAppClips = themeManager.getThemeToggleSetting("AsAppClips")
            themeAllApps = themeManager.getThemeToggleSetting("ThemeAllApps")
        }
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.folder], allowsMultipleSelection: false, onCompletion: { result in
            guard let url = try? result.get().first else { return }
            try? ThemingManager.shared.importTheme(from: url)
        })
    }
}

struct ThemingView_Previews: PreviewProvider {
    static var previews: some View {
        ThemingView()
    }
}
