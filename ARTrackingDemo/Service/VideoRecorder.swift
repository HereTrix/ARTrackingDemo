//
//  VideoRecorder.swift
//  ARTrackingDemo
//
//  Created by HereTrix on 6/2/20.
//

import AVFoundation

class VideoRecorder {
    
    static var hasRecordedVideo: Bool {
        return FileManager.default.fileExists(atPath: recordFileURL.path)
    }
    
    static var recordFileURL: URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(tmpFileName)
    }
    
    var errorCallback: ((Error)->Void)?
    private(set) var currentDuration: TimeInterval
    private(set) var isRecording: Bool = false
    
    private static let tmpFileName = "tmp.mp4"
    private let assetWriter: AVAssetWriter
    private var videoInput: AVAssetWriterInput
    private var pixelBufferInput: AVAssetWriterInputPixelBufferAdaptor
    private var videoOutputSettings: Dictionary<String, AnyObject>!
    private var audioSettings: [String: Any]?
    private var startingVideoTime: CMTime?
    
    init?(width: Int, height: Int) {
        do {
            assetWriter = try AVAssetWriter(outputURL: VideoRecorder.recordFileURL, fileType: AVFileType.mp4)
        } catch let error {
            debugPrint("Writer initialization failed: \(error)")
            return nil
        }
        
        currentDuration = 0
        
        videoOutputSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264 as AnyObject,
            AVVideoWidthKey: width as AnyObject,
            AVVideoHeightKey: height as AnyObject
        ]
        
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
        
        let transform = CGAffineTransform.identity
        videoInput.transform = transform.rotated(by: 0)

        videoInput.expectsMediaDataInRealTime = true
        pixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: nil)
        
        if assetWriter.canAdd(videoInput) {
            assetWriter.add(videoInput)
        } else {
            return nil
        }
    }
    
    func write(buffer: CVPixelBuffer, with time: CMTime) {
        switch assetWriter.status {
        case .unknown:
            startingVideoTime = time
            if assetWriter.startWriting() {
                assetWriter.startSession(atSourceTime: time)
                isRecording = true
                currentDuration = 0
            } else {
                if let error = assetWriter.error {
                    errorCallback?(error)
                }
                return
            }
        case .failed:
            if let error = assetWriter.error {
                errorCallback?(error)
            }
            return
        case .completed:
            return
        default:
            break
        }
        
        if videoInput.isReadyForMoreMediaData {
            if isRecording {
                append(pixel: buffer, with: time)
            }
        }

    }
    
    private func append(pixel buffer: CVPixelBuffer, with time: CMTime) {
        pixelBufferInput.append(buffer, withPresentationTime: time)
    }
    
    func end(writing finished: @escaping () -> Void) {
        if assetWriter.status == .writing {
            isRecording = false
            assetWriter.finishWriting(completionHandler: finished)
        }
    }
    
    class func clearTemp() {
        try? FileManager.default.removeItem(at: VideoRecorder.recordFileURL)
    }
}
