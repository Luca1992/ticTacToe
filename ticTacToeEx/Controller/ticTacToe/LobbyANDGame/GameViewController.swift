//
//  GameViewController.swift
//  ticTacToeEx
//
//  Created by Stefano Apuzzo on 28/03/18.
//  Copyright © 2018 Stefano Apuzzo. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class Utils{
    
    static func collectionToArray2D(arr: [UIButton],size: Int) -> [[UIButton]]{
        
        var result : [[UIButton]] = [[UIButton]](repeating: [UIButton](), count: size);
        var set = -1;
        let expectedSize = (arr.count / size) + (arr.count % size);
        
        for i in 0..<arr.count {
            if i % expectedSize == 0{
                set = set + 1;
            }
            
            result[set].append(arr[i]);
        }
        
        return result;
    }
    
}

class GameViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate{
    
    //----------------------Chat-------------------------
    
    @IBOutlet weak var chatTable: UITableView!
    
    @IBOutlet weak var textFieldMessage: UITextField!
    
    @IBOutlet weak var bottomTextField: NSLayoutConstraint!
    
    var messages: [Message] = []
    
    var messagesTot: Int = 0
    
    var textFieldTouched: UITextField!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        
        if messages[indexPath.row].nickName == MainViewController.user.nickName {
            
            let cell = chatTable.dequeueReusableCell(withIdentifier: "cellUser", for: indexPath) as! CustomUserChatCell
            
            cell.imageProfile.image = MainViewController.user.image
            
            cell.imageProfile.layer.cornerRadius = cell.imageProfile.frame.width / 2
            
            cell.imageProfile.layer.masksToBounds = true
            
            cell.nickNameLabel.text = MainViewController.user.nickName
            
            cell.messageLabel.text = messages[indexPath.row].message
            
            return cell
        }
        
        else {
            
            let cell = chatTable.dequeueReusableCell(withIdentifier: "cellEnemy", for: indexPath) as! CustomEnemyChatCell
            
            cell.imageProfile.image = self.enemy.image
            
            cell.imageProfile.layer.cornerRadius = cell.imageProfile.frame.width / 2
            
            cell.imageProfile.layer.masksToBounds = true
            
            cell.nickNameLabel.text = self.enemy.nickName
            
            cell.messageLabel.text = messages[indexPath.row].message
            
            return cell
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldTouched = textField
    }
    
    @objc func keyboardDidShow(notification: Notification) {
        
        let info = notification.userInfo! as NSDictionary
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        self.bottomTextField.constant = keyboardSize.height + 8.0
        if self.view.frame.origin.y >= 0 {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
                self.textFieldTouched.layoutIfNeeded()
            }, completion: nil)
        }
        
    }
    @objc func keyboardWillHide(notification: Notification) {
        
        self.bottomTextField.constant = 3
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
            self.textFieldTouched.layoutIfNeeded()
        }, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()  //if desired
        performAction()
        return true
    }
    
    func performAction() {
        let ref = Database.database().reference()
        let messageText = self.textFieldTouched.text as! String
        let message = [
            "Message" : "\(messageText)",
            "Nickname" : "\(MainViewController.user.nickName)"
        ]
        let newMessageNumber = self.messagesTot + 1
        ref.child("Messages\(nomeTabella)").child("Message\(newMessageNumber)").setValue(message)
        self.textFieldTouched.text = ""
    }
    //----------------------Game-------------------------
    
    var enemy = User()
    
    var fPlayer = false
    var sPlayer = false
    
    var nomeTabella = ""
    
    var vittorie: Int!
    var sconfitte: Int!
    
    var matrice: [[String]] = [["", "", ""], ["", "", ""],["","",""]]
    
    var myImage: UIImage!
    var oppositeImage: UIImage!
    
    @IBOutlet var buttons: [UIButton]!
    var buttons2D: [[UIButton]]!
    var buttonEnabled = 9
    
    var partitaFinita = false {
        didSet {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let ref = Database.database().reference()
        
        if fPlayer == true && sPlayer == false {
            
            nomeTabella = "\(MainViewController.user.nickName)VS\(self.enemy.nickName)"
        }
        else if fPlayer == false && sPlayer == true {
            
            nomeTabella = "\(self.enemy.nickName)VS\(MainViewController.user.nickName)"
        }
        
        for i in 0...2 {
            for y in 0...2 {
                ref.child("\(nomeTabella)").child("\(i):\(y)").child("toccata").setValue("")
                ref.child("\(nomeTabella)").child("\(i):\(y)").child("daChi").setValue("")
            }
        }
        ref.child("Utility\(nomeTabella)").child("buttonEnabled").setValue("9")
        self.buttonEnabled = 9
        
        
        buttons2D = Utils.collectionToArray2D(arr: buttons, size: 3)
        
        for buttons in buttons2D {
            for button in buttons {
                button.layer.borderColor = UIColor.black.cgColor
                button.layer.borderWidth = 1
            }
        }
        
        
        if fPlayer == true {
            myImage = UIImage(named: "croce.png")
            oppositeImage = UIImage(named: "cerchio.png")
        }
        else if sPlayer == true {
            myImage = UIImage(named: "cerchio.png")
            oppositeImage = UIImage(named: "croce.png")
        }
        
        self.chatTable.delegate = self
        self.chatTable.dataSource = self
        self.textFieldMessage.delegate = self
        
        let center = NotificationCenter.default
        
        center.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.hideKeyboardWhenTappedAround()
        
        ref.child("Messages\(nomeTabella)").child("Message0").setValue(["Nickname" : "", "Message" : ""])
        
        ref.child("Messages\(nomeTabella)").observe(.value) { (snap) in
            
            self.messages.removeAll()
            
            if  snap.value != nil {
                
                let dict = snap.value as! [String : Any]
                
                let n_key = dict.count
                self.messagesTot = n_key - 1
                
                for(key, value) in dict {
                    let keyMessage = key as String
                    let n_message = String(keyMessage.suffix(1))
                    
                    if n_message != "0" {
                        let dict2 = value as! [String : Any]
                        let message = Message()
                        message.nickName = dict2["Nickname"] as! String
                        message.message = dict2["Message"] as! String
                        message.n_message = Int(n_message)!
                        self.messages.append(message)
                    }
                }
                self.messages.sort(by: {$0.n_message < $1.n_message})
                self.chatTable.reloadData()
            }
        }
        
        
        ref.child("Utility\(nomeTabella)").observe(.value) { (snap) in
            
            let utility = snap.value as! [String : Any]
            let tmp = utility["buttonEnabled"] as! String
            self.buttonEnabled = Int(tmp)!
        }
        
        ref.child("\(nomeTabella)").observe(.value) { (snap) in
            
            let celle = snap.value as! [String : Any]
            
            if self.fPlayer == true {
                print("--------Sono \(MainViewController.user.nickName) e sono il primo giocatore----------")
            }
            else {
                print("--------Sono \(MainViewController.user.nickName) e sono il secondo giocatore----------")
            }
            
            for(key, value) in celle {
                
                let x = Int(String(key.first as! Character)) as! Int
                let y = Int(String(key.last as! Character)) as! Int
                
                let dati = value as! [String : String]
                
                let toccata = dati["toccata"] as! String
                let daChi = dati["daChi"] as! String
                
                if toccata == "Si" {
                    if daChi == MainViewController.user.nickName && self.fPlayer == true {
                        self.matrice[x][y] = "x"
                        self.buttons2D[x][y].setImage(self.myImage, for: .normal)
                    }
                    else if daChi == MainViewController.user.nickName && self.sPlayer == true {
                        self.matrice[x][y] = "o"
                        self.buttons2D[x][y].setImage(self.myImage, for: .normal)
                    }
                    else if daChi != MainViewController.user.nickName && self.fPlayer == true {
                        self.matrice[x][y] = "o"
                        self.buttons2D[x][y].setImage(self.oppositeImage, for: .normal)
                    }
                    else if daChi != MainViewController.user.nickName && self.sPlayer == true {
                        self.matrice[x][y] = "x"
                        self.buttons2D[x][y].setImage(self.oppositeImage, for: .normal)
                    }
                    
                    let winner = self.getWinner()
                    if winner == "Hai vinto" {
                        
                        ref.child("Players").child("\(MainViewController.user.nickName)").child("vittorie").setValue("\(MainViewController.user.vittorie + 1)")
                        
                        ref.child("Players").child("\(MainViewController.user.nickName)").child("invitatoDa").setValue("")
                        ref.child("Players").child("\(MainViewController.user.nickName)").child("invitoAccettato").setValue("")
                        ref.child("Players").child("\(MainViewController.user.nickName)").child("stato").setValue("online")
                        
                        ref.child("\(self.nomeTabella)").removeAllObservers()
                        ref.child("Utility\(self.nomeTabella)").removeAllObservers()
                        ref.child("Messages\(self.nomeTabella)").removeAllObservers()
                        
                        let alert = UIAlertController(title: "Hai vinto", message: "Complimenti", preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                            self.partitaFinita = true
                        }))
                        
                        self.present(alert, animated: true)
                        
                        
                    }
                    else if winner == "Hai perso" {
                        
                        ref.child("Players").child("\(MainViewController.user.nickName)").child("sconfitte").setValue("\(MainViewController.user.sconfitte + 1)")
                        ref.child("Players").child("\(MainViewController.user.nickName)").child("invitatoDa").setValue("")
                        ref.child("Players").child("\(MainViewController.user.nickName)").child("invitoAccettato").setValue("")
                        ref.child("Players").child("\(MainViewController.user.nickName)").child("stato").setValue("online")
                        
                        ref.child("\(self.nomeTabella)").removeAllObservers()
                        ref.child("Utility\(self.nomeTabella)").removeAllObservers()
                        ref.child("Messages\(self.nomeTabella)").removeAllObservers()
                        
                        ref.child("\(self.nomeTabella)").removeValue()
                        ref.child("Utility\(self.nomeTabella)").removeValue()
                        ref.child("Messages\(self.nomeTabella)").removeValue()
                        
                        let alert = UIAlertController(title: "Hai perso", message: "Mi spiace", preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                            self.partitaFinita = true
                        }))
                        
                        self.present(alert, animated: true)
                        
                    }
                }
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let ref = Database.database().reference()
        
        ref.child("Players").child("\(self.enemy.nickName)").child("image").observeSingleEvent(of: .value, with: { (snap) in
            
            let value = snap.value as! String
            
            let decodeString = Data(base64Encoded: value)
            
            let image = UIImage(data: decodeString!)
            
            let imagePNG = UIImagePNGRepresentation(image!)
            
            self.enemy.image = UIImage(data: imagePNG!)
        })
    }
    
    @IBAction func mossa(_ sender: UIButton) {
        
        let x = Int(String(sender.titleLabel?.text?.first as! Character)) as! Int
        let y = Int(String(sender.titleLabel?.text?.last as! Character)) as! Int
        
        if fPlayer == true {
            if buttonEnabled%2 != 0 && self.matrice[x][y] == "" {
                
                self.matrice[x][y] = "x"
                
                let ref = Database.database().reference()
                ref.child("\(nomeTabella)").child("\(sender.titleLabel?.text as! String)").setValue(["daChi":"\(MainViewController.user.nickName)","toccata":"Si"])
                ref.child("Utility\(nomeTabella)").child("buttonEnabled").setValue("\(buttonEnabled - 1)")
            }
        }
        else if sPlayer == true && self.matrice[x][y] == ""{
            if buttonEnabled%2 == 0 {
                
                self.matrice[x][y] = "o"
                
                let ref = Database.database().reference()
                ref.child("\(nomeTabella)").child("\(sender.titleLabel?.text as! String)").setValue(["daChi":"\(MainViewController.user.nickName)","toccata":"Si"])
                ref.child("Utility\(nomeTabella)").child("buttonEnabled").setValue("\(buttonEnabled - 1)")
            }
        }
    }
    
    
    func getWinner() -> String
    {
        
        var k = 0;
        var h = 0;
        // Verifico se il tris è presente in una riga
        for i in 0...2
        {
            for j in 0...2
            {
                if matrice[i][j] != nil && matrice[i][j] == "x"
                {
                    k += 1
                    if(k==3){
                        if fPlayer == true {
                            return "Hai vinto"
                        }
                        else {
                            return "Hai perso"
                        }
                    }
                }
                else
                {
                    if matrice[i][j] != nil && matrice[i][j] == "o"
                    {
                        h += 1;
                        if(h==3){
                            if fPlayer == true {
                                return "Hai perso"
                            }
                            else {
                                return "Hai vinto"
                            }
                        }
                    }
                }
            }
            k=0
            h=0
        }
        // Verifico se il tris è presente in una colonna
        for i in 0...2
        {
            for j in 0...2
            {
                if matrice[j][i] != nil && matrice[j][i] == "x"
                {
                    k += 1
                    if(k==3){
                        if fPlayer == true {
                            return "Hai vinto"
                        }
                        else {
                            return "Hai perso"
                        }
                    }
                }
                else
                {
                    if matrice[j][i] != nil && matrice[j][i] == "o"
                    {
                        h += 1;
                        if(h==3){
                            if fPlayer == true {
                                return "Hai perso"
                            }
                            else {
                                return "Hai vinto"
                            }
                        }
                    }
                }
            }
            k=0
            h=0
        }
        
        // Verifico se il tris è presente in una diagonale
        for i in 0...2
        {
            let j = i;
            if matrice[i][j] != nil && matrice[i][j] == "x"
            {
                k += 1;
                if(k==3){
                    if fPlayer == true {
                        return "Hai vinto"
                    }
                    else {
                        return "Hai perso"
                    }
                }
            }
            else
            {
                if matrice[i][j] != nil && matrice[i][j] == "o"
                {
                    h += 1
                    if(h==3){
                        if fPlayer == true {
                            return "Hai perso"
                        }
                        else {
                            return "Hai vinto"
                        }
                    }
                }
            }
        }
        
        k=0
        h=0
        var j = 2
        
        for i in 0...2
        {
            if matrice[i][j] != nil && matrice[i][j] == "x"
            {
                k += 1;
                if(k==3){
                    if fPlayer == true {
                        return "Hai vinto"
                    }
                    else {
                        return "Hai perso"
                    }
                }
            }
            else
            {
                if matrice[i][j] != nil && matrice[i][j] == "o"
                {
                    h += 1;
                    if(h==3){
                        if fPlayer == true {
                            return "Hai perso"
                        }
                        else {
                            return "Hai vinto"
                        }
                    }
                }
            }
            j -= 1
        }
        return " "
    }
}