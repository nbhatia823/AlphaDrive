// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from museinfo.djinni

#import <Foundation/Foundation.h>

/**
 * \if IOS_ONLY
 * \file
 * \endif
 * Notch Frequencies refer to the possible power line frequencies in a
 * geographic area that may create noise in raw EEG data.
 *
 * %Muse 2014 (
 * \if ANDROID_ONLY
 * \link com.choosemuse.libmuse.MuseModel.MU_01 MU_01\endlink
 * \elseif IOS_ONLY
 * \link ::IXNMuseModel::IXNMuseModelMu01 MU_01\endlink
 * \endif
 * ) headbands are equipped with a hardware filter to remove this noise
 * in certain preset configurations.
 *
 * For %Muse 2016 (
 * \if ANDROID_ONLY
 * \link com.choosemuse.libmuse.MuseModel.MU_02 MU_02\endlink
 * \elseif IOS_ONLY
 * \link ::IXNMuseModel::IXNMuseModelMu02 MU_02\endlink
 * \endif
 * ) headbands or %Muse 2014 (
 * \if ANDROID_ONLY
 * \link com.choosemuse.libmuse.MuseModel.MU_01 MU_01\endlink
 * \elseif IOS_ONLY
 * \link ::IXNMuseModel::IXNMuseModelMu01 MU_01\endlink
 * \endif
 * ) headbands using a research preset there is no hardware
 * filtering.
 *
 * \sa
 * \if ANDROID_ONLY
 * \li MusePreset
 * \elseif IOS_ONLY
 * \li IXNMusePreset
 * \endif
 * \li http://en.wikipedia.org/wiki/Utility_frequency
 */
typedef NS_ENUM(NSInteger, IXNNotchFrequency)
{
    /** The notch filter is not available on some hardware versions. */
    IXNNotchFrequencyNotchNone,
    /**
     * 50 Hz frequency is used in most parts of the world:
     * Europe, Russia, Africa
     */
    IXNNotchFrequencyNotch50hz,
    /**
     * 60 Hz frequency is used in North America and Asia.
     * This is the default setting.
     */
    IXNNotchFrequencyNotch60hz,
};