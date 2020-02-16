#!/usr/bin/env bash
# command line option
# $1: i686 | x86_64 : target architecture
#!/usr/bin/env bash
# charset
charsets=( "utf_8" "shift_jis"  "euc_jp" )
charset=${charsets[0]}

# version
open_jtalk_ver=1.11
hts_engine_api_ver=1.10
mmdagent_example_ver=1.8

re="(MINGW|CYGWIN)"
if [[ $(uname) =~ $re ]]; then
	bash build_portaudio_mingw $1
fi

if [ ! "$1" == "" ] ; then
    param=-Dtarget_arch=$1 -Dcharset=${charset}
fi
if [[ $(uname) =~ "MINGW" ]]; then
    arch=${MSYSTEM_CHOST}
elif [[ $(uname) =~ "CYGWIN" ]]; then
	if [ "$1" == "" ] ; then
		arch=$(uname -m)
	else
		arch=$1
	fi
	arch=$arch-w64-mingw32
fi

# dir name
bin=bin
voice=voice

open_jtalk=open_jtalk-${open_jtalk_ver}
hts_engine_api=hts_engine_API-${hts_engine_api_ver}
hts_voice=hts_voice_nitech_jp_atr503_m001-1.05

# download from open-jtalk
files=( $open_jtalk $hts_voice)
base_url=http://downloads.sourceforge.net/open-jtalk/
for file in ${files[@]}; do
    if [ ! -e $file.tar.gz ]; then
        wget ${base_url}$file.tar.gz
    fi
done

if [ ! -e ${open_jtalk} ]; then
    tar zxvf ${open_jtalk}.tar.gz
    echo -n > ${open_jtalk}/mecab/config.h
    cd ${open_jtalk}
    patch -Np1<../open_jtalk-${open_jtalk_ver}_mingw.patch
    cd ..
fi

# download from hts-engine
files=($hts_engine_api)
base_url=http://downloads.sourceforge.net/hts-engine/
for file in ${files[@]}; do
    if [ ! -e $file.tar.gz ]; then
        wget ${base_url}$file.tar.gz
    fi
done

if [ ! -e ${hts_engine_api} ]; then
    tar zxvf ${hts_engine_api}.tar.gz
fi

# make voice dir
if [ ! -d $voice ]; then
    mkdir $voice
fi

# hts_voice
if [ ! -d $voice/$hts_voice ]; then
    tar zxvf ${hts_voice}.tar.gz -C $voice
fi

# download from mmdagent
dir=$voice
if [ ! -d $dir ]; then
    mkdir $dir
fi
file=MMDAgent_Example-${mmdagent_example_ver}
if [ ! -e ${file}.zip ]; then
    base_url=http://downloads.sourceforge.net/mmdagent/
    wget ${base_url}${file}.zip
fi
persons=(mei takumi)
for person in ${persons[@]}; do
    if [ ! -d $dir/$person ]; then
        mkdir $dir/$person
        unzip ${file}.zip ${file}/Voice/$person/*.*
        mv ${file}/Voice/$person/*.* $dir/$person
        rm -r ${file}
    fi
done

# download from tohoku github
dir=$voice/htsvoice-tohoku-f01
if [ ! -d $dir ]; then
    mkdir $dir
fi
names=(angry happy neutral sad)
base_url=https://github.com/icn-lab/htsvoice-tohoku-f01/raw/master/
for name in ${names[@]}; do
    if [ ! -e $dir/tohoku-f01-${name}.htsvoice ]; then
        wget ${base_url}tohoku-f01-${name}.htsvoice -P $dir
    fi
done
files=(COPYRIGHT.txt README.md)
for file in ${files[@]}; do
    if [ ! -e $dir/$file ]; then
        wget ${base_url}$file -P $dir
    fi
done

build_dir=build$arch.dir
mkdir -p ${build_dir}
cd ${build_dir}
cmake .. $param
make
if [[ $(uname) =~ $re ]]; then
    make install/strip
else
    sudo make install/strip
fi
cd ..