//
//  ConnectionController.swift
//  MuseStatIos_Swift
//
//  Created by Ivan Rzhanoi on 24/11/2016.
//  Copyright © 2016 Ivan Rzhanoi. All rights reserved.
//

import UIKit

class ConnectionController: UIViewController, IXNMuseConnectionListener, IXNMuseDataListener, IXNMuseListener, IXNLogListener, UITableViewDelegate, UITableViewDataSource {
    /**
     * Handler method for Muse data packets
     *
     * \warning It is important that you do not perform any computation
     * intensive tasks in this callback. This would result in significant
     * delays in all the listener callbacks from being called. You should
     * delegate any intensive tasks to another thread or schedule it to run
     * with a delay through handler/scheduler for the platform.
     *
     * However, you can register/unregister listeners in this callback.
     * All previously registered listeners would still receive callbacks
     * for this current event. On subsequent events, the newly registered
     * listeners will be called. For example, if you had 2 listeners 'A' and 'B'
     * for this event. If, on the callback for listener A, listener A unregisters
     * all listeners and registers a new listener 'C' and then in the callback for
     * listener 'B', you unregister all listeners again and register a new listener
     * 'D'. Then on the subsequent event callback, only listener D's callback
     * will be invoked.
     *
     * \param packet The data packet
     * \param muse   The
     * \if ANDROID_ONLY
     * Muse
     * \elseif IOS_ONLY
     * IXNMuse
     * \endif
     * that sent the data packet.
     */
    
    @IBOutlet weak var startDrivingButton: UIButton!
    var muse = IXNMuse()
    var manager = IXNMuseManagerIos()
    var logLines = [Any]()
    var isLastBlink = false
    var connected: Bool = false {
        didSet {
            if connected == false {
                startDrivingButton.isEnabled = false

            }
            else {
                startDrivingButton.isEnabled = true
            }
        }
    }

    // Declaring an object that will call the functions in SimpleController()
    var connectionController = SimpleController()
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var logView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.tableView.delegate = self
        self.tableView.dataSource = self
        UIApplication.shared.isIdleTimerDisabled = true
        self.manager = IXNMuseManagerIos.sharedManager()
        self.navigationItem.title = "Prepare for Your Drive"
        self.connected = false
    }
    
        override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
            //if (self == super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)) {
    
            super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    
            self.manager = IXNMuseManagerIos.sharedManager()
            self.manager.museListener = self
            self.tableView = UITableView()
            self.logView = UITextView()
            self.logLines = [Any]()
            self.logView.text = ""
            IXNLogManager.instance()?.setLogListener(self)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
            //var dateStr = dateFormatter.string(fromDate: Date()).appending(".log")
            let dateStr = dateFormatter.string(from: Date()).appending(".log")
            print("\(dateStr)")
        }
    
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
    
    
    
    func receiveLog(_ log: IXNLogPacket) {
        //connectionController.receiveLog(log)
        //print("\(log.tag): \(log.timestamp) raw: \(log.raw) \(log.message)")
    }
    
    
    // TODO: Investigate the line below. Something wrong with tableView or it's update. It requires the manual table refresh.
    func museListChanged() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = connectionController.tableView(tableView, numberOfRowsInSection: section)
        return rows
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = connectionController.tableView(tableView, cellForRowAt: indexPath)
        
        
        // The code below works fine. It is simplier to use only one line above, but in case someone would like to completely port it to swift, I kept it.
        
//        let simpleTableIdentifier: String = "nil"
//        let muses = self.manager.getMuses()
//        
//        // Checking for the value. If cell doesn't receive any data (finding nil, while unwraping), we give empty.
//        if let cell = tableView.dequeueReusableCell(withIdentifier: simpleTableIdentifier) {
//            
//            if indexPath.row < muses.count {
//                let muse: IXNMuse = self.manager.getMuses()[indexPath.row] as! IXNMuse
//                cell.textLabel!.text = muse.getName()
//                if !muse.isLowEnergy() {
//                    cell.textLabel!.text = cell.textLabel!.text?.appending(muse.getMacAddress())
//                }
//            }
//            return cell
//            
//        } else {
//            let cell = UITableViewCell(style: .default, reuseIdentifier: simpleTableIdentifier)
//
//            if indexPath.row < muses.count {
//                let muse: IXNMuse = self.manager.getMuses()[indexPath.row] as! IXNMuse
//                
//                // TODO: Check the code below in the future
//                cell.textLabel?.text = muse.getName()
//                if !muse.isLowEnergy() {
//                    cell.textLabel?.text = cell.textLabel?.text?.appending(muse.getMacAddress())
//                }
//            }
//            return cell
//        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        var muses = self.manager.getMuses()
        if indexPath.row < muses.count {
            let muse: IXNMuse = muses[indexPath.row] as! IXNMuse
            self.muse = muse
            self.connect()
            print("======Chose device to connect: \(self.muse.getName()) \(self.muse.getMacAddress())======\n")
        }
    }
    
    func receive(_ packet: IXNMuseConnectionPacket, muse: IXNMuse?) {       // TODO: Find and error over here!
        var state: String
        switch packet.currentConnectionState {
        case IXNConnectionState.disconnected:
            connected = false
            state = "disconnected"
        case IXNConnectionState.connected:
            connected = true
            state = "connected"
        case IXNConnectionState.connecting:
            state = "connecting"
        case IXNConnectionState.needsUpdate:
            state = "needs update"
        case IXNConnectionState.unknown:
            state = "unknown"
        }
        print("connect: \(state)")
    }
    
    
    func connect() {
        self.muse.register(self)
        self.muse.register(self, type: IXNMuseDataPacketType.alphaAbsolute)
        self.muse.runAsynchronously()
    }
    
    func receive(_ packet: IXNMuseDataPacket?, muse: IXNMuse?) {
        if packet?.packetType() == IXNMuseDataPacketType.alphaAbsolute || packet?.packetType() == IXNMuseDataPacketType.eeg {
            if let info = packet?.values() {
                print("Alpha: \(info[0]) \(info[1]) \(info[2]) \(info[3])")
            }
        }
    }
    
    func receive(_ packet: IXNMuseArtifactPacket, muse: IXNMuse?) {
        self.isLastBlink = packet.blink
    }
    
    
    @IBAction func disconnect(_ sender: Any) {
        connected = false
        if self.muse.getConnectionState() == IXNConnectionState.connected {
            self.muse.disconnect(true)
        }
    }
    
    @IBAction func scan(_ sender: AnyObject) {
        self.manager.startListening()
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
    }
    
    @IBAction func stopScan(_ sender: AnyObject) {
        self.manager.stopListening()
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

 // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "startDrive") {
            muse.unregisterAllListeners()
            let viewController = segue.destination as! DrivingViewController
            viewController.muse = self.muse
            viewController.manager = self.manager
            manager.museListener = viewController
            viewController.connectionController = self.connectionController
            
        }
        
    }
    
    @IBAction func startDriving(_ sender: Any) {
        if self.connected == true && self.muse.getConnectionState() == IXNConnectionState.connected {
            let url = URL(string: "http://167.99.161.100:8000/api/start_trip/haozhuo/")!
            let session = URLSession.shared
            session.dataTask(with:url, completionHandler: {(data, response, error) in
                guard let data = data, error == nil else { return }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
                    let confirmation = (json["data"] as AnyObject? as? String) ?? ""
                    if confirmation == "1" {
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "startDrive", sender: self)
                        }
                    }
                } catch let error as NSError {
                    print(error)
                }
            }).resume()
        }
    }
}
