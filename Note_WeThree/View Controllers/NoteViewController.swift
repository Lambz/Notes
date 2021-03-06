//
//  NoteViewController.swift
//  Note_WeThree
//
//  Created by Chetan on 2020-06-22.
//  Copyright © 2020 Chaitanya Sanoriya. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import AVFoundation

class NoteViewController: UIViewController {
    
    //    variables to distinguish between weather old note opened or new note
    var selectedNote: Int?
    var forCategory: Int?
    //    index variable to store the new note
    var tempNoteIndex: Int?
    
    var noteViewContext: NSManagedObjectContext!
    var openedNote: Note!
    var latitude: Double?
    var longitude: Double?
    
    
    //    for audio recording and playing
    
    var recordingIsAvailable = false
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer : AVAudioPlayer!
    var mDidRecord = false
    var mAudioFileName: String!
    
    //    variables for location manager
    let locationManager = CLLocationManager()
    var didUpdatedLocation: (() -> ())?
    
    //    image view variables
    var imagePickerController = UIImagePickerController()
    
    
    
    //    screen element outlets
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var noteImage: UIImageView!
    @IBOutlet weak var noteTitle: UITextField!
    @IBOutlet weak var noteText: UITextView!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var locationLabel: UIButton!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //        sets up context for data
        let noteViewDelegate = UIApplication.shared.delegate as! AppDelegate
        self.noteViewContext = noteViewDelegate.persistentContainer.viewContext
        initalSetupOnViewLoad()
        
        startLocationManager()
        dismissKey()
    }
    
    
    
    //    MARK: UI event handler methods implemented
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        
        self.selectedNote = nil
        self.forCategory = nil
        performSegue(withIdentifier: "backToNoteView", sender: self)
        
    }
    
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        
        if(self.forCategory != nil) {
            saveNewNote()
        }
        else {
            saveOldNote()
        }
        
    }
    
    
    
    @IBAction func deleteNoteTapped(_ sender: Any) {
        
        if(self.selectedNote != nil) {
            if let noteIndex = self.selectedNote {
                do {
                    try NotesHelper.getInstance().deleteNote(at: noteIndex, context: self.noteViewContext)
                    self.cancelButtonTapped(self)
                }
                catch {
                    print(error)
                }
            }
        }
        else {
            let msg = "Can't delete unsaved note!"
            let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                self.cancelButtonTapped(self)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    
    @IBAction func recordAudio(_ sender: Any) {
        if recordingIsAvailable || mDidRecord
        {
            playAudio()
            micButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        }
        else
        {
            if audioRecorder == nil
            {
                startRecording()
                micButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
            } else
            {
                finishRecording(success: true)
                micButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
        }
    }
    
    @IBAction func viewLocation(_ sender: Any) {
        
        if(self.forCategory == nil) {
            if(self.openedNote.mLat != nil && self.openedNote.mLong != nil) {
                performSegue(withIdentifier: "mapScreen", sender: self)
            }
                
            else {
                let alert = UIAlertController(title: "Location cannot be displayed!", message: "The location when this note was taken is not available. It could be due to insufficient permissions or network error on your device.", preferredStyle: .alert)
                let action = UIAlertAction(title: "Okay", style: .default, handler: nil)
                alert.addAction(action)
                
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    @IBAction func cameraButtonTapped(_ sender: Any) {
        
        imagePickerController.delegate = self
        
        let actionSheet = UIAlertController(title: "Add image to note", message: "Choose a source to add image", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            
            if(UIImagePickerController.isSourceTypeAvailable(.camera)) {
                self.imagePickerController.sourceType = .camera
                self.imagePickerController.allowsEditing = false
                self.present(self.imagePickerController, animated: true, completion: nil)
            }
            else {
                let alert = UIAlertController(title: "Camera Error!", message: "Can't access camera", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { (action) in
            self.imagePickerController.sourceType = .photoLibrary
            self.present(self.imagePickerController, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    
    
    //    handler for variable passing for next screen
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destinationView = segue.destination as? MapViewController {
            let location = CLLocation(latitude: CLLocationDegrees(exactly: self.latitude!)!, longitude: CLLocationDegrees(self.longitude!))
            destinationView.mDestination = location
        }
        
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}



// MARK: implements other delegate methods
extension NoteViewController {
    //    MARK: sets up initial values on view load
    func initalSetupOnViewLoad() {
        
        do {
            self.noteText.isEditable = true
            self.noteText.isUserInteractionEnabled = true
            
            
            if(forCategory == nil) {
                //            sets up note object if saved note opened
                if let noteIndex = self.selectedNote {
                    openedNote = try NotesHelper.getInstance().getNote(at: noteIndex)
                    if(openedNote.mAudioFileLocation != nil)
                    {
                        mAudioFileName = openedNote.mAudioFileLocation
                        self.micButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                        recordingIsAvailable = true
                    }
                    else {
                        mAudioFileName = randomString(length: 10) + ".m4a"
                        self.micButton.isHidden = true
                    }
                    showNoteOnLoad()
                }
            }
            else {
                self.locationLabel.isHidden = true
                self.dateLabel.isHidden = true
                if let category = self.forCategory {
                    self.tempNoteIndex = try NotesHelper.getInstance().getNumberOfNotes(forCategory: category)
                    self.mAudioFileName = randomString(length: 10) + ".m4a"
                }
            }
            setupRecording()
        }
        catch {
            print(error.localizedDescription)
        }
        
    }
    
    
    
    //    MARK: loads note incase old note opened
    func showNoteOnLoad() {
        
        self.noteTitle.text = self.openedNote.mTitle
        //        show date after formatting
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = formatter.string(from: self.openedNote.mDate)
        self.dateLabel.text = date
        
        if let message = self.openedNote.mMessage {
            //            self.noteTextLabel.text = message
            self.noteText.text = message
        }
        if let image = self.openedNote.mImage {
            self.noteImage.image = image
        }
        if let lat = self.openedNote.mLat {
            self.latitude = lat
        }
        if let long = self.openedNote.mLong {
            self.longitude = long
        }
        
    }
    
    
    
    
    // MARK: Note saving methods
    //    checks nil title before saving
    func checkTitle(titleText: String?) -> Bool {
        if(titleText == nil || titleText!.count < 1) {
            let alert = UIAlertController(title: "Oops!", message: "Title can't be left blank", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return false
        }
        return true
    }
    
    
    //    saves note if previously saved
    func saveOldNote() {
        
        let title = self.noteTitle.text
        if(!checkTitle(titleText: title)) {
            return
        }
        else {
            //            let msg = self.noteTextLabel.text
            let newNote: Note = Note.getCopy(note: openedNote)
            let msg = self.noteText.text
            let img = self.noteImage.image
            newNote.mTitle = title!
            newNote.mMessage = msg
            newNote.mImage = img
            if let noteIndex = selectedNote {
                do {
                    try NotesHelper.getInstance().updateNote(oldNote: noteIndex, newNote: newNote, context: self.noteViewContext)
                    self.cancelButtonTapped(self)
                }
                catch {
                    print(error)
                    showSaveErrorAlert()
                }
            }
            self.stopLocationManager()
        }
        
    }
    
    //    saves if new note
    func saveNewNote() {
        print("in func")
        do {
            let title = self.noteTitle.text
            let date = Date()
            var category: String!
            if let categoryIndex = self.forCategory {
                category = try NotesHelper.getInstance().getCategory(at: categoryIndex)
            }
            if(!checkTitle(titleText: title)) {
                return
            }
            else {
                print("conditions checked")
                //                let msg = self.noteTextLabel.text
                let msg = self.noteText.text
                let img = self.noteImage.image
                var audiolocation: String?
                if mDidRecord
                {
                    audiolocation = mAudioFileName
                    print("audiolocation: \(audiolocation)")
                }
                
                self.openedNote = Note(title: title!, message: msg, lat: self.latitude, long: self.longitude, image: img, date: date, categoryName: category, audioFileLocation: audiolocation)
                
                try NotesHelper.getInstance().addNote(note: self.openedNote, context: self.noteViewContext)
                
                stopLocationManager()
                
                self.cancelButtonTapped(self)
            }
        }
        catch {
            print(error.localizedDescription)
            showSaveErrorAlert()
        }
        
    }
    
    //    shows error if note can't be saved
    func showSaveErrorAlert() {
        let alert = UIAlertController(title: "Error!", message: "Error while saving note. Please try again!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}


//MARK: delegate for audio recording
extension NoteViewController: AVAudioRecorderDelegate
{
    
    func setupRecording()
    {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        //                        self.loadRecordingUI()
                    } else {
                        print("not allowed")
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent(mAudioFileName)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
        } catch {
            finishRecording(success: false)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        
        if success {
            print("success")
            mDidRecord = true
            
        } else {
            print("not success")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
}


//MARK: delegate for audio playing
extension NoteViewController: AVAudioPlayerDelegate
{
    func playAudio()
    {
        dump(audioRecorder)
        var error : NSError?
        do
        {
            var url: URL
            if recordingIsAvailable
            {
                url = getDocumentsDirectory().appendingPathComponent(mAudioFileName)
                //                    url = URL.init(string: urlString)!
            }
            else
            {
                url = audioRecorder.url
            }
            print(url)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            if let err = error{
                print("audioPlayer error: \(err.localizedDescription)")
            }else{
                audioPlayer.play()
            }
            audioPlayer.delegate = self
        }
        catch
        {
            print(error)
            
        }
        
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer!, error: NSError!) {
        print("Audio Play Decode Error")
    }
    
    
}


// MARK: delegate methods to handle user lcoation
extension NoteViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if(forCategory != nil) {
            longitude = locations.last?.coordinate.longitude
            latitude = locations.last?.coordinate.latitude
        }
        
    }
    
    func startLocationManager() {
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        if(CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
    }
    
    func stopLocationManager() {
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
    }
}




// MARK: methods for handling image selection
extension NoteViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        noteImage.image = image
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated: true, completion: nil)
    }
}


extension NoteViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension NoteViewController {
    func dismissKey()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer( target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard()
    {
        noteTitle.resignFirstResponder()
        noteText.resignFirstResponder()
    }
}
