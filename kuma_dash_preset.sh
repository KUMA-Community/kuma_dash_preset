#!/bin/bash
# ver. 0.3 (05.12.2024)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

KUMA_VER=$(/opt/kaspersky/kuma/kuma version | cut -d "." -f1-2)
ACTUAL_TENANT_ID=$(/opt/kaspersky/kuma/mongodb/bin/mongo localhost/kuma --quiet --eval 'db.tenants.find({"main":true},{"_id": 1}).map(function(doc){return doc._id;});' | sed "s/'/\"/g" | cut -d '"' -f2)

if [[ $(bc <<< "$KUMA_VER >= 3.2") -eq 1 ]]; then 
	ACTUAL_CLUSTER_ID=$(/opt/kaspersky/kuma/mongodb/bin/mongo localhost/kuma --quiet --eval 'db.services.find({"kind": "storage", "status": "green", "tenantID": "'$ACTUAL_TENANT_ID'"})[0].resourceID')
else
	ACTUAL_CLUSTER_ID=$(sqlite3 /opt/kaspersky/kuma/core/00000000-0000-0000-0000-000000000000/raft/sm/db "select resource_id from services where kind='storage' and status='green' and tenant_id='$mainID';")

	mainID=$(/opt/kaspersky/kuma/mongodb/bin/mongo localhost/kuma --quiet --eval 'db.tenants.findOne({"main":true})._id');/opt/kaspersky/kuma/mongodb/bin/mongo localhost/kuma --quiet --eval 'db.dashboards.updateMany({"name": {$in:["[OOTB] KWTS","[OOTB] KSMG","[OOTB] KSC","[OOTB] KATA & EDR","Network Overview"]}}, {$set: {"widgets.$[x].search.clusterID": "'"$ACTUAL_CLUSTER_ID"'"}},{arrayFilters: [{"x.search.clusterID": {$in:["phantomID","","6c964dab-e303-4a2c-bb31-d84866a20599"]}, "x.specialKind": ""}]});'
fi

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
		/opt/kaspersky/kuma/mongodb/bin/mongo localhost/kuma --quiet --eval 'db.dashboards.find({"name": "'$2'"}).forEach(function(doc){print(JSON.stringify(doc));});' | jq -c '._id="UUID" | .widgets[].tenantIDs=["T_ID"] | .tenantIDs=["T_ID"] | .widgets[].search.clusterID="C_ID" | del(.results)'> $3
		
		if [[ $? -eq 0 ]]; then
			echo -e "${GREEN}[OK] Dashboard ${2} exported to file $3!${NC}"
		else
			echo -e "${RED}[FAILED] to export dashboard ${2} to file $3!${NC}"
		fi
		
	fi
    ;;

    "-importDash")
	if [[ ! $# -eq 2 ]] || [[ $2 == ""  ]] || [[ ! -f $2 ]]; then
		echo -e "${YELLOW}Please enter valid arguments!\nExample: -import /path/MyDashboard.json${NC}"
        echo -e "${YELLOW}OR Please check file $2, is it exist?${NC}"
	else
        sed -i "s/T_ID/$ACTUAL_TENANT_ID/g" $2
        sed -i "s/C_ID/$ACTUAL_CLUSTER_ID/g" $2
        sed -i "s/UUID/$(cat /proc/sys/kernel/random/uuid)/g" $2
		
		/opt/kaspersky/kuma/mongodb/bin/mongo localhost/kuma --quiet --eval 'db.dashboards.insertOne('"$2"');'
		
		if [[ $? -eq 0 ]]; then
			echo -e "${GREEN}[OK] from file ${2} imported!${NC}"
		else
			echo -e "${RED}[FAILED] to import dashboard ${2}!${NC}"
		fi
	fi
    ;;

    "-deleteDash")
	if [[ ! $# -eq 2 ]] || [[ $2 == ""  ]]; then
		echo -e "${YELLOW}Please enter valid arguments!\nExample: -delete \"My Dashboad\"${NC}"
	else
        /opt/kaspersky/kuma/mongodb/bin/mongo kuma --eval 'db.dashboards.remove({"name": "'$2'"})'
		
		if [[ $? -eq 0 ]]; then
			echo -e "${GREEN}[OK] Dashboard ${2} deleted!${NC}"
		else
			echo -e "${RED}[FAILED] to delete dashboard ${2}!${NC}"
		fi
	fi
    ;;

	"-exportPreset")
	if [[ ! $# -eq 3 ]] || [[ $2 == ""  ]] || [[ $3 == ""  ]] || [[ $IS_EXPORT == 0 ]]; then
		echo -e "${YELLOW}Please enter valid arguments!\nExample: -exportPreset \"My Preset\" MyPreset.json\n OR check is jq installed?${NC}"
	else
		/opt/kaspersky/kuma/mongodb/bin/mongo localhost/kuma --quiet --eval 'db.resources.find({"kind":"eventPreset","name": "'$2'"}).forEach(function(doc){print(JSON.stringify(doc));});' | jq -c '._id="UUID" | .payload.tenantID="T_ID" | .tenantID="T_ID"'> $3
		
		if [[ $? -eq 0 ]]; then
			echo -e "${GREEN}[OK] Preset ${2} exported to file $3!${NC}"
		else
			echo -e "${RED}[FAILED] to export preset ${2} to file $3!${NC}"
		fi
	fi
    ;;

	"-importPreset")
	if [[ ! $# -eq 2 ]] || [[ $2 == ""  ]] || [[ ! -f $2 ]]; then
		echo -e "${YELLOW}Please enter valid arguments!\nExample: -importPreset \"My Preset\" MyPreset.json${NC}"
		echo -e "${YELLOW}OR Please check file $2, is it exist?${NC}"
	else
		sed -i "s/T_ID/$$ACTUAL_TENANT_ID/g" $2
		sed -i "s/UUID/$(cat /proc/sys/kernel/random/uuid)/g" $2

		if [[ cat $2 | grep -c '"kind":"eventPreset"' -eq 0 ]]; then
			echo -e "$[FAILED] It is not preset file!${2}!${NC}"
			exit 1
		fi
		
		/opt/kaspersky/kuma/mongodb/bin/mongo localhost/kuma --quiet --eval 'db.resources.insertOne('"$2"');'
		
		if [[ $? -eq 0 ]]; then
			echo -e "${GREEN}[OK] from file ${2} imported!${NC}"
		else
			echo -e "${RED}[FAILED] to import dashboard ${2}!${NC}"
		fi
	fi
    ;;

	* )
	echo -e $usage
	;;
esac
