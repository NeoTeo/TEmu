//
//  File.swift
//  OscSound
//
//  Created by teo on 20/05/2020.
//  Copyright © 2020 teos. All rights reserved.
//

import Foundation
import AudioUnit
import AVFoundation

final class ToneOutputUnit: NSObject {
    var auAudioUnit: AUAudioUnit!       /// Placeholder for Audio Unit
    var avActive        = false         /// AVAudioSession active flag
    var audioRunning    = false         /// Audio Unit running flag
    
    var sampleRate: Double = 44100.0    /// Typical audio sample rate
    
    var f0 = 880.0      /// Default frequency of tone: 'A' above concert A
    var v0 = 16383.0    /// Default volume of tone: Half of full scale
    
    var toneCount: Int32 = 0 /// Number of samples of tone to play. 0 for silence.
    
    private var phY = 0.0 /// Save phase of sine wave to prevent clicking
    private var interrupted = false /// For restart from audio interruption notification
    
    func setFrequency(freq: Double) {
        f0 = freq
    }
    
    func setToneVolume(vol: Double) {
        v0 = vol * 32766.0
    }
    
    func setToneTime(t: Double) {
        toneCount = Int32(t * sampleRate)
    }
    
    func enableSpeaker() {
        
        guard audioRunning == false else { return }
        /// Start audio hardware
        do {
            // MARK: the component type differs from example
            let audioComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_Output,
                                                                      componentSubType: kAudioUnitSubType_DefaultOutput,
                                                                      componentManufacturer: kAudioUnitManufacturer_Apple,
                                                                      componentFlags: 0,
                                                                      componentFlagsMask: 0)
            if auAudioUnit == nil {
                try auAudioUnit = AUAudioUnit(componentDescription: audioComponentDescription)
                
                let bus0 = auAudioUnit.inputBusses[0]
                let audioFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16,
                                                sampleRate: sampleRate,
                                                channels: AVAudioChannelCount(2),
                                                interleaved: true)
                
                try bus0.setFormat(audioFormat ?? AVAudioFormat())

                
                self.auAudioUnit.outputProvider = { (actionFlags, timestamp, frameCount, inputBusNumber, inputDataList) -> AUAudioUnitStatus in
                    self.fillSpeakerBuffer(inputDataList: inputDataList, frameCount: frameCount)
                    return 0
                }
            }
            
            auAudioUnit.isOutputEnabled = true
            toneCount = 0
            
            try auAudioUnit.allocateRenderResources() /// v2 AudioUnitInitialize
            try auAudioUnit.startHardware() /// v2 AudioOutputUnitStart
            audioRunning = true
            
        } catch {
            print("hardware init error: \(error)")
        }
    }
    
    // process buffer for output
     private func fillSpeakerBuffer(inputDataList : UnsafeMutablePointer<AudioBufferList>, frameCount : UInt32 ) {
        
            let inputDataPtr = UnsafeMutableAudioBufferListPointer(inputDataList)
            let nBuffers = inputDataPtr.count
            let tau = Double.pi * 2.0
        
            if (nBuffers > 0) {

                let mBuffers : AudioBuffer = inputDataPtr[0]
                let count = Int(frameCount)

                // Speaker Output == play tone at frequency f0
                if (   self.v0 > 0)
                    && (self.toneCount > 0 )
                {
                    // Volume of sound corresponds to amplitude of sine wave (or radius of circle)
                    let amplitude  = self.v0.truncatingRemainder(dividingBy: 32767)
                    let half_sz = Int(mBuffers.mDataByteSize) / 2

                    var angle  = self.phY        // restore angle from previous call
                    let delta  = tau * self.f0 / self.sampleRate     // phase delta

                    let bufferPointer = UnsafeMutableRawPointer(mBuffers.mData)
                    if var bptr = bufferPointer {
                        for i in 0 ..< count {
                            
                            let u  = sin(angle)             // create a unit sine at angle
                            let x = Int16(amplitude * u + 0.5)      // scale & round
                            
                            angle = (angle + delta).truncatingRemainder(dividingBy: tau) // increment angle and truncate

                            if i < half_sz {
                                bptr.assumingMemoryBound(to: Int16.self).pointee = x
                                bptr += 2   // increment by 2 bytes for next Int16 item
                                bptr.assumingMemoryBound(to: Int16.self).pointee = x
                                bptr += 2   // stereo, so fill both Left & Right channels
                            }
                        }
                    }

                    self.phY        =   angle                   // save sinewave phase
                    self.toneCount  -=  Int32(frameCount)   // decrement time remaining
                } else {
                    // audioStalled = true
                    memset(mBuffers.mData, 0, Int(mBuffers.mDataByteSize))  // silence
                }
            }
        }

        func stop() {
            if (audioRunning) {
                auAudioUnit.stopHardware()
                audioRunning = false
            }
        }
}
