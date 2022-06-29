const { ethers } = require("hardhat");
const { CRYPTODEVS_NFT_CONTRACT_ADDRESS } = require("../constants");


async function main() {
    // Deploy Fake NFT marketplace
    const FakeNFTMarketplace = await ethers.getContractFactory("FakeNFTMarketplace")
    const fakeNftMarketplace = await FakeNFTMarketplace.deploy()
    await fakeNftMarketplace.deployed()

    console.log("FakeNFTMarketplace deployed to: ", fakeNftMarketplace.address)

    // Deploy CryptoDevsDAO contract

    const CryptoDevsDAO = await ethers.getContractFactory("CryptoDevsDAO");

    const cryptoDevsDAO = await CryptoDevsDAO.deploy(
        fakeNftMarketplace.address,
        CRYPTODEVS_NFT_CONTRACT_ADDRESS,
        {
            // This assumes the account has at least 1 ETH in it's account
            value: ethers.utils.parseEther("1")
        }
    );

    await cryptoDevsDAO.deployed()

    console.log("CryptoDevsDAO deployed to: ", cryptoDevsDAO.address)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1)
    })
