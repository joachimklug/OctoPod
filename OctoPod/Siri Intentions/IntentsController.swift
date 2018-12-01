import Foundation
import UIKit

class IntentsController {
    
    func bedTemperature(printer: Printer, temperature: NSNumber?, callback: @escaping (Bool, Int?, Int) -> Void) {
        let restClient = getRESTClient(hostname: printer.hostname, apiKey: printer.apiKey, username: printer.username, password: printer.password)
        var newTarget: Int = 0
        if let temperature = temperature {
            let tempInt = Int(truncating: temperature)
            newTarget = tempInt <= 0 ? 0 : tempInt
        }
        restClient.bedTargetTemperature(newTarget: newTarget) { (requested: Bool, error: Error?, response: HTTPURLResponse) in
            callback(requested, newTarget, response.statusCode)
        }
    }
    
    func toolTemperature(printer: Printer, tool: NSNumber?, temperature: NSNumber?, callback: @escaping (Bool, Int?, Int) -> Void) {
        let restClient = getRESTClient(hostname: printer.hostname, apiKey: printer.apiKey, username: printer.username, password: printer.password)
        var toolNumber = 0
        if let tool = tool {
            toolNumber = Int(truncating: tool)
        }
        var newTarget: Int = 0
        if let temperature = temperature {
            let tempInt = Int(truncating: temperature)
            newTarget = tempInt <= 0 ? 0 : tempInt
        }
        restClient.toolTargetTemperature(toolNumber: toolNumber, newTarget: newTarget) { (requested: Bool, error: Error?, response: HTTPURLResponse) in
            callback(requested, newTarget, response.statusCode)
        }
    }
    
    func coolDownPrinter(printer: Printer, callback: @escaping (Bool, Int) -> Void) {
        let restClient = getRESTClient(hostname: printer.hostname, apiKey: printer.apiKey, username: printer.username, password: printer.password)
        // Cool down extruder 0
        restClient.toolTargetTemperature(toolNumber: 0, newTarget: 0) { (requested: Bool, error: Error?, response: HTTPURLResponse) in
            if requested {
                // Request worked so now request to cool down bed
                restClient.bedTargetTemperature(newTarget: 0, callback: { (requested: Bool, error: Error?, response: HTTPURLResponse) in
                    callback(requested, response.statusCode)
                })
            } else {
                callback(requested, response.statusCode)
            }
        }
    }
    
    func pauseJob(printer: Printer, callback: @escaping (Bool, Int) -> Void) {
        let restClient = getRESTClient(hostname: printer.hostname, apiKey: printer.apiKey, username: printer.username, password: printer.password)
        restClient.pauseCurrentJob { (requested: Bool, error: Error?, response: HTTPURLResponse) in
            callback(requested, response.statusCode)
        }
    }
    
    func resumeJob(printer: Printer, callback: @escaping (Bool, Int) -> Void) {
        let restClient = getRESTClient(hostname: printer.hostname, apiKey: printer.apiKey, username: printer.username, password: printer.password)
        restClient.resumeCurrentJob { (requested: Bool, error: Error?, response: HTTPURLResponse) in
            callback(requested, response.statusCode)
        }
    }
    
    func cancelJob(printer: Printer, callback: @escaping (Bool, Int) -> Void) {
        let restClient = getRESTClient(hostname: printer.hostname, apiKey: printer.apiKey, username: printer.username, password: printer.password)
        restClient.cancelCurrentJob { (requested: Bool, error: Error?, response: HTTPURLResponse) in
            callback(requested, response.statusCode)
        }
    }
    
    func restartJob(printer: Printer, callback: @escaping (Bool, Int) -> Void) {
        let restClient = getRESTClient(hostname: printer.hostname, apiKey: printer.apiKey, username: printer.username, password: printer.password)
        restClient.restartCurrentJob { (requested: Bool, error: Error?, response: HTTPURLResponse) in
            callback(requested, response.statusCode)
        }
    }
    
    func remainingTime(printer: Printer, callback: @escaping (Bool, String?, Int) -> Void) {
        let restClient = getRESTClient(hostname: printer.hostname, apiKey: printer.apiKey, username: printer.username, password: printer.password)
        restClient.currentJobInfo { (result: NSObject?, error: Error?, response: HTTPURLResponse) in
            if let result = result as? Dictionary<String, Any>, let progress = result["progress"] as? Dictionary<String, Any> {
                if let printTimeLeft = progress["printTimeLeft"] as? Int {
                    callback(true, self.secondsToTimeLeft(seconds: printTimeLeft), response.statusCode)
                } else {
                    callback(true, "0", response.statusCode)
                }
            } else {
                callback(false, nil, response.statusCode)
            }
        }
    }
    
    // MARK: - Private functions
    
    fileprivate func getRESTClient(hostname: String, apiKey: String, username: String?, password: String?) -> OctoPrintRESTClient {
        let restClient = OctoPrintRESTClient()
        restClient.connectToServer(serverURL: hostname, apiKey: apiKey, username: username, password: password)
        return restClient
    }

    fileprivate func secondsToTimeLeft(seconds: Int) -> String {
        if seconds == 0 {
            return ""
        } else if seconds < 0 {
            // Should never happen but an OctoPrint plugin is returning negative values
            // so return 'Unknown' when this happens
            return NSLocalizedString("Unknown", comment: "ETA is Unknown")
        }
        let duration = TimeInterval(seconds)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .brief
        formatter.includesApproximationPhrase = true
        formatter.allowedUnits = [ .day, .hour, .minute ]
        return formatter.string(from: duration)!
    }
}
