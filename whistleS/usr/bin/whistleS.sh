#!/bin/bash
count=1
port=9000
port_count=150

. /etc/whistleS/whistleS.conf

let "max_port=${port} + ${port_count}*2 - 2"

currsh=$0
currpid=$$
runpid=$(lsof -t ${currsh} | paste -s -d " " )

if [[ ${runpid} == ${currpid} ]]
then
  cur_port=$(cat $port_dir/cur.port)
  if [  "${cur_port}" = "" ]
  then
    cur_port=${port}
  fi
  for files in $(ls ${whistleS_root_dir}/outcome/ )
  do
    echo ${whistleS_root_dir}/outcome/${files}" "${cur_port}
    est=$(lsof | grep ${whistleS_root_dir}/outcome/${files} | wc -l)
    if [ ${est} = "0" ]
    then
      tar -cf ${whistleS_root_dir}/outcome/${files}".tar" --directory=${whistleS_root_dir}/outcome/ ${files}
#     udp-sender --file /home/user/in/*.tar --interface usb0 --max-bitrate 100m --async  --portbase ${cur_port} --autostart 1
      udp-sender --file ${whistleS_root_dir}/outcome/${files}".tar" --interface usb0 --max-bitrate 10m --fec 16x16/128 --async --portbase ${cur_port} --autostart 1
      echo ${files} arch sent to ${cur_port} at `date +%Y-%m-%d---%T` >> ${logdir}/whistleS.log
      rm ${whistleS_root_dir}/outcome/${files}".tar"
      mv -f ${whistleS_root_dir}/outcome/${files} ${whistleS_root_dir}/outcome/
      let "cur_port=${cur_port}+2"

      if [ "${cur_port}" -gt "${max_port}" ]
      then
        cur_port=${port}
      fi

      echo ${cur_port} > ${port_dir}/cur.port
      let "count=${count}+1"

      if [ "${count}" -gt "${port_count}" ]
      then
        echo limit ${port_count} is exceeded
      break
      fi
    else
      echo ${files} still opened >> ${logdir}/whistleS.log
    fi
  done
else
  echo -e "\nPID(${runpid})(${currpid}) ::: already run ${currsh} \n"
fi
