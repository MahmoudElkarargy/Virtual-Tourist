//
//  Client.swift
//  Virtual Tourist
//
//  Created by Mahmoud Elkarargy on 5/4/20.
//  Copyright © 2020 Mahmoud Elkarargy. All rights reserved.
//


// MARK: Setting all requests to the Flickr API.

import Foundation

class FlickrClient{
    
    // MARK: EndPoints.
    enum EndPoints{
        
        static let key = "446cd218ea26fd83ea868f73085551f9"
        static let base = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=" + "\(key)"
                
        case searchImages(lat: Double, lon: Double, page: Int)
        case loadImage(farmID: String, serverID: String, secret: String, id: Int)
        
        var stringValue: String{
            switch self {
            case .searchImages(let lat, let lon, let page):
                return EndPoints.base + "&media=photos&lat=\(lat)"
                + "&lon=\(lon)" + "&radius=15&per_page=18&page=\(page)" +
                "&format=json&nojsoncallback=1"
                
            case .loadImage(let farmID, let serverID, let secret, let id):
                return " https://farm\(farmID)" + ".staticflickr.com/\(serverID)/\(id)"
                    + "_\(secret).jpg"
            }
        }
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    
    
    //MARK: Search Image Request
    class func getPhotosSearchResult(lat:Double,lon:Double, page: Int ,completionHandler: @escaping (ImagesSearchResponse?, Error?) -> Void){
        
        let task = URLSession.shared.dataTask(with: EndPoints.searchImages(lat: lat, lon: lon, page: page).url) { data, response, error in
            guard let data = data else {
                completionHandler(nil, error)
                return
            }
            do {
                let decoder = JSONDecoder()
                let responseObject = try decoder.decode(ImagesSearchResponse.self, from: data)
                print(String(data: data, encoding: .utf8)!)
                DispatchQueue.main.async {
                        completionHandler(responseObject, nil)
                    }
                } catch {
                   DispatchQueue.main.async {
                        completionHandler(nil, error)
                    }
                }
            }
            task.resume()
    }
    
//    class func loadImage(photoData: Photo, image: Image, completion: @escaping (Image, Data?, Error?)->Void){
//        let request = URLRequest(url: Endpoints.loadImage(
//            ["Server": photoData.server ,
//             "ID": photoData.id,
//             "Secret": photoData.secret]
//            , photoData.farm).url)
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//
//            guard error == nil, data != nil else{
//                 completion(image, nil, error)
//                return
//            }
//
//            completion(image, data, nil)
//        }
//
//        task.resume()
//    }
    
}