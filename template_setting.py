'''
   Authentification 
'''
Auth = {
    'TenantID' : '*****************************',
    'TenantName' :  '************',
    'ApiUsername' : '************',
    'ApiPassword' : '************'}

'''
USE api SecutiryGroup Name, ImageName, FlavorsName 
'''
Vpn = {
    'SecurityGroup' : "gncs-******",
    'TagName' : "******tag name of the instance*****", 
    'ImageName' : "** os images***" ,
    'FlavorsName' : "g-1gb",
    'keyname': "key-2018-**-**",
    #'adminPass':'*********',
    'StartScript' : "startup_conoha_SSLH.sh"}

# Copy endpoints from web site.
EndPoints = {
    "AccountService": "https://account.*******/v1/" + Auth["TenantID"],
    "ComputeService": "https://compute.*********/v2/  + Auth["TenantID"],
    "ImageService" : "https://***********.conoha.io",
    "DNSService": "https://**********.conoha.io",
    "IdentityService" : "https://**********/v2.0",
    "NetworkService": "https://****************.io"}

