
#!/bin/bash -l

export LANG=en_US.UTF-8

echo "🌲 ------------- Pod 操作 --------------------"

pod install

echo "🌲 ------------- Pod 完成 --------------------"

#!/bin/sh -l

echo "☁️ ------------- 构建开始 --------------------"


echo "🌰 ------------- 获取材料 --------------"

#本机 Mac 的用户名
sys_username="xx"
#Jenkins 构建的任务名
jenkinsName=${JOB_NAME}
# 工程名
APP_NAME="xx"
#scheme名
SCHEME_NAME="xx"
#bundleID
BundleID=com.xxx.xx


#工程绝对路径
project_path="/Users/${sys_username}/.jenkins/workspace/${jenkinsName}"
#时间
DATE="$(date +%Y-%m-%d-%H-%M-)"
#info.plist路径
project_infoplist_path="./${APP_NAME}/Info.plist"

#buglys 命令行工具路径
buglyPath=/Users/${sys_username}/Desktop/buglySymboliOS


#取版本号(不是build值)
bundleShortVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" "${project_infoplist_path}")

#取build值
#修改ipa的版本号，和jenkins编译的号码相同
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "${project_infoplist_path}"

bundleVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" "${project_infoplist_path}")

echo "bundle Verision:${bundleVersion} Jenkins Build: $BUILD_NUMBER "




#导出.ipa文件所在路径
exportFilePath=/Users/${sys_username}/Desktop/iOS_IPA/${APP_NAME}/${Mode}/${bundleShortVersion}.${bundleVersion}

#build文件夹路径,和 IPA 同目录下
build_path=${exportFilePath}
#build_path=/Users/${sys_username}/Desktop/build/${development_mode}/${bundleShortVersion}.${bundleVersion}/


#要上传的ipa文件路径
IPA_PATH=${exportFilePath}/${APP_NAME}.ipa

echo "🔑 ------------- 配置证书 ----------------"
#配置环境，Release或者Snapshot
#Release模式打包AppStore正式版;
if [ "$Mode" = "Release" ];then
   echo "🍃🍃🍃  Mode 为 Release 🍃🍃🍃"

development_mode=Release
CODE_SIGN_DISTRIBUTION="iPhone Distribution: xxxx"
exportOptionsPlist_path="/Users/${sys_username}/Desktop/exportPlistPath/ExportOptions-xxx.plist"

fi

#Snapshot(基于release)模式打包Development测试版
if [ "$Mode" = "Snapshot" ];then
   echo "🍃🍃🍃  Mode 为 Snapshot 🍃🍃🍃"
   
development_mode=Snapshot
CODE_SIGN_DISTRIBUTION="iPhone Developer: xxxx"
exportOptionsPlist_path="/Users/${sys_username}/Desktop/exportPlistPath/ExportOptionsDevelop-xxx.plist"
fi

#//下面2行是没有Cocopods的用法
#echo "=================clean================="
#xcodebuild -target "${APP_NAME}"  -configuration 'Release' clean
#
#echo "+++++++++++++++++build+++++++++++++++++"
#xcodebuild -target "${APP_NAME}" -sdk iphoneos -configuration 'Release' CODE_SIGN_IDENTITY="${CODE_SIGN_DISTRIBUTION}" SYMROOT='$(PWD)'

#//下面2行是集成有Cocopods的用法
echo "🏎️🏎️ =================clean=================  🏎️🏎️ "
 
xcodebuild -workspace "${APP_NAME}.xcworkspace" -scheme "${APP_NAME}"  -configuration ${development_mode} clean


#xcodebuild -workspace "${APP_NAME}.xcworkspace" -scheme "${APP_NAME}" -sdk iphoneos -configuration ${development_mode}
#CODE_SIGN_IDENTITY="${CODE_SIGN_DISTRIBUTION}" SYMROOT='$(PWD)'


echo "🚗🚗🚗 *** 正在 编译工程 For ${development_mode} 🚗🚗🚗"
xcodebuild \
archive -workspace ${project_path}/${APP_NAME}.xcworkspace \
-scheme ${SCHEME_NAME} \
-configuration ${development_mode} \
-archivePath ${build_path}/${APP_NAME}.xcarchive -quiet  || exit

echo '✅ *** 编译完成 ***'


echo '🚄 ***************** 正在 打包  ***************** 🚄 '

xcodebuild -exportArchive -archivePath ${build_path}/${APP_NAME}.xcarchive \
-exportPath ${exportFilePath} \
-exportOptionsPlist ${exportOptionsPlist_path} \
-allowProvisioningUpdates \
-quiet || exit


if [ -e ${exportFilePath}/${APP_NAME}.ipa ]; then
#if [ -e ${IPA_PATH} ]; then
echo "✅ *** .ipa文件已导出 ***"

#open $exportFilePath
echo $exportFilePath

else
echo "❌ *** 创建.ipa文件失败 ***"
fi


echo '📦  *** 打包完成 ***'



if [ "$Mode" = "Snapshot" ];then
   echo "🚀 上传蒲公英 ++++++++++++++upload+++++++++++++"
   
#User Key
uKey="xxx"
#API Key
apiKey="xxx"
#执行上传至蒲公英的命令
curl -F "file=@${IPA_PATH}" -F "uKey=${uKey}" -F "_api_key=${apiKey}" http://www.pgyer.com/apiv1/app/upload
   
   echo "✅ Finsh - 蒲公英上传完毕"
fi

if [ "$Mode" = "Release" ];then
echo "📝 ------------Release 增加 Git Tag ----------"


#echo "-------- 查看当前分支 --------"
#git branch -a

#echo "-------- 切换选择的分支 --------"

#git checkout ${Branch}

echo "--------- 当前 Tag -----------"
git tag


echo "--------- 打 Tag ------------"
GitTag=V${bundleShortVersion}_${bundleVersion}


git tag -a ${GitTag} -m "Tag:${GitTag} "

echo "Tag ${GitTag}"


#推送标签
#推送本地全部标签 git push origin --tags
git push origin ${GitTag}

echo "✅ ----------- Git Tag 推送完毕 ----------"

#TODO 需要解决 Jenkins GIT 游离态问题
#cut="$Branch"
#echo ${cut#*/}
#shell 截取字符串
#branch_name=${cut#*/}
#echo "🔥 --- $branch_name"
#commitID=$(git rev-parse --short HEAD)
#根据提交建立新分支
#git checkout branch temp $commitID
#echo "---------- 提交 git 版本修改"
#git add .
#git commit -m "Build->${bundleVersion}"

fi




echo " 📦 ------ 开始符号表 相关工作 ------"

cd $exportFilePath/${APP_NAME}.xcarchive/dSYMs/
zip -r $exportFilePath/${APP_NAME}.dSYM.zip ${APP_NAME}.app.dSYM

echo " ✅ 压缩完成 "



echo " ©️ ----- 上传符号表 ------- ©️"

if [ "$Mode" = "Snapshot" ];then
   echo "🚀  Bugly Snapshot 测试版本符号表"
   buglyID=xxx
   buglyKey=xxxx
fi

if [ "$Mode" = "Release" ];then
   echo "🚀  Bugly Release 正式版本符号表"
   buglyID=xxx
   buglyKey=xxx
fi

dSYMPath=$exportFilePath/${APP_NAME}.xcarchive/dSYMs/
cd $buglyPath 

echo "----- 开始上传符号表 ---------- "
java -jar buglySymboliOS.jar \
-i ${dSYMPath}/${APP_NAME}.app.dSYM \
-u -id ${buglyID} \
-key  ${buglyKey} \
-package ${BundleID} \
-version ${bundleShortVersion}

echo "✅ ---------- 上传符号表完毕 ------"

