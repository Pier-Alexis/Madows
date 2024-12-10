import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var filePath: String = ""
    @State private var outputLog: String = ""
    @State private var isRunning = false
    @State private var progressValue: Double = 0.0

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
                isRunning = true
                progressValue = 0.0
                checkAndInstallWine { success in
                    if success {
                        runExecutable(filePath: filePath)
                    }
                    isRunning = false
                }
            }
            .padding()
            .disabled(isRunning)

            if isRunning {
                ProgressView("Exécution en cours...", value: progressValue, total: 100)
                    .padding()
            }

            ScrollView {
                Text(outputLog)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .frame(width: 600, height: 500)
    }

    func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.init(filenameExtension: "exe")!, .init(filenameExtension: "msi")!]

        if panel.runModal() == .OK, let selectedFile = panel.url?.path {
            if validateFile(selectedFile) {
                filePath = selectedFile
                outputLog.append("Fichier sélectionné : \(selectedFile)\n")
            } else {
                outputLog.append("Erreur : Le fichier sélectionné n'est pas valide.\n")
            }
        } else {
            outputLog.append("Aucun fichier sélectionné.\n")
        }
    }

    func validateFile(_ path: String) -> Bool {
        // Vérifie si le fichier est accessible et a une taille non nulle.
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path), let attributes = try? fileManager.attributesOfItem(atPath: path) {
            if let fileSize = attributes[.size] as? Int, fileSize > 0 {
                return true
            }
        }
        return false
    }

    func checkAndInstallWine(completion: @escaping (Bool) -> Void) {
        let winePath = "/usr/local/bin/wine"

        if FileManager.default.fileExists(atPath: winePath) {
            completion(true) // Wine est déjà installé.
        } else {
            outputLog.append("Wine n'est pas installé. Installation en cours...\n")
            installWine { success in
                if success {
                    outputLog.append("Wine installé avec succès !\n")
                    completion(true)
                } else {
                    outputLog.append("Échec de l'installation de Wine.\n")
                    completion(false)
                }
            }
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
        DispatchQueue.global().async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/wine")
            process.arguments = [filePath]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()

                // Mise à jour fictive de la progression
                for i in 0...100 {
                    Thread.sleep(forTimeInterval: 0.05)
                    DispatchQueue.main.async {
                        progressValue = Double(i)
                    }
                }

                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? "Erreur inconnue"
                DispatchQueue.main.async {
                    outputLog.append(output)
                }
            } catch {
                DispatchQueue.main.async {
                    outputLog.append("Échec de l'exécution : \(error.localizedDescription)\n")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
