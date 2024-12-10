import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var filePath: String = ""
    @State private var outputLog: String = ""

    var body: some View {
        VStack {
            Text("Madows")
                .font(.largeTitle)
                .padding()

            Button("Choisir un fichier .exe ou .msi") {
                chooseFile()
            }
            .padding()

            TextField("Chemin du fichier sélectionné", text: $filePath)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Lancer le fichier") {
                checkAndRunExecutable(filePath: filePath)
            }
            .padding()

            ScrollView {
                Text(outputLog)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .frame(width: 600, height: 400)
    }

    func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.init(filenameExtension: "exe")!, .init(filenameExtension: "msi")!]

        if panel.runModal() == .OK, let selectedFile = panel.url?.path {
            filePath = selectedFile
            outputLog.append("Fichier sélectionné : \(selectedFile)\n")
        } else {
            outputLog.append("Aucun fichier sélectionné.\n")
        }
    }

    func checkAndRunExecutable(filePath: String) {
        let winePath = "/usr/local/bin/wine"

        if !FileManager.default.fileExists(atPath: winePath) {
            outputLog.append("Wine n'est pas installé. Installation en cours...\n")
            installWine { success in
                if success {
                    outputLog.append("Wine installé avec succès !\n")
                    runExecutable(filePath: filePath)
                } else {
                    outputLog.append("Échec de l'installation de Wine.\n")
                }
            }
        } else {
            outputLog.append("Wine est déjà installé.\n")
            runExecutable(filePath: filePath)
        }
    }

    func installWine(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global().async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["brew", "install", "--cask", "wine-stable"]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()

                let status = process.terminationStatus
                DispatchQueue.main.async {
                    completion(status == 0)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    func runExecutable(filePath: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/wine")
        process.arguments = [filePath]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Erreur inconnue"
            outputLog.append(output)
        } catch {
            outputLog.append("Échec de l'exécution : \(error.localizedDescription)\n")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

