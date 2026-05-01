import Foundation

public struct USBDevice: Identifiable, Hashable {
    public let id: UInt64
    public let locationID: UInt32
    public let vendorID: UInt16
    public let productID: UInt16
    public let vendorName: String?
    public let productName: String?
    public let serialNumber: String?
    public let usbVersion: String?
    public let speedRaw: UInt8?
    public let busPowerMA: Int?
    public let currentMA: Int?
    public let rawProperties: [String: String]

    public init(
        id: UInt64,
        locationID: UInt32,
        vendorID: UInt16,
        productID: UInt16,
        vendorName: String?,
        productName: String?,
        serialNumber: String?,
        usbVersion: String?,
        speedRaw: UInt8?,
        busPowerMA: Int?,
        currentMA: Int?,
        rawProperties: [String: String]
    ) {
        self.id = id
        self.locationID = locationID
        self.vendorID = vendorID
        self.productID = productID
        self.vendorName = vendorName
        self.productName = productName
        self.serialNumber = serialNumber
        self.usbVersion = usbVersion
        self.speedRaw = speedRaw
        self.busPowerMA = busPowerMA
        self.currentMA = currentMA
        self.rawProperties = rawProperties
    }

    public var speedLabel: String {
        // IOUSBHostDevice "Device Speed" enum values
        switch speedRaw {
        case 0: return "Low Speed (1.5 Mbps)"
        case 1: return "Full Speed (12 Mbps)"
        case 2: return "High Speed (480 Mbps)"
        case 3: return "Super Speed (5 Gbps)"
        case 4: return "Super Speed+ (10 Gbps)"
        case 5: return "Super Speed+ Gen 2x2 (20 Gbps)"
        default: return "Unknown speed"
        }
    }
}
