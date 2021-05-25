//
//  ViewController.swift
//  FoodaSearch
//
//  Created by Setu Desai on 4/13/21.
//

import UIKit
import FoursquareAPIClient
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate{
    
    //MARK:- IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    //@IBOutlet weak var collectionview: UICollectionView!
    
    //MARK:- Declaring Variables
    let locationManager = CLLocationManager()
    let annotation = MKPointAnnotation()
    var dictSend: [[Double]] = [[]]
    var startLocation: CLLocation!
    //var arrLoc:[[String]] = []
    var a = 0
    var flag = false
    
    //MARK:- View Life cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.allowsBackgroundLocationUpdates = true
        mapView.delegate = self
        locationManager.delegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    //MARK: - Delegate methods for MapKit and CollectionView
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let annotations = mapView?.annotations {
            for annotation in annotations {
                if let annotation = annotation as? MKAnnotation
                {
                    self.mapView.removeAnnotation(annotation)
                }
            }
        }
        //arrLoc = []
        if let location = locations.first {
            let loc = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            loc.fetchCityAndCountry { city, country, error in
                guard let city = city, let country = country, error == nil else { return }
                let near = city + ", " + country
                self.setUpFoursquare(near: near)
            }
            let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            self.mapView.setRegion(region, animated: true)
            //mapView.reloadInputViews()
        }
    }
    
    //MARK:- Funtion
    func getDirections(enterdLocations:[String], name: [String], formattedAddress: [String])  {
        var locations = [MKPointAnnotation]()
        for i in 0..<enterdLocations.count {
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(enterdLocations[i], completionHandler: {(placemarks, error) -> Void in
                if error != nil {
                    print(error)
                }
                if let placemark = placemarks?.first {
                    let coordinates:CLLocationCoordinate2D = placemark.location!.coordinate
                    let dropPin = MKPointAnnotation()
                    dropPin.coordinate = coordinates
                    dropPin.title = "\(name[i])"
                    dropPin.subtitle = "\(formattedAddress[i])"
                    self.mapView.addAnnotation(dropPin)
                    self.mapView.selectAnnotation(dropPin, animated: true)
                    self.mapView.showAnnotations(self.mapView.annotations, animated: false)
                    locations.append(dropPin)
                }
            })
        }
        //        if(flag) {
        //            self.collectionview.reloadData()
        //        }
    }
    
    //MARK:- Get API Function
    func setUpFoursquare(near: String){
        let client = FoursquareAPIClient(clientId: "WQYKKM1H5GIJB3FROHNVAB24NB10II5UPTKBQ1EOUV0THSSL", clientSecret: "FZFIQFXZ4HETXOLBXEJIUDEA0AO2THTEUSHB13PIIMJK3QBR")
        
        let parameter: [String: String] = [
            "near" : near,//destination!,
            "categoryId":"4bf58dd8d48988d1e0931735"
        ];
        client.request(path: "venues/search", parameter: parameter) { [self] result in
            locationManager.startMonitoringSignificantLocationChanges()
            switch result {
            case let .success(data):
                let json = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let dict = json?["response"] as? [String: Any] ?? [:]
                let venue = dict["venues"] as? [Any] ?? []
                var arr:[String] = []
                var nameArr:[String] = []
                var nameFormattedArr:[String] = []
                for k in 0..<venue.count {
                    let extra = venue[k] as? [String:Any] ?? [:]
                    let location = extra["location"] as? [String:Any] ?? [:]
                    let formattedAddress = location["formattedAddress"] as? [String] ?? []
                    nameFormattedArr.append(formattedAddress.joined(separator: ""))
                    let categories = extra["categories"] as? [Any] ?? []
                    let name = categories[0] as? [String:Any] ?? [:]
                    let nameFinal = name["name"] as? String ?? ""
                    nameArr.append(nameFinal)
                    let addressCoffee = "\(location["address"] ?? "")"
                    let stateCoffee = "\(location["state"] ?? "")"
                    let countryCoffee = "\(location["country"] ?? "")"
                    let postalCode = "\(location["postalCode"] ?? "")"
//                    var arrLos: [String] = []
//                    arrLos.append(nameFinal)
//                    arrLos.append(formattedAddress.joined())
//                    self.arrLoc.append(arrLos)
                    let showAddress = addressCoffee + ", " + stateCoffee + ", " + countryCoffee + " " + postalCode
                    arr.append(showAddress)
                }
                //                if(flag == false) {
                //                    self.collectionview.reloadData()
                //                    flag = true
                //                }
                self.getDirections(enterdLocations: arr, name: nameArr, formattedAddress: nameFormattedArr)
                
            case let .failure(error):
                // Error handling
                switch error {
                case let .connectionError(connectionError):
                    print(connectionError)
                case let .responseParseError(responseParseError):
                    print(responseParseError)   // e.g. JSON text did not start with array or object and option to allow fragments not set.
                case let .apiError(apiError):
                    print(apiError.errorType)   // e.g. endpoint_error
                    print(apiError.errorDetail) // e.g. The requested path does not exist.
                }
            }
        }
    }
}

//MARK:- Extension
extension CLLocation {
    func fetchCityAndCountry(completion: @escaping (_ city: String?, _ country:  String?, _ error: Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(self) { completion($0?.first?.locality, $0?.first?.administrativeArea, $1) }
    }
}


//MARK:- Extra View Code Function and Delegate Methods
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return arrLoc.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionview.dequeueReusableCell(withReuseIdentifier: "ListCollectionViewCell", for: indexPath) as! ListCollectionViewCell
//        cell.lblTitle.text = arrLoc[indexPath.row][0]
//        cell.lblDetails.text = arrLoc[indexPath.row][1]
//        cell.imgIcon.image = UIImage(named: "images")
//        cell.listView.layer.cornerRadius = 20
//        cell.listView.backgroundColor = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1)
//        cell.listView.layer.shadowOpacity = 1
//        cell.listView.layer.shadowRadius = 5
//        cell.listView.layer.shadowOffset = CGSize(width: 0, height: 0)
//        cell.listView.layer.shadowColor = UIColor.black.cgColor
//        cell.listView.layer.masksToBounds = true
//        return cell
//    }
//    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//        a = 0
//        let location = view.annotation!
//        for item in arrLoc {
//            if item[0] == location.title! && item[1] == location.subtitle! {
//                collectionview.scrollToItem(at: IndexPath(item: a, section: 0), at: .centeredHorizontally, animated: true)
//                break
//            }
//            a += 1
//        }
//    }



//MARK:- Extraneous Code if the location request exceeds by maps. Put delay seconds for more than 3 seconds for better results
//DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(seconds))
