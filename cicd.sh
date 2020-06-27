#!/bin/bash
#basepath=$(cd `dirname $0`; pwd)/$(basename $0)
set -e 

TimeTag=$(date +"%Y-%m-%d-%H-%M-%S")
release_time=10s

build() {
	docker build -t ${registry}/${proj}:${TimeTag} -f ${config} ${BuildDir}
}

push() {
	docker push ${registry}/${proj}:${TimeTag}	
}

update() {
	# 发布
	kubectl set image deployment/${proj} ${proj}=${registry}/${proj}:${TimeTag} -n ${namespace}	

	# 检查发布/回滚
	timeout ${release_time} kubectl rollout status deployment/${proj} && wait 
	if [[ $? = 0 ]]; then
		echo "Published successfully ！！！"
	else
		echo "发布失败，执行回滚"
		kubectl rollout undo deployment/${proj} 
		if [[ $? = 0 ]]; then
			echo "回滚完成"
		else
			echo "回滚失败，请检查手动回滚 ！！！"
		fi
	fi	
}

main() {
	build
	push
	update
}

Usage() {
    #echo -e "Usage: bash ${basepath} -o [ProjName] -r [Docker_Registry_url]\n
    echo -e "Usage: cicd -o [ProjName] -r [Docker_Registry_url]\n
    -o [ProjName] (Required) \n
    -r [Docker_Registry_url] (Required)\n
    -f [Config] Name of the Dockerfile (Optional,Default is 'PATH/Dockerfile')\n 
    -d [BuildDir] (Optional,Default is 'PATH')\n
    -n [Namespace] (Optional,Default is 'default')\n"
    exit 1
}

while getopts "o:r:f:d:n:h:" arg; do
	case $arg in
		o)
		proj=$OPTARG
	;;
		r)
		registry=$OPTARG
	;;
		f)
		config=$OPTARG
	;;
		d)
		BuildDir=$OPTARG
	;;
		n)
		namespace=$OPTARG
	;;
		h)
		Usage
	;;
		?)	
		Usage
	;;
esac
done

[ ! ${proj} ] && Usage
[ ! ${registry} ] && Usage
[ ! ${config} ] && config=$(pwd)/Dockerfile
[ ! ${BuildDir} ] && BuildDir=$(pwd)
[ ! ${namespace} ] && namespace="default"

cat <<  EOF > ./index.html
IMAGE: ${registry}/${proj}:${TimeTag}
EOF

main 
