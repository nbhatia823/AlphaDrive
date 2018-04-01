//
//  DriveSummaryViewController.swift
//  MuseStatIos_Swift
//
//  Created by Nikhil Bhatia on 3/31/18.
//  Copyright © 2018 Ivan Rzhanoi. All rights reserved.
//

import UIKit
import Charts

class DriveSummaryViewController: UIViewController {

    
    @IBOutlet weak var lineChart: LineChartView!
    @IBAction func exitSummaryClick(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    var finalData: [(date: Date, alpha: Double)]!
    
    func setupLineChart() {
        lineChart.legend.form = .line
        lineChart.chartDescription?.enabled = false
        let lYAxis = lineChart.leftAxis
        lYAxis.removeAllLimitLines()
        lYAxis.axisMaximum = 1.2
        lYAxis.axisMinimum = -0.2
        lYAxis.gridLineDashLengths = [5, 5]
        lYAxis.drawLimitLinesBehindDataEnabled = true
        
        lineChart.rightAxis.enabled = false
        
        let lXAxis = lineChart.xAxis
        
        
        lXAxis.axisMinimum = 0
        lXAxis.gridLineDashLengths = [5, 5]
        lXAxis.drawLimitLinesBehindDataEnabled = true
        lXAxis.gridLineDashPhase = 0
        
        var startTime: TimeInterval?
        var chartData = [ChartDataEntry]()
        for (date,alpha) in finalData {
            if startTime == nil {
                startTime = date.timeIntervalSinceReferenceDate
            }
            let time = date.timeIntervalSinceReferenceDate - startTime!
            chartData.append(ChartDataEntry(x: time, y: alpha))
        }
        lXAxis.axisMaximum = Double(chartData.count) * 5.0

        let dataSet = LineChartDataSet(values: chartData, label: "Your Alpha Waves: Time (seconds) vs. Alpha Values")
        
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.title = "Your Drive Summary"
        setupLineChart()
        // Do any additional setup after loading the view.
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
