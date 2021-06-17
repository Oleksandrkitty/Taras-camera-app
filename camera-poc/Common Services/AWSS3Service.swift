//
//  AWSS3Service.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 17.06.2021.
//


import Foundation
import AWSS3

typealias progressBlock = (_ progress: Double) -> Void
typealias completionBlock = (_ response: Any?, _ error: Error?) -> Void
typealias CompletionHandler = (_ success:Bool) -> Void

class AWSS3Service {
    private let bucketName = "camera-poc"
    static let shared = AWSS3Service()
    private init () {}
    
    func uploadFileFromURL(_ fileUrl: URL, conentType: String, progress: progressBlock?, completion: completionBlock?) {
        let fileName = fileUrl.lastPathComponent
        self.uploadfile(fileUrl: fileUrl, fileName: fileName, contenType: conentType, progress: progress, completion: completion)
    }
    
    //MARK:- AWS file upload
    // fileUrl : file local path url
    // fileName : name of file, like “SampleVImage.jpg” “SampleVideoClip.mp4”
    // contenType: file MIME type
    // progress: file upload progress, value from 0 to 1, 1 for 100% complete
    // completion: completion block when uplaoding is finish, we will get S3 url of upload file here
    private func uploadfile(fileUrl: URL, fileName: String, contenType: String, progress: progressBlock?, completion: completionBlock?) {
        // Upload progress block
        let expression = AWSS3TransferUtilityUploadExpression()
        //Mark ACL as public
        // expression.setValue(“public-read”, forRequestParameter: “x-amz-acl”)
        // expression.setValue(“public-read”, forRequestHeader: “x-amz-acl”)
        expression.progressBlock = {(task, awsProgress) in
            guard let uploadProgress = progress else { return }
            DispatchQueue.main.async {
                uploadProgress(awsProgress.fractionCompleted)
            }
        }
        // Completion block
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if error == nil {
                    let url = AWSS3.default().configuration.endpoint.url
                    let publicURL = url?.appendingPathComponent(self.bucketName).appendingPathComponent(fileName)
                    // print(“Uploaded to:\(String(describing: publicURL))”)
                    if let completionBlock = completion {
                        completionBlock(publicURL?.absoluteString, nil)
                    }
                } else {
                    if let completionBlock = completion {
                        completionBlock(nil, error)
                    }
                }
            })
        }
        // Start uploading using AWSS3TransferUtility
        let awsTransferUtility = AWSS3TransferUtility.default()
        let identifier = UIDevice.current.identifierForVendor?.uuidString ?? "undefined_iphone"
        let path = "\(UIDevice.modelName)/\(identifier)/\(fileName)"
        awsTransferUtility.uploadFile(fileUrl, bucket: bucketName, key: path, contentType: contenType, expression: expression, completionHandler: completionHandler).continueWith { (task) -> Any? in
            if let error = task.error {
                print("error is: \(error.localizedDescription)")
            }
            if let _ = task.result {
                // your uploadTask
                // print(“result is: \(result)”)
            }
            return nil
        }
    }
}
