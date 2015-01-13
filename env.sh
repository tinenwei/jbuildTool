# prerequisite: apt-get install gawk  for cfg.awk

export PROGDIR=${PWD}
export LOCAL_DIR=

export JDB_CMD=jdb

export JAVA_MAIN_CLASS=
export DEFAUT_CFG_FILES=(./cfg/empty.cfg)
export CFG_FILES=$DEFAUT_CFG_FILE

export JAVA_SOURCE_PATH= 		# The source path from parsed cfg file (search path + fixed source path)
export JAVA_CLASS_PATH=			# The class path from parsed cfg file (search path + fixed class path)
export JAVA_ALL_SOURCE_PATH=	# The source path from parsed cfg file (search path + fixed class path)
export JAVA_ALL_CLASS_PATH=

export CFG_SOURCE_SEARCH_PATHS=
export CFG_SOURCE_PATHS=
export CFG_CLASS_PATHS=
export CFG_JAR_SEARCH_PATHS=

export WEBAPP_PATH=
export JSP_SOURCE_PATH=
export SERVER_TYPE=
export SERVER_PATH=

export WEBAPP_DIR=./web

export DEFAULT_CLASSES_DIR=./bin 
export DEFAULT_LIBRARY_DIR=./lib 
export DEFAULT_SOURCE_DIR=./src/main/java 

export CLASSES_DIR=$DEFAULT_CLASSES_DIR # classes path
export LIBRARY_DIR=$DEFAULT_LIBRARY_DIR # this shoud can't be modified except in j_init
export SOURCE_DIR=$DEFAULT_SOURCE_DIR #this shoud can't be modified except in j_init
export LOCAL_CFG_FILE=project.cfg

export ANT_BUILD_FILE=$PROGDIR/build.xml # For the use of makefile 

export BASE_DIR=$PROGDIR # for base of relative path

export SOURCE_SEARCH_KEY="java"
export CACHE_DIR=cache
export LOCAL_CACHE_DIR=.

export JNI_DIR=./jni
export JNI_SRC=$JNI_DIR/src
export JNI_INCLUDE=$JNI_DIR/include
export JNI_OBJ=$JNI_DIR/obj
export JNI_LIB=$JNI_DIR/lib
export JNI_OUTPUT_DIR=$JNI_DIR/bin
export JNI_LIBARY=


if [ -z "$JAVA_HOME" ]; then
	echo "Error: \$JAVA_HOME is not set!!"
	return 1
fi


j_init()
{	
	local CLASS_PATH_STRING
	local WEB_DIR=""
	
	local temp_library_dir=""
	local temp_source_dir=""
	local temp_classes_dir=""

	if [ -n "$SERVER_TYPE" ]; then
		CLASSES_DIR=$WEBAPP_DIR/WEB-INF/classes
		LIBRARY_DIR=$WEBAPP_DIR/WEB-INF/lib
	else
		CLASSES_DIR=$DEFAULT_CLASSES_DIR # classes path
		LIBRARY_DIR=$DEFAULT_LIBRARY_DIR # this shoud can't be modified except in j_init	
	fi
	SOURCE_DIR=$DEFAULT_SOURCE_DIR #this shoud can't be modified except in j_init
	
	JAVA_ALL_CLASS_PATH=""
	JAVA_ALL_SOURCE_PATH=""
	
	JAVA_INIT_SOURCE_PATH=""
	JAVA_INIT_CLASS_PATH=""
	
	JAVA_MAIN_CLASS=""
	
	LOCAL_DIR=${PWD}
	TT=${PWD}

	local local_cfg_main_class=""
	


	if [ -f ./${LOCAL_CFG_FILE} ]; then
	
		local_cfg_main_class=`getCFG "Main-Class" ${LOCAL_CFG_FILE}`
	
		temp_source_search_path=`getCFG "source-search-path" ${LOCAL_CFG_FILE}`
		temp_source_search_path=`getCFG "source-search-path" ${LOCAL_CFG_FILE}`
		temp_source_path=`getCFG "source-path" ${LOCAL_CFG_FILE}`		
		temp_jar_search_path=`getCFG "jar-search-path" ${LOCAL_CFG_FILE}`
		temp_class_path=`getCFG "class-path" ${LOCAL_CFG_FILE}`		
		
		temp_library_dir=`getCFG "library-dir" ${LOCAL_CFG_FILE}`
		temp_classes_dir=`getCFG "classes-dir" ${LOCAL_CFG_FILE}`
		temp_source_dir=`getCFG "source-dir" ${LOCAL_CFG_FILE}`
		
		BASE_DIR=${LOCAL_DIR}

		# cache local search
		
		cache_file=${BASE_DIR}/${LOCAL_CACHE_DIR}/local.src.cache
		if [ -n "$temp_source_search_path" ]; then		
			l_java_source_path=""
			getCache=""
			if [ -f ${cache_file} ]; then
				timestamp=`stat -c %Y $1`
				cache_timestamp=`sed -n 's/timestamp=\(.*\)/\1/p' ${cache_file}`
				if [ "$timestamp" = "$cache_timestamp" ]; then
					l_java_source_path=`sed -n 's/path=\(.*\)/\1/p' ${cache_file}`
					getCache="yes"
					echo "use '${cache_file##*/}' for cache!!"
				fi
			fi
			
			if [ -z "$getCache" ]; then
				l_java_source_path=`parse_source_search_paths $temp_source_search_path`
				echo "timestamp=`stat -c %Y $1`" > ${cache_file}
				echo "path=$l_java_source_path" >> ${cache_file}
			fi

			JAVA_INIT_SOURCE_PATH=$l_java_source_path
		else
			if [ -f ${cache_file} ]; then
				rm -f $cache_file > /dev/null
			fi
		fi		


		cache_file=${BASE_DIR}/${LOCAL_CACHE_DIR}/local.jar.cache
		if [ -n "$temp_jar_search_path" ]; then		
			l_java_class_path=""
			getCache=""
			if [ -f ${cache_file} ]; then
				timestamp=`stat -c %Y $1`
				cache_timestamp=`sed -n 's/timestamp=\(.*\)/\1/p' ${cache_file}`
				if [ "$timestamp" = "$cache_timestamp" ]; then
					l_java_class_path=`sed -n 's/path=\(.*\)/\1/p' ${cache_file}`
					getCache="yes"
					echo "use '${cache_file##*/}' for cache!!"
				fi
			fi
			
			if [ -z "$getCache" ]; then
				l_java_class_path=`parse_jar_search_paths $temp_jar_search_path`
				echo "timestamp=`stat -c %Y $1`" > ${cache_file}
				echo "path=$l_java_class_path" >> ${cache_file}
	 
			fi
			
			JAVA_INIT_CLASS_PATH=$l_java_class_path
		else
			if [ -f ${cache_file} ]; then
				rm -f $cache_file > /dev/null
			fi
		fi
		# ~cache local search
		
		if [ -n "$temp_source_path" ]; then
			out_init_source_path=`get_absolute_paths $temp_source_path`		
			if [ -n "$JAVA_SOURCE_PATH" ]; then
				JAVA_INIT_SOURCE_PATH=$out_init_source_path:$JAVA_INIT_SOURCE_PATH
			else
				JAVA_INIT_SOURCE_PATH=$out_init_source_path
			fi
		fi

		if [ -n "$temp_class_path" ]; then
			out_init_class_path=`get_absolute_paths $temp_class_path`		
			if [ -n "$JAVA_SOURCE_PATH" ]; then
				JAVA_INIT_CLASS_PATH=$out_init_class_path:$JAVA_INIT_CLASS_PATH
			else
				JAVA_INIT_CLASS_PATH=$out_init_class_path
			fi
		fi		
		

		if [ -n "$temp_library_dir" ]; then
			LIBRARY_DIR=$temp_library_dir	
		fi		
		
		if [ -n "$temp_classes_dir" ]; then
			CLASSES_DIR=$temp_classes_dir
		fi			
		
		if [ -n "$temp_source_dir" ]; then
			SOURCE_DIR=$temp_source_dir	
		fi		 
	fi
	
	# multiple sources
	SOURCE_DIR_LIST=""
	found=""
	for s in $SOURCE_DIR;
	do
		if [ "$found" = "" -a -d $s ];then
			found="yes"
		fi
		
		if [ -n "$SOURCE_DIR_LIST" ]; then
			SOURCE_DIR_LIST=${SOURCE_DIR_LIST}:${s}
		else
			SOURCE_DIR_LIST=${s}
		fi
	done
	
	if [ -z "$found" ]; then
		echo "$SOURCE_DIR doesn't exist!! "
		return 1
	fi
	SOURCE_DIR=$SOURCE_DIR_LIST
	
	# record used cfg files
	if [ ! -f ./${LOCAL_CFG_FILE} ]; then
		cp ${PROGDIR}/${LOCAL_CFG_FILE} .		
	fi
	
	if grep -q 'cfg:' ./${LOCAL_CFG_FILE}; then
		cfg_files=${CFG_FILES[@]//\//\\/} # change / => \/		
		t_cfg_files=`sed -n 's/[ \t]*cfg:\(.*\)/\1/p' ./${LOCAL_CFG_FILE}`
		trim_cfg_files=`echo ${CFG_FILES[@]} | sed 's/^[ \t]*//;s/[ \t]*$//'`
		trim_t_cfg_files=`echo $t_cfg_files | sed 's/^[ \t]*//;s/[ \t]*$//'`
		local change_cfg="no"
		if [ "$trim_cfg_files" != "$trim_t_cfg_files" ]; then
			echo "Change cfg field of project.cfg : "
			echo -n "from '${trim_t_cfg_files}' to '${CFG_FILES[@]}' (n/y)? "
			read  change_cfg
		fi
		if [ "$change_cfg" != "" -a \( "$change_cfg" = "y" -o "$change_cfg" = "Y" \) ]; then
			sed -i 's/[ \t]*cfg:.*/cfg: '"${cfg_files}"'/g' ./${LOCAL_CFG_FILE}		
		fi
	else
		echo "" >> ./${LOCAL_CFG_FILE}
		echo "cfg: ${CFG_FILES[@]}" >> ./${LOCAL_CFG_FILE}
	fi
	# ~record used cfg files
	
:<<eof	
	if [ ! -e $SOURCE_DIR ];then
		echo "$SOURCE_DIR does'nt exist!! "
		return 1
	fi
eof

	# ~multiple sources
	

	JNI_LIBARY=
	if [ -d $JNI_DIR ]; then
		JNI_LIBARY=`sed -n 's/^PROGRAM   = \(.*\)/\1/p' $JNI_DIR/makefile`
	fi
	
	
	if [ -d $WEBAPP_DIR ]; then
		#WEB_DIR="web/"
		WEB_DIR=${WEBAPP_DIR}/
	fi        

	
	# Handle manifest: main class, class path
	MANIFEST_CLASS_PATH_STRING=""
	if [ -f ./${WEB_DIR}META-INF/MANIFEST.MF ]; then	
		JAVA_MAIN_CLASS=`getCFG "Main-Class" ./${WEB_DIR}META-INF/MANIFEST.MF`
		MANIFEST_CLASS_PATH_STRING=`getCFG "Class-Path" ./${WEB_DIR}META-INF/MANIFEST.MF`
	fi

	if [ -n "$local_cfg_main_class" ]; then
		JAVA_MAIN_CLASS=$local_cfg_main_class
	fi

	
	
	# Handle the Class-Path of MANIFEST.MF
	MANIFEST_CLASS_PATH=""
	for j in $MANIFEST_CLASS_PATH_STRING;
	do
		if [ -n "$MANIFEST_CLASS_PATH" ]; then
			MANIFEST_CLASS_PATH=${MANIFEST_CLASS_PATH}:${j}
		else
			MANIFEST_CLASS_PATH=${j}
		fi
	done

	# Handle LIBRARY_DIR
	if [ -d $LIBRARY_DIR ]; then
		local jar_path=`find_jar_path $LIBRARY_DIR`
		if [ -n "$jar_path" ]; then
			if [ -n "$MANIFEST_CLASS_PATH" ]; then
				MANIFEST_CLASS_PATH=$jar_path:$MANIFEST_CLASS_PATH
			else
				MANIFEST_CLASS_PATH=$jar_path
			fi
		fi
	fi	
	
	# Combine  JAVA_INIT_CLASS_PATH , Class-Path of MANIFEST.MF and LIBRARY_DIR
	if [ -n "$MANIFEST_CLASS_PATH" ]; then
		if [ -n "$JAVA_INIT_CLASS_PATH" ]; then		
			JAVA_INIT_CLASS_PATH=${MANIFEST_CLASS_PATH}:${JAVA_INIT_CLASS_PATH}
		else
			JAVA_INIT_CLASS_PATH=${MANIFEST_CLASS_PATH}	
		fi
	fi
	
	# Add ./ and CLASSES_DIR to JAVA_INIT_CLASS_PATH
	if [ -n "$JAVA_INIT_CLASS_PATH" ]; then		
		JAVA_INIT_CLASS_PATH=.:${CLASSES_DIR}:${JAVA_INIT_CLASS_PATH}
	else
		JAVA_INIT_CLASS_PATH=.:${CLASSES_DIR}	
	fi
	
	# Combine JAVA_INIT_CLASS_PATH, JAVA_CLASS_PATH to JAVA_ALL_CLASS_PATH
	if [ -n "$JAVA_CLASS_PATH" ]; then
		if [ -n "$JAVA_INIT_CLASS_PATH" ]; then	
        		JAVA_ALL_CLASS_PATH=${JAVA_INIT_CLASS_PATH}:${JAVA_CLASS_PATH}
		else
        		JAVA_ALL_CLASS_PATH=${JAVA_CLASS_PATH}
		fi
    else
		if [ "$JAVA_INIT_CLASS_PATH" != "" ]; then	
        		JAVA_ALL_CLASS_PATH=${JAVA_INIT_CLASS_PATH}
		fi		
	fi
	
	
	
	# handle source path
	if [ -n "$SOURCE_DIR" ]; then
		if [ -n "$JAVA_INIT_SOURCE_PATH" ]; then		
			JAVA_INIT_SOURCE_PATH=${SOURCE_DIR}:${JAVA_INIT_SOURCE_PATH}
		else
			JAVA_INIT_SOURCE_PATH=${SOURCE_DIR}	
		fi
	fi		
	
	if [ -n "$JAVA_SOURCE_PATH" ]; then
		if [ -n "$JAVA_INIT_SOURCE_PATH" ]; then	
        		JAVA_ALL_SOURCE_PATH=${JAVA_INIT_SOURCE_PATH}:${JAVA_SOURCE_PATH}
		else
        		JAVA_ALL_SOURCE_PATH=${JAVA_SOURCE_PATH}
		fi
    	else
		if [ -n "$JAVA_INIT_SOURCE_PATH" ]; then	
        		JAVA_ALL_SOURCE_PATH=${JAVA_INIT_SOURCE_PATH}
		fi		
	fi

}

j_undeploy()
{
	if [ -z "$WEBAPP_PATH" ]; then
		echo '$WEBAPP_PATH is empty !!'
		return 1;
	fi

	if [ -e ./web_home_name ]; then
		local name=`cat ./web_home_name`
		rm $WEBAPP_PATH/$name && rm ./web_home_name
		if [ "$SERVER_TYPE" = "jetty" ]; then
			if [ -f $SERVER_PATH/contexts/$name.xml ]; then
				rm $SERVER_PATH/contexts/$name.xml 
			fi

		fi
	fi
	
}

j_deploy()
{

	# ijetty
	if [ "$SERVER_TYPE" = "ijetty" ]; then
		i_jetty_deploy
		return 0
	fi
	# ~ijetty

	if [ -z "$WEBAPP_PATH" ]; then
		echo '$WEBAPP_PATH is empty !!'
		return 1;
	fi
<< comment
	if [ ! -e ./build ]; then
		echo "'./build' doesn't exist !! "
		return 1;
	fi
	
	local war_dir

	cd ./build
	for d in $(ls)
	do
		if [ -d "$d" ]; then
			war_dir=$d
			break
		fi
	done 
	cd - >> /dev/null
comment
	if [ -e ./web_home_name ]; then
		local name=`cat ./web_home_name`
		echo "already depoly!!"
		echo "The name is '$name'"
		return 0
	fi

	local WEB_DIR_NAME

	echo -n "Web Directory Name (${PWD##*/}): "
	read WEB_DIR_NAME
	
	#if [ -z "$WEB_DIR_NAME" ]; then
	#	WEB_DIR_NAME=${PWD##*/}
	#fi

	WEB_DIR_NAME=${WEB_DIR_NAME:-${PWD##*/}}
	

	if [ -e $WEBAPP_PATH/$WEB_DIR_NAME ]; then
		echo "already depoly in webapp path:"
		echo "$WEBAPP_PATH/$WEB_DIR_NAME"
		return 0
	fi

	echo "$WEB_DIR_NAME" > ./web_home_name

	if [ -n "$WEBAPP_PATH" ]; then
		if [ "$SERVER_TYPE" = "jboss" ]; then
			#cp -arvf ./build/$war_dir $WEBAPP_PATH
			#ln -s ${PWD}/build/$war_dir $WEBAPP_PATH
			ln -s ${PWD}/web ${WEBAPP_PATH}/${WEB_DIR_NAME}.war
			echo "-------------------------------------------------"
			echo "link ${PWD}/web to"
			echo "   $WEBAPP_PATH/${WEB_DIR_NAME}.war"
			echo "-------------------------------------------------"
			#echo ${PWD}/build/$war_dir
			#echo "cp -arvf ./build/$war_dir $WEBAPP_PATH"
		else
			#cp -arvf ./build/$war_dir $WEBAPP_PATH
			#ln -s ${PWD}/build/$war_dir $WEBAPP_PATH
			ln -s ${PWD}/web $WEBAPP_PATH/$WEB_DIR_NAME
			echo "-------------------------------------------------"
			echo "link ${PWD}/web to"
			echo "   $WEBAPP_PATH/$WEB_DIR_NAME"
			echo "-------------------------------------------------"
			#echo ${PWD}/build/$war_dir
			#echo "cp -arvf ./build/$war_dir $WEBAPP_PATH"
		fi
	fi

	if [ "$SERVER_TYPE" = "jetty" ]; then

		if [ -e "$SERVER_PATH"/contexts ]; then
			cat > "$SERVER_PATH"/contexts/$WEB_DIR_NAME.xml << eof
<?xml version="1.0"  encoding="ISO-8859-1"?>
<!DOCTYPE Configure PUBLIC 
          "-//Mort Bay Consulting//DTD Configure//EN"
          "http://jetty.mortbay.org/configure.dtd">
<Configure class="org.eclipse.jetty.webapp.WebAppContext">
   <Set name="contextPath">/${WEB_DIR_NAME}</Set>
   <Set name="war">${PWD}/web</Set>
</Configure>
eof
		fi
	elif [ "$SERVER_TYPE" = "jboss" ]; then
		touch  $WEBAPP_PATH/${WEB_DIR_NAME}.war.dodeploy
	fi
	
}

# for reload of tomcat:
# modify tomcat_home/conf/tomcat-users.xml
#  <role rolename="manager-gui"/>
#  <role rolename="manager-script"/>
#  <user username="admin" password="admin" roles="manager-gui,manager-script"/>

j_reload()
{
	local WEB_DIR_NAME

	if [ -e ./web_home_name ]; then
		WEB_DIR_NAME=`cat ./web_home_name`
	else
		echo "not deploy !!"
		return 1
	fi

	if [ "$SERVER_TYPE" = "tomcat" ]; then
		wget --user=admin --password=admin \
		http://localhost:8080/manager/text/reload?path=/$WEB_DIR_NAME -q -O /dev/stdout
		echo "reload successfully!!"
	elif [ "$SERVER_TYPE" = "jetty" ]; then
		echo "touch $SERVER_PATH/contexts/$WEB_DIR_NAME.xml"
		touch $SERVER_PATH/contexts/$WEB_DIR_NAME.xml
		echo "reload successfully!!"
	elif [ "$SERVER_TYPE" = "jboss" ]; then
		touch  $WEBAPP_PATH/${WEB_DIR_NAME}.war.dodeploy
		echo "reload successfully!!"
	fi
	
}

export WGET_PATH=

j_wget()
{

	if [ x"$@" != "x" ]; then
		if [ -e ./web_home_name ]; then
			WGET_PATH=http://localhost:8080/`cat ./web_home_name`/$@
		else
			WGET_PATH=http://localhost:8080/$@
		fi
	fi
	

	if [ -z "$WGET_PATH" ]; then
		echo "http path is empty !! "
		return 1
	fi
	

	echo "wget $WGET_PATH"
	wget $WGET_PATH -q -O /dev/stdout
}

j_tomcat_list()
{
	if [ "$SERVER_TYPE" = "tomcat" ]; then
		wget --user=admin --password=admin \
		http://localhost:8080/manager/text/list -q -O /dev/stdout

	fi
}

j_debug()
{
	if [ -z "$SERVER_TYPE" ]; then
		j_init || return 1
		if [ -z "$JAVA_MAIN_CLASS" ]; then
			echo "No Main Class !!"
			return 0
		fi
		make -f ${PROGDIR}/makefile \
		CLASS_PATH=${JAVA_ALL_CLASS_PATH} \
 		SOURCE_DIR=${SOURCE_DIR} \
		OUTPUT_DIR=${CLASSES_DIR} || return 1
		
		#echo ${JAVA_ALL_SOURCE_PATH}
		
		#JAVA_ALL_SOURCE_PATH=${JAVA_SOURCE_PATH}

		if [ -d $JNI_DIR ]; then
			${JDB_CMD} \
			-Djava.library.path=$JNI_OUTPUT_DIR \
			-classpath ${JAVA_ALL_CLASS_PATH} \
			-sourcepath ${JAVA_ALL_SOURCE_PATH} $JAVA_MAIN_CLASS $@
		else
			${JDB_CMD} \
			-classpath ${JAVA_ALL_CLASS_PATH} \
			-sourcepath ${JAVA_ALL_SOURCE_PATH} $JAVA_MAIN_CLASS $@
		fi
	else
		#if [ ! -e ./web ]; then
			#echo "'./web' doesn't exist !! "
			#return 1
		#fi
		#JAVA_ALL_SOURCE_PATH=${JAVA_SOURCE_PATH}
		#if [ "$SERVER_TYPE" = "tomcat" -a "$JSP_SOURCE_PATH" != "" ]; then
		local JSP_SRC_PATH=""
		if [ "$SERVER_TYPE" = "tomcat" ]; then
			if [ -e ./web_home_name -a -e ./web ]; then
				#JAVA_ALL_SOURCE_PATH=${JAVA_SOURCE_PATH}:${JSP_SOURCE_PATH}/`cat ./web_home_name`
				#JAVA_ALL_SOURCE_PATH=${JAVA_SOURCE_PATH}:./web
				local jsp_files=`find web -name '*.jsp'`
				if [ -n "$jsp_files" ];  then
					mkdir -p ./temp_jsp_src_path/org/apache > /dev/null
					ln -s $PWD/web ./temp_jsp_src_path/org/apache/jsp > /dev/null
					JSP_SRC_PATH=./temp_jsp_src_path
					#echo $JAVA_ALL_SOURCE_PATH
				fi
			fi
		fi

		${JDB_CMD} \
		-sourcepath ${JAVA_ALL_SOURCE_PATH}:${JSP_SRC_PATH} \
		-connect com.sun.jdi.SocketAttach:hostname=localhost,port=$DEBUG_PORT

		rm -rf ./temp_jsp_src_path > /dev/null
	fi


}


j_remote_java()
{
	local PORT=8000

	java \
	-classpath ${JAVA_CLASS_PATH} \
	-Xdebug -Xrunjdwp:transport=dt_socket,address=$PORT,server=y,suspend=y $@
}

j_remote_jdb()
{
	local PORT=8000
	if [ -n "$1" ]; then
		PORT=$1	
	fi
	${JDB_CMD} \
	-sourcepath ${JAVA_SOURCE_PATH} \
	-connect com.sun.jdi.SocketAttach:hostname=localhost,port=$PORT
	#-listen $PORT
}

j_xjdb()
{
	local xjdb_classpath
	local xjdb_sourcepath

	if [ -z "${JAVA_CLASS_PATH}" ]; then
		xjdb_classpath="."
	else
		xjdb_classpath=".:${JAVA_CLASS_PATH}"
	fi

	if [ -z "${JAVA_SOURCE_PATH}" ]; then
		xjdb_sourcepath="."
	else
		xjdb_sourcepath=".:${JAVA_SOURCE_PATH}"
	fi
	
	${JDB_CMD} \
	-classpath ${xjdb_classpath} \
	-sourcepath ${xjdb_sourcepath} $@
}

j_javac()
{
	local javac_classpath

	if [ -z "${JAVA_CLASS_PATH}" ]; then
		 javac_classpath="."
	else
		 javac_classpath=".:${JAVA_CLASS_PATH}"
	fi

	echo "javac -g -classpath ${javac_classpath} $@"

	javac -g \
	-classpath ${javac_classpath} \
	$@
}


j_java()
{
	local java_classpath

	if [ -z "${JAVA_CLASS_PATH}" ]; then
		java_classpath="."
	else
		java_classpath=".:${JAVA_CLASS_PATH}"
	fi

	echo "java -classpath ${javac_classpath} $@"

	java \
	-classpath ${java_classpath} \
	$@
}

j_run_debug()
{
	local debug_port="5000"
	if [ -n "$1" ]; then
		debug_port=$1
		shift
	fi
	
	J_RUN_DEBUG="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=$debug_port"

	j_init || return 1

	if [ -z $JAVA_MAIN_CLASS ]; then
		echo "No Main Class !!"
		return 0
	fi
	
	debug JAVA_ALL_CLASS_PATH
	
	if [ -d $JNI_DIR ]; then
		java \
		$J_RUN_DEBUG \
		-Djava.library.path=$JNI_OUTPUT_DIR \
		-classpath ${JAVA_ALL_CLASS_PATH}  $JAVA_MAIN_CLASS  $@
	else
		#echo "java -classpath ${JAVA_ALL_CLASS_PATH}  $JAVA_MAIN_CLASS  $@" > run.sh
		java \
		$J_RUN_DEBUG \
		-classpath ${JAVA_ALL_CLASS_PATH}  $JAVA_MAIN_CLASS  $@
	fi
}

j_run()
{
	j_init || return 1

	if [ -z $JAVA_MAIN_CLASS ]; then
		echo "No Main Class !!"
		return 0
	fi
	
	debug JAVA_ALL_CLASS_PATH
	
	if [ -d $JNI_DIR ]; then
		java \
		-Djava.library.path=$JNI_OUTPUT_DIR \
		-classpath ${JAVA_ALL_CLASS_PATH}  $JAVA_MAIN_CLASS  $@
	else
		#echo "java -classpath ${JAVA_ALL_CLASS_PATH}  $JAVA_MAIN_CLASS  $@" > run.sh
		java \
		-classpath ${JAVA_ALL_CLASS_PATH}  $JAVA_MAIN_CLASS  $@
	fi
}

j_gdb()
{
	if [ ! -d $JNI_DIR ]; then
		echo "There is no jni dir !!"
		return 0
	fi

	j_init || return 1

	if [ -z $JAVA_MAIN_CLASS ]; then
		echo "No Main Class !!"
		return 0
	fi
	gdb --args \
	java \
	-Djava.library.path=$JNI_OUTPUT_DIR \
	-classpath ${JAVA_ALL_CLASS_PATH}  $JAVA_MAIN_CLASS  $@
	
}

j_gdb_attach()
{
	if [ ! -d $JNI_DIR ]; then
		echo "There is no jni dir !!"
		return 0
	fi

	j_init || return 1

	k=$1
	if [ -z "$1" ]; then
		if [ -n "$JAVA_MAIN_CLASS" ]; then
			k=$JAVA_MAIN_CLASS
		else
			echo "Please provide pid key."
			return 0
		fi
	fi
	pid_key_word="[${k:0:1}]${k:1}"
	#pid=`ps aux | grep $pid_key_word | sed 's/[^ \t]*[ \t]*\([^ \t]*\).*/\1/' | tail -1`
	pid=`ps aux | grep $pid_key_word | awk '{ print $2 }' | tail -1`
	gdb -p $pid
}


j_build()
{
	j_init || return 1

	#make -f ${PROGDIR}/makefile CLASS_PATH=${JAVA_ALL_CLASS_PATH}:$CLASSES_DIR && j_run $@
	make -f ${PROGDIR}/makefile \
	CLASS_PATH=${JAVA_ALL_CLASS_PATH} \
 	SOURCE_DIR=${SOURCE_DIR} \
	OUTPUT_DIR=${CLASSES_DIR} #|| return 1
	
	local res=$?

	if [ "$res" = "0" -a -d $JNI_DIR ]; then
		if [ -n "$JNI_LIBARY" ]; then
			make -C $JNI_DIR \
			MY_CFLAGS="-fPIC -Wall" \
			CPPFLAGS="-I./include -I${JAVA_HOME}/include -I${JAVA_HOME}/include/linux" \
			LDFLAGS=-shared \
			SRCDIRS="./src ./include" \
			PROGRAM=$JNI_LIBARY
			res=$?
		else
			echo "JNI_LIBARY Name is empty!!"
		fi
	fi

	# ijetty
	if [ "$SERVER_TYPE" = "ijetty" ]; then
		if [ "$res" = "0" ]; then
			#i_jetty_deploy
			return 0
		else
			return 0
		fi
	fi
	# ~ijetty
	
	if [ "$res" = "0" -a -e ./web_home_name ]; then
		j_reload
	fi


	return $res
	
}


j_jar()
{
	if [ ! -d $CLASSES_DIR ]; then
		echo "'$CLASSES_DIR' does'nt exist !!"
		return 1
	fi

	local JAR_NAME
	echo -n "Jar Name: "
	read JAR_NAME
	
	if [ -z "$JAR_NAME" ]; then
		JAR_NAME=${PWD##*/}
	fi
	
	jar cvfm $JAR_NAME.jar ./META-INF/MANIFEST.MF -C $CLASSES_DIR . || return 1
	
	if [ -f $JAR_NAME.jar ]; then
		if [ -d ./dist ]; then
			rm -rvf ./dist > /dev/null
		fi
		mkdir ./dist
		mv $JAR_NAME.jar ./dist
	fi

	
}

export WAR_NAME;

j_war()
{
	if [ ! -d $CLASSES_DIR ]; then
		echo "'$CLASSES_DIR' does'nt exist !!"
		return 1
	fi

	#local WAR_NAME
	echo -n "Jar Name: "
	read WAR_NAME

	#if [ -z "$WAR_NAME" ]; then
	#	WAR_NAME=${PWD##*/}
	#fi

	WAR_NAME=${WAR_NAME:-${PWD##*/}}
	
	mkdir -p ./build

<<comment
	mkdir -p ./build/$WAR_NAME
        cp -arvf ./web/* ./build/$WAR_NAME/
	
	mkdir -p ./build/$WAR_NAME/WEB-INF/classes
	mkdir -p ./build/$WAR_NAME/WEB-INF/$LIBRARY_DIR

	cp -arvf $CLASSES_DIR/* ./build/$WAR_NAME/WEB-INF/classes
	cp -arvf $LIBRARY_DIR/* ./build/$WAR_NAME/WEB-INF/$LIBRARY_DIR
comment
	
	jar cvf ./build/$WAR_NAME.war -C ./web . || return 1
	
}

j_clean()
{
	j_init || return 1
	
	if [ -d $CLASSES_DIR ];then
		rm -rvf $CLASSES_DIR
	fi
	
	if [ -d $JNI_DIR ]; then
		make -C $JNI_DIR clean
	fi

	echo "clean completely !! "
		
}

j_proj()
{
	if [ ! -f ./${LOCAL_CFG_FILE} ]; then
		cp ${PROGDIR}/${LOCAL_CFG_FILE} .
	fi

	temp_cfgs=`getCFG "cfg" ${LOCAL_CFG_FILE}`
	
	cd $T
	. ${PROGDIR}/env.sh ${temp_cfgs}
	cd - >> /dev/null
	echo "use ${temp_cfgs}."
}


#export PACKAGE_NAME 
#export DIR_NAME

export JNI_APP=no

j_javah()
{
	j_init || return 1

	if [ -d $JNI_DIR ]; then
		javah_class_name=$JAVA_MAIN_CLASS

		if [ -n "$1" ]; then
			javah_class_name=$1
		fi
		
		javah -jni -verbose -d $JNI_INCLUDE -classpath $CLASSES_DIR $javah_class_name
		
	else
		echo "There is no jni dir!!"
	fi
}

j_new_jni_app()
{
	j_new_app "jni"
}

j_new_app()
{
	local PACKAGE_NAME
	local MAIN_CLASS
	local DIR_NAME
	

	local SRC_PREFIX=./src/main/java
	local MANIFEST_DIR=./META-INF
	local MANIFEST_FILE=MANIFEST.MF

	[ "$1" = "jni" ] && JNI_APP="yes" || JNI_APP="no"

	echo -n "Directory Name: "
	read DIR_NAME
	[ -z "$DIR_NAME" ] && echo "Error: Direcotry name is empty!!" && return 1
	[ -e "$DIR_NAME" ] && echo "Error: Direcotry name already exists!!" && return 1

	echo -n "Package Name: "
	read PACKAGE_NAME
	[ -z "$PACKAGE_NAME" ] && echo "Error: Package name is empty!!" && return 1

	echo -n "Main-Class: "
	read MAIN_CLASS
	[ -z "$MAIN_CLASS" ] && echo "Error: Main class is empty!!" && return 1

	local JNI_LIBRARY_NAME
	if [ "$JNI_APP" = "yes" ]; then
		echo -n "JNI Library Name: "
		read JNI_LIBRARY_NAME
		JNI_LIBRARY_NAME=${JNI_LIBRARY_NAME:-"TestJni"}
		
		mkdir -p $DIR_NAME/$JNI_SRC	
		mkdir -p $DIR_NAME/$JNI_INCLUDE	
		mkdir -p $DIR_NAME/$JNI_OBJ	
		mkdir -p $DIR_NAME/$JNI_LIB	
		mkdir -p $DIR_NAME/$JNI_OUTPUT_DIR	

		cp $T/makefile_jni $DIR_NAME/$JNI_DIR/makefile
		jni_output_library=../$JNI_OUTPUT_DIR/lib${JNI_LIBRARY_NAME}.so
		jni_cppflags="-I./include -I${JAVA_HOME}/include -I${JAVA_HOME}/include/linux"

		sed -i "s:\(^PROGRAM   \)=.*:\1= $jni_output_library:" $DIR_NAME/$JNI_DIR/makefile
		sed -i "s:\(^CPPFLAGS  \)=.*:\1= $jni_cppflags:" $DIR_NAME/$JNI_DIR/makefile
		

		#JNI_LIBRARY_NAME

		JNI_BASENAME=`echo ${PACKAGE_NAME} | sed 's/\./_/g'`
		JNI_BASENAME=${JNI_BASENAME}_${MAIN_CLASS}
		cat > ${DIR_NAME}/${JNI_SRC}/${JNI_BASENAME}.c << eof
#include <jni.h>
#include <stdio.h>
#include "${JNI_BASENAME}.h"
JNIEXPORT void JNICALL
Java_${JNI_BASENAME}_print(JNIEnv *env, jobject obj)
{
	printf("Hello World!\n");
	return ;
}
		
eof


		cat > ${DIR_NAME}/${JNI_INCLUDE}/${JNI_BASENAME}.h << eof
/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class ${JNI_BASENAME} */

#ifndef _Included_${JNI_BASENAME}
#define _Included_${JNI_BASENAME}
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     ${JNI_BASENAME}
 * Method:    print 
 * Signature: ()V
 */
JNIEXPORT void JNICALL Java_${JNI_BASENAME}_print
  (JNIEnv *, jobject);

#ifdef __cplusplus
}
#endif
#endif
eof
	cat > .gdbinit <<eof
#set solib-search-path ./jni
set breakpoint pending on
eof
		
	fi
	
	PACKAGE_DIR=`echo ${PACKAGE_NAME} | sed 's/\./\//g'`
	local JAVA_PACKAGE_DIR=$DIR_NAME/$SRC_PREFIX/$PACKAGE_DIR

        mkdir -p $JAVA_PACKAGE_DIR
	mkdir -p $DIR_NAME/$MANIFEST_DIR
	
	if [ "$JNI_APP" = "yes" ]; then
		cat > $JAVA_PACKAGE_DIR/${MAIN_CLASS}.java << eof
package ${PACKAGE_NAME};

public class ${MAIN_CLASS} {

	public static void main(String[] args) {

		new ${MAIN_CLASS}().print();

	}

	public native void print(); 
    	static {
    		System.loadLibrary("$JNI_LIBRARY_NAME"); 
   	}
}

eof
	else
		cat > $JAVA_PACKAGE_DIR/${MAIN_CLASS}.java << eof
package ${PACKAGE_NAME};

public class ${MAIN_CLASS} {
	public static void main(String[] args) {
	
		System.out.println("hello world!!");

	}
}

eof
	fi
	
	cat > $DIR_NAME/$MANIFEST_DIR/$MANIFEST_FILE << eof
Main-Class: ${PACKAGE_NAME}.${MAIN_CLASS}
Class-Path: 
eof

	# record used cfg files
	cp ${PROGDIR}/${LOCAL_CFG_FILE} $DIR_NAME			
	
	if grep -q 'cfg:' $DIR_NAME/${LOCAL_CFG_FILE}; then
		cfg_files=${CFG_FILES[@]//\//\\/} # change / => \/		
		sed -i 's/[ \t]*cfg:.*/cfg:'"${cfg_files}"'/g' $DIR_NAME/${LOCAL_CFG_FILE}		
	else
		echo "" >> ./${LOCAL_CFG_FILE}
		echo "cfg: ${CFG_FILES[@]}" >> $DIR_NAME/${LOCAL_CFG_FILE}
	fi
	# ~record used cfg files
	
	cd $DIR_NAME	
	echo "Complete !!"
}

# ijetty

export servletName=
export ijetty_timestamp=
i_jetty_deploy()
{
	servletName=${PWD//*\/}
	#ijetty_timestamp=`date +"%s"`
	servletName_war=${servletName}.war
	ijetty_war
	ijetty_upload
	
}

ijetty_war()
{
	baseDir=${PWD}
	classes_zip="classes.zip"
	#servletName=${PWD//*\/}
	#servletName_war=${servletName}.war

	if [ -e ./web/WEB-INF/lib/classes.zip ]; then 
		rm ./web/WEB-INF/lib/classes.zip > /dev/null
	fi

	dx_jar="/media/Transcend/android_projects/adt-bundle-linux-x86_64-20140702/sdk/build-tools/21.1.1/lib/dx.jar"
	
	if [ ! -d ./web/WEB-INF/lib ]; then
		mkdir -p ./web/WEB-INF/lib
	fi

	local classes_dir=./web/WEB-INF/classes

	if [ -f ./${LOCAL_CFG_FILE} ]; then
		temp_classes_dir=`getCFG "classes-dir" ${LOCAL_CFG_FILE}`
	fi
	
	if [ "$temp_classes_dir" != "" ]; then
		classes_dir=$temp_classes_dir
	fi

	#java -jar ${dx_jar} \
	/media/Transcend/android_projects/adt-bundle-linux-x86_64-20140702/sdk/build-tools/17.0.0/dx \
	--dex --debug --verbose --output=./web/WEB-INF/lib/classes.dex \
	$classes_dir ./web/WEB-INF/lib
	#./web/WEB-INF/classes ./web/WEB-INF/lib


	cd ./web/WEB-INF/lib/
	jar cvf ./${classes_zip} classes.dex
	rm classes.dex > /dev/null
	cd $baseDir

	cd ./web
	if [ -e ../${servletName_war} ]; then
		rm ../${servletName_war} > /dev/null
	fi
	jar -cvf ${servletName_war} *
	mv ${servletName_war} ..

	cd $baseDir
}

ijetty_upload()
{
	#servletName=${PWD//*\/}
	contexts_file=${servletName}.xml
	#servletName_war=${servletName}.war
	ADB="/media/bttn/Transcend/tnw_project/android-4.1.2_r1/out/host/linux-x86/bin/adb"

	#rm ${contexts_file} > /dev/null
	if [ ! -e ${contexts_file} ]; then
        	cat > ${contexts_file} <<eof
<?xml version="1.0"  encoding="ISO-8859-1"?>
<!DOCTYPE Configure PUBLIC
          "-//Mort Bay Consulting//DTD Configure//EN"
          "http://jetty.mortbay.org/configure.dtd">
<Configure class="org.eclipse.jetty.webapp.WebAppContext">
   <Set class="org.eclipse.jetty.util.resource.Resource" name="defaultUseCaches">false</Set>
   <Set name="extractWAR">True</Set>
   <Set name="copyWebDir">True</Set>
   <Set name="contextPath">/${servletName}</Set>
   <Set name="war"><SystemProperty name="jetty.home" default="."/>/webapps/${servletName_war}</Set>
</Configure>
eof
	fi

	if [ -e ${contexts_file} ]; then
		${ADB} push ${contexts_file} /sdcard/jetty/contexts/
	fi

	if [ -e ${servletName_war} ]; then
		#${ADB} shell rm /sdcard/jetty/webapps/${servletName}_*.war
		#${ADB} shell rm -rf /sdcard/jetty/webapps/${servletName} > /dev/null
		${ADB} push ${servletName_war} /sdcard/jetty/webapps/
		#${ADB} shell mkdir -p  /sdcard/jetty/webapps/${servletName}
		#${ADB} shell unzip /sdcard/jetty/webapps/${servletName_war} -d /sdcard/jetty/webapps/${servletName}
		#${ADB} shell rm /sdcard/jetty/webapps/${servletName_war} > /dev/null
	fi

}
:<<comment
export servletName=
export ijetty_timestamp=
i_jetty_deploy()
{
	servletName=${PWD//*\/}
	ijetty_timestamp=`date +"%s"`
	servletName_war=${servletName}_${timestamp}.war
	ijetty_war
	ijetty_upload
	
}

ijetty_war()
{
	baseDir=${PWD}
	classes_zip="classes_${ijetty_timestamp}.zip"
	#servletName=${PWD//*\/}
	#servletName_war=${servletName}.war

	if [ -e ./web/WEB-INF/lib/classes_*.zip ]; then 
		rm ./web/WEB-INF/lib/classes_*.zip > /dev/null
	fi

	dx_jar="/media/Transcend/android_projects/adt-bundle-linux-x86_64-20140702/sdk/build-tools/21.1.1/lib/dx.jar"
	
	if [ ! -d ./web/WEB-INF/lib ]; then
		mkdir -p ./web/WEB-INF/lib
	fi

	#java -jar ${dx_jar} \
	/media/Transcend/android_projects/adt-bundle-linux-x86_64-20140702/sdk/build-tools/17.0.0/dx \
	--dex --debug --verbose --output=./web/WEB-INF/lib/classes.dex \
	./web/WEB-INF/classes ./web/WEB-INF/lib


	cd ./web/WEB-INF/lib/
	jar cvf ./${classes_zip} classes.dex
	rm classes.dex > /dev/null
	cd $baseDir

	cd ./web
	if [ -e ../${servletName}_*.war ]; then
		rm ../${servletName}_*.war > /dev/null
	fi
	jar -cvf ${servletName_war} *
	mv ${servletName_war} ..

	cd $baseDir
}

ijetty_upload()
{
	#servletName=${PWD//*\/}
	contexts_file=${servletName}.xml
	#servletName_war=${servletName}.war
	ADB="/media/bttn/Transcend/tnw_project/android-4.1.2_r1/out/host/linux-x86/bin/adb"

	rm ${contexts_file} > /dev/null
	if [ ! -e ${contexts_file} ]; then
        	cat > ${contexts_file} <<eof
<?xml version="1.0"  encoding="ISO-8859-1"?>
<!DOCTYPE Configure PUBLIC
          "-//Mort Bay Consulting//DTD Configure//EN"
          "http://jetty.mortbay.org/configure.dtd">
<Configure class="org.eclipse.jetty.webapp.WebAppContext">
   <Set class="org.eclipse.jetty.util.resource.Resource" name="defaultUseCaches">false</Set>
   <Set name="extractWAR">True</Set>
   <Set name="copyWebDir">True</Set>
   <Set name="contextPath">/${servletName}</Set>
   <Set name="war"><SystemProperty name="jetty.home" default="."/>/webapps/${servletName}</Set>
</Configure>
eof
	fi

	if [ -e ${contexts_file} ]; then
		${ADB} push ${contexts_file} /sdcard/jetty/contexts/
	fi

	if [ -e ${servletName_war} ]; then
		#${ADB} shell rm /sdcard/jetty/webapps/${servletName}_*.war
		${ADB} shell rm -rf /sdcard/jetty/webapps/${servletName} > /dev/null
		${ADB} push ${servletName_war} /sdcard/jetty/webapps/
		${ADB} shell mkdir -p  /sdcard/jetty/webapps/${servletName}
		${ADB} shell unzip /sdcard/jetty/webapps/${servletName_war} -d /sdcard/jetty/webapps/${servletName}
		${ADB} shell rm /sdcard/jetty/webapps/${servletName_war} > /dev/null
	fi

}

comment
# ~ijetty

j_new_war_app()
{

	if [ -z "$SERVER_TYPE" ]; then
		echo "server type is empty"
		return 0
	fi

	local PACKAGE_NAME
	local MAIN_CLASS
	local SERVLET_NAME
	local DIR_NAME
	

	local SRC_PREFIX=./src/main/java
	local MANIFEST_DIR=./META-INF
	#local WEB_DIR=./web/
	local WEB_DIR=${WEBAPP_DIR}
	local WEB_INF_DIR=WEB-INF
	local WEB_XML_FILE=web.xml
	local MANIFEST_FILE=MANIFEST.MF

	echo -n "Directory Name: "
	read DIR_NAME

	echo -n "Package Name: "
	read PACKAGE_NAME

	echo -n "Servlet Name: "
	read SERVLET_NAME

	echo -n "Main-Class: "
	read MAIN_CLASS
	
	PACKAGE_DIR=`echo ${PACKAGE_NAME} | sed 's/\./\//g'`
	local JAVA_PACKAGE_DIR=$DIR_NAME/$SRC_PREFIX/$PACKAGE_DIR

        mkdir -p $JAVA_PACKAGE_DIR
	mkdir -p $DIR_NAME/$WEB_DIR/$WEB_INF_DIR
	mkdir -p $DIR_NAME/$WEB_DIR/$MANIFEST_DIR

# > --------------   template servlet java ----------------------
	if [ "$SERVER_TYPE" = "jetty" -o "$SERVER_TYPE" = "ijetty" ]; then

	cat > $JAVA_PACKAGE_DIR/${MAIN_CLASS}.java << eof
package ${PACKAGE_NAME};

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class ${MAIN_CLASS} extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
                        throws ServletException, IOException {
        PrintWriter out = resp.getWriter();
        out.println("<html>");
        out.println("<head>");
        out.println("<title>Hello Servlet</title>");
        out.println("</head>");
        out.println("<body>");
        out.println("<h1> Hello! World!</h1>");
        out.println("</body>");
        out.println("</html>");
        out.close();
    }
}

eof

	else # other template
	
cat > ${JAVA_PACKAGE_DIR}/${MAIN_CLASS}.java << eof
package ${PACKAGE_NAME};

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet(name="${SERVLET_NAME}", urlPatterns={"/${SERVLET_NAME}.oview"},
    loadOnStartup=1)
public class ${MAIN_CLASS} extends HttpServlet {
@Override
protected void doGet(HttpServletRequest req, HttpServletResponse resp)
		throws ServletException, IOException {
PrintWriter out = resp.getWriter();
out.println("<html>");
out.println("<head>");
out.println("<title>Hello Servlet</title>");
out.println("</head>");
out.println("<body>");
out.println("<h1> Hello! World!</h1>");
out.println("</body>");
out.println("</html>");
out.close();
}
}

eof

fi
#  <--------------   template servlet java ----------------------

cat > $DIR_NAME/$WEB_DIR/$WEB_INF_DIR/$WEB_XML_FILE << eof
<?xml version="1.0" encoding="UTF-8"?>
<web-app version="3.0" xmlns="http://java.sun.com/xml/ns/javaee"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://java.sun.com/xml/ns/javaee
http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd">
    <servlet>
        <servlet-name>${SERVLET_NAME}</servlet-name>
        <servlet-class>${PACKAGE_NAME}.${MAIN_CLASS}</servlet-class>
         <load-on-startup>1</load-on-startup>
    </servlet>
    <servlet-mapping>
        <servlet-name>${SERVLET_NAME}</servlet-name>
        <url-pattern>/${SERVLET_NAME}.view</url-pattern>
    </servlet-mapping>
</web-app>
eof
	

	cat > $DIR_NAME/$WEB_DIR/$MANIFEST_DIR/$MANIFEST_FILE << eof
Main-Class: ${PACKAGE_NAME}.${MAIN_CLASS}
Class-Path: 
eof

if [ "$SERVER_TYPE" = "tomcat" ]; then

	cat > $DIR_NAME/$WEB_DIR/$MANIFEST_DIR/context.xml <<eof
<?xml version="1.0" encoding="UTF-8"?>
<Context reloadable="true" antiResourceLocking="true">
</Context>
eof

fi

	# record used cfg files
	cp ${PROGDIR}/${LOCAL_CFG_FILE} $DIR_NAME			
	
	if grep -q 'cfg:' $DIR_NAME/${LOCAL_CFG_FILE}; then
		cfg_files=${CFG_FILES[@]//\//\\/} # change / => \/		
		sed -i 's/[ \t]*cfg:.*/cfg:'"${cfg_files}"'/g' $DIR_NAME/${LOCAL_CFG_FILE}		
	else
		echo "" >> ./${LOCAL_CFG_FILE}
		echo "cfg: ${CFG_FILES[@]}" >> $DIR_NAME/${LOCAL_CFG_FILE}
	fi
	# ~record used cfg files

# ijetty
if [ "$SERVER_TYPE" = "ijetty" ]; then
	cat > $DIR_NAME/${LOCAL_CFG_FILE} <<eof
ource-path:
source-search-path:
class-path:
/media/bttn/Transcend/tnw_project/android-4.1.2_r1/prebuilts/sdk/16/android.jar
/media/bttn/Transcend/tnw_project/android-4.1.2_r1/out/target/common/obj/APPS/IJetty_intermediates/classes.jar

jar-search-path:

library-dir: 
classes-dir: ./bin
source-dir:

cfg: cfg/ijetty.cfg
eof
fi
# ~ijetty

	cd $DIR_NAME	
	echo "Complete !!"
}

find_source_search_path()
{

	output_dir=""
	if [ -n "$1" ]; then
		base_dir=$1
		for p in $(find $base_dir -name ${SOURCE_SEARCH_KEY} ! -path "*/test/*");
		do
			if [ "$output_dir" = "" ]; then
				output_dir=$p	
			else
				output_dir=${output_dir}:$p	
			fi
		done
	fi

	echo $output_dir
}

tool_find_source_search_path()
{

	output_dir=""
	if [ -n "$1" ]; then
		base_dir=$1
		for p in $(find $base_dir -name java ! -path "*/test/*");
		do
			if [ "$output_dir" = "" ]; then
				output_dir=$PWD/$p	
			else
				output_dir=${output_dir}:$PWD/$p	
			fi
		done
	fi

	echo $output_dir
}

find_target_search_path()
{

	output_dir=""
	if [ -n "$1" ]; then
		base_dir=$1
		for p in $(find $base_dir -name classes ! -path "*/test/*");
		do
			if [ -z "$output_dir" ]; then
				output_dir=$PWD/$p	
			else
				output_dir=${output_dir}:$PWD/$p	
			fi
		done
	fi

	echo $output_dir
}

# ex:
# get_absolute_paths ./a/b  /c/d
# output > $BASE_DIR/a/b:/c/d  ($BASE_DIR will change by j_init)
get_absolute_paths()
{	
	output_dir=""
	if [ -n "$1" ]; then
		for p in $@;
		do
			if [ "${p:0:1}" != "/" ]; then
				#p=$PROGDIR/$p
				p=$BASE_DIR/$p
			fi

			if [ -z "$output_dir" ]; then
				output_dir=$p	
			else
				output_dir=${output_dir}:$p	
			fi
		done
	fi

	echo $output_dir
}

find_jar_path()
{
	output_dir=""
	if [ -n "$1" ]; then
		base_dir=$1
		# for find, append "/"
		if [ -n "${base_dir##*/}" ]; then
			base_dir=$base_dir/
		fi
		
		for p in $(find $base_dir -name '*.jar' ! -path "*/test/*");
		do
			if [ -z "$output_dir" ]; then
				output_dir=$p	
			else
				output_dir=${output_dir}:$p	
			fi
		done
	fi

	echo $output_dir
}

parse_cfg_file_and_add_path()
{
	
	#CFG_SOURCE_SEARCH_PATHS=""
	#CFG_JAR_SEARCH_PATHS=""
	if [ -z "$1" ]; then
		return 0
	fi

	cfg_filename=${1##*/}

	parse_cfg_web_server_info $1
	
	temp_source_path=`getCFG "Source-Path" $1`
	temp_source_search_path=`getCFG "Source-Search-Path" $1`
	temp_class_path=`getCFG "Class-Path" $1`
	temp_jar_search_path=`getCFG "Jar-Search-Path" $1`
	
	temp_source_search_key=`getCFG "Source-Search-Key" $1`
	
	if [ -n "$temp_source_search_key" ]; then
		SOURCE_SEARCH_KEY=$temp_source_search_key 
	fi
	
	
	if [ -n "$temp_source_path" ]; then		
		if [ -n "$CFG_SOURCE_PATHS" ]; then			
			CFG_SOURCE_PATHS="$CFG_SOURCE_PATHS $temp_source_path"
		else
			CFG_SOURCE_PATHS=$temp_source_path
		fi
	fi

# for j_show_info
	if [ -n "$temp_source_search_path" ]; then
		if [ -n "$CFG_SOURCE_SEARCH_PATHS" ]; then
			CFG_SOURCE_SEARCH_PATHS="$CFG_SOURCE_SEARCH_PATHS $temp_source_search_path" 
		else
			CFG_SOURCE_SEARCH_PATHS=$temp_source_search_path
		fi		
	fi
# ~for j_show_info
	
	cache_file=./${CACHE_DIR}/${cfg_filename%%.cfg}.src.cache
	if [ -n "$temp_source_search_path" ]; then		
		l_java_source_path=""
		getCache=""
		if [ -f ${cache_file} ]; then
			timestamp=`stat -c %Y $1` # get system modified time of cfg file $1 in seconds.
			cache_timestamp=`sed -n 's/timestamp=\(.*\)/\1/p' ${cache_file}`
			if [ "$timestamp" = "$cache_timestamp" ]; then
				l_java_source_path=`sed -n 's/path=\(.*\)/\1/p' ${cache_file}`
				getCache="yes"
				echo "use '${cache_file##*/}' for cache!!"
			fi
		fi
		
		if [ -z "$getCache" ]; then
			l_java_source_path=`parse_source_search_paths $temp_source_search_path`
			echo "timestamp=`stat -c %Y $1`" > ${cache_file}
			echo "path=$l_java_source_path" >> ${cache_file}
		fi

		if [ -n "$l_java_source_path" ]; then
			if [ -n "$JAVA_SOURCE_PATH" ]; then
				JAVA_SOURCE_PATH="$JAVA_SOURCE_PATH:$l_java_source_path"
			else
				JAVA_SOURCE_PATH=$l_java_source_path
			fi
		fi
	else
		if [ -f ${cache_file} ]; then
			rm -f $cache_file > /dev/null
		fi
	fi
	
	if [ -n "$temp_class_path" ]; then
		if [ -n "$CFG_CLASS_PATHS" ]; then			
			CFG_CLASS_PATHS="$CFG_CLASS_PATHS $temp_class_path"
		else
			CFG_CLASS_PATHS=$temp_class_path
		fi		
	fi

# for j_show_info
	if [ -n "$temp_jar_search_path" ]; then
		if [ -n "$CFG_JAR_SEARCH_PATHS" ]; then
			CFG_JAR_SEARCH_PATHS="$CFG_JAR_SEARCH_PATHS $temp_class_path" 
		else
			CFG_JAR_SEARCH_PATHS=$temp_jar_search_path
		fi
	fi
# ~for j_show_info

	cache_file=./${CACHE_DIR}/${cfg_filename%%.cfg}.jar.cache
	if [ -n "$temp_jar_search_path" ]; then		
		l_java_class_path=""
		getCache=""
		if [ -f ${cache_file} ]; then
			timestamp=`stat -c %Y $1`
			cache_timestamp=`sed -n 's/timestamp=\(.*\)/\1/p' ${cache_file}`
			if [ "$timestamp" = "$cache_timestamp" ]; then
				l_java_class_path=`sed -n 's/path=\(.*\)/\1/p' ${cache_file}`
				getCache="yes"
				echo "use '${cache_file##*/}' for cache!!"
			fi
		fi
		
		if [ -z "$getCache" ]; then
			l_java_class_path=`parse_jar_search_paths $temp_jar_search_path`
			echo "timestamp=`stat -c %Y $1`" > ${cache_file}
			echo "path=$l_java_class_path" >> ${cache_file}
 
		fi
		
		if [ -n "$l_java_class_path" ]; then
			if [ -n "$JAVA_CLASS_PATH" ]; then
				JAVA_CLASS_PATH="$JAVA_CLASS_PATH:$l_java_class_path"
			else
				JAVA_CLASS_PATH=$l_java_class_path
			fi
		fi
	else
		if [ -f ${cache_file} ]; then
			rm -f $cache_file > /dev/null
		fi
	fi
	
	#CFG_JAR_SEARCH_PATHS=`sed -n 's/.*Class-Path:[ ]*\(.*\)/\1/p' $1`
	#echo $CFG_SOURCE_SEARCH_PATHS
	#echo $CFG_JAR_SEARCH_PATHS
}

parse_source_search_paths()
{
	out_path=""
	for p in $1;
	do
		temp_path=""

		if [ "${p:0:1}" != "/" ]; then
			p=$BASE_DIR/$p
		fi

		if [ -d $p ]; then
			temp_path=`find_source_search_path $p`
		fi

		if [ -z "$temp_path" ]; then
			continue
		fi	
		
		if [ -n "$out_path" ]; then
			out_path=${out_path}:$temp_path
		else
			out_path=$temp_path
		fi
	done
	echo $out_path
}

parse_jar_search_paths()
{	
	out_path=""
	for p in $1;
	do
		temp_path=""
		
		if [ "${p:0:1}" != "/" ]; then
			p=$BASE_DIR/$p
		fi

		if [ -f $p ]; then
			temp_path=$p
		elif [ -d $p ]; then
			temp_path=`find_jar_path $p`
		fi

		if [ -z "$temp_path" ]; then
			continue
		fi	
		
		if [ -n "$out_path" ]; then
			out_path=${out_path}:$temp_path
		else
			out_path=$temp_path
		fi
	done
	echo $out_path
}

j_add_source_path()
{
	if [ -z "$1" ]; then
		echo "add nothing!!"
		return 0
	fi
	
	JAVA_SOURCE_PATH=$1:$JAVA_SOURCE_PATH
	echo "add path: "
	echo "$JAVA_SOURCE_PATH"
}

j_add_class_path()
{
	if [ -z "$1" ]; then
		echo "add nothing!!" 
		return 0
	fi
	
	JAVA_CLASS_PATH=$1:$JAVA_CLASS_PATH
	echo "add path: "
	echo "$JAVA_CLASS_PATH"
}

parse_cfg_web_server_info()
{
	
	# convert to absolute path
	if [ -z "$WEBAPP_PATH" ]; then
		local temp_webapp_path		
		temp_webapp_path=`getCFG "WebApp-Path" $1`		
		
		if [ -n "$temp_webapp_path" ];then
			if [ "${temp_webapp_path:0:1}" = "/" ]; then
				WEBAPP_PATH=$temp_webapp_path
			else
				WEBAPP_PATH=${PROGDIR}/$temp_webapp_path
			fi
		fi
	fi

	if [ -z "$SERVER_PATH" ]; then
		local temp_webapp_path		
		temp_server_path=`getCFG "Server-Path" $1`		
		
		if [ -n "$temp_server_path" ];then
			if [ "${temp_server_path:0:1}" = "/" ]; then
				SERVER_PATH=$temp_server_path
			else
				SERVER_PATH=${PROGDIR}/$temp_server_path
			fi
		fi
	fi

	if [ -z "$JSP_SOURCE_PATH" ]; then
		local temp_path		
		temp_path=`getCFG "JspSource-Path" $1`
		
		
		if [ -n "$temp_path" ];then
			if [ "${temp_path:0:1}" = "/" ]; then
				JSP_SOURCE_PATH=$temp_path
			else
				JSP_SOURCE_PATH=${PROGDIR}/$temp_path
			fi
		fi
	fi

	if [ -z "$SERVER_TYPE" ]; then		
		SERVER_TYPE=`getCFG "Server-Type" $1`
	fi

	if [ -z "$DEBUG_PORT" ]; then		
		DEBUG_PORT=`getCFG "Debug-Port" $1`
	fi

}

j_ed_cfg()
{
	vi  $PROGDIR/${CFG_FILES[0]}
}

getCFG()
{
	local value
	local AWK_CFG=`cat <<eof
BEGIN {
	FS="\n";
	RS="[^\n:]*:[^\n]*"	;
	ORS="";
	OFS="";
	val=val":";
	
}
{	
	if( savedRT ~ val)
	{
		split(savedRT,a,":");
		if(a[2] != "" )
			print a[2],$0;
		else
			print $0;
	}
	savedRT=RT
}
eof`
	
	value=`sed 's/\([^#]*\)#.*$/\1/g' $2 | awk -v val="$1" -f $PROGDIR/cfg.awk`
	#value=`awk -v val="$1" -f $PROGDIR/cfg.awk $2`
	#value=`awk -v val="$1" $AWK_CFG $2`
	echo $value
}

j_show_info()
{
	echo
	echo '-------------------------------------------------------------'
	echo "Source Path : (JAVA_SOURCE_PATH)" 
	echo  ${JAVA_SOURCE_PATH}
	echo
	echo "Class Path : (JAVA_CLASS_PATH)" 
	echo  ${JAVA_CLASS_PATH}
	echo
	echo "Source Search Path :" 
	echo  ${CFG_SOURCE_SEARCH_PATHS}
	echo
	echo "Class Search Path :" 
	echo  ${CFG_JAR_SEARCH_PATHS}
	echo


	if [ -n "$WEBAPP_PATH" ]; then
		echo
		echo "WebApp Path :" 
		echo  ${WEBAPP_PATH}
	fi

	if [ -n "$SERVER_PATH" ]; then
		echo
		echo "Server Path :" 
		echo "  ${SERVER_PATH}"
	fi

	if [ -n "$SERVER_TYPE" ]; then
		echo
		echo "Server Type :" 
		echo "  ${SERVER_TYPE}"
	fi

	echo
	echo "cfg files :"
	echo ${CFG_FILES[@]}
	
	echo
	echo "CLASSES_DIR=$CLASSES_DIR"
	echo "LIBRARY_DIR=$LIBRARY_DIR"
	echo "SOURCE_DIR=$SOURCE_DIR"
	echo "SOURCE_SEARCH_KEY=$SOURCE_SEARCH_KEY"

	echo '-------------------------------------------------------------'
	echo
}

CFG_SOURCE_PATHS=""
CFG_SOURCE_SEARCH_PATHS=""
CFG_CLASS_PATHS=""
CFG_JAR_SEARCH_PATHS=""

WEBAPP_PATH=""
SERVER_TYPE=""
SERVER_PATH=""
JSP_SOURCE_PATH=""



if [ ! -d ./${CACHE_DIR} ]; then
	mkdir ./${CACHE_DIR}
fi

#CFG_SOURCE_PATHS=`cat ./${CACHE_DIR}/${1%%.cfg}.src.cache`

CFG_FILES=($(echo $@ | sort | uniq))

if [[ ${#CFG_FILES[@]} > 0 ]]; then

	for cfg_file in ${CFG_FILES[@]}; do
		 parse_cfg_file_and_add_path $cfg_file
	done

else
	CFG_FILES=$DEFAUT_CFG_FILES
	parse_cfg_file_and_add_path $CFG_FILES
fi

if [ -n "$SERVER_TYPE" ]; then
	CLASSES_DIR=$WEBAPP_DIR/WEB-INF/classes
	LIBRARY_DIR=$WEBAPP_DIR/WEB-INF/lib
fi

BASE_DIR=${PROGDIR}

out_source_path=`get_absolute_paths ${CFG_SOURCE_PATHS}`
if [ -n "$JAVA_SOURCE_PATH" ]; then
	JAVA_SOURCE_PATH=$out_source_path:$JAVA_SOURCE_PATH
else
	JAVA_SOURCE_PATH=$out_source_path
fi

out_class_path=`get_absolute_paths ${CFG_CLASS_PATHS}`
if [ -n "$JAVA_CLASS_PATH" ]; then
	JAVA_CLASS_PATH=$out_class_path:$JAVA_CLASS_PATH
else
	JAVA_CLASS_PATH=$out_class_path
fi

# set jdb for j_debug

if [ -f $PROGDIR/xjdb_tool/xjdb ]; then
	JDB_CMD=$PROGDIR/xjdb_tool/xjdb
else
	JDB_CMD=jdb
fi

	
export T=${PWD}
