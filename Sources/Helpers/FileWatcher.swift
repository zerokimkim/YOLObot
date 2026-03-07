import Foundation

final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private let fileDescriptor: Int32
    private let callback: () -> Void

    init?(path: String, callback: @escaping () -> Void) {
        self.callback = callback
        self.fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return nil }
    }

    func start() {
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .extend],
            queue: .global(qos: .utility)
        )
        source.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.callback()
            }
        }
        source.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
            }
        }
        source.resume()
        self.source = source
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    deinit {
        stop()
    }
}
