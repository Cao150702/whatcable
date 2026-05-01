import Foundation
import IOKit
import IOKit.usb

@MainActor
final class USBWatcher: ObservableObject {
    @Published private(set) var devices: [USBDevice] = []

    private var notifyPort: IONotificationPortRef?
    private var addedIter: io_iterator_t = 0
    private var removedIter: io_iterator_t = 0

    func start() {
        guard notifyPort == nil else { return }
        let port = IONotificationPortCreate(kIOMainPortDefault)
        IONotificationPortSetDispatchQueue(port, DispatchQueue.main)
        notifyPort = port

        let matching = IOServiceMatching("IOUSBHostDevice") as NSMutableDictionary

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let addedCallback: IOServiceMatchingCallback = { refcon, iterator in
            guard let refcon else { return }
            let watcher = Unmanaged<USBWatcher>.fromOpaque(refcon).takeUnretainedValue()
            Task { @MainActor in watcher.handleAdded(iterator: iterator) }
        }

        let removedCallback: IOServiceMatchingCallback = { refcon, iterator in
            guard let refcon else { return }
            let watcher = Unmanaged<USBWatcher>.fromOpaque(refcon).takeUnretainedValue()
            Task { @MainActor in watcher.handleRemoved(iterator: iterator) }
        }

        IOServiceAddMatchingNotification(
            port,
            kIOMatchedNotification,
            matching.copy() as! CFDictionary,
            addedCallback,
            selfPtr,
            &addedIter
        )
        handleAdded(iterator: addedIter)

        IOServiceAddMatchingNotification(
            port,
            kIOTerminatedNotification,
            matching.copy() as! CFDictionary,
            removedCallback,
            selfPtr,
            &removedIter
        )
        handleRemoved(iterator: removedIter)
    }

    func stop() {
        if addedIter != 0 { IOObjectRelease(addedIter); addedIter = 0 }
        if removedIter != 0 { IOObjectRelease(removedIter); removedIter = 0 }
        if let port = notifyPort {
            IONotificationPortDestroy(port)
            notifyPort = nil
        }
        devices.removeAll()
    }

    private func handleAdded(iterator: io_iterator_t) {
        while case let service = IOIteratorNext(iterator), service != 0 {
            if let device = makeDevice(from: service) {
                if !devices.contains(where: { $0.id == device.id }) {
                    devices.append(device)
                }
            }
            IOObjectRelease(service)
        }
        devices.sort { ($0.productName ?? "") < ($1.productName ?? "") }
    }

    private func handleRemoved(iterator: io_iterator_t) {
        while case let service = IOIteratorNext(iterator), service != 0 {
            var entryID: UInt64 = 0
            IORegistryEntryGetRegistryEntryID(service, &entryID)
            devices.removeAll { $0.id == entryID }
            IOObjectRelease(service)
        }
    }

    private func makeDevice(from service: io_service_t) -> USBDevice? {
        var entryID: UInt64 = 0
        IORegistryEntryGetRegistryEntryID(service, &entryID)

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else {
            return nil
        }

        let vendorID = (dict["idVendor"] as? NSNumber)?.uint16Value ?? 0
        let productID = (dict["idProduct"] as? NSNumber)?.uint16Value ?? 0
        let locationID = (dict["locationID"] as? NSNumber)?.uint32Value ?? 0
        let speedRaw = (dict["Device Speed"] as? NSNumber)?.uint8Value
        let bcdUSB = (dict["bcdUSB"] as? NSNumber)?.uint16Value
        let busPower = (dict["Bus Power Available"] as? NSNumber).map { $0.intValue * 2 }
        let current = (dict["Requested Power"] as? NSNumber).map { $0.intValue * 2 }

        var raw: [String: String] = [:]
        for (k, v) in dict {
            raw[k] = stringify(v)
        }

        return USBDevice(
            id: entryID,
            locationID: locationID,
            vendorID: vendorID,
            productID: productID,
            vendorName: dict["USB Vendor Name"] as? String,
            productName: dict["USB Product Name"] as? String,
            serialNumber: dict["USB Serial Number"] as? String,
            usbVersion: bcdUSB.map { formatBCD($0) },
            speedRaw: speedRaw,
            busPowerMA: busPower,
            currentMA: current,
            rawProperties: raw
        )
    }

    private func formatBCD(_ value: UInt16) -> String {
        let major = (value >> 8) & 0xFF
        let minor = (value >> 4) & 0xF
        let sub = value & 0xF
        return sub == 0 ? "\(major).\(minor)" : "\(major).\(minor).\(sub)"
    }

    private func stringify(_ value: Any) -> String {
        switch value {
        case let n as NSNumber: return n.stringValue
        case let s as String: return s
        case let d as Data: return d.map { String(format: "%02X", $0) }.joined(separator: " ")
        case let a as [Any]: return "[\(a.map { stringify($0) }.joined(separator: ", "))]"
        default: return String(describing: value)
        }
    }
}

