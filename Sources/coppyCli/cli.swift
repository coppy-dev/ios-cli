
import Foundation

@main
struct Cli {
    static func generateCommand(configPath: String?, outputPath: String?, classPrefix: String?) async {
        let currentDirectoryUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        var configUrl = currentDirectoryUrl.appendingPathComponent("Coppy.plist")
        if let configPath = configPath  {
            configUrl = URL(fileURLWithPath: configPath)
        }
        
        guard let config = try? Coppy.loadConfig(configUrl: configUrl) else {
            print("Failed to read Coppy config file. Make sure you're passing correct path, and that the file exists")
            exit(1)
        }
        
        let content: [String: Any]
        do {
            content = try await Coppy.download(config: config)
        } catch {
            print("Failed to download data")
            print(error.localizedDescription)
            exit(1)
        }
        
        let generatedContent: String
                do {
            generatedContent = try CoppyGenerator.generateContentFile(content, classPrefix: classPrefix)
        } catch {
            print("Failed to generate content")
            print(error.localizedDescription)
            exit(1)
        }
        
        var outputUrl = currentDirectoryUrl.appendingPathComponent("coppyContent.swift")
        if let outputPath = outputPath  {
            outputUrl = URL(fileURLWithPath: outputPath)
        }
        
        do {
            try FileManager.default.createDirectory(
                at: outputUrl.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try generatedContent.write(to: outputUrl, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write generated content")
            print(error.localizedDescription)
            exit(1)
        }
        
        exit(0)
    }
    
    static func main() async {
        // Parse the command-line arguments and run the appropriate subcommand
        let arguments = CommandLine.arguments
        guard arguments.count >= 2 else {
            print("""
                Usage: coppy generate [path/to/config/file.plist] [path/to/output.swift] [ClassPrefix]
                
                Coppy CLI is a companion tool for the Coppy SDK. It generates swift
                classes that will be used by the SDk in the runtime.
                
                Arguments:
                - path/to/config/file.plist     Path to a Property List file with Coppy config. The
                                                file should contain the ContentKey property, which
                                                will be used to load the appropriate content.
                
                                                If this argument is ommited, the tool will look for the
                                                Coppy.plist file in the current working directory.
                
                
                - path/to/output.swift          Path where the generated content should be saved.
                                                It should be a swift file, that then should be picked
                                                up by your build system.
                
                                                If this argument is ommited, the tool will save the
                                                generated classes in "coppyContent.swift" file in
                                                current working directory.
                
                
                - ClassPrefix                   Optional class prefix. By default, this tool will generate
                                                main content class with "CoppyContent" name. However, you
                                                can alter that name and pass prefix, so the name of the
                                                generated class will become "ClassPrefixCoppyContent".
                """)
            exit(1)
        }
        let subcommand = arguments[1]
        switch subcommand {
            
        case "generate", "g":
            let configPath = arguments.count >= 3 ? arguments[2] : nil
            let outputPath = arguments.count >= 4 ? arguments[3] : nil
            let classPrefix = arguments.count >= 5 ? arguments[4] : nil
            await generateCommand(configPath: configPath, outputPath: outputPath, classPrefix: classPrefix)
            
        default:
            print("Unknown coppy command: \(subcommand)")
            exit(1)
        }
    }

}
