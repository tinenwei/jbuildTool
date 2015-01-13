#usage:
# OUTPUT_DIR for classes path
# CLASS_PATH for library path
# SOURCE_DIR for sources path and paths are concatened by ':'

# SEARCH_LIB_DIR for searching *.jar and dirs are concatened by ':'
# ANT_BUILD_FILE for ant build file
# DIST_JAR_NAME for distribution jar file name

#Location of trees.
ANT_MAKE	:= no
ANT_BUILD_FILE	:= ./build.xml
BASE_DIR	:= .
SOURCE_DIR	:= ./src
OUTPUT_DIR	:= ./bin
SOURCE_DIR_LIST := $(subst :, ,$(SOURCE_DIR))
ALL_JAVAS	:= $(foreach i,$(SOURCE_DIR_LIST), $(shell cd $(i);find . -name '*.java' ! -name 'package-info.java'))
ALL_CLASSES	:= $(addprefix $(OUTPUT_DIR),		\
			$(patsubst ./%,/%,		\
			  $(ALL_JAVAS:.java=.class)))
DIST_DIR 	:= ./dist
DIST_JAR_NAME   := dist.jar

# Linux tools
FIND	:= /usr/bin/find
MKDIR	:= mkdir -p
RM	:= rm -rf

# Java tools
JAVA		:= java
JAVAC		:= javac


CLASS_PATH	?= $(OUTPUT_DIR)
ALL_CLASS_PATH	:= $(CLASS_PATH)

# concatenate jar
SEARCH_LIB_DIR	:= 

ifneq ($(strip $(SEARCH_LIB_DIR)),)	
SEARCH_LIB_DIR_LIST := $(subst :, ,$(SEARCH_LIB_DIR))
ALL_LIB_JARS	:= $(foreach i,$(SEARCH_LIB_DIR_LIST), $(shell find $(i) -name '*.jar'))
noop            :=
space = $(noop) $(noop)
JARS_LIB	:= $(subst $(space),:,$(strip $(ALL_LIB_JARS)))

#$(warning JARS_LIB=$(JARS_LIB))

ifneq ($(strip $(JARS_LIB)),)	

ifdef COMSPEC
ALL_CLASS_PATH	:= $(ALL_CLASS_PATH)\;$(JARS_LIB)
else
ALL_CLASS_PATH	:= $(ALL_CLASS_PATH):$(JARS_LIB)
endif

endif # JARS_LIB is not empty

endif # SEARCH_LIB_DIR  is not empty



JFLAGS		:= -sourcepath $(SOURCE_DIR)	\
	   	   -d $(OUTPUT_DIR)		\
		   -g 				\
	   	   -classpath $(ALL_CLASS_PATH)	


.PHONY: all clean create_dir dist
all : create_dir $(ALL_CLASSES)

create_dir :
	@if [ ! -d $(OUTPUT_DIR) ]; then \
	mkdir -p $(OUTPUT_DIR); \
	fi

#ifeq ("x","y") # comment multi lines
#echo $@
#echo $^
#endif


define java_build
ifeq ($(ANT_MAKE),yes) 
$(OUTPUT_DIR)/%.class : $(1)/%.java
	@ant -f ${ANT_BUILD_FILE} \
	-Dbasedir=$(BASE_DIR) \
	-Ddir.classes=$(ALL_CLASS_PATH) \
	-Ddir.build=$(OUTPUT_DIR) \
	-Ddir.src=$(SOURCE_DIR)	
else	
$(OUTPUT_DIR)/%.class : $(1)/%.java	
	$$(JAVAC) $$(JFLAGS) $$< 
endif
endef

$(foreach i,$(SOURCE_DIR_LIST), $(eval $(call java_build,$(i))))

clean:
	if [ -d $(OUTPUT_DIR) ]; then \
	rm -rf $(OUTPUT_DIR); \
	fi
	if [ -e ${DIST_DIR} ]; then \
	rm -rf ${DIST_DIR} ; \
	fi

dist:
	@for d in $(SOURCE_DIR_LIST); do \
	cd $$d; \
	find . ! -name '*.java' -type f -exec cp --parents -vf {} $(OUTPUT_DIR) \;; \
	cd - >/dev/null ; \
	done
	@if [ ! -d ${DIST_DIR} ]; then \
	mkdir ${DIST_DIR}; \
	fi; 
	jar cf ${DIST_DIR}/$(DIST_JAR_NAME) -C $(OUTPUT_DIR) . 

