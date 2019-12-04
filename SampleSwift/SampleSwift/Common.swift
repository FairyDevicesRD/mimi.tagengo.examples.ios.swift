//
//  Copyright © 2019 Fairy Devices, Inc. All rights reserved.
//

import AVFoundation
import SwiftUI

func toData(PCMBuffer: AVAudioPCMBuffer) -> Data {
    let channelCount = 1
    let channels = UnsafeBufferPointer(start: PCMBuffer.int16ChannelData, count: channelCount)
    let ch0data = Data(bytes: channels[0], count: Int(PCMBuffer.frameCapacity * PCMBuffer.format.streamDescription.pointee.mBytesPerFrame))
    return ch0data
}
