const Gachi = artifacts.require("./Gachi.sol");
const Bank = artifacts.require("./Bank.sol")


module.exports = async function (deployer) {
    await deployer.deploy(Gachi);
    const token = await Gachi.deployed();
    await deployer.deploy(Bank, token.address, 200);
};