What is jbuildTool
=============
jbuildTool is written in bash shell script.  
It use shell commands to build java source codes.  
and you can use commands to debug and run projects.  
Adding classpath and sourcepath in IDE is cumbersome.  
jbuildTool use "find" command to handle this.  

How to use?
=============
Install the prerequisite: gawk.  
Copy ./cfg/empty.cfg to ./cfg/xxx.cfg and edit your desired the paths of libraries and source in ./cfg/xxx.cfg.
in the directory of jbuildTool, execute the following command:  

    . env.sh cfg/xxx.cfg

Start a new project by executing the following command:

    j_new_app

This command will ask you to enter 'Directory Name', 'Package Name' and 'Main-Class'.  
('Main-Class' doesn't contain package name)  
for example:  

    Directory Name: Test
    Package Name: com.example.test
    Main-Class: MyTest

After entering these, it will create a template of "hello world" project.
Execute the following command:

    j_build 

For running the program, executing the following command:

    j_run

For debugging the program, executing the following command:

    j_debug

for cleaning the projects, executing the following command:

    j_clean


./jbuildTool/xxx.cfg is a top cfg file for the general paths of libaries and source codes.
For the current project, you can use ./project.cfg in the directory of current project to 
define your desired path of libraries and source codes.   
The example for cfg files is in ./cfg/jetty_7.6.12.cfg and ./cfg/spring_3.0.7.cfg.  
You can use j_new_war_app to start a servlet application. (see ./cfg/jetty_7.6.12.cfg)   
You can use j_new_jni_app to start a jni java project.




