//
//  ThemingManager.swift
//  CowabungaJailed
//
//  Created by lemin on 3/24/23.
//

import Foundation
import AppKit

class ThemingManager: ObservableObject {
    static let shared = ThemingManager()
    @Published var currentTheme: String? = nil
    var processing: Bool = false
    @Published var themes: [ThemingManager.Theme] = []
    
    struct AppIconChange {
        var appID: String
        var themeIconURL: URL?
        var name: String
    }
    
    struct Theme: Codable, Identifiable, Equatable {
        var id = UUID()
        
        var name: String
        var iconCount: Int
    }
    
    private static let filePath: String = "HomeDomain/Library/WebClips"
    
    public func makeInfoPlist(displayName: String = " ", bundleID: String, isAppClip: Bool = false) throws -> Data {
        let info: [String: Any] = [
            "ApplicationBundleIdentifier": bundleID,
            "ApplicationBundleVersion": 1,
            "ClassicMode": false,
            "ConfigurationIsManaged": false,
            "ContentMode": "UIWebClipContentModeRecommended",
            "FullScreen": true,
            "IconIsPrecomposed": false,
            "IconIsScreenShotBased": false,
            "IgnoreManifestScope": false,
            "IsAppClip": isAppClip,
            "Orientations": 0,
            "ScenelessBackgroundLaunch": false,
            "Title": displayName,
            "WebClipStatusBarStyle": "UIWebClipStatusBarStyleDefault",
            "RemovalDisallowed": false
        ]
        
        return try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
    }
    
    public func getAppliedThemeFolder() -> URL? {
        return DataSingleton.shared.getCurrentWorkspace()?.appendingPathComponent("AppliedTheme/HomeDomain/Library/WebClips")
    }
    
    public func getCurrentAppliedTheme() -> String? {
        guard let appliedThemes = getAppliedThemeFolder() else {
            return nil
        }
        let infoPlist = appliedThemes.appendingPathComponent("Info.plist")
        if !FileManager.default.fileExists(atPath: infoPlist.path) {
            return nil
        }
        guard let infoData = try? Data(contentsOf: infoPlist) else {
            return nil
        }
        guard let plist = try? PropertyListSerialization.propertyList(from: infoData, options: [], format: nil) as? [String: Any] else { return nil }
        guard let name = plist["ThemeName"] as? String else { return nil }
        return name
    }
    
    public func makeWebClip(displayName: String = " ", image: Data, bundleID: String, isAppClip: Bool = false) throws {
        let folderName: String = "Cowabunga_" + bundleID + ".webclip"// + String(bundleID.data(using: .utf8)!.base64EncodedString()) + ".webclip"
        guard let folderURL = getAppliedThemeFolder()?.appendingPathComponent(folderName) else {
            throw "Error getting webclip folder"
        }
        do {
            if !FileManager.default.fileExists(atPath: folderURL.path) {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false)
            }
            // create the info plist
            let infoPlist = try makeInfoPlist(displayName: displayName, bundleID: bundleID, isAppClip: isAppClip)
            try? FileManager.default.removeItem(at: folderURL.appendingPathComponent("Info.plist")) // delete if info plist already exists
            try infoPlist.write(to: folderURL.appendingPathComponent("Info.plist"))
            // write the icon file
            try? FileManager.default.removeItem(at: folderURL.appendingPathComponent("icon.png")) // delete if icon already exists
            try image.write(to: folderURL.appendingPathComponent("icon.png"))
        } catch {
            // remove from backup
            try? FileManager.default.removeItem(at: folderURL)
            throw "Error creating WebClip for icon bundle \(bundleID)"
        }
    }
    
    public func eraseAppliedTheme() {
        processing = true
        guard let appliedFolder = getAppliedThemeFolder() else {
            processing = false
            return
        }
        do {
            for folder in try FileManager.default.contentsOfDirectory(at: appliedFolder, includingPropertiesForKeys: nil) {
                try? FileManager.default.removeItem(at: folder)
            }
            processing = false
        } catch {
            processing = false
            print(error.localizedDescription)
        }
    }
    
    public func getThemesFolder() -> URL {
        let themesFolder = documentsDirectory.appendingPathComponent("Themes")
        if !FileManager.default.fileExists(atPath: themesFolder.path) {
            try? FileManager.default.createDirectory(at: themesFolder, withIntermediateDirectories: false)
        }
        return themesFolder
    }
    
    public func applyTheme(themeName: String, hideDisplayNames: Bool = false, appClips: Bool = false) throws {
        let themeFolder = getThemesFolder().appendingPathComponent(themeName)
        if !FileManager.default.fileExists(atPath: themeFolder.path) {
            throw "No theme folder found for \(themeName)!"
        }
        guard let infoPlistPath = getAppliedThemeFolder()?.appendingPathComponent("Info.plist") else { return }
        if FileManager.default.fileExists(atPath: infoPlistPath.path) {
            try? FileManager.default.removeItem(at: infoPlistPath)
        }
        let newPlist = try PropertyListSerialization.data(fromPropertyList: ["ThemeName": themeName], format: .xml, options: 0)
        try newPlist.write(to: infoPlistPath)
        let apps = getHomeScreenApps()
        
        for file in try FileManager.default.contentsOfDirectory(at: themeFolder, includingPropertiesForKeys: nil) {
            let bundleID: String = file.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "-large", with: "")
            // CHECK IF THE USER HAS THE BUNDLE ID INSTALLED
            // IF NOT, CONTINUE
            if apps[bundleID] == nil { continue }
            var displayName: String = " "
            if !hideDisplayNames {
                // get the display name from the bundle id
                displayName = apps[bundleID]!
            }
            do {
                let imgData = try Data(contentsOf: file)
                try makeWebClip(displayName: displayName, image: imgData, bundleID: bundleID, isAppClip: appClips)
            } catch {
                Logger.shared.logMe(error.localizedDescription)
            }
        }
    }
    
    public func getThemes() {
        let themesFolder = getThemesFolder()
        themes.removeAll(keepingCapacity: true)
        do {
            for t in try FileManager.default.contentsOfDirectory(at: themesFolder, includingPropertiesForKeys: nil) {
                guard let c = try? FileManager.default.contentsOfDirectory(at: t, includingPropertiesForKeys: nil) else { continue }
                themes.append(.init(name: t.lastPathComponent, iconCount: (c).count))
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    public func icons(forAppIDs: [String], from: ThemingManager.Theme) throws -> [NSImage?] {
        let themesFolder = getThemesFolder().appendingPathComponent(from.name)
        var finals: [NSImage?] = []
        for d in forAppIDs {
            if FileManager.default.fileExists(atPath: themesFolder.appendingPathComponent(d+"-large.png").path) {
                finals.append(NSImage(contentsOf: themesFolder.appendingPathComponent(d+"-large.png")))
            }
        }
        return finals
    }
    
    public func isCurrentTheme(_ name: String) -> Bool {
        return currentTheme == name
    }
}
