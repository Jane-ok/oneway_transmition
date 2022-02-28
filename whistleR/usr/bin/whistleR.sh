#!/bin/bash
port=9000
port_count=150

. /etc/whistleR/whistleR.conf

whistleR_logfile=$logdir/whistleR.log
whistleR_arch=$whistleR_root_dir/arch
whistleR_Out=$whistleR_root_dir/income

for ((i=${port}; i<${port}+${port_count}*2; i=i+2))
do
  est=$(ps -ef | grep udp | grep "portbase "$i | wc -l )
  if [ ${est} = "0" ]
  then
    udp-receiver --file ${whistleR_Out}/$(date +%Y%m%d_%H%M%S_%N)".tar.bz2" --portbase $i --interface usb0 &
  else
    echo portbase $i already started
  fi
done

for files in $(find ${whistleR_Out}/ -type f -name "*.bz2" -printf "%f\n")
do
  est=$(lsof | grep ${whistleR_Out}/${files} | wc -l )
  if [ ${est} = "0" ]
  then
    echo ${files} was received at `date +%Y-%m-%d---%T` >> ${whistleR_logfile}
    tar --touch -C ${whistleR_Out}/ -xvf ${whistleR_Out}/${files} 2>> ${whistleR_logfile}

    if [[ "${files}" =~ check_files.log$ ]];
    then
      mv -f ${whistleR_Out}/${files} ${logdir}/chekc_loss/
    fi

    mv -f ${whistleR_Out}/${files} ${whistleR_arch}/ 2>> ${whistleR_logfile}
  else
    echo ${files} still download >> ${whistleR_logfile}
    echo $(lsof | grep $whistleR_Out/$files) >> ${whistleR_logfile}
  fi
done
