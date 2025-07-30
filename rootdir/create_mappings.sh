#!/system/bin/sh

touch /tmp/script_started
echo "Attempting to start mapping"

touch /tmp/mapping_log
echo "Starting dynamic partition mapping" >> /tmp/mapping_log

# (After PATH export, add:)
WAIT_COUNT=0
while [ ! -f /tmp/copy_done ] && [ $WAIT_COUNT -lt 30 ]; do
    echo "Waiting for copy completion... ($WAIT_COUNT/30)" >> /tmp/mapping_log
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done
if [ ! -f /tmp/copy_done ]; then
    echo "ERROR: Copy timeout" >> /tmp/mapping_log
    exit 1
fi
# Then super wait and mapping

# Wait for super device (up to 30s)
for i in $(seq 1 30); do
  if [ -b /dev/block/by-name/super ]; then
    echo "Super device ready after $i seconds" >> /tmp/mapping_log
    break
  fi
  sleep 1
  echo "Waiting for super ($i/30)" >> /tmp/mapping_log
done

if [ ! -b /dev/block/by-name/super ]; then
  echo "Error: super timeout" >> /tmp/mapping_log
else
  ls /dev/block/by-name/super >> /tmp/mapping_log 2>&1
  echo "Super found, running lptodm" >> /tmp/mapping_log
  /system/bin/lptodm /dev/block/by-name/super | /system/bin/dmctl >> /tmp/mapping_log 2>&1
fi

# After dmctl if block, add:
if [ ! -d /dev/block/mapper ]; then
  echo "dmctl failed, trying lpmake alternative" >> /tmp/mapping_log
  /system/bin/lpmake --metadata-size 65536 --super-name super --metadata-slots 2 --device super:10737418240 --group main:8589934592 --partition system_a:readonly:0:main --image system_a=/dev/block/by-name/system_a --partition vendor_a:readonly:0:main --image vendor_a=/dev/block/by-name/vendor_a # Add other partitions as needed
fi

# After super ready check:
echo "Creating manual dm-linear mappings" >> /tmp/mapping_log
SUPER_DEV="/dev/block/by-name/super"
CURRENT_SLOT="$(getprop ro.boot.slot_suffix)"

# Clear any placeholder sizes and replace with actual values based on image sizes
# Partition order: system system_ext product vendor odm system_dlkm vendor_dlkm
# Sizes in bytes:
SYSTEM_SIZE=911978496
SYSTEM_EXT_SIZE=843628544
PRODUCT_SIZE=526434304
VENDOR_SIZE=279220224
ODM_SIZE=950272
SYSTEM_DLKM_SIZE=12578816
VENDOR_DLKM_SIZE=70070272

# Convert to sectors (512 bytes per sector)
SECTOR_SIZE=512
SYSTEM_SECTORS=$(expr $SYSTEM_SIZE / $SECTOR_SIZE)
SYSTEM_EXT_SECTORS=$(expr $SYSTEM_EXT_SIZE / $SECTOR_SIZE)
PRODUCT_SECTORS=$(expr $PRODUCT_SIZE / $SECTOR_SIZE)
VENDOR_SECTORS=$(expr $VENDOR_SIZE / $SECTOR_SIZE)
ODM_SECTORS=$(expr $ODM_SIZE / $SECTOR_SIZE)
SYSTEM_DLKM_SECTORS=$(expr $SYSTEM_DLKM_SIZE / $SECTOR_SIZE)
VENDOR_DLKM_SECTORS=$(expr $VENDOR_DLKM_SIZE / $SECTOR_SIZE)

# Cumulative offsets in sectors
SYSTEM_OFFSET=0
SYSTEM_EXT_OFFSET=$(expr $SYSTEM_OFFSET + $SYSTEM_SECTORS)
PRODUCT_OFFSET=$(expr $SYSTEM_EXT_OFFSET + $SYSTEM_EXT_SECTORS)
VENDOR_OFFSET=$(expr $PRODUCT_OFFSET + $PRODUCT_SECTORS)
ODM_OFFSET=$(expr $VENDOR_OFFSET + $VENDOR_SECTORS)
SYSTEM_DLKM_OFFSET=$(expr $ODM_OFFSET + $ODM_SECTORS)
VENDOR_DLKM_OFFSET=$(expr $SYSTEM_DLKM_OFFSET + $SYSTEM_DLKM_SECTORS)

# Create mappings for current slot
echo "Creating dm-linear for system$CURRENT_SLOT" >> /tmp/mapping_log
dmctl create system$CURRENT_SLOT -ro linear 0 $SYSTEM_SECTORS $SUPER_DEV $SYSTEM_OFFSET >> /tmp/mapping_log 2>&1

echo "Creating dm-linear for system_ext$CURRENT_SLOT" >> /tmp/mapping_log
dmctl create system_ext$CURRENT_SLOT -ro linear 0 $SYSTEM_EXT_SECTORS $SUPER_DEV $SYSTEM_EXT_OFFSET >> /tmp/mapping_log 2>&1

echo "Creating dm-linear for product$CURRENT_SLOT" >> /tmp/mapping_log
dmctl create product$CURRENT_SLOT -ro linear 0 $PRODUCT_SECTORS $SUPER_DEV $PRODUCT_OFFSET >> /tmp/mapping_log 2>&1

echo "Creating dm-linear for vendor$CURRENT_SLOT" >> /tmp/mapping_log
dmctl create vendor$CURRENT_SLOT -ro linear 0 $VENDOR_SECTORS $SUPER_DEV $VENDOR_OFFSET >> /tmp/mapping_log 2>&1

echo "Creating dm-linear for odm$CURRENT_SLOT" >> /tmp/mapping_log
dmctl create odm$CURRENT_SLOT -ro linear 0 $ODM_SECTORS $SUPER_DEV $ODM_OFFSET >> /tmp/mapping_log 2>&1

echo "Creating dm-linear for system_dlkm$CURRENT_SLOT" >> /tmp/mapping_log
dmctl create system_dlkm$CURRENT_SLOT -ro linear 0 $SYSTEM_DLKM_SECTORS $SUPER_DEV $SYSTEM_DLKM_OFFSET >> /tmp/mapping_log 2>&1

echo "Creating dm-linear for vendor_dlkm$CURRENT_SLOT" >> /tmp/mapping_log
dmctl create vendor_dlkm$CURRENT_SLOT -ro linear 0 $VENDOR_DLKM_SECTORS $SUPER_DEV $VENDOR_DLKM_OFFSET >> /tmp/mapping_log 2>&1

# Verify
ls -l /dev/block/mapper >> /tmp/mapping_log 2>&1

echo "Dynamic partition mapping completed" >> /tmp/mapping_log
