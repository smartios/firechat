//
//  FirebaseMethods.swift
//  mPower
//
//  Created by SS042 on 05/09/17.
//
//

import Foundation
import Firebase

class FirebaseMethods {

    var userDetail = NSMutableArray()
    
    //Firebase variables
    var reference:DatabaseReference!
    fileprivate var _refHandle: DatabaseHandle!
    var storageRef: StorageReference!
    var grpMsgRef:DatabaseReference!
    var msgRef :DatabaseReference!
    var logRef:DatabaseReference!
    let dateFormat = ChatDateFormatter()
    
    init(base_url:String,user:String) {
        
        //---- reference of the database----//
        
        reference = Database.database().reference(fromURL: base_url)
        self.msgRef = reference
        self.grpMsgRef = self.msgRef
    }


    
    //MARK:- Fetch last 10 messages from firebase
    
    func fetchMessages(completionHandler:@escaping (_ data:NSMutableArray) -> Void){
        grpMsgRef.child("messages").queryOrderedByKey().observeSingleEvent(of: .value, with: {  (snapshot) -> Void in
            print(snapshot)
            let messages = NSMutableArray()
            for snap in snapshot.children{
                
               messages.add(snap as! DataSnapshot)
            }
            completionHandler(messages)
        })
    }
   
    //MARK:- Fetch total number of messages
    func fetchTotalNumberOfmessages(completionHandler:@escaping (_ data:Int) -> Void){
        grpMsgRef.child("messages").queryOrderedByKey().observe(.value, with: {  (snapshot) -> Void in
            let count = Int(snapshot.childrenCount)
            completionHandler(count)
        })
    }
    
    //MARK:- Fetch message with page
    func fetchMessagesWithPage(endtimeStamp:TimeInterval,starttimeStamp:TimeInterval,completionHandler:@escaping (_ data:NSMutableArray) -> Void){
        
        grpMsgRef.child("messages").queryOrdered(byChild: "date").queryStarting(atValue: starttimeStamp, childKey: "date").queryEnding(atValue: endtimeStamp, childKey: "date").queryLimited(toLast: 11).observe(.value, with: {  (snapshot) -> Void in
            print(snapshot)
            let messages = NSMutableArray()
            for snap in snapshot.children{
                
                messages.add((snap as! DataSnapshot).value as! NSDictionary)
            }
            messages.removeObject(at: messages.count - 1)
            completionHandler(messages)
        })
    }
    
    //MARK: Configure message observer to fetch,receive and send messages
    func configureChatDatabase(completionHandler:@escaping (_ data:NSDictionary,_ key:String) -> Void){
        // Listen for new messages in the Firebase database
        _refHandle = grpMsgRef.child("messages").observe(.childAdded, with: {  (snapshot) -> Void in
            print(snapshot)
            completionHandler(snapshot.value as! NSDictionary,"\(snapshot.key)")
        })
        
    }
    
    //MARK:- Configure chat databse to observe change in value of child
    func configurecChatToObserveChange(completionHandler:@escaping (_ data:NSDictionary,_ key:String) -> Void){
        // Listen for new messages in the Firebase database
        
         grpMsgRef.child("messages").observe(.childChanged, with: {  (snapshot) -> Void in
            print(snapshot)
            completionHandler(snapshot.value as! NSDictionary,"\(snapshot.key)")
          
        })
    }
    
    //MARK: Send message to firebase
    func sendMessage(withData data: [String: Any],groupUniqueID:String) {
       
        
        self.msgRef.child("messages").childByAutoId().setValue(data)
        
    }
    
    
    /// Upload media(audio/vedio) content in firebase
    ///
    /// - Parameters:
    ///   - type: File type (.mp4.mp3 etc..)
    ///   - filePath: local devide path of file
    ///   - referenceURL: Loacl file path url
    ///   - groupUniqueID: unique id of group
    ///   - completionHandler: return success/fail
    func sendMedia(type:String,filePath:String,referenceURL:URL,groupUniqueID:String,completionHandler:@escaping (_ status:String) -> Void){
        /*Store media in firebase */
        Storage.storage().reference().child(filePath)
            .putFile(from: referenceURL, metadata: nil) { (metadata, error) in
                let downloadURL = Storage.storage().reference().child((metadata?.path)!).description
                var data:[String:Any] = ["date": ServerValue.timestamp()]
                data[Constants.MessageFields.message] = "\(downloadURL)"
                data[Constants.MessageFields.message_type] = "\(type)"
                
                if error != nil {
                    data[Constants.MessageFields.status] = "failed"
                }else{
                    data[Constants.MessageFields.status] = "sent"
                }
                self.sendMessage(withData: data, groupUniqueID: groupUniqueID)
        }
    }
    
    
    /// Upload image in firebase
    ///
    /// - Parameters:
    ///   - imgData: Image data
    ///   - fileName: Name of image
    ///   - groupUniqueID: group unique id
    ///   - completionHandler: Status failed/success
    
    func sendImage(imgData:Data?,fileName:String,groupUniqueID:String,completionHandler:@escaping (_ status:String) -> Void){
        /*Store media in firebase */
       let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            Storage.storage().reference().child(fileName)
                .putData(imgData!, metadata: metadata) { [weak self] (metadata, error) in
                    guard let strongSelf = self else { return }
                    let downloadURL = Storage.storage().reference().child((metadata?.path)!).description
                    
                    var data:[String:Any] = ["date": ServerValue.timestamp()]
                    data[Constants.MessageFields.message] = "\(downloadURL)"
                    data[Constants.MessageFields.message_type] = "image"
                    if error != nil {
                        data[Constants.MessageFields.status] = "failed"
                    }else{
                        data[Constants.MessageFields.status] = "sent"
                    }
                    strongSelf.sendMessage(withData: data, groupUniqueID: groupUniqueID)
            }
    }
    
    //Updat value for media messages
    func updateValueAtNode(childKey:String,status:String,download_url:String){
        grpMsgRef.child("messages").child(childKey).updateChildValues(["status": status,"message":download_url])
        //        grpMsgRef.child("messages").child(childKey).updateChildValues(["status": status])
    }

    //MARK: Set timestamp of user last activity in firebase
    func setLastActivityTimestamp(groupUniqueID:String,status:String){
        
        let token = ((userDetail.object(at: 0) as AnyObject).object(forKey: "id") as AnyObject) as! String
        let logRef = reference.child("logTime")
        let userRef = logRef.child("\(groupUniqueID)")
        var deviceToken = ""
        if let x = UserDefaults.standard.object(forKey: "device_token") as? String    {
           deviceToken = x
        }else{
            deviceToken = ""
        }
        userRef.child("\((token.components(separatedBy: "@"))[0] )").updateChildValues(["date": [".sv": "timestamp"],"token":"\(deviceToken)","status":"\(status)"])
    }
    
    //MARK:Remove all observer 
    func removeAllObservers(){
        if self.grpMsgRef != nil{
            self.grpMsgRef.child("messages").removeAllObservers()
            self.grpMsgRef.removeAllObservers()
            self.grpMsgRef = nil
        }
    }
    
    //Group Listing section
    func getloggedTimeOnGroup(groupUniqueId:String,completionHandler:@escaping (_ data:NSDictionary,_ unreadCount:Int,_ groupID:String) -> Void){
        
        let token = ((userDetail.object(at: 0) as AnyObject).object(forKey: "id") as AnyObject) as! String
        
        let userRef = logRef.child("\(groupUniqueId)")
        
        //---- Fetch last logged time on group---//
        userRef.child("\((token.components(separatedBy: "@"))[0] )").observeSingleEvent(of: .value, with: {
            (snapshot) -> Void in
            
            print("-----Logged time stamp -----\n\(snapshot)")
            
            //--Retrive the unread messages from firebase database----//
            if let x = snapshot.value as? NSDictionary{
                if let timeInterval = x.object(forKey: "date") as? TimeInterval{
                    
                    self.getOneLastMessageIfNoUnreadMessages(timestamp: timeInterval, groupUniqueId: groupUniqueId, completionHandler: {(message,count,groupID) -> Void in
                        completionHandler(message,count,groupID)
                    })
                }
            }else{
                self.getOneLastMessageIfNoUnreadMessages(timestamp: nil, groupUniqueId: groupUniqueId, completionHandler: {(message,count,groupID) -> Void in
                    completionHandler(message,count,groupID)
                })
            }
        })
    }
    
    //Get unread message of the group from Firebase
    func getUnreadMessage(timestamp:TimeInterval?,groupUniqueId:String,completionHandler:@escaping (_ unreadCount:Int,_ groupID:String) -> Void){
        
        let grpMsgRef = msgRef.child("\(groupUniqueId)")
        let query:DatabaseQuery!
        
        if timestamp == nil{
            query = grpMsgRef.child("messages").queryOrderedByKey()
        }else{
            query = grpMsgRef.child("messages").queryOrdered(byChild: "date").queryStarting(atValue: timestamp, childKey: "date")
        }
        
        query.observeSingleEvent(of: .value, with: {
            (snapshot) -> Void in
            print("----- message Snapshot -----\n\(snapshot)")
            print(snapshot)
            completionHandler(Int(snapshot.childrenCount),groupUniqueId)
        })
    }
    
    func getOneLastMessageIfNoUnreadMessages(timestamp:TimeInterval?,groupUniqueId:String,completionHandler:@escaping (_ data:NSDictionary,_ unreadCount:Int,_ groupID:String) -> Void){
        
        let grpMsgRef = msgRef.child("\(groupUniqueId)")
        let query:DatabaseQuery!
        query = grpMsgRef.child("messages").queryOrderedByKey().queryLimited(toLast: 1)
        query.observe(.childAdded, with: {
            (snapshot) -> Void in
            print("----- message Snapshot -----\n\(snapshot)")
            print(snapshot)
            if snapshot.value != nil{
                //                let msgDict = (snapshot.children.allObjects.last as! DataSnapshot).value as! NSDictionary
                let msgDict = snapshot.value as! NSDictionary
                
                self.getUnreadMessage(timestamp: timestamp, groupUniqueId: groupUniqueId, completionHandler: {(count,groupID) -> Void in
                    
                    completionHandler(msgDict,count,groupID)
                })
            }else{
                self.getUnreadMessage(timestamp: timestamp, groupUniqueId: groupUniqueId, completionHandler: {(count,groupID) -> Void in
                    completionHandler(NSDictionary(),count,groupID)
                })
            }
        })
    }
    

     //MARK:- function for download from firebase

    
    //Make thumb image nad store it on documnet folder

    

    
    func getDownloadURL(storagePath:String,completionHandler:@escaping (_ url:URL?) -> Void){
        Storage.storage().reference(forURL: storagePath).downloadURL(completion: {
            (url,error) -> Void in
            if error != nil{
                completionHandler(url)
            }else{
                completionHandler(nil)
            }
         })
    }
    
    // Function to set notes data for particular step of microstep
    func setNotesData(userId:String,microstepId:String,stepId:String,data:String,completionHandler:@escaping (_ status:String) -> Void){
        var notesRef:DatabaseReference!
        notesRef = reference.child("Notes").child("\(userId)").child("\(microstepId)")
         notesRef.child("\(stepId)").updateChildValues(["Data":data])
        
        completionHandler("Success")
    }
    
    /// Function to get notes data from firebase
    ///
    /// - Parameters:
    ///   - userId: current logged in user id
    ///   - microstepId: current program id
    ///   - stepId: current step id
    ///   - completionHandler: for fetched note
    
    func getNotesData(userId:String,microstepId:String,stepId:String,completionHandler:@escaping (_ status:String,_ data:String) -> Void){
        var notesRef:DatabaseReference!
        notesRef = reference.child("Notes").child("\(userId)").child("\(microstepId)")
     
        notesRef.child("\(stepId)").observeSingleEvent(of: .value, with: {
            (snapshot) -> Void in
            print("-----Notes data -----\n\(snapshot)")
         
            if let x = snapshot.value as? NSDictionary{
                if let data = x.object(forKey: "Data") as? String{
                    self.reference.child("Notes").removeAllObservers()
                    completionHandler("Success",data)
                }
            }else{
                completionHandler("Success","")
            }
        })
     }
    
    func sendNotesImage(imgData:Data?,fileName:String,localPath:String,completionHandler:@escaping (_ status:String,_ url:String) -> Void){
        /*Store media in firebase */
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        Storage.storage().reference().child("Notes/\(fileName)")
            .putData(imgData!, metadata: metadata) { [weak self] (metadata, error) in
              if error != nil {
                    completionHandler("Fail","")
                }else{
                    let downloadURL = (metadata?.downloadURL())!.absoluteString
                    completionHandler("Success",downloadURL)
                }
        }
    }
    
    /// Upload media(audio/vedio) content in firebase
    ///
    /// - Parameters:
    ///   - type: File type (.mp4.mp3 etc..)
    ///   - filePath: local devide path of file
    ///   - referenceURL: Loacl file path url
    ///   - groupUniqueID: unique id of group
    ///   - completionHandler: return success/fail
    func sendNoteMedia(type:String,filePath:String,referenceURL:URL,completionHandler:@escaping (_ status:String,_ url:String) -> Void){
        /*Store media in firebase */
        Storage.storage().reference().child("Notes/\(filePath)")
            .putFile(from: referenceURL, metadata: nil) { (metadata, error) in
                if error != nil {
                    completionHandler("Fail","")
                }else{
                    let downloadURL = (metadata?.downloadURL())!.absoluteString
                    completionHandler("Success",downloadURL)
                }
                
        }
    }
    
    
}
