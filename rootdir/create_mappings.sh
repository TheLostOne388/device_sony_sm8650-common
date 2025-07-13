#!/system/bin/sh



echo "Starting create_mappings.sh" > /tmp/mapping_log

/system/bin/lptodm /dev/block/by-name/super > /tmp/lptodm_output 2>&1

if [ $? -ne 0 ]; then

  echo "lptodm failed" >> /tmp/mapping_log

else

  while read -r line; do

    echo "Executing: dmctl $line" >> /tmp/mapping_log

    /system/bin/dmctl $line >> /tmp/mapping_log 2>&1

  done < /tmp/lptodm_output

fi

echo "Script completed" >> /tmp/mapping_log
