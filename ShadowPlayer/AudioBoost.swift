import AVFoundation
import Accelerate

/// Boosts playback loudness beyond the normal 1.0 ceiling.
///
/// iOS caps `AVPlayer.volume` at 1.0 (relative to the system volume), so to go
/// louder we multiply the decoded audio samples via an `MTAudioProcessingTap`.
enum AudioBoost {
    /// Linear gain applied to every sample. 1.0 = unchanged; ~1.8 ≈ +5 dB.
    /// Raising this further increases loudness but risks clipping/distortion.
    static let gain: Float = 1.8

    /// Builds an audio mix that amplifies the given audio track, or nil on failure.
    static func makeAudioMix(track: AVAssetTrack) -> AVAudioMix? {
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: nil,
            init: tapInit,
            finalize: tapFinalize,
            prepare: nil,
            unprepare: nil,
            process: tapProcess
        )

        var tap: MTAudioProcessingTap?
        let status = MTAudioProcessingTapCreate(
            kCFAllocatorDefault,
            &callbacks,
            kMTAudioProcessingTapCreationFlag_PostEffects,
            &tap
        )
        guard status == noErr, let tap else { return nil }

        let params = AVMutableAudioMixInputParameters(track: track)
        params.audioTapProcessor = tap

        let mix = AVMutableAudioMix()
        mix.inputParameters = [params]
        return mix
    }
}

// MARK: - Tap callbacks (C function pointers; gain is kept in tap storage)

private let tapInit: MTAudioProcessingTapInitCallback = { _, _, tapStorageOut in
    let storage = UnsafeMutablePointer<Float>.allocate(capacity: 1)
    storage.pointee = AudioBoost.gain
    tapStorageOut.pointee = UnsafeMutableRawPointer(storage)
}

private let tapFinalize: MTAudioProcessingTapFinalizeCallback = { tap in
    MTAudioProcessingTapGetStorage(tap).assumingMemoryBound(to: Float.self).deallocate()
}

private let tapProcess: MTAudioProcessingTapProcessCallback = {
    tap, numberFrames, _, bufferListInOut, numberFramesOut, flagsOut in

    let status = MTAudioProcessingTapGetSourceAudio(
        tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut
    )
    guard status == noErr else { return }

    var gain = MTAudioProcessingTapGetStorage(tap).assumingMemoryBound(to: Float.self).pointee
    for buffer in UnsafeMutableAudioBufferListPointer(bufferListInOut) {
        guard let data = buffer.mData else { continue }
        let count = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
        let samples = data.assumingMemoryBound(to: Float.self)
        vDSP_vsmul(samples, 1, &gain, samples, 1, vDSP_Length(count))
    }
}
