#!/bin/bash
#
# update function: 多线程转换
# date     :     2017-06-27
#-----------------------------------------

#使用方法： ./convert_pcm_to_wav.sh /home/work/pcm_dir log.txt

wav_path_file=""
_split_dir="split_dir"
thread_num=10


# 将源文件夹中的所有.wav 文件按照Kaldi的要求转换
function convert()
{
	echo "   ---> convert... "$1" file's pcm"	

	while read file
	do
		#echo -e $file
		if [ "${file##*.}"x = "pcm"x ];then
		
			temp_file_name=${file%.*}
			temp_file_name+=".wav"
			sox -t raw -c 1 -s -b 16 -r 16000 $file -t wav -c 1 $temp_file_name
			rm $file
		fi
	done < $1
	
	echo "   ---> convert done!"	
}


# walk 函数 一个配置
# 第一个是遍历的目标文件
function create_pcm_list()
{
	# ${1}为调用walk函数时传入的第一个参数
	for file in `ls ${1}` #ls输出当前路径下的所有文件以及文件夹，利用for in分别对其进行操作
	do
		path=${1}"/"${file} #拼接当前将要处理的文件或文件夹路径
		if [[ -d ${path} ]];then  #-d 是测试其是否是文件夹
			create_pcm_list ${path}
		elif [[ -f ${path} ]];then
			if [ "${path##*.}"x = "pcm"x ];then
				echo "${path}" >> $wav_path_file 
			fi
		fi
	done
}

function split_files()
{
	line_num=`wc -l $wav_path_file | awk '{print $1}'`
	if [[ -e $_split_dir ]];then
		rm -rf $_split_dir
	fi
	mkdir -p $_split_dir
	cp $wav_path_file $_split_dir
	cd $_split_dir
	each_file_line_num=$(($line_num/$thread_num))
	
	echo "   ---> split file "$temp_file"to "$thread_num" part!"
	echo "   ---> each_file_line_num:$each_file_line_num"
	
	temp_file=${wav_path_file##*/}
	if [[ $line_num -gt $thread_num ]];then
		split -l $each_file_line_num $temp_file
		if [[ -f $temp_file ]];then
			rm $temp_file
		fi
	fi

	cd ../
}

function init()
{	
	de_source_dir=$1 # 源文件夹
	de_target_dir=""

	last_char=${de_source_dir: -1}

	if [[ $last_char == "/" ]];then
		de_target_dir=${de_source_dir%?}
	else
		de_target_dir=$de_source_dir
	fi
		
	de_target_dir=${de_target_dir##*/} #输出的目标文件夹
	
	de_dir_to_walk=${de_source_dir} #将要遍历操作文件夹
    

	cur_work_home=`pwd`
	wav_path_file=$cur_work_home"/"$2
	# 调用walk函数
	create_pcm_list $de_dir_to_walk

}


SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"
SETCOLOR_WARNING="echo -en \\033[1;33m"


if [ $# -lt 2 ];then
	$SETCOLOR_FAILURE
	echo -e "\nPlease input pcm_dir(absolute path) and log_file\n" 
	echo -e "\n  eg: ./convert_pcm_to_wav.sh /home/work/pcm_dir log.txt"
	cur_work_home=`pwd`
	wav_path_file=$cur_work_home"/"$2
	if [[ -f $wav_path_file ]];then
		rm -f $wav_path_file
	fi
	$SETCOLOR_NORMAL
	exit -1
elif [ ! -x "$1" ];then
	$SETCOLOR_FAILURE
	echo -e "\nThe source file is not exist!\n"
	$SETCOLOR_NORMAL
	exit -1
fi

$SETCOLOR_WARNING

echo -e "\nsource directory : [ $1 ] !\n"

$SETCOLOR_SUCCESS

echo -e "\nStart Convert...\n"

if [[ -f $2 ]];then
	rm -f $2
fi

init $1 $2; # 程序初始化执行


if [[ -f $wav_path_file ]];then
	split_files $wav_path_file
fi

echo -e "\n   ---> start mutil thread convert!\n"

for file in `ls $_split_dir`
do
	convert "$_split_dir/$file" &	
done

wait

echo -e "\nComplete!\n"
$SETCOLOR_NORMAL




