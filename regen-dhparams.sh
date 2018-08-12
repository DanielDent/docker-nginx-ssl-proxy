#!/bin/sh

openssl dhparam -inform PEM -in dhparams.pem -check -text
openssl dhparam -out dhparams.pem 2048
openssl dhparam -inform PEM -in dhparams.pem -check -text
