import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deployments, ethers } from "hardhat";
import { createProposal } from "../../../test/utils/helpers";
import * as ethersTypes from "ethers";

const { deploy } = deployments;
let deployer: SignerWithAddress;

// //alfajores
// const governanceDelegatorAddress = "0x5c27e2600a3eDEF53DE0Ec32F01efCF145419eDF";
// const proxyAdminAddress = "0x79f9ca5f1A01e1768b9C24AD37FF63A0199E3Fe5";
// const communityAdminProxyAddress = "0x1c33D75bcE52132c7a0e220c1C338B9db7cf3f3A";
// const communityTestAddress = "0xDFFCace49060DFdADF3e28A6125Bf67298F7c88A";


// mainnet
const governanceDelegatorAddress = "0x8f8BB984e652Cb8D0aa7C9D6712Ec2020EB1BAb4";
const proxyAdminAddress = "0xFC641CE792c242EACcD545B7bee2028f187f61EC";
const communityAdminProxyAddress = "0xd61c407c3A00dFD8C355973f7a14c55ebaFDf6F9";
const communityTestAddress = "0xaac71b9ae81d9847e8dc322c42e52ffa76783b39"; //communityId = 200

let newCommunityAdminImplementationAddress: string;
let newCommunityImplementationAddress: string;

let GovernanceProxy: ethersTypes.Contract;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	// @ts-ignore
	// const { deployments, ethers } = hre;

	const accounts: SignerWithAddress[] = await ethers.getSigners();
	deployer = accounts[0];

	GovernanceProxy = await ethers.getContractAt(
		"PACTDelegate",
		governanceDelegatorAddress
	);

	await deployNewCommunityImplementation();
	await deployNewCommunityAdminImplementation();
	await createUpgradeImplementation();
};

async function deployNewCommunityImplementation() {
	console.log("Deploying new contract for Community");

	await new Promise((resolve) => setTimeout(resolve, 6000));
	newCommunityImplementationAddress = (
		await deploy('CommunityImplementation', {
			from: deployer.address,
			args: [],
			log: true,
			// gasLimit: 13000000,
		})
	).address;
}

async function deployNewCommunityAdminImplementation() {
	console.log("Deploying new contract for CommunityAdmin");
	newCommunityAdminImplementationAddress = (
		await deploy('CommunityAdminImplementation', {
			from: deployer.address,
			args: [],
			log: true,
			// gasLimit: 13000000,
		})
	).address;
}
async function createUpgradeImplementation() {
	console.log("Creating new proposal");

	await new Promise((resolve) => setTimeout(resolve, 6000));
	await createProposal(
		GovernanceProxy,
		deployer,
		[
			proxyAdminAddress,
			communityAdminProxyAddress,
			communityAdminProxyAddress,
			communityTestAddress,
		],
		[0, 0, 0, 0],
		[
			"upgrade(address,address)",
			"updateCommunityImplementation(address)",
			"communityListAt(uint256)", //only to check if the update works
			"beneficiaryListAt(uint256)", //only to check if the update works
		],
		[
			["address", "address"],
			["address"],
			["uint256"],
			["uint256"]
		],
		[
			[communityAdminProxyAddress, newCommunityAdminImplementationAddress],
			[newCommunityImplementationAddress],
			[200],
			[20]
		],
		'Upgrade CommunityAdmin implementation and CommunityImplementation'
	);
}

export default func;
func.tags = ["CommunityAdminAndCommunity_upgrade"];
