import base64
import json
import requests
import sys
from requests.exceptions import ConnectionError, RequestException, HTTPError

class CONOHA(object):

    _api_user = 'gncu83671683'
    _api_pass = 'H@KiMwRt7wF'
    _tid = 'a392384925e9457bbcab5ece4f1a1fe8'
    _token = ''
    _endpoints = {
        "Account_Service": "https://account.tyo1.conoha.io/v1/" + _tid ,
        "Compute_Service": "https://compute.tyo1.conoha.io/v2/" + _tid,
        "Volume_Service" : "https://block-storage.tyo1.conoha.io/v2/" + _tid,
        "Database_Service" :"https://database-hosting.tyo1.conoha.io/v1" ,
        "Image_Service" : "https://image-service.tyo1.conoha.io",
        "DNS_Service": "https://dns-service.tyo1.conoha.io",
        "Object_Storage_Service": "https://object-storage.tyo1.conoha.io/v1/nc_"+ _tid,
        "Mail_Service" : "https://mail-hosting.tyo1.conoha.io/v1",
        "Identity_Service" : "https://identity.tyo1.conoha.io/v2.0",
        "Network_Service ": "https://networking.tyo1.conoha.io"
    }

    def __init__(self):
        _api = self._endpoints["Identity_Service"]+"/tokens"
        _header = {'Accept': 'application/json'}
        _body = {
                   "auth": {
                       "passwordCredentials": {
                           "username": self._api_user,
                           "password": self._api_pass
                       },
                       "tenantId": self._tid
                 }}
        try:
            _res = requests.post(_api, data=json.dumps(_body), headers=_header)
            self._token = (json.loads(_res.text))["access"]["token"]["id"]
            print(_res)
                   
        except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:
            print('Error: Could not get ConoHa token text.', e)
            sys.exit()
    
    def post(self,endpoint,body):
        _header = {'Accept': 'application/json', 'X-Auth-Token': self.__to}
        try:
            if how=='POST':
                _res = requests.post(endpoint, data=json.dumps(body), headers=_header)
                return json.loads(_res.content)
    
        except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:

            print('Error: Could not get ConoHa flavor uuid.', e)
            sys.exit()
            
    def get(self,endpoint):
        ''' Function of getting Conoha Server Plan ID from Server Plan Name '''
        _header = {'Accept': 'application/json', 'X-Auth-Token': self._token}
        try:
            _res = requests.get(endpoint, headers=_header)
            print(json.loads(_res.content))
        
        except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:

            print('Error: Could not get ConoHa flavor uuid.', e)
            sys.exit()

    def get_example(self):
        endpoint=self._endpoints["Compute_Service"]+'/flavors'
        self.get(endpoint)
        


            


def get_startup_base64(src_path):
    ''' Function of transforming from shell script to base64 value '''
    with open(src_path, encoding='utf-8') as f:
        _script_text = f.read()

    try:
        return base64.b64encode(_script_text.encode('utf-8')).decode()
    except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:
        print('Error: Could not get base64 value of startup script.¥n', e)
        sys.exit()
    

def create_server(tid, sgroup, stag, token, admin_pass, fid, iid, Sval):
    ''' Function of creatting New Server '''
    _api = 'https://compute.tyo1.conoha.io/v2/' + tid + '/servers'
    _header = {'Accept': 'application/json', 'X-Auth-Token': token}
    _body = {"server": {
                "security_groups": [{"name": sgroup}],
                "metadata": {"instance_name_tag": stag},
                "adminPass": admin_pass,
                "flavorRef": fid,
                "imageRef": iid,
                "user_data": Sval
        }}

    try:
        _res = requests.post(_api, data=json.dumps(_body), headers=_header)
        if json.loads(_res.text)['server']:
            print('Success: WordPress new server started!')
    except (ValueError, NameError, ConnectionError, RequestException, HTTPError) as e:
        print('Error: Could not create server.', e)
        sys.exit()
    except KeyError:
        print('Error Code   : {code}¥nError Message: {res}'.format(
                code=_res.text['badRequest']['message'],
                res=_res.text['badRequest']['code']))
        sys.exit()

def main():
    # Get API token
    con=CONOHA()
    con.get_example()
    # Get Flavor UUID
    #Fuuid = get_flavor_uuid(TENANT, Token, FLAVORNAME)

    # Get Flavor UUID
    #Iuuid = get_image_uuid(TENANT, Token, IMAGENAME)

    # Get Base64 value of Startup script
    #Svalue = get_startup_base64(SCRIPTPATH)

    # Create New Server
    #create_server(TENANT, SECGRP, STAG, Token, ROOTPASS, Fuuid, Iuuid, Svalue)
        
if __name__ == '__main__':
    main()
    
