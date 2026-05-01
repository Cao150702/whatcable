import Foundation

/// Discover Identity response from a USB-PD endpoint, parsed from
/// `IOPortTransportComponentCCUSBPDSOP` services.
struct PDIdentity: Identifiable, Hashable {
    enum Endpoint: String {
        case sop = "SOP"        // Port partner (the connected device/charger)
        case sopPrime = "SOP'"  // Cable's near-side e-marker
        case sopDoublePrime = "SOP''" // Cable's far-side e-marker
        case unknown
    }

    let id: UInt64
    let endpoint: Endpoint
    let parentPortType: Int
    let parentPortNumber: Int
    let vendorID: Int
    let productID: Int
    let bcdDevice: Int
    let vdos: [UInt32]
    let specRevision: Int

    var portKey: String { "\(parentPortType)/\(parentPortNumber)" }

    var idHeader: PDVDO.IDHeader? {
        guard let v = vdos.first else { return nil }
        return PDVDO.decodeIDHeader(v)
    }

    /// The Cable VDO is at index 3 (VDO[3] in 1-indexed PD spec terms).
    var cableVDO: PDVDO.CableVDO? {
        guard endpoint == .sopPrime || endpoint == .sopDoublePrime,
              vdos.count > 3 else { return nil }
        let header = idHeader
        let isActive = header?.ufpProductType == .activeCable
        return PDVDO.decodeCableVDO(vdos[3], isActive: isActive)
    }
}
