import Foundation

enum ShellExecutor {
    @discardableResult
    static func run(_ command: String) -> (output: String, exitCode: Int32) {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ("Error: \(error.localizedDescription)", -1)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return (output, process.terminationStatus)
    }

    static func runAsync(_ command: String, completion: @escaping (String, Int32) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = run(command)
            DispatchQueue.main.async {
                completion(result.output, result.exitCode)
            }
        }
    }
}
