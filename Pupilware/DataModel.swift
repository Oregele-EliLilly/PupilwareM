//
//  DataModel.swift
//  Pupilware
//
//  Created by Raymond Martin on 1/27/16.
//  Edited by Chatchai Mark Wangwiwattana on 7/26/2016.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

import Foundation

@objc class DataModel: NSObject{
    static let sharedInstance = DataModel()
    
    
    // For tobii
    var tobiiProject:String = ""
    var tobiiCurrentParticipant = ""
    var tobiiCurrentCalibration = ""
    var tobiiCurrentCalibrationState = ""
    var tobiiCurrentRecording = ""
    var tobiiSubjectIds: [String: String] = [:]
    
    
    
    var currentSubjectID:String = ""
    var allSubjectIDs:[String] = []
    var faceInView:Bool = false
    var currentTest:Test?
    var digitIteration = 0
    var calibration_files = (face:"", params:"", data:"")
    var settings = (dist:60, movAvg:11, medBlur:11, baseStart:20, baseEnd:40, thresh:15, markCost:1, baseline: 0, cogHigh:0)
    var lumMode = true
    var numberStartFrame = 0
    var numberStopFrame = 0
    var bridgeDelegate:BridgeDelegate?
    var glassDelegate:GlassDelegate?
    var digitTestLumProgress = [
        1: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        2: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        3: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        4: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        5: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        ] as [Int:[Int:[Bool]]]
    
    var digitTestAngleProgress = [
        1: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        2: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        3: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        4: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        5: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        ] as [Int:[Int:[Bool]]]
    
    var targetTestProgress = [false,false,false,false]
    
    override init(){
        super.init()
        self.fetchSubjectIDs()
    }
    
    func getDist()->Int{return settings.dist}
    func getMovAvg()->Int{return settings.movAvg}
    func getmedBlur()->Int{return settings.medBlur}
    func getBaseStart()->Int{return settings.baseStart}
    func getBaseEnd()->Int{return settings.baseEnd}
    func getThresh()->Int{return settings.thresh}
    func getMarkCost()->Int{return settings.markCost}
    func getBaseline()->Int{return settings.baseline}
    func getCogHigh()->Int{return settings.cogHigh}
    
    func fetchSubjectIDs(){
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("allSubjectIDs") as? NSData {
            self.allSubjectIDs = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [String]
        }
        
        if let tobiiData = NSUserDefaults.standardUserDefaults().objectForKey("tobiiSubjects") as? NSData {
            self.tobiiSubjectIds = NSKeyedUnarchiver.unarchiveObjectWithData(tobiiData) as! [String: String]
        }
    }
    
    func archiveSubjectIDs(){
        let data = NSKeyedArchiver.archivedDataWithRootObject(allSubjectIDs)
        let tobiiData = NSKeyedArchiver.archivedDataWithRootObject(tobiiSubjectIds)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "allSubjectIDs")
        NSUserDefaults.standardUserDefaults().setObject(tobiiData, forKey: "tobiiSubjects")
    }
    
    func getFaceVideoFileName()->NSString{
        if(self.currentTest == nil)
        {
            let time:String = String(Int64(NSDate().timeIntervalSince1970*10.0))
            return "default_face_" + time + ".mp4"
        }
        
        return self.currentTest!.getFaceVideoFileName()
    }
    
    func getFaceMetaFileName()->NSString{
        if(self.currentTest == nil)
        {
            let time:String = String(Int64(NSDate().timeIntervalSince1970*10.0))
            return "default_fmeta_" + time + ".csv"
        }
        
        return self.currentTest!.getFaceMetaFileName()
    }
    
    
    func calParamFileName()->NSString{
        return self.currentTest!.getCALFileName()
    }
    
    
    func getPupilFileName()->NSString{
        
        if(self.currentTest == nil)
        {
            let time:String = String(Int64(NSDate().timeIntervalSince1970*10.0))
            return "default_pupil_" + time + ".csv"
        }
        
        return self.currentTest!.getPupilSizeFileName()
    }
    
    
    func writeMetaData(){
        self.currentTest?.writeData()
    }
    
    func setNewCalibrationFiles(){
        
        //        var testType = "unknown"
        //        if(self.currentTest is TargetTest)
        //        {
        //            testType = "target"
        //        }
        //        else if(self.currentTest is DigitTest)
        //        {
        //            let dTest = self.currentTest as! DigitTest
        //
        //            if (lumMode){
        //                testType = "digit_lux\(dTest.lux)"
        //            }
        //            else{
        //                testType = "digit_angle\(dTest.angle)"
        //            }
        //        }
        
        let id:String = String(Int64(NSDate().timeIntervalSince1970*10.0))
        calibration_files.face = "\(currentSubjectID)_calib_face_\(id).mp4"
        calibration_files.params = "\(currentSubjectID)_calib_params_\(id).csv"
        calibration_files.data = "\(currentSubjectID)_calib_data_\(id).csv"
        
        
    }
    
    func getCalibrationFaceVideoFileName()->NSString{
        return calibration_files.face
    }
    
    func getCalibrationParamsFileName()->NSString{
        return calibration_files.params
    }
    
    func getCalibrationDataFileName()->NSString{
        return calibration_files.data
    }
    
    
    func resetProgress(){
        digitTestLumProgress = [
            0: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            1: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            2: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            3: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            4: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            ] as [Int:[Int:[Bool]]]
        
        digitTestAngleProgress = [
            1: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            2: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            3: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            4: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            5: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            ] as [Int:[Int:[Bool]]]
    }
    
    
    func completeDigitTest(lum:Int, digit:Int, iter:Int){
        if (self.lumMode){
            self.digitTestLumProgress[lum]![digit]![iter-1] = true
        }else{
            self.digitTestAngleProgress[lum]![digit]![iter-1] = true
        }
    }
    
    func isDigitTestComplete(lum:Int, digit:Int, iter:Int)->Bool{
        if self.lumMode{
            return self.digitTestLumProgress[lum+1]![digit]![iter-1]
        }else{
            return self.digitTestAngleProgress[lum+1]![digit]![iter-1]
        }
    }
    
    func compeleteTargetTest(iter:Int){
        self.targetTestProgress[iter-1] = true
    }
    
    func isTargetTestComplete(iter:Int)->Bool{
        return self.targetTestProgress[iter-1]
    }
}

protocol Test{
    func completeTest()
    func getDigits()->[Int]
    func writeData()
    func getFaceVideoFileName()->String
    func getFaceMetaFileName()->String
    func getPupilSizeFileName()->String
    func getCALFileName()->String
}

class TargetTest: Test{
    let model = DataModel.sharedInstance
    let ID:String = String(Int64(NSDate().timeIntervalSince1970*10.0))
    var missing_digits:Int, iter:Int, lux:Int, exact_lux:Double, subjectID:String, angle:Int
    var labels = (face:"", faceMetaFile:"", pupilFile:"", calFile:"")
    
    
    init(subjectID:String, missing_digits:Int, iter:Int, exact_lux:Double){
        self.missing_digits = missing_digits
        self.iter = iter
        self.lux = -1
        self.exact_lux = exact_lux
        self.subjectID = subjectID
        self.angle = -1
        self.labels.face = "\(self.subjectID)_target_dgt\(self.missing_digits)_itr\(self.iter)_face.mp4"
        self.labels.faceMetaFile = "\(self.subjectID)_target_dgt\(self.missing_digits)_itr\(self.iter)_fmeta.csv"
        self.labels.pupilFile = "\(self.subjectID)_target_dgt\(self.missing_digits)_itr\(self.iter)_result.csv"
        self.labels.calFile = "\(self.subjectID)_target_dgt\(self.missing_digits)_itr\(self.iter)_calib.csv"
    }
    
    func getFaceVideoFileName() -> String {
        return labels.face
    }
    
    func getCALFileName() -> String {
        return labels.calFile
    }
    
    func getFaceMetaFileName() -> String {
        return labels.faceMetaFile
    }
    
    func getPupilSizeFileName() -> String {
        return labels.pupilFile
    }
    
    func completeTest(){
        model.compeleteTargetTest(iter)
        self.writeData()
    }
    
    func getDigits()->[Int]{
        switch iter{
        case 0: // intended for practicing (tutorial)
            return [1, 2, 3, 4, 5, 1, 7, 8, 9, 10, 11, 7, 13, 14, 15, 16, 17, 18, 19, 20]
        case 1:
            return [1, 2, 3, 4, 5, 9, 7, 8, 9, 10, 11, 1, 13, 14, 15, 16, 17, 13, 19, 20]
        case 2:
            return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
        case 3:
            return [1, 2, 3, 4, 5, 10, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 15, 19, 20]
        case 4:
            return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 8, 19, 20]
        default:
            print("TARGET TEST NOT FOUND")
        }
        return []
    }
    
    func getTimeStamp()->String{
        let currentDateTime = NSDate()
        let formatter = NSDateFormatter()
        formatter.timeStyle = NSDateFormatterStyle.MediumStyle
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        return formatter.stringFromDate(currentDateTime)
    }
    
    func writeData(){
        var attempt = 1
        while (attempt <= 999){
            let fileName = "\(self.subjectID)_target_meta_\(self.ID)_\(String(format: "%03d", attempt)).json"
            
            if(self.writeJSONFile(fileName)){
                break
            }
            attempt += 1
            print("WRITE FAILED CRITICAL ERROR ATTEMPT: \(attempt)")
        }
    }
    
    func writeJSONFile(fileName:String)->Bool{
        let data: [String: AnyObject] = [
            "user_id": self.subjectID,
            "type" : "Target Test",
            "missing_digits" : self.missing_digits,
            "iteration": self.iter,
            "lux_level" : self.lux,
            "exact_lux_level" : self.exact_lux,
            "angle" : self.angle,
            "face_file_name" : self.labels.face,
            "pupil_data_file_name" : self.labels.pupilFile,
            "face_data_file_name" : self.labels.faceMetaFile,
            "calibration_face" : model.getCalibrationFaceVideoFileName(),
            "parameter_file" : model.getCalibrationParamsFileName(),
            "calibration_data_file" : model.getCalibrationDataFileName(),
            "write_time" : self.getTimeStamp(),
            "ID" : self.ID,
            "numberStartFrame" : model.numberStartFrame,
            "numberStopFrame" : model.numberStopFrame
        ]
        
        var jsonData: NSData!
        do {
            jsonData = try NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions())
            let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding)
            print(jsonString!)
        } catch let error as NSError {
            print("Array to JSON conversion failed: \(error.localizedDescription)")
        }
        
        let documentsDirectoryPathString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        let documentsDirectoryPath = NSURL(string: documentsDirectoryPathString)!
        
        let jsonFilePath = documentsDirectoryPath.URLByAppendingPathComponent(fileName)
        let fileManager = NSFileManager.defaultManager()
        var isDirectory: ObjCBool = false
        
        // creating a .json file in the Documents folder
        if !fileManager.fileExistsAtPath(jsonFilePath.absoluteString, isDirectory: &isDirectory) {
            let created = fileManager.createFileAtPath(jsonFilePath.absoluteString, contents: nil, attributes: nil)
            if created {
                print("File created")
                do {
                    let file = try NSFileHandle(forWritingToURL: jsonFilePath)
                    file.writeData(jsonData)
                    print("JSON data was written to the file successfully!")
                } catch let error as NSError {
                    print("Couldn't write to file: \(error.localizedDescription)")
                }
            } else {
                print("Couldn't create file for some reason")
            }
        } else {
            print("File already exists")
            return false
        }
        return true
    }
}


class DigitTest: Test{
    let model = DataModel.sharedInstance
    let ID:String = String(Int64(NSDate().timeIntervalSince1970*10.0))
    var digits:Int, iter:Int, lux:Int, exact_lux:Double, subjectID:String, angle:Int
    var labels = (face:"", faceMetaFile:"", pupilFile:"", calFile:"")
    
    
    init(subjectID:String, digits:Int, iter:Int, lux:Int, exact_lux:Double){
        self.digits = digits
        self.iter = iter
        self.lux = lux
        self.exact_lux = exact_lux
        self.subjectID = subjectID
        self.angle = -1
        self.labels.face = "\(self.subjectID)_digit_lux\(self.lux)_dgt\(self.digits)_itr\(self.iter)_face.mp4"
        self.labels.faceMetaFile = "\(self.subjectID)_digit_lux\(self.lux)_dgt\(self.digits)_itr\(self.iter)_fmeta.csv"
        self.labels.pupilFile = "\(self.subjectID)_digit_lux\(self.lux)_dgt\(self.digits)_itr\(self.iter)_result.csv"
        self.labels.calFile = "\(self.subjectID)_digit_lux\(self.lux)_dgt\(self.digits)_itr\(self.iter)_calib.csv"
    }
    
    init(subjectID:String, digits:Int, iter:Int, angle:Int, exact_lux:Double){
        self.digits = digits
        self.iter = iter
        self.lux = -1
        self.exact_lux = exact_lux
        self.subjectID = subjectID
        self.angle = angle
        self.labels.face = "\(self.subjectID)_digit_ang\(self.angle)_dgt\(self.digits)_itr\(self.iter)_face.mp4"
        self.labels.faceMetaFile = "\(self.subjectID)_digit_ang\(self.angle)_dgt\(self.digits)_itr\(self.iter)_fmeta.csv"
        self.labels.pupilFile = "\(self.subjectID)_digit_ang\(self.angle)_dgt\(self.digits)_itr\(self.iter)_result.csv"
        self.labels.calFile = "\(self.subjectID)_digit_ang\(self.angle)_dgt\(self.digits)_itr\(self.iter)_calib.csv"
    }
    
    
    func getFaceVideoFileName() -> String {
        return labels.face
    }
    
    func getCALFileName() -> String {
        return labels.calFile
    }
    
    func getFaceMetaFileName() -> String {
        return labels.faceMetaFile
    }
    
    func getPupilSizeFileName() -> String {
        return labels.pupilFile
    }
    
    func completeTest(){
        if lux == -1{
            model.completeDigitTest(angle, digit: digits, iter: iter)
        }else{
            model.completeDigitTest(lux, digit: digits, iter: iter)
        }
        self.writeData()
    }
    
    func getListOfDigits(digits:Int)->[Int]
    {
        var result:[Int] = []
        for _ in 0..<digits{
            result.append(Int(arc4random() % 9))
        }
        return result
    }
    
    func getDigits()->[Int]{
        switch digits{
        case 5:
            switch iter{
            case 1:
                //case 1:return [1, 2, 3, 4, 5]
                return getListOfDigits(5)
            case 2:
                //return [1, 2, 3, 4, 5]
                return getListOfDigits(5)
                
            case 3:
                //return [1, 2, 3, 4, 5]
                return getListOfDigits(5)
                
            case 4:
                // return [1, 2, 3, 4, 5]
                return getListOfDigits(5)
                
            default:print("DIGIT TEST NOT FOUND")
            }
        case 6: //use fix number set for consitancy accross participants, and avoid prediable pattern.
            switch iter{
            case 1:return [6, 4, 8, 9, 2, 1]
            case 2:return [3, 2, 3, 7, 1, 0]
            case 3:return [5, 2, 6, 4, 2, 8]
            case 4:return [1, 4, 7, 2, 1, 6]
            default:print("DIGIT TEST NOT FOUND")
            }
        case 7:
            switch iter{
            case 1:return [2, 4, 7, 5, 7, 2, 1]
            case 2:return [4, 3, 6, 8, 0, 9, 7]
            case 3:return [8, 2, 5, 7, 3, 0, 7]
            case 4:return [3, 7, 4, 8, 6, 2, 0]
            default:print("DIGIT TEST NOT FOUND")
            }
        case 8:
            switch iter{
            case 1:return [1, 3, 8, 5, 7, 3, 9, 8]
            case 2:return [5, 2, 4, 7, 0, 6, 3, 8]
            case 3:return [6, 3, 1, 8, 5, 2, 0, 4]
            case 4:return [0, 2, 6, 4, 9, 5, 8, 7]
            default:print("DIGIT TEST NOT FOUND")
            }
        default:
            print("DIGIT TEST NOT FOUND")
        }
        return []
    }
    
    func getTimeStamp()->String{
        let currentDateTime = NSDate()
        let formatter = NSDateFormatter()
        formatter.timeStyle = NSDateFormatterStyle.MediumStyle
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        return formatter.stringFromDate(currentDateTime)
    }
    
    func writeData(){
        var attempt = 1
        while (attempt <= 999){
            let fileName = "\(self.subjectID)_digit_meta_\(self.ID)_\(String(format: "%03d", attempt)).json"
            if(self.writeJSONFile(fileName)){
                break
            }
            attempt += 1
            print("WRITE FAILED CRITICAL ERROR ATTEMPT: \(attempt)")
        }
    }
    
    func writeJSONFile(fileName:String)->Bool{
        let data: [String: AnyObject] = [
            "user_id": self.subjectID,
            "type" : "digit span",
            "digits" : self.digits,
            "iteration": self.iter,
            "lux_level" : self.lux,
            "exact_lux_level" : self.exact_lux,
            "angle" : self.angle,
            "face_file_name" : self.labels.face,
            "pupil_data_file_name" : self.labels.pupilFile,
            "calibration_face" : model.getCalibrationFaceVideoFileName(),
            "parameter_file" : model.getCalibrationParamsFileName(),
            "calibration_data_file" : model.getCalibrationDataFileName(),
            "write_time" : self.getTimeStamp(),
            "ID" : self.ID,
            "numberStartFrame" : model.numberStartFrame,
            "numberStopFrame" : model.numberStopFrame
        ]
        
        var jsonData: NSData!
        do {
            jsonData = try NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions())
            let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding)
            print(jsonString!)
        } catch let error as NSError {
            print("Array to JSON conversion failed: \(error.localizedDescription)")
        }
        
        let documentsDirectoryPathString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        let documentsDirectoryPath = NSURL(string: documentsDirectoryPathString)!
        
        let jsonFilePath = documentsDirectoryPath.URLByAppendingPathComponent(fileName)
        let fileManager = NSFileManager.defaultManager()
        var isDirectory: ObjCBool = false
        
        // creating a .json file in the Documents folder
        if !fileManager.fileExistsAtPath(jsonFilePath.absoluteString, isDirectory: &isDirectory) {
            let created = fileManager.createFileAtPath(jsonFilePath.absoluteString, contents: nil, attributes: nil)
            if created {
                print("File created")
                do {
                    let file = try NSFileHandle(forWritingToURL: jsonFilePath)
                    file.writeData(jsonData)
                    print("JSON data was written to the file successfully!")
                } catch let error as NSError {
                    print("Couldn't write to file: \(error.localizedDescription)")
                }
            } else {
                print("Couldn't create a file for some reasons")
            }
        } else {
            print("File already exists")
            return false
        }
        return true
    }
}


class ACTTest: Test{
    let model = DataModel.sharedInstance
    let ID:String = String(Int64(NSDate().timeIntervalSince1970*10.0))
    var itemID:Int, subjectID:String
    var labels = (face:"", faceMetaFile:"", pupilFile:"", calFile:"")
    
    
    init(subjectID:String, itemID:Int){
        self.itemID = itemID
        self.subjectID = subjectID
        
        self.labels.face = "\(self.subjectID)_ACT_\(self.itemID)_face.mp4"
        self.labels.faceMetaFile = "\(self.subjectID)_ACT_\(self.itemID)_fmeta.csv"
        self.labels.pupilFile = "\(self.subjectID)_ACT_\(self.itemID)_result.csv"
        self.labels.calFile = "\(self.subjectID)_ACT_\(self.itemID)_calib.csv"
    }
    
    
    func getFaceVideoFileName() -> String {
        return labels.face
    }
    
    func getCALFileName() -> String {
        return labels.calFile
    }
    
    func getFaceMetaFileName() -> String {
        return labels.faceMetaFile
    }
    
    func getPupilSizeFileName() -> String {
        return labels.pupilFile
    }
    
    func completeTest(){
        self.writeData()
    }
    
    
    func getDigits()->[Int]{
        // ??
        return [];
    }
    
    func getTimeStamp()->String{
        let currentDateTime = NSDate()
        let formatter = NSDateFormatter()
        formatter.timeStyle = NSDateFormatterStyle.MediumStyle
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        return formatter.stringFromDate(currentDateTime)
    }
    
    func writeData(){
        var attempt = 1
        while (attempt <= 999){
            let fileName = "\(self.subjectID)_digit_meta_\(self.ID)_\(String(format: "%03d", attempt)).json"
            if(self.writeJSONFile(fileName)){
                break
            }
            attempt += 1
            print("WRITE FAILED CRITICAL ERROR ATTEMPT: \(attempt)")
        }
    }
    
    func writeJSONFile(fileName:String)->Bool{
        let data: [String: AnyObject] = [
            "user_id": self.subjectID,
            "type" : "ACT",
            "itemID" : self.itemID,
            "face_file_name" : self.labels.face,
            "pupil_data_file_name" : self.labels.pupilFile,
            "calibration_face" : model.getCalibrationFaceVideoFileName(),
            "parameter_file" : model.getCalibrationParamsFileName(),
            "calibration_data_file" : model.getCalibrationDataFileName(),
            "write_time" : self.getTimeStamp(),
            "ID" : self.ID
        ]
        
        var jsonData: NSData!
        do {
            jsonData = try NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions())
            let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding)
            print(jsonString!)
        } catch let error as NSError {
            print("Array to JSON conversion failed: \(error.localizedDescription)")
        }
        
        let documentsDirectoryPathString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        let documentsDirectoryPath = NSURL(string: documentsDirectoryPathString)!
        
        let jsonFilePath = documentsDirectoryPath.URLByAppendingPathComponent(fileName)
        let fileManager = NSFileManager.defaultManager()
        var isDirectory: ObjCBool = false
        
        // creating a .json file in the Documents folder
        if !fileManager.fileExistsAtPath(jsonFilePath.absoluteString, isDirectory: &isDirectory) {
            let created = fileManager.createFileAtPath(jsonFilePath.absoluteString, contents: nil, attributes: nil)
            if created {
                print("File created")
                do {
                    let file = try NSFileHandle(forWritingToURL: jsonFilePath)
                    file.writeData(jsonData)
                    print("JSON data was written to the file successfully!")
                } catch let error as NSError {
                    print("Couldn't write to file: \(error.localizedDescription)")
                }
            } else {
                print("Couldn't create a file for some reasons")
            }
        } else {
            print("File already exists")
            return false
        }
        return true
    }
}



@objc protocol BridgeDelegate{
    func trackingFaceDone()
    func startTrackingFace()
    func finishCalibration()
    func faceInView()
    func faceNotInView()
    
    
    optional func isNumberStarted() -> Bool
    optional func isNumberStoped() -> Bool
    optional func isTestingFinished() -> Bool
    optional func sendLog(text:String)
}

@objc protocol GlassDelegate {
    func finishGlassCalibration()
}
