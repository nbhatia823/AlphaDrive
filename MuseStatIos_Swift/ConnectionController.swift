//
//  ConnectionController.swift
//  MuseStatIos_Swift
//
//  Created by Ivan Rzhanoi on 24/11/2016.
//  Copyright © 2016 Ivan Rzhanoi. All rights reserved.
//

import UIKit

class ConnectionController: UIViewController, IXNMuseConnectionListener, IXNMuseDataListener, IXNMuseListener, IXNLogListener /*UITableViewDelegate, UITableViewDataSource*/ {
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
    @IBOutlet weak var connectButton: UIButton!
    //@IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    
    //var updateStatusTimer: Timer?
    
    var muse = IXNMuse()
    var manager = IXNMuseManagerIos()
    var isLastBlink = false
    var connected: Bool = false {
        didSet {
            if connected == false {
                startDrivingButton.isEnabled = false
                //disconnectButton.isEnabled = false
                connectButton.setTitle("Connect", for: UIControlState.normal)
                if connectButton.allTargets.count > 0 {
                    connectButton.removeTarget(self, action: #selector(disconnect(_:)), for: .touchUpInside)
                }
                connectButton.addTarget(self, action: #selector(connect(_:)), for: .touchUpInside)
            }
            else {
                startDrivingButton.isEnabled = true
                connectButton.setTitle("Disconnect", for: UIControlState.normal)
                if connectButton.allTargets.count > 0 {
                    connectButton.removeTarget(self, action: #selector(connect(_:)), for: .touchUpInside)
                }
                connectButton.addTarget(self, action: #selector(disconnect(_:)), for: .touchUpInside)
                //disconnectButton.isEnabled = true
            }
        }
    }

    // Declaring an object that will call the functions in SimpleController()
    var connectionController = SimpleController()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
//        self.tableView.delegate = self
//        self.tableView.dataSource = self
        UIApplication.shared.isIdleTimerDisabled = true
        self.manager = IXNMuseManagerIos.sharedManager()
        self.navigationItem.title = "Prepare for Your Drive"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.manager.startListening()
        if self.manager.getMuses().count == 0 {
            connected = false
            statusLabel.text = "Disconnected"
        }
        else if !connected {
            startDrivingButton.isEnabled = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //updateStatusTimer?.invalidate()
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.manager = IXNMuseManagerIos.sharedManager()
        self.manager.museListener = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func receiveLog(_ log: IXNLogPacket) {

    }

    func museListChanged() {

    }
    
    func receive(_ packet: IXNMuseConnectionPacket, muse: IXNMuse?) {       // TODO: Find and error over here!
        var state: String
        switch packet.currentConnectionState {
        case IXNConnectionState.disconnected:
            connected = false
            state = "disconnected"
            statusLabel.text = "Disconnected"
        case IXNConnectionState.connected:
            connected = true
            print ("reached")
            state = "connected"
            statusLabel.text = "Connected"
        case IXNConnectionState.connecting:
            state = "connecting"
            statusLabel.text = "Connecting"
        case IXNConnectionState.needsUpdate:
            state = "needs update"
        case IXNConnectionState.unknown:
            state = "unknown"
        }
        print("connect: \(state)")
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
    
    
    @objc func disconnect(_ sender: Any) {
        connected = false
        if self.muse.getConnectionState() == IXNConnectionState.connected {
            self.muse.disconnect(true)
        }
    }
    
    @objc func connect(_ sender: AnyObject) {
        var muses = self.manager.getMuses()
        print(muses.count, " is count of muses")
        if 0 < muses.count {
            let muse: IXNMuse = muses[0] as! IXNMuse
            self.muse = muse
            self.muse.register(self)
            self.muse.runAsynchronously()
            if self.muse.getConnectionState() == IXNConnectionState.connecting {
                statusLabel.text = "Connecting"
            }
            print("======Chose device to connect: \(self.muse.getName()) \(self.muse.getMacAddress())======\n")
            print(self.muse.getConnectionState() == IXNConnectionState.connecting)
            print(self.muse.getConnectionState() == IXNConnectionState.connected)
            print(self.muse.getConnectionState() == IXNConnectionState.disconnected)
            print(self.muse.getConnectionState() == IXNConnectionState.unknown)
        }
        else {
            statusLabel.text = "No muse available"
        }
        print(muses)
        print(self.muse)
        
//        DispatchQueue.main.async{
//            self.tableView.reloadData()
//        }
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
