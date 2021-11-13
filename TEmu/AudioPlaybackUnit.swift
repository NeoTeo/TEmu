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
var converter: AVAudioConverter?

func playPCM(filePath: String) {
    guard FileManager.default.fileExists(atPath: filePath) else { print("Failed to find \(filePath)") ; return }
    let fileUrl = URL(fileURLWithPath: filePath)

    do {
        if try fileUrl.checkResourceIsReachable() == true { print("cool") }
        ///*
        let pcmdat = try Data(contentsOf: fileUrl)
//        for i in pcmdat.indices {
//            print(String(format: "%02x ", pcmdat[i]), terminator: "")
//            if (i+1) % 8 == 0 { print("") }
//        }
        guard let inFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 44100.0, channels: 2, interleaved: true) else { return }
        let frameCount = UInt32(pcmdat.count) / inFormat.streamDescription.pointee.mBytesPerFrame
        print("frameCount is \(frameCount)")
        
        // Use system format as output format
        let outFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        converter = AVAudioConverter(from: inFormat, to: outFormat)!
        let mixer = engine.mainMixerNode
        engine.attach(player)
        engine.connect(player, to: mixer, format: nil)

        // Prepare input and output buffer
        let inputBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: frameCount)!
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: frameCount)!
        
        inputBuffer.frameLength = inputBuffer.frameCapacity
        let auBuf = inputBuffer.audioBufferList.pointee.mBuffers
        pcmdat.withUnsafeBytes { (bufferPointer) in
            guard let addr = bufferPointer.baseAddress else { return }
            auBuf.mData?.copyMemory(from: addr, byteCount: Int(auBuf.mDataByteSize))
        }

        /*
        //let frameCount = UInt32(audioFile.length)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { print("playPCM failed to  create buffer") ; return }
        buf.frameLength = buf.frameCapacity
        let auBuf = buf.audioBufferList.pointee.mBuffers
        pcmdat.withUnsafeBytes { (bufferPointer) in
            guard let addr = bufferPointer.baseAddress else { return }
            auBuf.mData?.copyMemory(from: addr, byteCount: Int(auBuf.mDataByteSize))
        }
         */
        // */
        /*
        let audioFile = try AVAudioFile(forReading: fileUrl)
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)
        print("frameCount is \(frameCount)")
        print("format: \(format.formatDescription)")
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { print("playPCM failed to  create buffer") ; return }
        try audioFile.read(into: buf)
         */

        let status  = converter?.convert(to: outputBuffer, error: nil) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }
        print("converter status: \(String(describing: status?.rawValue))")
        
        player.scheduleBuffer(outputBuffer)
        /*
        player.scheduleBuffer(buf, completionHandler: nil)
         */
        engine.prepare()
        try engine.start()
        player.play()

    } catch {
        print("playPCM error \(error)")
    }
}
