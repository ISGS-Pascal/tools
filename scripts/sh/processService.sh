#!/bin/sh

#
# Description
#
# Script to activate or deactivate services (agents and daemons).
# The services are deactivated adding a suffix to plist extension.
# The services are searched in:
#     /Library/LaunchAgents
#     /Library/LaunchDaemons
# 
# Usage:
#     processService [-s] [pattern]
#         If “-s” specified then simulation mode. Should be at first position.
#         Default mode: execution
# 
#         If pattern omitted then Avast (initially created for this antivirus)
#         Examples of pattern:
#         - for Avast: com.avast.*.plist
#         - for TeamViewer: com.teamviewer.*.plist
# 
#
# History
#        1         2         3         4         5         6         7         8
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
# +------------------------+----------+----------------------------------------+
# | Who                    | When     | What                                   |
# +------------------------+----------+----------------------------------------+
# | Pascal DEVAUX          | 20160927 | Creation on OS X (Mac) for Avast       |
# |                        |          | Initial name of script: processService |
# +------------------------+----------+----------------------------------------+
# | Pascal DEVAUX          | 20160928 | Simulation mode added                  |
# +------------------------+----------+----------------------------------------+
# | Pascal DEVAUX          | 20161018 | Add message to restart                 |
# +------------------------+----------+----------------------------------------+
#

curDate=`date +%Y-%m-%d`
curTime=`date +%H:%M:%S`
echo ===========================================================
echo ${curDate} ${curTime}
echo ===========================================================

# Information about OS name
curOS=`uname -s`
if [ “${curOS}” != “Darwin” ]
then
    echo
    echo ________________________________________________________________
    echo
    echo This script has been developed and tested on Darwin unix system.
    echo You are using ${curOS} without any guarantee of success!
    echo ________________________________________________________________
    echo
fi

# ——------------------------------
# Global variables for this script
# for debug purposes
#  0 for production, 1 for debug (add outputs)
debugMode=0
#
# constants
simulationMode=simulation
executionMode=execution
#
flagSimulation=0
# 
# Do NOT modify this suffix. Flag to toggle activation.
suffixOff=_OFF
lengthSuffixOff=${#suffixOff}
#
# Default service = if not specified
servicePattern=com.avast.*.plist
#
# Default mode to run
runMode=${executionMode}
#
# Initial value for command
toggleCmd=`echo No command` 
# End of global variables
# ——------------------------------


# 
# Processing parameters
#
if [ ${debugMode} -eq 1 ]; then echo List of $# parameters: $@ ; fi
if [ ! -e $1 ] # First positional parameter exists
then
    if  [ “$1” == “-s” ] # simulation mode
    then
        flagSimulation=1
        runMode=${simulationMode}
        if [ ! -e $2 ]; then servicePattern=$2; fi
    else
        servicePattern=$1
    fi
#else: First positional parameter empty, so no parameter. Nothing to do.
fi
if [ “${runMode}” == “${simulationMode}” ]
then
    echo
    echo __________________________
    echo
    echo Mode is ${runMode}
    echo __________________________
    echo
    echo
fi
#
# Parameters processed.
#
if [ ${debugMode} -eq 1 ]
then
    echo Context after processing parameters
    echo Parameters: $*
    echo Mode: ${runMode}
    echo Service pattern: ${servicePattern}
fi


if [ ${debugMode} -eq 1 ]; then echo Suffix used to deactivate service: ‘${suffixOff}’ \(length=${lengthSuffixOff}\); fi

echo Processing for services with pattern ‘${servicePattern}’...
for curFolder in /Library/LaunchAgents /Library/LaunchDaemons
do
    flagFoundType=0
    cd ${curFolder}
    nbResult=`ls ${servicePattern} 2> /dev/null | wc -l`
    echo \\t- folder ‘${curFolder}’ with ${nbResult} active services
    # If services then process
    if [ $nbResult -gt 0 ]
    then
        flagFoundType=1 # active service
        for curService in `ls ${servicePattern}`
        do
            echo \\t\\t- service to deactivate ‘${curService}’ 
            newService=${curService}${suffixOff}
            echo \\t\\t\\tcurrent service: ${curService}
            echo \\t\\t\\tnew service    : ${newService}
            toggleCmd=`echo sudo mv ${curService} ${newService}`
            echo \\t\\t\\tcommand: ${toggleCmd}
            # Execution of command
            if [ “${runMode}” == “${executionMode}” ]; then ${toggleCmd}; fi
        done
    else
        # No services. Search if deactivated…
        nbResult=`ls ${servicePattern}${suffixOff} 2> /dev/null | wc -l`
        echo \\t- folder ‘${curFolder}’ with ${nbResult} deactivated services
        # Deactivated services to reactivate
        if [ $nbResult -gt 0 ]
        then
            flagFoundType=2 # Deactivated service
            for curService in `ls ${servicePattern}${suffixOff}`
            do
                echo \\t\\t- service to reactivate ‘${curService}’ 
                newService=${curService:0:${#curService}-${lengthSuffixOff}}
                echo \\t\\t\\tcurrent service: ${curService}
                echo \\t\\t\\tnew service    : ${newService}
                toggleCmd=`echo sudo mv ${curService} ${newService}`
                echo \\t\\t\\tcommand: ${toggleCmd}
                # Execution of command
                if [ “${runMode}” == “${executionMode}” ]; then ${toggleCmd}; fi
            done
        fi 
    fi
    if [ ${flagFoundType} -eq 0 ]
    then
        echo Note that no services are found based on pattern ‘${servicePattern}’!
    fi
done 
# End of loop on folders for services

# Message to user about restarting the machine
if [ “${runMode}” == “${executionMode}” ]
then
    echo \\n\\nYour changes will take effect after next restart.\\n\\n
fi

# End of script
