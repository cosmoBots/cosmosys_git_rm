#!/usr/bin/python3
"""
Script that creates Personal Access Token for Gitlab API;
Tested with:
- Gitlab Community Edition 10.1.4
- Gitlab Enterprise Edition 12.6.2
- Gitlab Enterprise Edition 13.4.4

Thanks to https://github.com/vitalyisaev2/gitlab_token

"""
import sys
import requests
from urllib.parse import urljoin
from bs4 import BeautifulSoup
import os

endpoint = "http://gitlab"
root_route = urljoin(endpoint, "/")
sign_in_route = urljoin(endpoint, "/users/sign_in")
pat_route = urljoin(endpoint, "/-/profile/personal_access_tokens")

login = "root"
login_bot = "cosmobots"
password = "cosmobotsDeployPassGIT"
password_bot = "cosmobotsDeployPassGIT"

def find_csrf_token(text):
    soup = BeautifulSoup(text, "lxml")
    token = soup.find(attrs={"name": "csrf-token"})
    param = soup.find(attrs={"name": "csrf-param"})
    data = {param.get("content"): token.get("content")}
    return data


def obtain_csrf_token():
    r = requests.get(root_route)
    token = find_csrf_token(r.text)
    return token, r.cookies


def obtain_authenticity_token(cookies):
    r = requests.get(pat_route, cookies=cookies)
    soup = BeautifulSoup(r.text, "lxml")
    token = soup.find('input', attrs={'name': 'authenticity_token', 'type': 'hidden'}).get('value')
    return token


def sign_in(csrf, cookies,thislogin,thispassword):
    data = {
        "user[login]": thislogin,
        "user[password]": thispassword,
        "user[remember_me]": 0,
        "utf8": "✓"
    }
    data.update(csrf)
    r = requests.post(sign_in_route, data=data, cookies=cookies)
    token = find_csrf_token(r.text)
    return token, r.history[0].cookies


def obtain_personal_access_token(name, expires_at, csrf, cookies, authenticity_token):
    data = {
        "personal_access_token[expires_at]": expires_at,
        "personal_access_token[name]": name,
        "personal_access_token[scopes][]": "api",
        "authenticity_token": authenticity_token,
        "utf8": "✓"
    }
    data.update(csrf)
    r = requests.post(pat_route, data=data, cookies=cookies)
    soup = BeautifulSoup(r.text, "lxml")
    thistoken = soup.find('input', id='created-personal-access-token').get('value')
    return thistoken


import gitlab
import yaml

def main():
    csrf1, cookies1 = obtain_csrf_token()
    print("root", csrf1, cookies1,login,password)
    csrf2, cookies2 = sign_in(csrf1, cookies1,login,password)
    print("sign_in", csrf2, cookies2,login,password)
    authenticity_token = obtain_authenticity_token(cookies2)

    name = 'cosmosys' # sys.argv[1]
    expires_at = '' # sys.argv[2]
    token = obtain_personal_access_token(name, expires_at, csrf2, cookies2, authenticity_token)
    print("gitlab root user token:",token)

    gl = gitlab.Gitlab(endpoint, api_version=4, private_token=token)

    print("Using Gitlab API with user",login)
    user = None
    print("BEGIN - Gitlab user list")
    for u in gl.users.list():
        print(u)
        if (u.username == login_bot):
            print("the bot user exists with ID",u.id)
            user = u

    print("END - Gitlab user list")
    gl.auth()
    rootuser = gl.user

    print("We need to revoke the previous cosmosys tokens for the root user, and to keep the last one")
    access_tokens = gl.personal_access_tokens.list(user_id=rootuser.id)
    print("BEGIN access tokens for boot user with ID",rootuser.id)
    tokens_to_revoke = []
    for at in access_tokens:
        print("access_token",at.name,at.id)
        if (at.name == name):
            print("The access token exists, we revoke it",at)
            tokens_to_revoke += [at.id]

    # We need to revoke all the ids in the list except the last one
    print(tokens_to_revoke)
    tokens_to_revoke.sort()
    print(tokens_to_revoke)
    tokens_to_revoke = tokens_to_revoke[:-1]
    print(tokens_to_revoke)

    for tkid in tokens_to_revoke:
        comando = "curl --request DELETE --header \"PRIVATE-TOKEN: "+token+"\" \""+endpoint+"/api/v4/personal_access_tokens/"+str(tkid)+"\""
        print(comando)
        os.system(comando)


    print("Root user dump:",rootuser)
    
    if (user is None):
        print("Let's proceed creating the boot user:",login_bot)
        user = gl.users.create({'email': 'cosmobots@cosmobots.eu',
                                'password': password_bot,
                                'username': login_bot,
                                'skip_confirmation': True,
                                'name': 'cosmoBots.eu BOT'})

        print("UserID created",user.id)
    else:
        print("Using pre-existing user with UserID",user.id)
    
    print("bot user dump:",dir(user))

    print("We need to revoke the cosmosys token for the bot user, and to generate a new one")
    access_tokens = gl.personal_access_tokens.list(user_id=user.id)
    print("BEGIN access tokens for boot user with ID",user.id)
    for at in access_tokens:
        print(at.name)
        if (at.name == name):
            print("The access token exists, we revoke it")
            # at.delete()
            comando = "curl --request DELETE --header \"PRIVATE-TOKEN: "+token+"\" \""+endpoint+"/api/v4/personal_access_tokens/"+str(at.id)+"\""
            print(comando)
            os.system(comando)

    print("END access tokens for boot user with ID",user.id)

    print("Process to obtain the access_token for user ",login_bot)
    csrf1b, cookies1b = obtain_csrf_token()
    print("bot user csrf", csrf1b, cookies1b,login_bot,password_bot)
    csrf2b, cookies2b = sign_in(csrf1b, cookies1b,login_bot,password_bot)
    print("bot user sign_in csrf", csrf2b, cookies2b)
    authenticity_tokenb = obtain_authenticity_token(cookies2b)
    print("bot user authenticity token", authenticity_tokenb)

    print("Let's obtain the personal access token named",name,"for user",login_bot)
    token_bot = obtain_personal_access_token(name, expires_at, csrf2b, cookies2b, authenticity_tokenb)
    print("El token que he obtenido es",token_bot)

    configyaml = {
        'endpoint' : endpoint,
        'roottoken' : token,
        'username' : 'cosmobots',
        'userpass' : 'cosmobotsDeployPassGIT',
        'authtokenname' : name,
        'authtoken' : token_bot
    }

    print("Voy a crear el fichero con este contenido",configyaml)

    with open("~/gitlabapicfg.yaml", "w") as fh:
        yaml.dump(configyaml, fh)
    
    k = user.keys.create({'title': 'cosmosys',
        'key': open('~/.ssh/id_rsa.pub').read()})  

    # This is for forgetting ensuring git is able to stablish the authenticity of the gitlab host
    # See https://serverfault.com/questions/132970/can-i-automatically-add-a-new-host-to-known-hosts
    os.system('ssh-keyscan -H gitlab >> ~/.ssh/known_hosts')
    

if __name__ == "__main__":
    main()


