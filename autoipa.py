# -*- coding: utf-8 -*-
import os
import sys
import time
import hashlib
from email import encoders
from email.header import Header
from email.mime.text import MIMEText
from email.utils import parseaddr, formataddr
import smtplib

# 项目根目录
#/Users/xx/project"
project_path = "" 
#profile文件名  xcode获取
app_profile=""
#对应的证书 生产/开发（keychain获取）
app_codesignIdentity=""
#app的target,一般来说，target和scheme相同
app_target=""
#app的scheme
app_scheme=""
# 指定项目下编译目录
build_path = "build"
#app_name...xxx.app，有时候appname会更改，和Target不同，会导致无法导出
app_name="xxx.app"
# 编译成功后.app所在目录 
app_path = '%s/%s/Build/Products/Release-iphoneos/%s'%(project_path,build_path,app_name)

#configuration debug/release/AdHoc
#Debug=True
Debug=False

# 打包后ipa存储目录
targerIPA_parth = ""

# fir.im的api token
fir_api_token = ""

# 第三方 SMTP 服务
mail_host=""  #设置服务器
mail_user=""    #用户名
mail_pass=""   #口令

sender = ''
# 接收邮件组，可设置为你的QQ邮箱或者多个其他邮箱
receivers = ['','']  




#显示已有的参数
def showParameter():
    print "targetName                 :%s"%app_target
    #print "gitPath                    :%s"%gitPath
    print "certificateName            :%s"%app_profile
    print "firToken                   :%s"%fir_api_token
    print "emailFromUser              :%s"%emailFromUser
    print "emailToUser                :%s"%mail_user
    print "emailPassword              :%s"%mail_pass
    print "emailHost                  :%s"%mail_host
   #print "keychainPassword(Optional) :%s"%keychainPassword
    
#设置参数
def setParameter():
    global targetName
    global tempFinder
    global mainPath
    global gitPath
    global certificateName
    global firToken
    global emailFromUser
    global emailToUser
    global emailPassword
    global emailHost
    global keychainPassword
    targetName = raw_input("input targetName:")
    if not isNone(targetName):
        m = hashlib.md5()
        m.update('BossZP')
        tempFinder = m.hexdigest()
        mainPath = commendPath + 'Documents' + '/' + tempFinder
    gitPath = raw_input("input gitPath:")
    certificateName = raw_input("input certificateName:")
    firToken = raw_input("input firToken:")
    emailFromUser = raw_input("input emailFromUser:")
    emailToUser = raw_input("input emailToUser:")
    emailPassword = raw_input("input emailPassword:")
    emailHost = raw_input("input emailHost:")
    #keychainPassword = raw_input("input keychainPassword:")
    #保存到本地
    writeJsonFile()

#判断字符串是否为空
def isNone(para):
    if para == None or len(para) == 0:
        return True
    else:
        return False

#写json文件
def writeJsonFile():
    showParameter()
    try:
        fout = open(commendFilePath,'w')
        js = {}
        js["targetName"] = targetName
        js["gitPath"] = gitPath
        js["certificateName"] = certificateName
        js["firToken"] = firToken
        js["emailFromUser"] = emailFromUser
        js["emailToUser"] = emailToUser
        js["emailPassword"] = emailPassword
        js["emailHost"] = emailHost
        js["tempFinder"] = tempFinder
        js["mainPath"] = mainPath
        js["keychainPassword"] = keychainPassword
        outStr = json.dumps(js,ensure_ascii = False)
        fout.write(outStr.strip().encode('utf-8') + '\n')
        fout.close()
    except Exception,e:
        print Exception
        print e



# 清理项目 创建build目录
def clean_project_mkdir_build():
    os.system('cd %s;xcodebuild clean' % project_path) # clean 项目
    os.system('cd %s;mkdir build' % project_path)

def build_project():
    print("build release start")
    os.system ('xcodebuild -list')
    #release/debug
    if Debug:
        os.system ('cd %s;xcodebuild -workspace %s.xcworkspace  -scheme %s -configuration debug -derivedDataPath %s ONLY_ACTIVE_ARCH=NO || exit' % (project_path,app_target,app_scheme,build_path))
    else:
        os.system ('cd %s;xcodebuild -workspace %s.xcworkspace  -scheme %s -configuration release CODE_SIGN_IDENTITY=%s APP_PROFILE=%s -derivedDataPath %s ONLY_ACTIVE_ARCH=NO || exit' % (project_path,app_target,app_scheme,app_codesignIdentity,app_profile,build_path))
# CONFIGURATION_BUILD_DIR=./build/Release-iphoneos

# 打包ipa 并且保存在桌面
def build_ipa():
    global ipa_filename
    ipa_filename = time.strftime('xx_%Y-%m-%d-%H-%M-%S.ipa',time.localtime(time.time()))
    os.system ('xcrun -sdk iphoneos PackageApplication -v %s -o %s/%s'%(app_path,targerIPA_parth,ipa_filename))
#上传
def upload_fir():
    if os.path.exists("%s/%s" % (targerIPA_parth,ipa_filename)):
        print('watting...')
        # 直接使用fir 有问题 这里使用了绝对地址 在终端通过 which fir 获得
        ret = os.system("/usr/local/bin/fir p '%s/%s' -T '%s'" % (targerIPA_parth,ipa_filename,fir_api_token))
    else:
        print("没有找到ipa文件")

def _format_addr(s):
    name, addr = parseaddr(s)
    return formataddr((Header(name, 'utf-8').encode(), addr))

# 发邮件
def send_mail():
    print("开始发送邮件")
    message = MIMEText('iOS测试项目已经打包完毕，请前往 http://fir.im/GoSpark 下载测试！', 'plain', 'utf-8')
    message['From'] = Header("zzgo <zzgoCC@gmail.com>", 'utf-8')
    message['To'] =  Header("river <river@quseit.com>", 'utf-8')  # 昵称

    subject  = '测试邮件'
    message['Subject'] = Header(subject, 'utf-8')


    try:
        smtpObj = smtplib.SMTP()
        smtpObj.connect(mail_host, 25)    # 25 为 SMTP 端口号
        smtpObj.login(mail_user,mail_pass)
        smtpObj.sendmail(sender, receivers, message.as_string())
        #   server.quit()
        print str(time.localtime(time.time())) + "send email Success!"
    except smtplib.SMTPException:
        print str(datetime.date.today()) + "Error"
 


def main():
    # 清理并创建build目录
    clean_project_mkdir_build()
    # 编译coocaPods项目文件并 执行编译目录
    build_project()
    # 打包ipa 并制定到桌面
    build_ipa()
    # 上传fir
    upload_fir()
    # 发邮件
    send_mail()

# 执行
main()










