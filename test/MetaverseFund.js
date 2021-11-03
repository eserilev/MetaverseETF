const { expect } = require("chai");
const { ethers } = require("hardhat");

const GWEI = ethers.BigNumber.from(10).pow(8);

describe("Metaverse Fund contract", function () {
    let owner, token, fund, operator;
    before(async function() {
        [owner] = await ethers.getSigners();

        const MetaverseFundToken = await ethers.getContractFactory("MetaverseFundToken");
        const MetaverseFund = await ethers.getContractFactory("MetaverseFund");
        const MetaverseFundOperator = await ethers.getContractFactory("MetaverseFundOperator");
        
        fund = await MetaverseFund.deploy();

        token = await MetaverseFundToken.deploy();
        operator = await MetaverseFundOperator.deploy();

        // let adminRole = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("ADMIN_ROLE"));

        // await token.grantRole(adminRole, fund.address);
    });

    it("Add token address to fund", async function () {

        await fund.addToken(token.address);

        expect(await fund.token()).to.equal(token.address);
    });
    it("Update price", async function() {

        let numerator = 1;
        let denominator = 100000;
        await fund.updatePrice(numerator,denominator);
        
        expect((await fund.currentPrice()).numerator).to.equal(numerator);
        expect((await fund.currentPrice()).denominator).to.equal(denominator);
    });
    it("Buy shares", async function() {
        let currentPrice = await fund.currentPrice();
        let purchaseFee = await fund.PURCHASE_FEE();

        await fund.buyShares(owner.address, {
            value: GWEI
        });

        let convertedValue = GWEI.mul(currentPrice.numerator).div(currentPrice.denominator);
        let purchaseValue = convertedValue.mul(purchaseFee).div(100);

        let tokenBalance = await token.balanceOf(owner.address);
        
        expect(tokenBalance).to.equal(purchaseValue);
    });
    it("Failed withdrawal", async function() {
        let tokenBalance = await token.balanceOf(owner.address);
        await fund.sellShares(owner.address, tokenBalance.mul(2));
        let newTokenBalance = await token.balanceOf(owner.address);
        expect(tokenBalance).to.equal(newTokenBalance);
    });
    it("Withdraw half the shares", async function() {
        // TODO: also need to check ETH balance
        let tokenBalance = await token.balanceOf(owner.address);
        
        await fund.sellShares(owner.address, tokenBalance.div(2));

        newTokenBalance = await token.balanceOf(owner.address);

        expect(tokenBalance).to.equal(newTokenBalance.mul(2));
    });
    it("Withdraw the rest", async function() {
        // TODO: also need to check ETH balance
        let currentPrice = await fund.currentPrice();
        let withdrawFee = await fund.WITHDRAW_FEE();
        let tokenBalance = await token.balanceOf(owner.address);
        
        await fund.sellShares(owner.address, tokenBalance);

        tokenBalance = await token.balanceOf(owner.address);

        expect(tokenBalance).to.equal(0);
    });

});