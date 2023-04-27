#!/bin/bash
if [[ ! -e 'chainbridge-deploy' ]]; then
    git clone -b v1.0.0 --depth 1 https://github.com/ChainSafe/chainbridge-deploy && cd chainbridge-deploy/cb-sol-cli && npm install && make install
fi
cat <<EOF >configVars
SRC_GATEWAY=https://testnet.xchain.finance/ext/bc/XChain/rpc
DST_GATEWAY=https://api.avax-test.network/ext/bc/C/rpc

SRC_ADDR="0x68a2b5C9E9eaa92aec6DD6cf9a2e0deBE97Dad9f" #<Your address on XCHAIN>
SRC_PK="69fe5f33732b92afa970c814b7b13dc2823ff57220a4093539f2b0d9c4df82ff" #<Your private key on XCHAIN>
DST_ADDR="0x68a2b5C9E9eaa92aec6DD6cf9a2e0deBE97Dad9f"
DST_PK="69fe5f33732b92afa970c814b7b13dc2823ff57220a4093539f2b0d9c4df82ff"

SRC_TOKEN="0x3Ee7094DADda15810F191DD6AcF7E4FFa37571e4"
RESOURCE_ID="0x000000000000000000000000000000c76ebe4a02bbc34786d860b355f5a5ce00"

EOF
source ./configVars;
cb-sol-cli deploy --url $SRC_GATEWAY --privateKey $SRC_PK --gasPrice 25000000000 \
    --bridge --erc20Handler \
    --relayers $SRC_ADDR \
    --relayerThreshold 1 \
    --expiry 500 \
    --chainId 0
read -p "Digite a HEX da Bridge Gerado acima:" SRC_BRIDGE
read -p "Digite a HEX da Erc20 Handler Gerado acima:" SRC_HANDLER
echo "SRC_BRIDGE=\"$SRC_BRIDGE\"" >> configVars
echo "SRC_HANDLER=\"$SRC_HANDLER\"" >> configVars
source ./configVars;
cb-sol-cli bridge register-resource --url $SRC_GATEWAY --privateKey $SRC_PK --gasPrice 25000000000 \
    --bridge $SRC_BRIDGE \
    --handler $SRC_HANDLER \
    --resourceId $RESOURCE_ID \
    --targetContract $SRC_TOKEN
cb-sol-cli deploy --url $DST_GATEWAY --privateKey $DST_PK --gasPrice 25000000000 \
    --bridge --erc20 --erc20Handler \
    --relayers $DST_ADDR \
    --relayerThreshold 1 \
    --chainId 1
read -p "Digite a HEX da Bridge Gerado acima:" DST_BRIDGE
read -p "Digite a HEX da Erc20 Handler Gerado acima:" DST_HANDLER
read -p "Digite a HEX da Erc20 Gerado acima:" DST_TOKEN
echo "DST_BRIDGE=\"$DST_BRIDGE\"" >> configVars
echo "DST_HANDLER=\"$DST_HANDLER\"" >> configVars
echo "DST_TOKEN=\"$DST_TOKEN\"" >> configVars
source ./configVars;
cb-sol-cli bridge register-resource --url $DST_GATEWAY --privateKey $DST_PK --gasPrice 25000000000 \
    --bridge $DST_BRIDGE \
    --handler $DST_HANDLER \
    --resourceId $RESOURCE_ID \
    --targetContract $DST_TOKEN
cb-sol-cli bridge set-burn --url $DST_GATEWAY --privateKey $DST_PK --gasPrice 25000000000 \
    --bridge $DST_BRIDGE \
    --handler $DST_HANDLER \
    --tokenContract $DST_TOKEN
cb-sol-cli erc20 add-minter --url $DST_GATEWAY --privateKey $DST_PK --gasPrice 25000000000 \
    --minter $DST_HANDLER \
    --erc20Address $DST_TOKEN
if [[ ! -e 'chainbridge-deploy' ]]; then
    git clone -b v1.1.1 --depth 1 https://github.com/ChainSafe/chainbridge && cd chainbridge && make build
fi
cd ./chainbridge/build && \
echo "{
  \"chains\": [
    {
      \"name\": \"XCHAIN\",
      \"type\": \"ethereum\",
      \"id\": \"0\",
      \"endpoint\": \"$SRC_GATEWAY\",
      \"from\": \"$SRC_ADDR\",
      \"opts\": {
        \"bridge\": \"$SRC_BRIDGE\",
        \"erc20Handler\": \"$SRC_HANDLER\",
        \"genericHandler\": \"$SRC_HANDLER\",
        \"gasLimit\": \"1000000\",
        \"maxGasPrice\": \"50000000000\",
        \"http\": \"true\",
        \"blockConfirmations\":\"0\"
      }
    },
    {
      \"name\": \"Fuji\",
      \"type\": \"ethereum\",
      \"id\": \"1\",
      \"endpoint\": \"$DST_GATEWAY\",
      \"from\": \"$DST_ADDR\",
      \"opts\": {
        \"bridge\": \"$DST_BRIDGE\",
        \"erc20Handler\": \"$DST_HANDLER\",
        \"genericHandler\": \"$DST_HANDLER\",
        \"gasLimit\": \"1000000\",
        \"maxGasPrice\": \"50000000000\",
        \"http\": \"true\",
        \"blockConfirmations\":\"0\"
      }
    }
  ]
}" >> config.json