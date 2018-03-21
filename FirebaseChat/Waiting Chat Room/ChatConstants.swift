//
//  Copyright (c) 2015 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

struct Constants {
 struct MessageFields {
    static let sender_name = "sender_name"
    static let message = "message"
    static let message_type = "message_type"
    static let sender_id = "sender_id"
    static let timestamp = "date"
    static let status = "status"
    static let downloadProgress = "downloadProgress"
  }
}

class ChatDateFormatter{
    
   func findDateOrTime(dateTimeString:Date,dateRequired:Bool,dateFormatForChat:String) -> String{
    
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = dateFormatForChat
        dateformatter.timeZone = NSTimeZone(name: "UTC") as TimeZone!
        
        let convertedToDate = dateTimeString
        dateformatter.dateFormat = dateFormatForChat
        dateformatter.timeZone = NSTimeZone.local
        
        let convertedToRequiredString = dateformatter.string(from: convertedToDate)
        
//            return dateRequired == true ? convertedToRequiredString.components(separatedBy: " ")[0] : convertedToRequiredString.components(separatedBy: " ")[1] + convertedToRequiredString.components(separatedBy: " ")[2]
         return convertedToRequiredString
    }
    
    func getDateStringFromDateString(date: String, fromDateString: String, toDateString: String) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = fromDateString
        let getDate = dateFormatter.date(from: date)
        dateFormatter.dateFormat = toDateString
        return dateFormatter.string(from: getDate!)
    }
    
    
    
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d", minutes, seconds)
    }
    func stringForTimeInterval(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours,minutes, seconds)
    }
    
 }

extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    
    /// Returns the data for the specified image in PNG format
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the PNG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    var png: Data? { return UIImagePNGRepresentation(self) }
    
    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    func jpeg(_ quality: JPEGQuality) -> Data? {
        return UIImageJPEGRepresentation(self, quality.rawValue)
    }
    
    func resizeImageWith(newSize: CGSize) -> UIImage {
        
        let horizontalRatio = newSize.width / size.width
        let verticalRatio = newSize.height / size.height
        
        let ratio = max(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
        draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

