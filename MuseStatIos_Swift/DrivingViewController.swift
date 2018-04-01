//
//  DrivingViewController.swift
//  MuseStatIos_Swift
//
//  Created by Nikhil Bhatia on 3/31/18.
//  Copyright © 2018 Ivan Rzhanoi. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class DrivingViewController: UIViewController, IXNMuseConnectionListener, IXNMuseDataListener, IXNMuseListener, IXNLogListener {
    
    
    var muse: IXNMuse!
    var manager: IXNMuseManagerIos!
    var connectionController: SimpleController!
    var timer: Timer?
    var stopAlarmTimer: Timer?
    var alarmStartTime = 0.0
    var alarmEndTime = 10.0
    var finalData: [(date: String, alpha: Double)] = []
    var finalStartTime: String = ""
    var audioPlayer:AVAudioPlayer!
    var connected: Bool = false {
        didSet {
            print("REACHED")
            if connected == false  {
                let alertController = UIAlertController(title: "Error", message:
                    "The headset has been disconnected", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                self.present(alertController, animated: true, completion: nil)
                endDrive(self)
            }
        }
    }
    
    
    @IBOutlet weak var recievedData1: UILabel!
    @IBOutlet weak var recievedData2: UILabel!
    @IBOutlet weak var recievedData3: UILabel!
    @IBOutlet weak var recievedData4: UILabel!
    
    @IBOutlet weak var requestLabel: UILabel!
    
    @IBAction func endDrive(_ sender: Any) {
        
        print ("TRYING END REQUEST")
        self.muse.unregisterAllListeners()
        timer?.invalidate()
        
        let url = URL(string: "http://167.99.161.100:8000/api/end_trip/haozhuo/")!
        let session = URLSession.shared
        session.dataTask(with:url, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else { return }
            do {
                print(data)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print (json)
                if let array = json as? [Dictionary<String, Any>] {
                    for dict in array {
                        if self.finalStartTime == "" {
                            self.finalStartTime = dict["time"] as! String
                        }
                        let time = dict["time"] as! String
                        let alpha = dict["avg_alpha"] as! Double
                        self.finalData.append((time, alpha))
                    }
                }
                print (self.finalData)
//                DispatchQueue.main.async {
//                    self.requestLabel.text = (json["data"] as AnyObject? as? String) ?? ""
//                }
            } catch let error as NSError {
                print(error)
            }
        }).resume()
    }
    
    
    
    
    func receiveLog(_ log: IXNLogPacket) {
        print("Doing nothing with log in DrivingVC")
    }
    
    func museListChanged() {
        print("Muse list changed in DrivingVC")
    }
    
    func receive(_ packet: IXNMuseDataPacket?, muse: IXNMuse?) {
        if packet?.packetType() == IXNMuseDataPacketType.alphaAbsolute {
            print("Alpha data has been recieved to DrivingVC")
            if let info = packet?.values() {
                recievedData1.text = "\(info[0])"
                recievedData2.text = "\(info[1])"
                recievedData3.text = "\(info[2])"
                recievedData4.text = "\(info[3])"
            }
        }
    }
    
    func receive(_ packet: IXNMuseArtifactPacket, muse: IXNMuse?) {
        print("Received blink artifact")
    }
    
    func receive(_ packet: IXNMuseConnectionPacket, muse: IXNMuse?) {       // TODO: Find and error over here!
        var state: String
        switch packet.currentConnectionState {
        case .disconnected:
            connected = false
            state = "disconnected"
        case .connected:
            connected = true
            state = "connected"
        case .connecting:
            state = "connecting"
        case .needsUpdate:
            state = "needs update"
        case .unknown:
            state = "unknown"
        }
        print("connect: \(state)")
    }

    func connect() {
        print("Connecting VC to Muse")
        self.muse.register(self)
        self.muse.register(self, type: IXNMuseDataPacketType.alphaAbsolute)
        self.muse.runAsynchronously()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.title = "Your Current Drive"
        // Do any additional setup after loading the view.
    }

    func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(sendData), userInfo: nil, repeats: true)
    }
    
    @objc func checkAlarmTimer() {
        if self.alarmStartTime >= self.alarmEndTime {
            self.audioPlayer.stop()
            stopAlarmTimer?.invalidate()
            stopAlarmTimer = nil
            alarmStartTime = 0.0
        }
        alarmStartTime = alarmStartTime + 1.0
    }
    
    func soundTheAlarm() {
        let path = Bundle.main.path(forResource: "alarm_sound", ofType: "mp3")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path!))
        } catch {
            print("Something wrong in prepareAudios() func")
        }
        
        // This code sets max volume on device
        let masterVolumeSlider = MPVolumeView()
        if let view = masterVolumeSlider.subviews.first as? UISlider{
            view.value = 1.0
        }
        
        audioPlayer.volume = 1.0
        audioPlayer.prepareToPlay()
        stopAlarmTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkAlarmTimer), userInfo: nil, repeats: true)
        audioPlayer.play()
    }
    
    @objc func sendData() {
        
        let userName = "haozhuo"
        if let data1 = self.recievedData1.text, let data2 = self.recievedData2.text, let data3 = self.recievedData3.text, let data4 = self.recievedData4.text{
            let index1 = data1 != "0" ? data1.index(data1.startIndex, offsetBy: 4) : data1.index(data1.startIndex, offsetBy: 1)
            let alpha1 = data1.substring(to: index1)
            
            let index2 = data2 != "0" ? data2.index(data2.startIndex, offsetBy: 4) : data2.index(data1.startIndex, offsetBy: 1)
            let alpha2 = data2.substring(to: index2)
            
            let index3 = data3 != "0" ? data3.index(data3.startIndex, offsetBy: 4) : data3.index(data1.startIndex, offsetBy: 1)
            let alpha3 = data3.substring(to: index3)
            
            let index4 = data4 != "0" ? data4.index(data4.startIndex, offsetBy: 4) : data4.index(data1.startIndex, offsetBy: 1)
            let alpha4 = data4.substring(to: index4)
            
            let urlString = "http://167.99.161.100:8000/api/send_data/" + userName + "?v1=" + alpha1 + "&v2=" + alpha2 + "&v3=" + alpha3 + "&v4=" + alpha4
            
            
            print(urlString)
            let url = URL(string: urlString)!
            let session = URLSession.shared
            session.dataTask(with:url, completionHandler: {(data, response, error) in
                guard let data = data, error == nil else { return }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
                    DispatchQueue.main.async { // Correct
                        let dateFormatter : DateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let date = Date()
                        let dateString = dateFormatter.string(from: date)
                        let data = ((json["status"] as AnyObject? as? String) ?? "")
                        if data == "-1" {
                            self.soundTheAlarm()
                        }
                        self.requestLabel.text = dateString + " Response:" + data
                    }
                } catch let error as NSError {
                    print(error)
                }
            }).resume()
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(muse)
        print(manager)
        print(muse.getConnectionState() == IXNConnectionState.connected )
        connect()
        startTimer()
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation
     */
     
     /*
     // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
