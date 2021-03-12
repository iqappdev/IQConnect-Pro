class LarixSettingsKeys {

    internal let camera_location_key  = "pref_camera"
    internal let camera_location_back = "back"
    
    internal let video_resolution_key = "pref_resolution"
    internal let video_resolution_hd = 720

    internal let camera_type_key  = "pref_device_type"
    internal let camera_type_default = "Auto"
    
    internal let multi_cam_key = "pref_multi_cam"

    internal let VideoResolutions: [Int:CMVideoDimensions] = [
        144: CMVideoDimensions(width: 192, height: 144),
        288: CMVideoDimensions(width: 352, height: 288),
        360: CMVideoDimensions(width: 480, height: 360),
        480: CMVideoDimensions(width: 640, height: 480),
        540: CMVideoDimensions(width: 960, height: 540),
        720: CMVideoDimensions(width: 1280, height: 720),
        1080: CMVideoDimensions(width: 1920, height: 1080),
        2160: CMVideoDimensions(width: 3840, height: 2160)
    ]
    
    internal let video_orientation_key       = "pref_orientation"
    internal let video_orientation_landscape = "landscape"
    internal let video_orientation_portrait  = "portrait"
    
    internal let video_bitrate_key  = "pref_video_bitrate"
    internal let video_bitrate_auto = 0
    
    internal let video_framerate_key = "pref_fps"
    internal let video_framerate_def = 30.0
    
    internal let video_keyframe_key = "pref_keyframe"
    internal let video_keyframe_def = 2 // 2 sec.
    
    internal let video_codec_type_key = "pref_video_codec_type"
    internal let video_codec_type_h264 = "h264"
    internal let video_codec_type_hevc = "hevc"
    
    internal let avc_profile_key = "pref_avc_profile"
    internal let hevc_profile_key = "pref_hevc_profile"    
    internal let baseline = "baseline"
    internal let main = "main"
    internal let high = "high"
    internal let main10 = "main10"
   
    internal let audio_channels_key  = "pref_channel_count"
    internal let audio_channels_mono = 1 // Mono
    
    internal let audio_bitrate_key = "pref_audio_bitrate"
    internal let audio_bitrate_auto = 0
    
    internal let audio_samplerate_key  = "pref_sample_rate"
    internal let audio_samplerate_auto = 0.0
    
    internal let radio_mode  = "pref_radio_mode"
    
    internal let record_stream_key = "pref_record_stream"
    
    internal let core_image_key = "pref_core_image"
    
    internal let live_rotation_key = "pref_live_rotation"
    internal let live_rotation_on  = "on"
    
    internal let session_port_key = "pref_session_port"
    internal let session_port_auto = "AudioSessionPortAutoSelect"
    internal let session_port_mic = "AudioSessionPortBuiltInMic"
    internal let session_port_headset = "AudioSessionPortHeadsetMic"
    internal let session_port_bt = "AudioSessionPortBluetoothHFP"
    
    internal let stabilization_mode_key = "pref_stabilization_mode"
    internal let stabilization_mode_off = "off"
    internal let stabilization_mode_standard = "standard"
    internal let stabilization_mode_cinematic = "cinematic"
    internal let stabilization_mode_auto = "auto"
    
    internal let abr_mode_key = "abr_mode"
    internal let abr_mode_off = 0
    
    internal let adaptive_fps_key = "adaptive_fps"
    
    internal let record_storage_key = "pref_record_storage"
    internal let record_duration_key = "pref_record_duration"
    internal let snapshot_format_key = "pref_snapshot_format"
    internal let photo_album_id = "pref_photo_album_id"

    internal let volume_keys_capture_key = "pref_volume_keys"

}
