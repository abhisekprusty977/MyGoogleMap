//
//  CEnumClass.swift
//  MyGoogleMap
//
//  Created by Abhisek Prusty on 24/02/23.
//

import Foundation
import AVFoundation
class CEnumObj: NSObject {
    static let shareInstance = CEnumObj()
    
    func convertToJSON(resulTDict:NSDictionary) -> NSDictionary{
        let theJSONData = try? JSONSerialization.data(withJSONObject: resulTDict, options: JSONSerialization.WritingOptions(rawValue: 0))
        let jsonString = NSString(data: theJSONData!, encoding: String.Encoding.utf8.rawValue)
        let returnDict = self.convertToDictionary(text:jsonString! as String)
        let userData = returnDict as NSDictionary? as? [AnyHashable: Any] ?? [:]
        return userData as NSDictionary
        
    }
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8){
            do {
                let jsonDict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: UInt(0)))
                return jsonDict as? [String : Any]
            } catch {
                //print(error.localizedDescription)
            }
        }
        return nil
    }
}
