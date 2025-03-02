# Remove these lines
TARGET_MEDIA_C2_INCLUDES := \
    $(TOP)/out/soong/.intermediates/hardware/interfaces/media/omx/1.0/android.hardware.media.omx@1.0_genc++_headers/gen

SOONG_ADDITIONAL_INCLUDES += $(TARGET_MEDIA_C2_INCLUDES) 

# Sensors
TARGET_USES_QCOM_SENSORS_HAL := true
USE_SENSOR_MULTI_HAL := true

# Include vendor override configuration
# This handles modules that should be taken from vendor prebuilts instead of being built from source
include device/sony/sm8650-common/vendor_override.mk

