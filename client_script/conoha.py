#
#  Auto Create a Instance at Conoha VPS
#  1. API-user/password Information should be in written 
#    properly in ./setting.py.
#  Auth: darkqueen

import sys
import requests
import base64
import json
from requests.exceptions import HTTPError, RequestException, ReadTimeout

#
#  
# 
class CONOHA(object):
    import setting as __setting
    __endpoints = __setting.EndPoints
    __auth = __setting.Auth
    __vpn = __setting.Vpn      
    
    def __init__(self):

        self._create_token = self.__endpoints["IdentityService"] + "/tokens"
        self._token = ''
        self._headers = {'Accept': 'application/json'}
    
        _body = {
                   "auth": {
                       "passwordCredentials": {
                           "username": self.__auth["ApiUsername"],
                           "password": self.__auth["ApiPassword"]},
                       "tenantId": self.__auth["TenantID"]}}

        try:
            _res = requests.post(self._create_token, data=json.dumps(_body), headers=self._headers)
            self._token = (json.loads(_res.text))["access"]["token"]["id"]
            
            # Fetching token information to the headers.
            self._headers = {'Accept': 'application/json', 'X-Auth-Token': self._token}
            print('Authentification Token is Successfully Recived. ')
                   
        except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:
            print('Error: Could not get ConoHa token text.', e)
            sys.exit()
    
    # post
    def post(self,endpoint,body):
        '''
        standerd post method :
        '''
        try:
            __res = requests.post(endpoint, data=json.dumps(body), headers=self._headers)
            return json.loads(__res.content)
    
        except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:
            print('Error: Post', e)
            sys.exit()

    # delete (access error)
    def delete(self,endpoint):
        try:
            __res = requests.delete( endpoint, headers=self._headers)
            return  __res

        except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:
            print('Error: GET', e)
            sys.exit()

    # get 
    def get(self,endpoint):
        '''
        standerd get method :
        '''
        try:
            __res = requests.get(endpoint, headers=self._headers)
            return json.loads(__res.content)

        except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:
            print('Error: GET', e)
            sys.exit()

    #
    #  list of flavor names
    #
    def dump_flavors(self):
        '''
        dump flavors information
        '''
        __endpoint = self.__endpoints["ComputeService"]+'/flavors/detail'
        __res = self.get(__endpoint)
        print(json.dumps(__res, indent=2, sort_keys=True))

    #
    # list of images 
    def dump_images(self):
        '''
        dump images information
        '''
        __endpoint = self.__endpoints["ComputeService"]+'/images/detail'
        __res=self.get(__endpoint)
        print(json.dumps(__res, indent=2, sort_keys=True))

    #
    # security group
    #
    def dump_security_group(self):
        '''
        dump security group
        '''
        __endpoint = self.__endpoints["NetworkService"]+ '/v2.0/security-groups'
        __res=self.get(__endpoint)
        print(json.dumps(__res, indent=2, sort_keys=True))

    def get_keyname(self):
        return self.__vpn["keyname"]

    def get_tagname(self):
        return self.__vpn["TagName"]

    def get_security_name(self):
        return self.__vpn["SecurityGroup"]

    def get_security_uuid(self, security_name=None):
        ''' UUID of the security (HTTP port setting) whose name is specified in the setting file.'''
        __endpoint = self.__endpoints["NetworkService"] + '/v2.0/security-groups'
        
        if security_name is None:
            security_name = self.__vpn["SecurityGroup"]
        try:
            __json_list = self.get(__endpoint)["security_groups"] 
            for __dict in __json_list:
                if __dict['name'] == security_name:
                    return __dict['id']

        except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:
            print('Error GET', e)
            sys.exit()

    def get_flavor_uuid(self, flavorname=None):
        ''' UUID of the flavor (system setting) whose name is specified in the setting file.'''
        __endpoint = self.__endpoints["ComputeService"] + '/flavors/detail'
        if flavorname is None:
            flavorname = self.__vpn["FlavorsName"]
        try:
            __json_dict = self.get(__endpoint)['flavors'] 
            for _flavor_dict in __json_dict:
                if _flavor_dict['name'] == flavorname:
                    return _flavor_dict['id']

        except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:
            print('Error GET', e)
            sys.exit()

    def del_my_public_key(self,keytag):
        _endpoint = self.__endpoints["ComputeService"] + 'os-keypairs/' + keytag
        self.delete(_endpoint)
        

    def push_my_public_key(self, keytag, path_name):
        __endpoint = self.__endpoints["ComputeService"] + '/os-keypairs'

        if (path_name is None) or ( keytag is None):
            print('First, create your key in your local machine.')
            raise ValueError("Please set public keyname path.")
        
        with open(path_name, 'r') as content_file:
            pubkey_content = content_file.read()
            pubkey_content = pubkey_content.rstrip("\n")

        __body = {  
            "keypair": {
                'name': keytag,
                "public_key":pubkey_content
        }}
        
        _res = self.post(__endpoint, __body)
        print(_res)
        return _res

    def get_server_info(self):
        __endpoint = self.__endpoints["ComputeService"] + '/servers/detail'
        try:
            __json_dict = self.get(__endpoint)['servers']
            return( __json_dict)
        except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:
            print('Error GET', e)
            sys.exit()     

    def get_image_uuid(self, imagename=None):
        ''' UUID of the image whose name is specified in the setting_file.'''
        __endpoint = self.__endpoints["ComputeService"] + '/images/detail'
        if imagename is None:
            imagename = self.__vpn["ImageName"]
        try:
            __json_dict = self.get(__endpoint)['images'] 
            for _flavor_dict in __json_dict:
                if _flavor_dict['name'] == imagename:
                    return _flavor_dict['id']

        except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:
            print('Error GET', e)
            sys.exit()     
    
    def get_adminPass(self):
        if self.__vpn["adminPass"] == '':
            return None
        else:
            return self.__vpn["adminPass"]


    def get_startup_base64(self, src_path=None):
        ''' Convert startup script into base64-form
            Arg: src_path: path to the startup script
            Rtn: base64 encorded 
        '''
        if src_path is None:
            src_path = self.__vpn['StartScript']

        with open(src_path, encoding='utf-8') as f:
            _script_text = f.read().rstrip("\n")
        try:
            return base64.b64encode(_script_text.encode('utf-8')).decode()
        except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:
            print('Error: Could not get base64 value of startup script.¥n', e)
            sys.exit()

    def create_server(self, flavor_uuid,
                      image_uuid,
                      adminPass=None,
                      startup_base64=None,
                      security_group=None, 
                      key_name=None,
                      tag_name=None):
        ''' Boot new server :
            Arg: flavor_uuid 
                 images_uuid
                 adminPass : root Password for console login. If None, random. 
                 startup_base64: Startup file in the form of base64 encorded.
                 security_group:  
                 key_name: login key name
                 tag_name: server name shown on the web console 
        '''
        __endpoint = self.__endpoints['ComputeService'] + '/servers'

        __basic = { "imageRef": image_uuid,
                    "flavorRef": flavor_uuid}

        if adminPass is not None:
            __basic["adminPass"] = adminPass
        if startup_base64 is not None:
            __basic["user_data"] = startup_base64
        if security_group is not None:
            __basic["security_groups"]=[{"name": security_group}]
        if key_name is not None:
            __basic["key_name"] = key_name
        if tag_name is not None:
            __basic["metadata"] = {"instance_name_tag": tag_name}
        _body = {"server": __basic}

        try:
            _res = requests.post(__endpoint, data=json.dumps(_body), headers=self._headers)
            print('Response:',_res)
            print('Check Web Console If New Server Is Instanciated. ')
            return _res
        except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:
            print('Error: Could not get base64 value of startup script.¥n', e)
            sys.exit()            


def main():
    con = CONOHA()
    _security_group = con.get_security_name()
    _flavor_uuid = con.get_flavor_uuid()
    _image_uuid = con.get_image_uuid()
    _startup_base64 = con.get_startup_base64()
    _keyname = con.get_keyname()
    _tag_name= con.get_tagname()
    _adminPass = con.get_adminPass()
    print('flavor uuid:', _flavor_uuid)
    print('start up: ', _startup_base64)
    print('image uuid: ', _image_uuid)
    # print('security group: ', _security_group)
    res = con.create_server(
        security_group= _security_group, 
        adminPass= _adminPass,
        key_name= _keyname,
        flavor_uuid =  _flavor_uuid,
        image_uuid = _image_uuid,
        startup_base64 = _startup_base64,
        tag_name=_tag_name)
        
    print(res)
    # show info
    res=con.get_server_info()
    print(res)

def push_new_key(new_key_name):
     con=CONOHA()
     con.push_my_public_key(new_key_name,'id_rsa.pub')

if __name__ == '__main__':
    # to push new key, copy key.pub in the same directory.
    #push_new_key('mykey')
    main()
