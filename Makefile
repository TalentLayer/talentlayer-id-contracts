#!make
include .env


#--------------FULL INSTALLATION----------------#

install: deploy copy-configuration setup-fakedata

allScripts: deploy copy-configuration setup-allFakeData

#--------------DEPLOY----------------#

deploy: 
	npx hardhat deploy --use-pohmock --use-test-erc20 --network $(DEPLOY_NETWORK)

deploy-verify: 
	npx hardhat deploy --use-pohmock --use-test-erc20 --verify --network $(DEPLOY_NETWORK)

#--------------COPY FILES----------------#


ifeq ($(OS),Windows_NT)
copy-configuration: 
	npx hardhat run scripts/setSubgraphNetwork.ts --network $(DEPLOY_NETWORK)
else
copy-configuration: 
	npx hardhat run scripts/setSubgraphNetwork.ts --network $(DEPLOY_NETWORK)
endif

#--------------PLAYGROUND LOCAL----------------#

wait_localhost = 5
wait_other_network = 60

ifeq ($(DEPLOY_NETWORK),localhost)
	w := $(wait_localhost)
else
	w := $(wait_other_network)
endif


ifeq ($(OS),Windows_NT)
setup-fakedata:
	timeout $(w)
	npx hardhat run scripts/playground/0-mint-platform-ID.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/1-mint-ID.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/2-create-service.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/3-make-proposal.ts --network $(DEPLOY_NETWORK)
else
setup-fakedata:
	sleep $(w)
	npx hardhat run scripts/playground/0-mint-platform-ID.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/1-mint-ID.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/2-create-service.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/3-make-proposal.ts --network $(DEPLOY_NETWORK)
endif

ifeq ($(OS),Windows_NT)
setup-allFakeData:
	timeout $(w)
	npx hardhat run scripts/playground/0-mint-platform-ID.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/1-mint-ID.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/2-create-service.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/2-update-service.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/3-make-proposal.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/4-update-proposal.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/5-reject-proposal.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/6-accept-ETHproposal.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/6-accept-tokenProposal.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/7-payETH.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/7-payToken.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/8-reviews.ts --network $(DEPLOY_NETWORK)
	timeout $(w)
	npx hardhat run scripts/playground/9-claim.ts --network $(DEPLOY_NETWORK)
else
setup-allFakeData:
	sleep $(w)
	npx hardhat run scripts/playground/0-mint-platform-ID.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/1-mint-ID.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/2-create-service.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/2-update-service.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/3-make-proposal.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/4-update-proposal.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/5-reject-proposal.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/6-accept-ETHproposal.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/6-accept-tokenProposal.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/7-payETH.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/7-payToken.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/8-reviews.ts --network $(DEPLOY_NETWORK)
	sleep $(w)
	npx hardhat run scripts/playground/9-claim.ts --network $(DEPLOY_NETWORK)
endif

mint-platformid:
	npx hardhat run scripts/playground/0-mint-platform-ID.ts --network $(DEPLOY_NETWORK)

mint-id:
	npx hardhat run scripts/playground/1-mint-ID.ts --network $(DEPLOY_NETWORK)

create-service:
	npx hardhat run scripts/playground/2-create-service.ts --network $(DEPLOY_NETWORK)

update-service:
	npx hardhat run scripts/playground/2-update-service.ts --network $(DEPLOY_NETWORK)

make-proposal:
	npx hardhat run scripts/playground/3-make-proposal.ts --network $(DEPLOY_NETWORK)

update-proposal:
	npx hardhat run scripts/playground/4-update-proposal.ts --network $(DEPLOY_NETWORK)

reject-proposal:
	npx hardhat run scripts/playground/5-reject-proposal.ts --network $(DEPLOY_NETWORK)

accept-ETHproposal:
	npx hardhat run scripts/playground/6-accept-ETHproposal.ts --network $(DEPLOY_NETWORK)

accept-tokenProposal:
	npx hardhat run scripts/playground/6-accept-tokenProposal.ts --network $(DEPLOY_NETWORK)

pay-ETHproposal:
	npx hardhat run scripts/playground/7-payETH.ts --network $(DEPLOY_NETWORK)

pay-tokenProposal:
	npx hardhat run scripts/playground/7-payToken.ts --network $(DEPLOY_NETWORK)

reviews:
	npx hardhat run scripts/playground/8-reviews.ts --network $(DEPLOY_NETWORK)

claim-balance:
	npx hardhat run scripts/playground/9-claim.ts --network $(DEPLOY_NETWORK)

dispute/setup:
	npx hardhat run scripts/playground/disputeResolution/0-setup.ts --network $(DEPLOY_NETWORK)

dispute/pay-arbitration-fee:
	npx hardhat run scripts/playground/disputeResolution/1-pay-arbitration-fee.ts --network $(DEPLOY_NETWORK)

dispute/create-dispute:
	npx hardhat run scripts/playground/disputeResolution/2-create-dispute.ts --network $(DEPLOY_NETWORK)

dispute/submit-evidence:
	npx hardhat run scripts/playground/disputeResolution/3-submit-evidence.ts --network $(DEPLOY_NETWORK)

dispute/submit-ruling:
	npx hardhat run scripts/playground/disputeResolution/4-submit-ruling.ts --network $(DEPLOY_NETWORK)