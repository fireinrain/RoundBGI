//
//  AppDelegate.swift
//  RoundBGI
//
//  Created by sunrise on 2022/6/26.
//  Copyright © 2022 sunrise. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    // 不需要显示窗口
    // var window: NSWindow!

    // 文件管理器
    let fileManager = FileManager.default

    // 需要的图片文件后缀
    let filteredTypes = [String](arrayLiteral: "jpg", "png", "jpeg")

    // image 集合
    var imageCollection = [NSURL]()

    // pre desktop background image path
    //[Screen:imagePath]
    var preBackgroundImagePath : [NSScreen: [String:Any]] = [NSScreen: [String:Any]]()


    // 状态栏
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    @IBOutlet weak var menu: NSMenu!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        // let contentView = ContentView()

        // Create the window and set the content view. 
        // window = NSWindow(
        //    contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
        //    styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
        //    backing: .buffered, defer: false)
        // window.center()
        // window.setFrameAutosaveName("Main Window")
        // window.contentView = NSHostingView(rootView: contentView)
        // window.makeKeyAndOrderFront(nil)

        if let button = statusItem.button {
            button.image = NSImage(named: "StatusIcon")
        }

        statusItem.menu = menu

        // 获取当前壁纸路径
        // 保存当前壁纸
        do {
            let screens = NSScreen.screens
            for sc in screens {
                let desktopImageURL = NSWorkspace.shared.desktopImageURL(for: sc)
                let desktopImageOptions = NSWorkspace.shared.desktopImageOptions(for: sc)
                var imageURLAndOptions = [String:Any]()
                imageURLAndOptions.updateValue(desktopImageURL as Any,forKey:"imageURL")
                imageURLAndOptions.updateValue(desktopImageOptions as Any,forKey:"imageOptions")

                self.preBackgroundImagePath.updateValue(imageURLAndOptions, forKey: sc)
                // print("desktopImageURL:\(desktopImageURL)")
            }
            // print("\(screens)")
            // print("\(self.preBackgroundImagePath)")
        } catch {
            print(error)
        }


    }

    @IBAction func actionForSetImgDir(_ sender: Any) {
        print("选择图片目录")
        let openPanel = NSOpenPanel()
        // Set openPanel settings for just directories
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowedFileTypes = ["none"]
        openPanel.allowsOtherFileTypes = false
        if (openPanel.runModal() == NSApplication.ModalResponse.OK) {
            let result = openPanel.urls.first!
            let dirChoosed = result.absoluteURL

            let allFilePath = self.fileManager.enumerator(at: dirChoosed,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles,
                    errorHandler: nil)
            let files = allFilePath?.allObjects

            let filteredFiles = self.filterDirFromFiles(files: files!)
            // print("filteredFiles: \(filteredFiles)")

            let imagePaths = self.filterFilesToImage(files: filteredFiles, filteredTypes: self.filteredTypes)

            // 修改背景图
            let imageA = URL(fileURLWithPath: "/Users/sunrise/Pictures/duvor.jpeg")
            do{
                if let cuScreen = NSScreen.main{
                    try NSWorkspace.shared.setDesktopImageURL(imageA, for: cuScreen,options:[
                        NSWorkspace.DesktopImageOptionKey.allowClipping:2
                    ])
                }
            }catch{
                print(error)
            }


            _ = "empty dir"
            // print("全部文件 : \(files ?? [defaultValue])")
            print("用户选择的目录为: \(result)")
        } else {
            // handle user clicking "cancel
            print("用户已取消选择")
        }

    }

    /**
     从文件路径中过滤出文件后缀为jpg 或者是jpeg png 的文件
     - Parameter files:
     - Parameter filteredType:
     - Returns:
     */
    func filterFilesToImage(files: [String], filteredTypes: [String]) -> [String] {
        var filteredTypesWithCase = [String]()
        var resultFiles = [String]()
        for type in filteredTypes {
            let uppercased = type.uppercased()
            filteredTypesWithCase.append(type)
            filteredTypesWithCase.append(uppercased)
        }

        for file in files {
            for type in filteredTypesWithCase {
                if file.hasPrefix(type) {
                    resultFiles.append(file)
                    continue
                }
            }
        }
        return resultFiles
    }

    /**
        过滤文件目录
     - Parameter files:
     - Returns:
     */
    func filterDirFromFiles(files: [Any]) -> [String] {
        var result = [String]()

        if files.count <= 0 {
            return result
        }
        for index in files {
            let indexUrl = index as! NSURL
            // print(indexUrl.filePathURL!)
            let isDir = self.fileManager.isDirectory(atPath: indexUrl.absoluteString!)
            if isDir == true {
                // print("index \(index) is Directory")
                continue
            }
            result.append(indexUrl.absoluteString!)
        }

        return result
    }

    // 退出运行
    @IBAction func actionForquitApp(_ sender: Any) {
        // 获取开始运行的壁纸地址 然后设置回来
        NSApplication.shared.terminate(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        print("程序即将关闭")
        // 把壁纸设置回去
        print("重置壁纸中")
        let screens = NSScreen.screens
        for sc in screens {
            let imageAndOptionsDic = self.preBackgroundImagePath[sc]
            guard let value = imageAndOptionsDic?["imageURL"] else {
                fatalError("guard failure handling has not been implemented")
            }
            let image = value
            let imageOptions = imageAndOptionsDic?["imageOptions"]
            let imageStr = image as! URL

            // print("-----: \(imageStr)")
            let imageBackOptions = imageOptions as! [NSWorkspace.DesktopImageOptionKey : Any]?
            do{
                try NSWorkspace.shared.setDesktopImageURL(imageStr, for: sc, options: imageBackOptions!)
            }catch{
                print(error)
            }
            // print("desktopImageURL:\(desktopImageURL)")
        }
    }


}


/**
 扩展FileManager 使其支持判断文件是否为目录
 */
extension FileManager {
    func isDirectory(atPath: String) -> Bool {
        // remote file://
        let atPath = atPath.replacingOccurrences(of: "file://", with: "")
        var check: ObjCBool = false
        if fileExists(atPath: atPath, isDirectory: &check) {
            return check.boolValue
        } else {
            return false
        }
    }
}



