//
//  AudioPlaybackUnit.swift
//  TEmu
//
//  Created by teo on 09/11/2021.
//

import Foundation
import AudioToolbox
import AVFAudio

class AudioPlaybackUnit : NSObject {
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    var converter: AVAudioConverter?

    let wavHeaderBytes = 44
    
    func wavPCM(from rawPCM: Data) {
        // Wav header size is 44 (0x2C) bytes
        let bitsPerSample: Int       = 0x08
        let bitsPerChannel: Int      = 0x08
        let channelsPerFrame: Int    = 0x02
        let bytesPerFrame = bitsPerChannel * channelsPerFrame / 8
        
        var wav = Data(capacity: wavHeaderBytes)
        wav.insert(0x52, at: 0x00)    // R
        wav.insert(0x49, at: 0x01)    // I
        wav.insert(0x46, at: 0x02)    // F
        wav.insert(0x46, at: 0x03)    // F
        
        // total size
        var wavChunk = UInt32(rawPCM.count + 36) // 44 - 8 (the RIFF and the 4 bytes of the size)
        let tSize = Data(bytes: &wavChunk, count: MemoryLayout.size(ofValue: wavChunk))
        wav.append(tSize)
        
        // Wav format consists of two subchunks; fmt, which describes the data subchunk that follows it.
        wav.insert(0x57, at: 0x08)    // W
        wav.insert(0x41, at: 0x09)    // A
        wav.insert(0x56, at: 0x0A)    // V
        wav.insert(0x45, at: 0x0B)    // E
        
        // SUBCHUNK 1: id
        wav.insert(0x66, at: 0x0C)    // f
        wav.insert(0x6D, at: 0x0D)    // m
        wav.insert(0x74, at: 0x0E)    // t
        wav.insert(0x20, at: 0x0F)    //

        // size subchunk, 4 bytes NB. Not the bit-depth but the byte size of subchunk 1
        wav.insert(0x10, at: 0x10)    // PCM subchunk size is 16 bytes
        wav.insert(0x00, at: 0x11)    //
        wav.insert(0x00, at: 0x12)    //
        wav.insert(0x00, at: 0x13)    //

        // audio format, 2 bytes
        wav.insert(0x01, at: 0x14)    //    1 = linear quantization
        wav.insert(0x00, at: 0x15)    //
        
        // number of channels, 2 bytes
        wav.insert(UInt8(channelsPerFrame), at: 0x16)    //    2 = stereo
        wav.insert(0x00, at: 0x17)    //

        // sample rate, 4 bytes
        var sampleRate = UInt32(44100)
        let srData = Data(bytes: &sampleRate, count: MemoryLayout.size(ofValue: sampleRate))
        wav.append(srData)
        
        // byte rate, 4 bytes
        var byteRate = sampleRate * UInt32(bytesPerFrame)
        let brData = Data(bytes: &byteRate, count: MemoryLayout.size(ofValue: byteRate))
        wav.append(brData)
        
        // blockalign, 2 bytes
        var bAlign = UInt16(bytesPerFrame)
        let baData = Data(bytes: &bAlign, count: MemoryLayout.size(ofValue: bAlign))
        wav.append(baData)
        
        // bits per sample, 2 bytes from 0x22
        var bps = UInt16(bitsPerSample)
        let bpsData = Data(bytes: &bps, count: MemoryLayout.size(ofValue: bps))
        wav.append(bpsData)
        
        // SUBCHUNK 2: data, 4 bytes from 0x24
        wav.insert(0x64, at: 0x24)    // d
        wav.insert(0x61, at: 0x25)    // a
        wav.insert(0x74, at: 0x26)    // t
        wav.insert(0x61, at: 0x27)    // a

        // raw data size, 4 bytes
        var rawSize = UInt32(rawPCM.count)
        let rsData = Data(bytes: &rawSize, count: MemoryLayout.size(ofValue: rawSize))
        wav.append(rsData)
        
        // The raw sound data
        wav.append(rawPCM)
        
        for i in wav.indices {
            print(String(format: "%02x ", wav[i]), terminator: "")
            if (i+1) % 8 == 0 { print("") }
        }

    }

    func stop() {
//        player.volume = 0
        player.stop()
        
    }
        
    func playPCM(filePath: String) {
        guard FileManager.default.fileExists(atPath: filePath) else { print("Failed to find \(filePath)") ; return }
        let fileUrl = URL(fileURLWithPath: filePath)
//        testicle(fileUrl: fileUrl) ; return
        do {
            if try fileUrl.checkResourceIsReachable() == true { print("cool") }
            ///*
            let pcmdat = try Data(contentsOf: fileUrl)
            //wavPCM(from: pcmdat) ; return
    //        for i in pcmdat.indices {
    //            print(String(format: "%02x ", pcmdat[i]), terminator: "")
    //            if (i+1) % 8 == 0 { print("") }
    //        }
            // for all.wav
//            guard let tFormat = AVAudioFormat(settings: [AVLinearPCMBitDepthKey : 16, AVLinearPCMIsFloatKey: false, AVFormatIDKey : kAudioFormatLinearPCM, AVSampleRateKey : 44100.0, AVNumberOfChannelsKey : 2]) else

            guard let tFormat = AVAudioFormat(settings: [AVLinearPCMBitDepthKey : 8, AVLinearPCMIsFloatKey: false, AVFormatIDKey : kAudioFormatLinearPCM, AVSampleRateKey : 8000.0, AVNumberOfChannelsKey : 2]) else
//            guard let tFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.otherFormat, sampleRate: 8000, channels: 2, interleaved: true) else
            { print("format fail") ; return }
            var asbd : AudioStreamBasicDescription = tFormat.streamDescription.pointee
//            asbd.mFormatFlags = kLinearPCMFormatFlagIsPacked // kAudioFormatFlagIsPacked
            asbd.mBytesPerPacket = 2
            asbd.mBytesPerFrame = 2
            asbd.mBitsPerChannel = 8
            
            guard let inFormat = AVAudioFormat(streamDescription: &asbd) else { return }
    //        print("inFormat bytes per frame: \(inFormat.streamDescription.pointee.mBytesPerFrame)")
            print("inFormat stream description: \(inFormat.streamDescription.pointee)")
            print("inFormat stream format flags: \(inFormat.streamDescription.pointee.mFormatFlags)")
    //        guard let inFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 44100.0, channels: 2, interleaved: true) else { return }
//            let frameCount = UInt32(pcmdat.count) / inFormat.streamDescription.pointee.mBytesPerFrame
            let frameCount = UInt32(pcmdat.count - wavHeaderBytes) / inFormat.streamDescription.pointee.mBytesPerFrame // subtract header size when not raw pcm buffer
            print("inFormat bytes per frame: \(inFormat.streamDescription.pointee.mBytesPerFrame)")
            print("frameCount is \(frameCount)")
            
            // Use system format as output format
//            let outFormat = engine.mainMixerNode.outputFormat(forBus: 0)
            let outFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 44100.0, channels: 2, interleaved: false)!
            print("outFormat stream description: \(outFormat.streamDescription.pointee)")
            converter = AVAudioConverter(from: inFormat, to: outFormat)!
            let mixer = engine.mainMixerNode
            engine.attach(player)
            engine.connect(player, to: mixer, format: nil)
            engine.prepare()
            try engine.start()
            
            // Prepare input and output buffer
            print("outFrame bytes per frame: \(outFormat.formatDescription.audioStreamBasicDescription!.mBytesPerFrame)")
//            let outFrameCap = frameCount*outFormat.formatDescription.audioStreamBasicDescription!.mBytesPerFrame
            let ratio =  outFormat.sampleRate / inFormat.sampleRate
            let outFrameCap = UInt32(Double(frameCount) * ratio)
            print("outFrameCap is \(outFrameCap)")
            guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: frameCount) else { print("failed to create inputbuffer") ; return }
            let outputBuffer = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: outFrameCap)!
            inputBuffer.frameLength = inputBuffer.frameCapacity
            
            print("input buffer format \(inputBuffer.format)")
            print("output buffer format \(outputBuffer.format)")

            // Fill the input buffer with the data from the pcmdat
            let auBuf = inputBuffer.audioBufferList.pointee.mBuffers
            print("copying \(auBuf.mDataByteSize) bytes")
            pcmdat.withUnsafeBytes { (bufferPointer) in
                guard let addr = bufferPointer.baseAddress else { return }
                auBuf.mData?.copyMemory(from: addr+wavHeaderBytes, byteCount: Int(auBuf.mDataByteSize))
            }
            /*
            // what are Taps and will they be useful for envelope stuff? https://stackoverflow.com/questions/48831411/converting-avaudiopcmbuffer-to-another-avaudiopcmbuffer
            
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
//            let tdat = Data(bytes: auBuf.mData!, count: Int(auBuf.mDataByteSize))
//            for i in tdat.indices {
//                print(String(format: "%02x ", tdat[i]), terminator: "")
//                if (i+1) % 8 == 0 { print("") }
//            }

            let status  = converter?.convert(to: outputBuffer, error: nil) { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }
            print("converter status: \(String(describing: status?.rawValue))")
            
//            player.scheduleBuffer(outputBuffer) {  ()->Void in
            player.scheduleBuffer(outputBuffer, completionCallbackType: .dataPlayedBack) {_ in
                
                print("scheduleBuffer callback")
            }
            self.player.play()
        } catch {
            print("playPCM error \(error)")
        }
    }
    func testicle(fileUrl: URL) {
        
        do {
        let audioFile = try AVAudioFile(forReading: fileUrl)
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)
        print("frameCount is \(frameCount)")
        print("format: \(format.formatDescription)")
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { print("playPCM failed to  create buffer") ; return }
        try audioFile.read(into: buf)
        } catch {
            print("testicle error! \(error)")
        }
    }

}
