//
//  ViewController.swift
//  GoodTasteProject
//
//  Created by Sena Uzun on 13.09.2022.
//

import UIKit
import MapKit
import CoreLocation // kullanıcıdan lokasyon alma kütüphanesi
import CoreData

class ViewController: UIViewController , MKMapViewDelegate, CLLocationManagerDelegate{

    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager() // Location manager olustur
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    
    
    var annotationTitle=""
    var annotationSubTitle=""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        //Gesture Recognizer - PIN
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.save, target: self, action: #selector(saveButtonClicked))
        
        if selectedTitle != "" {
            //get data
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            fetchReq.predicate = NSPredicate(format: "id = %@", idString) //id stringine eşit olanı cağır
            fetchReq.returnsObjectsAsFaults = false
            
            
            do{
                let result = try context.fetch(fetchReq)

                if result.count>0{
                    for result in result as! [NSManagedObject]{
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubTitle = subtitle
                                
                               
                            }
                            if let latitude = result.value(forKey: "latitude") as? Double {
                                annotationLatitude = latitude
                            }
                            if let longitude = result.value(forKey: "longitude") as? Double{
                                annotationLongitude = longitude
                                
                                
                                
                                
                                let annotation = MKPointAnnotation()
                                annotation.title = annotationTitle
                                annotation.subtitle = annotationSubTitle
                                
                                //coordinat vermek gerek
                                let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                annotation.coordinate = coordinate
                                
                                mapView.addAnnotation(annotation)
                                nameText.text = annotationTitle
                                commentText.text=annotationSubTitle
                                
                                
                                
                                locationManager.stopUpdatingLocation() // haritayı degiştirmemek için
                                
                                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                let region = MKCoordinateRegion(center: coordinate, span:span)
                                
                                mapView.setRegion(region, animated: true)
                            }
                        }
                      
                    }
                }
            }catch{
                print("error")
            }
                        
        }else {
            //Add new data
        }
        
    }
    
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer){
        
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint , toCoordinateFrom: self.mapView)
         
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            //pin
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedTitle == "" {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) //zoomlanacak alan
        let region = MKCoordinateRegion(center: location, span : span)
        mapView.setRegion(region, animated: true)
        } else{
            //
        }
        
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil //bunu pin ile göstermiyoruz
        }
        
        
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
            
        }else{
            pinView?.annotation=annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if selectedTitle != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks,error )in
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle//closure içinde self ile kullanılır
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }

            }
            
        }
    }

    @objc func saveButtonClicked() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")

        
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")

        
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("saved")
        }catch{
            print("Error")
        }
        NotificationCenter.default.post(name: NSNotification.Name("newPlaces"), object: nil)
        navigationController?.popViewController(animated: true) // önceki viewcontrollera gidiyoruz
        
        
    }
    
}

