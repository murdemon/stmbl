#!/bin/sh
# KLogic pre-start script


    echo ""
    echo " prepare to start KLogic target..."

    # ��� ������� � ���� � ����
    PRG="klogic-sa02"
    PTH="/home/klogic"
    # ���� ��� ���������� ������� ����� web
    UPLD="/sys/usr/www/public_html/cgi-bin/upld"

    cd $PTH


    # ��������, ����������� ��� ������ ��������
    case $PRG in
      "klogic-wb" )
        if [ -f /etc/wb-mqtt-mbgate.conf ]; then
          # ��������� ��������� ������������ ����������� Modbus TCP �������
          chattr +i /etc/wb-mqtt-mbgate.conf
        fi

        if [ -f /var/log/ppp.log ]; then
          # ������� ������ ��� pppd
          rm -f /var/log/ppp.log
        fi

        # ������������� �����
        wb-gsm restart_if_broken

        # ������������� ��������� ����� �� RTC
        #/sbin/hwclock -s -f /dev/rtc1
        wb-gsm-rtc restore_time
        ;;

      "klogic-ksb" )
        cpuserial="cpu-serial"
        curr_sn=`cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2`

        # ��������� �������� ����� CPU
        if [ -f $cpuserial ]; then
          orig_sn=`cat $cpuserial`
          if [ "$curr_sn" != "$orig_sn" ]; then
            exit -1
          fi
        else
          echo "$curr_sn" > $cpuserial
          chmod 640 $cpuserial
        fi

        # ������������� RTC � ��������� ���������� �������
        if [ ! -e /dev/rtc1 ]; then
          HCTOSYS_DEVICE=rtc0
          echo ds3231 0x68 > /sys/class/i2c-adapter/i2c-0/new_device
          I=0
          while [ $I -lt 5 ]
          do
            /sbin/hwclock -s -f /dev/rtc1 > /dev/null 2>&1
            RC=$?
            if [ $RC -eq 0 ]; then
              I=5
              HCTOSYS_DEVICE=rtc1
            else
              I=$(( $I + 1 ))
              sleep 1
            fi
          done
          rm -f /dev/rtc
          ln -s /dev/$HCTOSYS_DEVICE /dev/rtc
        fi

        # ������������� ��������� ������ ����
        if [ -f menu-klogic ]; then
          TEST=`ps -A | grep menu-klogic | wc -l`
          if [ $TEST -gt 0 ]; then
            killall menu-klogic
          else
            chvt 2
            gpio mode 6 out #PD14
          fi
          cat clr-seq > /dev/tty2
          echo "������ KLogic..." > /dev/tty2
          gpio write 6 1
        fi
        ;;

      "klogic-sa02" )
        # ������������� RTC � ��������� ���������� �������
        if [ ! -e /dev/rtc1 ]; then
          HCTOSYS_DEVICE=rtc0
          echo ds3231 0x68 > /sys/class/i2c-adapter/i2c-1/new_device
          I=0
          while [ $I -lt 5 ]
          do
            /sbin/hwclock -s -f /dev/rtc1 > /dev/null 2>&1
            RC=$?
            if [ $RC -eq 0 ]; then
              I=5
              HCTOSYS_DEVICE=rtc1
            else
              I=$(( $I + 1 ))
              sleep 1
            fi
          done
          rm -f /dev/rtc
          ln -s /dev/$HCTOSYS_DEVICE /dev/rtc
        fi
		
		TestFBExternal,
		Andrey Yurov, [29 Apr 2025 10:20:08]


Andrey Yurov, [29 Apr 2025 10:20:11]

		# ������������� ���������� �������, ��� � RTC
		hwclock -w
        # ������������� ���������� ������� ���������� PCA9536
        i2cset -y 2 0x41 0x03 0xf0
		# beeper 1 ��� ��� �������
		i2cset -y 2 0x41 0x01 0x0B
		sleep 0,1
        i2cset -y 2 0x41 0x01 0x0f
		

        # �������� ��������� �� ���������������� �����
        COM=`ls /dev | grep -c COM`
        if [ $COM -lt 5 ]; then
          if [ $COM -gt 0 ]; then
            rm -f /dev/COM*
          fi
          ln -s /dev/ttyS0 /dev/COM1
          ln -s /dev/ttyS3 /dev/COM2
          ln -s /dev/ttyS4 /dev/COM3
          ln -s /dev/ttyS5 /dev/COM4
          ln -s /dev/ttyS7 /dev/COM5
        fi

        # ������������ SD-����� � �������� ���������
        SD=`cat /proc/mounts | grep /dev/mmcblk3p1 | wc -l`
        if [ $SD -eq 0 ]; then
          if [ -L /home/klogic/arch ]; then
            rm -f /home/klogic/arch
          fi
          if [ -d /mnt/sd ]; then
            rm -rf /mnt/sd
          fi
          if [ -e /dev/mmcblk3p1 ]; then
            mkdir /mnt/sd
            mount -t vfat /dev/mmcblk3p1 /mnt/sd -o rw,umask=0000
            sleep 1
            if [ ! -d /mnt/sd/arch ]; then
              mkdir /mnt/sd/arch
            fi
            if [ -d /home/klogic/arch ]; then
              if [ ! -z "$(ls -A /home/klogic/arch)" ]; then
                cp -a /home/klogic/arch/* /mnt/sd/arch
              fi
              rm -rf /home/klogic/arch
            fi
            ln -s /mnt/sd/arch /home/klogic/arch
          fi
         fi
        ;;
    esac


if [ ! -f adjust-eth0 ]; then
#
# configure LAN1 IP address
#

    setip="set-ip0"
    if [ -f $setip ]; then
      chmod 755 $setip
      ./$setip
    fi


#
# applying routes
#

    setroute="set-route"
    if [ -f $setroute ]; then
      chmod 755 $setroute
      ./$setroute
    fi
else
    if [ $PRG = "klogic-nls" ]; then
      chmod 755 adjust-eth0
      ./adjust-eth0 &
    fi
fi


if [ ! -f adjust-eth1 ]; then
#
# configure LAN2 IP address
#

    setip="set-ip1"
    if [ -f $setip ]; then
      chmod 755 $setip
      ./$setip
    fi
fi


    LF="start.log"

    MESS_START=" starting KLogic target"
    MESS_DEL_CFG="  deleting config file"
    MESS_DEL_CFG_NEW="  deleting config.new file"
    MESS_DEL_KLD_NEW="  deleting $PRG.new file"
    MESS_UPD_KLD="  updating KLogic target"
    MESS_OK="OK"
    MESS_FAIL="failed"


#
# deleting config.new file
#

    newfile="config.new"
    if [ -f $newfile ]; then
      echo -n "$MESS_DEL_CFG_NEW - "
      rm -f $newfile
      if [ $? -ne 0 ]; then
        echo "$MESS_FAIL"
      else
        echo "$MESS_OK"
        echo "`date +%X" "%d.%m.%Y` | $MESS_DEL_CFG_NEW" >> $LF
      fi
    fi


#
# deleting klogic-[platform].new file
#

    newfile="$PRG.new"
    if [ -f $newfile ]; then
      echo -n "$MESS_DEL_KLD_NEW - "
      rm -f $newfile
      if [ $? -ne 0 ]; then
        echo "$MESS_FAIL"
      else
        echo "$MESS_OK"
        echo "`date +%X" "%d.%m.%Y` | $MESS_DEL_KLD_NEW" >> $LF
      fi
    fi


#
# moving update files from web directory
#

    if [ -f $UPLD/klogic.upd ]; then
      # ���������� ����� web ����� ������ ���������
      rm -f $PTH/*.upd
      rm -f $PTH/*.tar

      mv -f $UPLD/klogic.upd $PTH/klogic.tar
      # ������� ���������� ����������
      rm -f $UPLD/*
    fi


#
# updating KLogic target
#

    O=$PRG
    is_upd=0

    # ���������� ��� ����� � ������� ���������� �� �����
    # *logic*.upd - ���������� ����� WinSCP
    for filename in *logic*.upd
    do
      # �� �����, ��� ��������� ��������� ����
      U=$filename
    done

    # ���� ���� ������
    if [ $U != "*logic*.upd" ]; then
      echo -n "$MESS_UPD_KLD (type: 1) - "
      mv -f $U $O
      if [ $? -ne 0 ]; then
        echo "$MESS_FAIL"
      else
        echo "$MESS_OK"
        echo "`date +%X" "%d.%m.%Y` | $MESS_UPD_KLD" >> $LF
        chmod +x $O
        # ������� ����� ������� ����, ����� �� ���� �������� ����������
        rm -f $PTH/*.tar
        is_upd=1
      fi
    fi

    # ���������� �� ���������, ������� ������ �������
    if [ $is_upd -eq 0 ]; then
      # ���������� ��� ����� � ������� ���������� �� �����
      # *logic*.tar - ���������� ����� KLogic IDE
      for filename in *logic*.tar
      do
        U=$filename
      done

      # ���� ���� ������
      if [ $U != "*logic*.tar" ]; then
        echo -n "$MESS_UPD_KLD (type: 2) - "

        # ��������, ����������� ��� ������ ��������
        case $PRG in
          "klogic-SMH2Gi" )
            # SMH2Gi �� ������������ gzip
            tar -xf $U
            ;;

          * )
            tar -xzf $U
            ;;
        esac

        if [ $? -ne 0 ]; then
          echo "$MESS_FAIL"
        else
          echo "$MESS_OK"
          echo "`date +%X" "%d.%m.%Y` | $MESS_UPD_KLD" >> $LF
          chmod +x $O
        fi
        is_upd=2
      fi

      # ���� ���������� ���������, ����� ������� ����� � �����������
      if [ $is_upd -gt 0 ]; then
        echo -n "  deleting $U file - "
        rm -f $U
        if [ $? -ne 0 ]; then
          echo "$MESS_FAIL"
        else
          echo "$MESS_OK"
        fi
      fi
    fi


#
# check log file
#

    TLF="/tmp/$LF"

    # ���������� ����� ����� � ����
    if [ -f $LF ]; then
      s_count=`cat $LF | wc -l`
    else
      s_count=0
    fi

    # ������� ��� �� 20 �����, ���� �� ����� ������ 30
    if [ $s_count -gt 30 ]; then
      echo "  deleting old records from log file"
      tail -20 $LF > $TLF
      mv -f $TLF $LF
    fi

    s_count=`cat $LF | grep "$MESS_START" | wc -l`
    if [ $s_count -gt 0 ]; then
      cat $LF | grep "$MESS_START" | tail -1 > $TLF
    fi

    echo "`date +%X" "%d.%m.%Y` | $MESS_START" >> $LF

    # ��������� ����������� ����
    # ������ ������ ���� �� ����������� ���� � ������� ������
    if [ $s_count -gt 0 ]; then
      log_ok=0

      # �������� ����� ������ � ������ ����� ����������� � �������� ������� �������
      # FS="[\.:]" - ��������� ����� � ��������� � �������� ������������ ����� � ������ (�� ��������� ������������ �������� ������)
      # gsub(" ",":",$0); - ������ ���� �������� � ������ �� ���������
      LT=`cat $TLF | awk '{FS="[\.:]"; gsub(" ",":",$0); print 60*60*$1+60*$2+$3}'`
      CT=`tail -1 $LF | awk '{FS="[\.:]"; gsub(" ",":",$0); print 60*60*$1+60*$2+$3}'`

      # �������� �����������, ���������� ������������ ���� ����������� � �������� ������� �������
      # �������, ��� ��� ������ 01.01.1900 �� ����������
      LD=`cat $TLF | awk '{FS="[\.:]"; gsub(" ",":",$0); print ($6-1900)*10000+$5*100+$4}'`
      CD=`tail -1 $LF | awk '{FS="[\.:]"; gsub(" ",":",$0); print ($6-1900)*10000+$5*100+$4}'`

      # ���� ���� �����
      if [ $LD -eq $CD ]; then
        # ���� ����� ����������� ������ ������ ������� ��������
        if [ $LT -lt $CT ]; then
          # ��� ���������
          log_ok=1
        fi
      # �����
      else
        # ���� ���� ����������� ������ ������ ���� ��������
        if [ $LD -lt $CD ]; then
          # ��� ���������
          log_ok=1
        fi
      fi
    else
      # ������������ ����� ��� �������
      # �������, ��� ��� ���������
      log_ok=1
    fi

    # ���� ��� �� ���������
    if [ $log_ok -eq 0 ]; then
      echo " log file corrupted, deleting"
      # ������� ���
      # �� ��������� �����, �� ������ ������
      mv -f $PTH/$LF $PTH/start.bad
      # ��������������� ���
      echo "`date +%X" "%d.%m.%Y` | $MESS_START" >> $LF
    fi


#
# check restarts
#

    # ������������� ������ � ��������
    ANALYS_PERIOD_S=60
    # ������������ ����� ������� ������� �� ������
    S_MAX=5

    # �������� ���� ���������� ������ �������
    # �� ����, ��� ������� ����
    last_date=`tail -1 $LF | awk '{print $2}'`
    # �������� ����� ������ � ������ ����� ���������� ������ �������
    last_time=`tail -1 $LF | grep "$last_date" | grep "$MESS_START" | awk '{FS="[\.:]"; gsub(" ",":",$0); print 60*60*$1+60*$2+$3}'`
    # ���������� ������ ������� ��� �������
    last_time=`expr ${last_time} - $ANALYS_PERIOD_S`

    TDF="/tmp/log_del.tmp"
    TRF="/tmp/log_rest.tmp"

    if [ -f $TDF ]; then
      rm -f $TDF
    fi
    if [ -f $TRF ]; then
      rm -f $TRF
    fi

    # ��������� ����, ���������� ����� ������ � ������ ����� ���� �������� ������������ �� ��������������� ����� � ������ ������ ������� ������
    cat $LF | grep "$last_date" | grep "$MESS_DEL_CFG" | awk '{FS="[\.:]"; gsub(" ",":",$0); $0=60*60*$1+60*$2+$3; if ('${last_time}' <= $0) {print $0;}}' > $TDF

    # ���������� ����� �������� ������������
    if [ -f $TDF ]; then
      s_del_count=`cat $TDF | wc -l`
    else
      s_del_count=0
    fi

    # ���� ������������ ���������, �������������� ������ ������� ��� ������� �� ������ ���������� ��������
    # �� ����, ��������� ������������� ������, �������� �� ���� ��� ����������� �������� ������������
    if [ $s_del_count -gt 0 ]; then
      last_time=`tail -1 $TDF`
    fi

    # ��������� ����, ���������� ����� ������ � ������ ����� ���� ������� ������� �� ��������������� ����� � ������ ������ ������� ������
    cat $LF | grep "$last_date" | grep "$MESS_START" | awk '{FS="[\.:]"; gsub(" ",":",$0); $0=60*60*$1+60*$2+$3; if ('${last_time}' <= $0) {print $0;}}' > $TRF

    # ���������� ����� ������� ������� �� ��������������� ������
    s_count=`cat $TRF | wc -l`
    echo "  checking restarts for last $ANALYS_PERIOD_S sec: $s_count (max=$S_MAX, del=$s_del_count)"
    # ���� ���� ����������
    if [ $s_count -gt $S_MAX ]; then
      echo "$MESS_DEL_CFG"
      echo "`date +%X" "%d.%m.%Y` | $MESS_DEL_CFG" >> $LF
      # ������� ������������
      # �� ��������� �����, �� ������ ������
      mv -f $PTH/config.bin $PTH/config.bad
    fi


#
# starting KLogic runtime
#

    # ��������, ����������� ��� ������ ��������
    case $PRG in
      "klogic-decont" )
        mkdir /var/klogic
        mkdir /var/klogic/ppp
        cp -a /home/klogic/ppp-* /var/klogic
        cp -a /home/klogic/ppp/* /var/klogic/ppp

        #wdt-off
        ;;

      "klogic-bt6000" )
        chmod -R 644 /var/www
        find /var/www -type d -exec chmod 755 {} \;
        ;;

      "klogic-wb" )
        newconf="$PTH/newconf.flag"
        onestart="$PTH/onestart.flag"

        if [ -f $newconf ]; then
          if [ -f $onestart ]; then
            # ������� �����
            rm -f $newconf
            rm -f $onestart
            # ������ �����
            mqtt-delete-retained /devices/wb-gpio/#
            service wb-homa-gpio restart
          else
            # ��������� ���� ������� � ����� �������������
            echo "Starting with new config at `date +%X" "%d.%m.%Y`" >> $onestart
          fi
        fi
        ;;

      "klogic-ksb" )
        rm -f cnf-shm
        ;;
    esac

    echo "$MESS_START"
    echo ""

    exit 0
