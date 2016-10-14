//
//  PhotoAlbumUtility.swift
//  WatermarkMusicVideo
//
//  Created by Teck Liew on 10/6/16.
//  Copyright © 2016 Teck Liew. All rights reserved.
//
//
//  Saving image to custom album (사진첩 추가하여 사진저장 하기) @@ in Swift2.x - Xcode 7.1 iOS 9.1
//  Source: http://swifteyes.blogspot.com/2016/01/saving-image-to-custom-album-in-swift20.html

import UIKit
import Photos

enum PhotoAlbumUtilResult {
    case SUCCESS, ERROR, DENIED
}

class PhotoAlbumUtility: NSObject {
    //save video to custom album
    class func saveImageInAlbum(videoURL: NSURL, albumName: String, completion: ((result: PhotoAlbumUtilResult) -> ())?) {
        
        // create folder
        var eventAlbum: PHAssetCollection?
        let albumName = albumName
        let albums = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.Any, options: nil)
        albums.enumerateObjectsUsingBlock { (album, index, stop) in
            if album.localizedTitle == albumName {
                eventAlbum = album as? PHAssetCollection
                stop.memory = true
            }
        }
        
        // if the album does not exist
        if  let album = eventAlbum {
            completion?(result: .DENIED)
        }else{
            //eventAlbum == nil 경우 폴더 생성
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(albumName)
                }, completionHandler: { (succeeded, error) -> Void in
                    
                    if succeeded {
                        //save  image to the created album
                        self.saveImageInAlbum(videoURL, albumName: albumName, completion: completion)
                        
                        
                    } else {
                        // error
                        completion?(result: .ERROR)
                    }
            })
        }
        
        // if album is already created then to store image
        if let albumdex = eventAlbum {
            
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let result = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(videoURL)
                let assetPlaceholder = result!.placeholderForCreatedAsset
                let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: albumdex)
                let enumeration: NSArray = [assetPlaceholder!]
                albumChangeRequest!.addAssets(enumeration)
                
                }, completionHandler: { (succeeded, error) -> Void in
                    if succeeded {
                        completion?(result: .SUCCESS)
                    } else{
                        print(error!.localizedDescription)
                        completion?(result: .ERROR)
                    }
            })
        }
        
    }

}
