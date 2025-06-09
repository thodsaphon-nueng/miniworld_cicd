#!/bin/bash

vault auth enable userpass
vault policy write dev-policy /config_vault/dev-policy.hcl
vault write auth/userpass/users/devuser password="devpass" policies="dev-policy"
vault login -method=userpass username=devuser password=devpass

vault auth enable approle
vault policy write jenkins-policy /config_vault/jenkins-policy.hcl
vault write auth/approle/role/jenkins-role token_policies="jenkins-policy" token_ttl=1h token_max_ttl=4h
vault read auth/approle/role/jenkins-role/role-id
vault write -f auth/approle/role/jenkins-role/secret-id