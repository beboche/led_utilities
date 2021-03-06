#!/usr/bin/bash



###########################################################################
#########                                                       ###########
#########               splitVCF4LED                              ###########
######### @uthor : D Baux       david.baux<at>inserm.fr         ###########
######### Date : 10/09/2018                                     ###########
#########                                                       ###########
###########################################################################





#specific script to treat data beofre LED input
#we will get sample IDs then
#create smaller vcfs (1 sample each)
#then prepare indvidual file



VERSION=1.0
USAGE="
Program: splitVCF4LED
Version: ${VERSION}
Contact: Baux David <david.baux@inserm.fr>

Usage: bash splitVCF4LED.sh -i input.vcf [ -f <family_ID> -e <expriment_name> -t <team> -d <disease> -b /path/to/bcftools ]
default bcftools: /usr/local/bin/bcftools
"


if [ "$#" -eq 0 ]; then
	echo "${USAGE}"
	echo "Error Message : No arguments provided"
	echo ""
	exit 1
fi
#default
BCFTOOLS="/usr/local/bin/bcftools"
GENOME="hg19"
while [[ "$#" -gt 0 ]]
do
KEY="$1"
case "${KEY}" in
	-i|--input)					#mandatory
	VCF="$2"
	shift
	;;
	-f|--family)
	FAMILY="$2"
	shift
	;;
	-e|--experiment)
	EXPERIMENT="$2"
	shift
	;;
	-t|--team)
	TEAM="$2"
	shift
	;;
	-d|--disease)
	DISEASE="$2"
	shift
	;;
	-s|--suffix)
	SUFFIX="$2"
	shift
	;;
	-h|--help)
	echo "${USAGE}"
	exit 1
	;;
	*)
	echo "Error Message : Unknown option ${KEY}" 	# unknown option
	exit
	;;
esac
shift
done


RED='\033[0;31m'
LIGHTRED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# -- Log functions got from cww.sh -- simplified here

error() { log "[${RED}error${NC}]" "$1" ; }
warning() { log "[${YELLOW}warn${NC}]" "$1" ; }
info() { log "[${BLUE}info${NC}]" "$1" ; }
debug() { log "[${LIGHTRED}debug${NC}]" "$1" ; }

# -- Print log 

echoerr() { echo -e "$@" 1>&2 ; }

log() {
	echoerr "[`date +'%Y-%m-%d %H:%M:%S'`] $1 - splitVCF4LED version : ${VERSION} - $2"
}


treat_samples() {
	# "${FILENAME}" "${VCF}" "${BCFTOOLS}" "${SAMPLE}" "${FAMILY}" "${EXPERIMENT}" "${TEAM}" "${DISEASE}"
	info "creating splitted VCF: $5/$1/$4.vcf"
	#"${BCFTOOLS}" view -c1 -Ov -s$( IFS=$',';echo "${SAMPLES[*]}") -o "splitted_vcf/${FILENAME}.${SAMPLE_COUNT}.vcf" "${VCF}" 
	#info "$6 view -c1 -Ov -s$( IFS=$',';echo $4) -o splitted_vcf/$1_$2/$3.$1_$2.vcf $5" 
	"$3" view -c1 -Ov -s "$6" -o "$5/$1/$4.vcf" "$2" 
	if [ "${FAMILY}" -a "${DISEASE}" -a "${TEAM}" -a "${EXPERIMENT}" ];then
		cp "sample.txt" "$5/$1/$4.txt"
		sed -i.bak -e "8 s/\(patient_id:\).*/\1${SAMPLE_SIMPLE}/" \
			-e "9 s/\(family_id:\).*/family_id:${FAMILY}/" \
			-e "11 s/\(disease_name:\).*/disease_name:${DISEASE}/" \
			-e "12 s/\(team_name:\).*/team_name:${TEAM}/" \
			-e "14 s/\(experiment_type:\).*/experiment_type:${EXPERIMENT}/" "$5/$1/$4.txt"
		rm "$5/$1/$4.txt.bak"
	fi
}

if [ ! -f "${BCFTOOLS}" ];then
	error "bcftools not found"
fi

#info "VCF file is ${VCF} and Sample Number in new VCFs will be ${SAMPLE_NUM}"
#END=$((SAMPLE_NUM-1))

if [ -f "${VCF}" ];then
	VCFNAME=$(basename -- "${VCF}")
	DIRNAME=$(dirname "${VCF}")
	FILEEXT="${VCFNAME##*.}"
	FILENAME="${VCFNAME%.*}"
	if [ "${FILEEXT}" == "vcf" ];then
		info "${VCF} will be treated"
		#SAMPLES=$(${BCFTOOLS} query -l ${VCF} | cut -f 1- | awk '{print}')
		mkdir "${DIRNAME}/${FILENAME}"
		for SAMPLE in `"${BCFTOOLS}" query -l "${VCF}"`; do
			if [[ "${SAMPLE}" =~ ^(.+)${SUFFIX} ]];then
				SAMPLE_SIMPLE="${BASH_REMATCH[1]}"
			else
				SAMPLE_SIMPLE="${SAMPLE}"
			fi
			treat_samples "${FILENAME}" "${VCF}" "${BCFTOOLS}" "${SAMPLE_SIMPLE}" "${DIRNAME}" "${SAMPLE}"
			((SAMPLE_COUNT++))
		done
		info "${SAMPLE_COUNT} samples processed"
	else
		error "${VCF} does not appear to have a .vcf extension"
	fi
else
	error "Cannot find ${VCF} file"
fi

	


