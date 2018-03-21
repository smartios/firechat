//
//  WaitingChatRoomViewController.swift
//  QuickHealthDoctorApp
//
//  Created by SL036 on 20/02/18.
//  Copyright © 2018 SS142. All rights reserved.
//

import UIKit
import Firebase

class WaitingChatRoomViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {

    @IBOutlet weak var chatTableView: UITableView!{
        didSet{
            chatTableView.estimatedRowHeight = 80
            chatTableView.rowHeight = UITableViewAutomaticDimension
            chatTableView.register(UINib(nibName: "OwnMessageTableViewCell", bundle: nil), forCellReuseIdentifier: "ownMessageCell")
            chatTableView.register(UINib(nibName: "PartnerMessageTableViewCell", bundle: nil), forCellReuseIdentifier: "partnerTextCell")
        }
    }
    @IBOutlet weak var bottomConstraints: NSLayoutConstraint!
    
    @IBOutlet weak var messageTextView: UITextView!{
        didSet{
            messageTextView.text = "Write a reply..."
        }
    }
    var placeholder: String{
        get{
            return "Write a reply..."
        }
    }
    @IBOutlet weak var sendButton: UIButton!
    var user:String = (Auth.auth().currentUser?.uid)!
    var userName:String = ""
    private lazy var channelRef: DatabaseReference = Database.database().reference()
    
    private var channelRefHandle: DatabaseHandle?
    var ChatFirebase:FirebaseMethods!
    var Counter = 0
    var messages = NSMutableArray()
    var dateArrayForSection = NSArray()
    var  chatbygroup = NSMutableDictionary()
    let dateFormat = ChatDateFormatter()
    override func viewDidLoad() {
        super.viewDidLoad()
        ChatFirebase = FirebaseMethods(base_url: "https://fir-chatdemo-b3596.firebaseio.com/",user:self.user)
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
//        self.fetchMessage()
        self.fetchTotalNumberOfmessages()
        self.configurecChatToAdd()
//        self.configurecChatToObserveChange()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // MARK:- Send button Action
    @IBAction func onClickedSendButton(_ sender: UIButton) {
        self.view.endEditing(true)
       
        guard let text = messageTextView.text else { return }
        messageTextView.text = ""
        
        if text.trimmingCharacters(in: .whitespaces).characters.count > 0{
            var data:[String:Any] = ["date": ServerValue.timestamp()]
            data[Constants.MessageFields.message] = text
            data[Constants.MessageFields.message_type] = "text"
            data[Constants.MessageFields.status] = "sent"
            data[Constants.MessageFields.status] = "sent"
            data[Constants.MessageFields.sender_id] = user
            data[Constants.MessageFields.sender_name] = userName
            
            self.sendMessage(withData: data, msgtype: "text")
        }
        if messageTextView.text == ""{
            messageTextView.text = placeholder
        }
    }
    
    // MARK: - Keyboard Notification
    @objc func keyboardWillShow(_ notification: NSNotification)
    {
        if let userInfo = (notification as NSNotification).userInfo
        {
            if let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                if let keyboardDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double{
                    self.bottomConstraints.constant = keyboardSize.height
                    UIView.animate(withDuration: keyboardDuration, animations: {
                        self.view.layoutIfNeeded()
                    })
                }else{
                    self.bottomConstraints.constant = keyboardSize.height
                    UIView.animate(withDuration: 0.5, animations: {
                        self.view.layoutIfNeeded()
                    })
                }
                
            } else {
                // no UIKeyboardFrameBeginUserInfoKey entry in userInfo
            }
        } else {
            // no userInfo dictionary in notification
        }
        
    }
    @objc func keyboardWillHide(_ notification: NSNotification)
    {
        
        if let userInfo = (notification as NSNotification).userInfo
        {
            if let keyboardDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double{
                self.bottomConstraints.constant = 0
                UIView.animate(withDuration: keyboardDuration, animations: {
                    self.view.layoutIfNeeded()
                })
            }else{
                self.bottomConstraints.constant = 0
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }else{
            bottomConstraints.constant = 0
        }
        
    }
    // MARK: - UITableView DataSource/Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if ((messages.object(at: indexPath.row) as! NSDictionary).object(forKey: "sender_id") as! String) == self.user{
            cell = tableView.dequeueReusableCell(withIdentifier: "ownMessageCell") as! OwnMessageTableViewCell
            self.cellForOwnMessage(cell, indexPath: indexPath)
        }else{
            cell = tableView.dequeueReusableCell(withIdentifier: "partnerTextCell") as! PartnerMessageTableViewCell
            self.cellForPartnerMessage(cell, indexPath: indexPath)
        }
       
        cell.selectionStyle = .none
        return cell
    }
    
    // MARK: - Partner Cell
    func cellForPartnerMessage(_ cell: UITableViewCell, indexPath: IndexPath)
    {
        let messageLabel = cell.viewWithTag(2) as! UILabel
        let messageTimeLabel = cell.viewWithTag(3) as! UILabel
        messageLabel.text = ((messages.object(at: indexPath.row) as! NSDictionary).object(forKey: "message") as! String)
        if let x = (messages.object(at: indexPath.row) as! NSDictionary).object(forKey: "\(Constants.MessageFields.timestamp)") as? TimeInterval{
            let date = Date(timeIntervalSince1970: x/1000)
            
            messageTimeLabel.text =  dateFormat.findDateOrTime(dateTimeString: date, dateRequired: true, dateFormatForChat: "dd/MM/YYYY HH:mm")
            //                    timeStamp.text =  dateFormat.findDateOrTime(dateTimeString: date, dateRequired: true, dateFormatForChat: "hh:mm")
        }else{
            messageTimeLabel.text = ""
        }

    }
    // MARK: - Own Cell
    func cellForOwnMessage(_ cell: UITableViewCell, indexPath: IndexPath)
    {
        let messageLabel = cell.viewWithTag(12) as! UILabel
        let messageTimeLabel = cell.viewWithTag(13) as! UILabel
        messageLabel.text = ((messages.object(at: indexPath.row) as! NSDictionary).object(forKey: "message") as! String)
        if let x = (messages.object(at: indexPath.row) as! NSDictionary).object(forKey: "\(Constants.MessageFields.timestamp)") as? TimeInterval{
            let date = Date(timeIntervalSince1970: x/1000)
            
            messageTimeLabel.text =  dateFormat.findDateOrTime(dateTimeString: date, dateRequired: true, dateFormatForChat: "dd,MMM hh:mm a")

        }else{
            messageTimeLabel.text = ""
        }
    }

    // MARK: - UITextView Delegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        if messageTextView.text == placeholder{
            textView.text = ""
        }
    }
    func textViewDidChange(_ textView: UITextView) {
        if messageTextView.intrinsicContentSize.height>200 && messageTextView.isScrollEnabled == false{
            messageTextView.isScrollEnabled = true
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if messageTextView.text == ""{
            textView.text = placeholder
        }
    }
    
    

    
    //MARK:- ---------- Firebase functioons ---------
    
    
    
    
    //MARK:- Fetch total number messages from firebase
    func fetchTotalNumberOfmessages(){
        ChatFirebase.fetchTotalNumberOfmessages(completionHandler: {
            (count) -> Void in
            self.Counter = count
        })
    }
    //MARK:- Configure chat databse to observe change in value of child,fetch,receive and send messages
    func configurecChatToAdd(){
        // Listen for new messages in the Firebase database
        
        ChatFirebase.configureChatDatabase(completionHandler: { (dictionary,key) -> Void in
            self.addNewMessage(messageDictionary: dictionary, key: key)
        })
    }
   
    func fetchMessage(){
        ChatFirebase.fetchMessages { (data) in
            for item in data{
                self.addNewMessage(messageDictionary: (item as! DataSnapshot).value as! NSDictionary, key: (item as! DataSnapshot).key )
            }
            self.chatTableView.reloadData()
        }
    }
    
    func configurecChatToObserveChange(){
        // Listen for new messages in the Firebase database
        ChatFirebase.configurecChatToObserveChange(completionHandler: {
            (dictionary,key) -> Void in
            
//            self.addNewMessage(messageDictionary: dictionary, key: key)
        })
    }
    
    func addNewMessage(messageDictionary:NSDictionary,key:String){
        self.messages.add(messageDictionary)
        self.chatTableView.reloadData()
        self.scrollToBottom()
    }
    
    //MARK: Send message to firebase
    func sendMessage(withData data: [String: Any],msgtype:String) {
       ChatFirebase.sendMessage(withData: data,groupUniqueID:self.user)
    }
    //MARK:- ----------- Scrolling functions --------------
    func scrollToBottom() {
        if self.messages.count > 1 {
            // hard codded data
            if  (self.chatTableView.numberOfRows(inSection: self.chatTableView.numberOfSections - 1) > 0){
                let lastRowIndexPath = IndexPath(row: (self.chatTableView.numberOfRows(inSection: self.chatTableView.numberOfSections - 1)) - 1, section: self.chatTableView.numberOfSections - 1)
                
                self.chatTableView.scrollToRow(at: lastRowIndexPath, at: UITableViewScrollPosition.bottom, animated: false)
            }
        }
    }
    
    
}
