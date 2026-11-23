import SwiftUI
import IOKit.ps

// MARK: - Rotating Bible verses
private let verses: [(String, String)] = [
    ("Der Herr ist mein Hirte, mir wird nichts mangeln.", "Psalm 23,1"),
    ("Seid stille und erkennt, dass ich Gott bin.", "Psalm 46,11"),
    ("Dein Wort ist meines Fußes Leuchte und ein Licht auf meinem Wege.", "Psalm 119,105"),
    ("Alle eure Sorge werft auf ihn; denn er sorgt für euch.", "1. Petrus 5,7"),
    ("Ich vermag alles durch den, der mich mächtig macht.", "Philipper 4,13"),
    ("Kommt her zu mir, alle, die ihr mühselig und beladen seid; ich will euch erquicken.", "Matthäus 11,28"),
    ("Die auf den Herrn harren, kriegen neue Kraft.", "Jesaja 40,31"),
    ("Ich bin das Licht der Welt.", "Johannes 8,12"),
    ("Fürchte dich nicht, denn ich bin mit dir.", "Jesaja 41,10"),
    ("Gott ist Liebe.", "1. Johannes 4,16"),
]

// MARK: - Battery status via IOKit
private func battery() -> (Int, Bool)? {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
    for ps in list {
        if let d = IOPSGetPowerSourceDescription(info, ps)?.takeUnretainedValue() as? [String: Any],
           let cap = d[kIOPSCurrentCapacityKey] as? Int {
            return (cap, d[kIOPSIsChargingKey] as? Bool ?? false)
        }
    }
    return nil
}
