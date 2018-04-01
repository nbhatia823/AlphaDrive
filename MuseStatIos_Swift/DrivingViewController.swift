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
import Charts


class DrivingViewController: UIViewController, IXNMuseConnectionListener, IXNMuseDataListener, IXNMuseListener, IXNLogListener {
    
    
    var muse: IXNMuse!
    var manager: IXNMuseManagerIos!
    var connectionController: SimpleController!
    var postDataTimer: Timer?
    var updateChartTimer: Timer?
    var stopAlarmTimer: Timer?
    var alarmStartTime = 0.0
    var alarmEndTime = 10.0
    var startTimeSinceReference: Double?
    var finalData: [(date: Date, alpha: Double)] = []
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
    
    
    var recievedData1: String?
    var recievedData2: String?
    var recievedData3: String?
    var recievedData4: String?
    var recentAvgAlpha: Double = 0.0
    var recentTime: Double = 0.0
    
    @IBOutlet weak var lineChart: LineChartView!
    var chartData: [ChartDataEntry] = [ChartDataEntry(x: 0.0, y: 0.0)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.title = "Your Current Drive"
        // Do any additional setup after loading the view.
        setupLineChart()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(muse)
        print(manager)
        print(muse.getConnectionState() == IXNConnectionState.connected )
        connect()
        setupPostDataTimer()
        setupUpdateChartTimer()
        
    }
    
    func setupLineChart() {
        lineChart.legend.form = .line
        lineChart.chartDescription?.enabled = false
        let lYAxis = lineChart.leftAxis
        lYAxis.removeAllLimitLines()
        lYAxis.axisMaximum = 1.0
        lYAxis.axisMinimum = -1.0
        lYAxis.gridLineDashLengths = [5, 5]
        lYAxis.drawLimitLinesBehindDataEnabled = true
        
        lineChart.rightAxis.enabled = false
        
        let lXAxis = lineChart.xAxis
        
        
        lXAxis.axisMinimum = 0
        lXAxis.axisMaximum = 30
        lXAxis.gridLineDashLengths = [5, 5]
        lXAxis.drawLimitLinesBehindDataEnabled = true
        lXAxis.gridLineDashPhase = 0
    }
    
    func setupUpdateChartTimer() {
        guard updateChartTimer == nil else { return }
        updateChartTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateChart), userInfo: nil, repeats: true)
        
    }
    
    @objc func updateChart() {
        chartData.append(ChartDataEntry(x: recentTime, y: recentAvgAlpha))
        
        let dataSet = LineChartDataSet(values: chartData, label: "Your Current Alpha Waves")
        
        //Shift over graph to only show newest data points
        if chartData.count >= 25 * 2 {
            chartData = Array(chartData[0 ..< 30])
            lineChart.xAxis.axisMinimum += 10
            lineChart.xAxis.axisMaximum += 10
        }
        
        dataSet.drawIconsEnabled = false
        dataSet.setColor(.red)
        dataSet.lineWidth = 1.5
        dataSet.circleRadius = 0
        dataSet.drawCircleHoleEnabled = false
        dataSet.formLineDashLengths = [5, 2.5]
        dataSet.formLineWidth = 1
        dataSet.formSize = 15
        
        let gradientColors = [ChartColorTemplates.colorFromString("#00ff0000").cgColor,
                              ChartColorTemplates.colorFromString("#ffff0000").cgColor]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
        
        dataSet.fillAlpha = 1
        dataSet.fill = Fill(linearGradient: gradient, angle: 90) //.linearGradient(gradient, angle: 90)
        dataSet.drawFilledEnabled = true
        
        let data = LineChartData(dataSet: dataSet)
        
        data.setDrawValues(false)
        
        lineChart.data = data
    }
    
    @IBAction func endDrive(_ sender: Any) {
        
        print ("TRYING END REQUEST")
        self.muse.unregisterAllListeners()
        postDataTimer?.invalidate()
        stopAlarmTimer?.invalidate()
        updateChartTimer?.invalidate()
        
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
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                        let time = dict["time"] as! String
                        let date = dateFormatter.date(from: time) ?? Date()
                        let alpha = dict["avg_alpha"] as! Double
                        self.finalData.append((date, alpha))
                    }
                }
                print (self.finalData)
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "endDrive", sender: self)
                }
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
                recievedData1 = "\(info[0])"
                recievedData2 = "\(info[1])"
                recievedData3 = "\(info[2])"
                recievedData4 = "\(info[3])"
                
                var numZeroAlphas = 0.0
                //We only want to count nonZero alphas
                if recievedData1 == "0" {
                    numZeroAlphas += 1.0
                }
                if recievedData2 == "0" {
                    numZeroAlphas += 1.0
                }
                if recievedData3 == "0" {
                    numZeroAlphas += 1.0
                }
                if recievedData4 == "0" {
                    numZeroAlphas += 1.0
                }
                //If all are 0, we will divide by 0, so set to 1
                if numZeroAlphas == 0 {
                    numZeroAlphas -= 1.0
                }
                recentAvgAlpha = (Double(recievedData1!)! + Double(recievedData2!)! + Double(recievedData3!)! + Double(recievedData4!)!) / (4.0-numZeroAlphas)
                let date = Date()
                if startTimeSinceReference == nil {
                    startTimeSinceReference = date.timeIntervalSinceReferenceDate
                }
                recentTime = date.timeIntervalSinceReferenceDate - startTimeSinceReference!
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

    func setupPostDataTimer() {
        guard postDataTimer == nil else { return }
        postDataTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(sendData), userInfo: nil, repeats: true)
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
        if let data1 = self.recievedData1, let data2 = self.recievedData2, let data3 = self.recievedData3, let data4 = self.recievedData4{
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
                    DispatchQueue.main.async {
                        let dateFormatter : DateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let date = Date()
                        let dateString = dateFormatter.string(from: date)
                        let data = ((json["status"] as AnyObject? as? String) ?? "")
                        if data == "-1" {
                            self.soundTheAlarm()
                        }
                    }
                } catch let error as NSError {
                    print(error)
                }
            }).resume()
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation
     */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "endDrive") {
            let viewController = segue.destination as! DriveSummaryViewController
            viewController.finalData = self.finalData
        }
        
    }
    
     /*
     // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
