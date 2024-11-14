#!/bin/bash
# RU_PRESALE_TEAM_BORIS_O
# ver. 0.2 (11.11.2024)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

M_EXPORT=/opt/kaspersky/kuma/mongodb/bin/mongoexport
M_IMPORT=/opt/kaspersky/kuma/mongodb/bin/mongoimport
ACTUAL_TENANT_ID=$(/opt/kaspersky/kuma/mongodb/bin/mongo localhost/kuma --quiet --eval 'db.tenants.find({"main":true})[0]._id')
ACTUAL_CLUSTER_ID=$(/opt/kaspersky/kuma/mongodb/bin/mongo localhost/kuma --quiet --eval 'db.services.find({"kind": "storage", "status": "green", "tenantID": "'$ACTUAL_TENANT_ID'"})[0].resourceID')
usage="\n$(basename "$0") [-h] [-exportDash] [-importDash] [-deleteDash] [-exportPreset] [-importPreset] <ARGUMENTS> -- program for executing script\n
\n
where:\n
    ${YELLOW}-h${NC} -- show this help text\n
    ${YELLOW}-exportDash \"<Dashboard Name>\" </path/File Export Name.json>${NC} -- export dashboard to file in JSON (dashboard name must be UNIQUE! and use \" if spaces are in the name)\n
    ${YELLOW}-importDash <File Export Name.json>${NC} -- import dashboard to KUMA\n
    ${YELLOW}-deleteDash \"<Dashboard Name>\"${NC} -- delete dashboard from KUMA (dashboard name must be UNIQUE! and use \" if spaces are in the name)\n
	${YELLOW}-exportPreset \"<Preset Name>\" </path/File Export Name.json>${NC} -- export Preset to file in JSON (dashboard name must be UNIQUE! and use \" if spaces are in the name)\n
    ${YELLOW}-importPreset <File Export Name.json>${NC} -- import Preset to KUMA\n
\n
"

if [[ $# -eq 0 ]]; then
	echo -e "${RED}No arguments supplied${NC}"
	echo -e $usage
	exit 1
fi

if [[ ! -f $M_EXPORT ]] || [[ ! -f $M_IMPORT ]]; then
    echo -e "${RED}NO mongo import or export binary files in /opt/kaspersky/kuma/mongodb/bin/${NC}"
	echo -e $usage
	exit 1
fi

if ! command -v jq &> /dev/null; then
        echo -e "${RED}NO jq command, please install (example): sudo apt-get install jq${NC}"
		echo -e "${YELLOW}NO export functioanlity!${NC}"
		IS_EXPORT=0
fi


case $1 in
	"-h")
	echo -e $usage
	;;

    "-exportDash")
	if [[ ! $# -eq 3 ]] || [[ $2 == ""  ]] || [[ $3 == ""  ]] || [[ $IS_EXPORT == 0 ]]; then
		echo -e "${YELLOW}Please enter valid arguments!\nExample: -export \"My Dashboad\" MyDashboard.json\n OR check is jq installed?${NC}"
	else
        cd /opt/kaspersky/kuma/mongodb/bin
        ./mongoexport  --db=kuma --collection=dashboards --query='{"name": "'$2'"}' | jq -c '._id="UUID" | .widgets[].tenantIDs=["T_ID"] | .tenantIDs=["T_ID"] | .widgets[].search.clusterID="C_ID" | del(.results)'> $3
		echo -e "${GREEN}Dashboard ${2} exported to file $3!${NC}"
	fi
    ;;

    "-importDash")
	if [[ ! $# -eq 2 ]] || [[ $2 == ""  ]] || [[ ! -f $2 ]]; then
		echo -e "${YELLOW}Please enter valid arguments!\nExample: -import /path/MyDashboard.json${NC}"
        echo -e "${YELLOW}OR Please check file $2, is it exist?${NC}"
	else
        cd /opt/kaspersky/kuma/mongodb/bin
        sed -i "s/T_ID/$ACTUAL_TENANT_ID/g" $2
        sed -i "s/C_ID/$ACTUAL_CLUSTER_ID/g" $2
        sed -i "s/UUID/$(cat /proc/sys/kernel/random/uuid)/g" $2
        ./mongoimport  --db kuma --collection dashboards --file $2
		echo -e "${GREEN}Dashboard from file ${2} imported!${NC}"
	fi
    ;;

    "-deleteDash")
	if [[ ! $# -eq 2 ]] || [[ $2 == ""  ]]; then
		echo -e "${YELLOW}Please enter valid arguments!\nExample: -delete \"My Dashboad\"${NC}"
	else
        /opt/kaspersky/kuma/mongodb/bin/mongo kuma --eval 'db.dashboards.remove({"name": "'$2'"})'
		echo -e "${GREEN}Dashboard ${2} deleted!${NC}"
	fi
    ;;

	"-exportPreset")
	if [[ ! $# -eq 3 ]] || [[ $2 == ""  ]] || [[ $3 == ""  ]] || [[ $IS_EXPORT == 0 ]]; then
		echo -e "${YELLOW}Please enter valid arguments!\nExample: -exportPreset \"My Preset\" MyPreset.json\n OR check is jq installed?${NC}"
	else
        cd /opt/kaspersky/kuma/mongodb/bin
        ./mongoexport  --db=kuma --collection=resources --query='{"kind":"eventPreset","name": "'$2'"}' | jq -c '._id="UUID" | .payload.tenantID="T_ID" | .tenantID="T_ID"'> $3
		echo -e "${GREEN}Dashboard ${2} exported to file $3!${NC}"
	fi
    ;;

	"-importPreset")
	if [[ ! $# -eq 2 ]] || [[ $2 == ""  ]] || [[ ! -f $2 ]]; then
		echo -e "${YELLOW}Please enter valid arguments!\nExample: -importPreset \"My Preset\" MyPreset.json${NC}"
		echo -e "${YELLOW}OR Please check file $2, is it exist?${NC}"
	else
        cd /opt/kaspersky/kuma/mongodb/bin
        GENERATED_UUID=$(cat /proc/sys/kernel/random/uuid)
		sed -i "s/T_ID/$$ACTUAL_TENANT_ID/g" $2
		sed -i "s/UUID/${GENERATED_UUID}/g" $2
		./mongoimport  --db kuma --collection resources --file $2
		echo -e "${GREEN}Dashboard ${2} exported to file $3!${NC}"
	fi
    ;;

	* )
	echo -e $usage
	;;
esac