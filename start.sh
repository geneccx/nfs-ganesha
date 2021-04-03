#!/bin/bash
set -e

# Options for starting Ganesha
: ${GANESHA_LOGFILE:="/dev/stdout"}
: ${GANESHA_LOGLEVEL:="WARN"}
: ${GANESHA_CONFIGFILE:="/etc/ganesha/ganesha.conf"}
: ${GANESHA_OPTIONS:="-N NIV_EVENT"} # NIV_DEBUG
: ${GANESHA_EXPORT_ID:="2046"}
: ${GANESHA_EXPORT:="/data"}
: ${GANESHA_CLIENT_LIST:="*"}
: ${GANESHA_NFS_PROTOCOLS:="4"}
: ${GANESHA_TRANSPORTS:="TCP"}
: ${GANESHA_SECTYPE:="sys"}
: ${GANESHA_SQUASH:="Root_Squash"}
: ${GANESHA_ANON_UID:="-2"}
: ${GANESHA_ANON_GID:="-2"}

function bootstrap_ganesha_config {
  echo "Bootstrapping Ganesha NFS config"
  cat <<END >${GANESHA_CONFIGFILE}

NFSV4 {
    Allow_Numeric_Owners = false;
}

EXPORT
{
        # Export Id (mandatory, each EXPORT must have a unique Export_Id)
        Export_Id = ${GANESHA_EXPORT_ID};

        # Exported path (mandatory)
        Path = ${GANESHA_EXPORT};
        Pseudo = ${GANESHA_EXPORT};

        # Access control options
        Access_Type = NONE;
        Squash = ${GANESHA_SQUASH};
        Anonymous_Uid = ${GANESHA_ANON_UID};
        Anonymous_Gid = ${GANESHA_ANON_GID};

        Transports = "${GANESHA_TRANSPORTS}";
        Protocols = "${GANESHA_NFS_PROTOCOLS}";

        SecType = "${GANESHA_SECTYPE}";
        Manage_Gids = true;

        CLIENT {
            Clients = ${GANESHA_CLIENT_LIST};
            Access_Type = RW;
        }

        FSAL { 
            Name=VFS;
        }
}

LOG {
        Default_Log_Level = ${GANESHA_LOGLEVEL};
        Components {
                # ALL = DEBUG;
                # SESSIONS = INFO;
         }
}

END

}

function init_services {
    echo "Starting rpc services"
    rpcbind || return 0
    rpc.statd -L || return 0

    sleep 1
}

function init_dbus {
    echo "Starting dbus"
    rm -f /var/run/dbus/system_bus_socket
    rm -f /var/run/dbus/pid
    dbus-uuidgen --ensure
    dbus-daemon --system --fork
    sleep 1
}

function startup_script {
    if [ -f "${STARTUP_SCRIPT}" ]; then
    /bin/sh ${STARTUP_SCRIPT}
    fi
}

bootstrap_ganesha_config
startup_script

init_services
init_dbus

echo "Starting Ganesha NFS"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib
exec /usr/bin/ganesha.nfsd -F -L ${GANESHA_LOGFILE} -f ${GANESHA_CONFIGFILE} ${GANESHA_OPTIONS}