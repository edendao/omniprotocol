#!/usr/bin/env bash

# Read the Rinkeby RPC URL
echo ">>>> Make sure to have the .env.{chain} properly configured!"
echo -n "What chain do you want to deploy to? "
read chain

source ".env.${chain}"

# Read the contract name
echo -n "Which contract do you want to deploy? "
read contract

# Read the constructor arguments
echo -n "Enter constructor arguments separated by spaces: "
read -ra args

forge create ./src/${contract}.sol:${contract} --constructor-args ${args}
