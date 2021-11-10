//
//  AudioPlaybackUnit.swift
//  TEmu
//
//  Created by teo on 09/11/2021.
//

import Foundation
import AudioToolbox
import AVFAudio

let engine = AVAudioEngine()
let player = AVAudioPlayerNode()

func playPCM(filePath: String) {
    guard FileManager.default.fileExists(atPath: filePath) else { print("Failed to find \(filePath)") ; return }
    let fileUrl = URL(fileURLWithPath: filePath)
    let mixer = engine.mainMixerNode

    do {
        if try fileUrl.checkResourceIsReachable() == true { print("cool") }
        let pcm8bit = try Data(contentsOf: fileUrl)
        for i in pcm8bit.indices {
            print(String(format: "%02x ", pcm8bit[i]), terminator: "")
            if (i+1) % 8 == 0 { print("") }
        }

        guard let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 44100.0, channels: 2, interleaved: false)
//        guard let format  = AVAudioFormat(settings: [
//            AVLinearPCMBitDepthKey : 16,
//            AVLinearPCMIsBigEndianKey : false,
//            AVFormatIDKey : kAudioFormatLinearPCM,
//            AVLinearPCMIsFloatKey : false,
//            AVSampleRateKey : 44100.0,
//            AVNumberOfChannelsKey : 1
//        ])
        else { print("playPCM Failed to format audio") ; return }
        print("framecount \(pcm8bit.count)")
        
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(pcm8bit.count<<1)) else { print("playPCM failed to  create buffer") ; return }
        
        
        engine.attach(player)
        
        engine.connect(player, to: mixer, format: buf.format)
        /*
        engine.prepare()
        
        do {
            try engine.start()
        } catch {
            print("Error info: \(error)")
        }
        player.play()

        player.scheduleBuffer(buf, completionHandler: nil)
 */
    } catch {
        print("playPCM error \(error)")
    }
}
