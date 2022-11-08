const { ethers } = require("hardhat");
const { expect } = require("chai");
const { BigNumber } = ethers;

describe("ERC1155", () => {
  let contractERC1155: any = null;
  let accounts: any = null;
  let provider = null;

  beforeEach(async function () {
    const ContractFactoryERC1155 = await ethers.getContractFactory(
      "Yul_Caller"
    );
    contractERC1155 = await ContractFactoryERC1155.deploy();

    await contractERC1155.deployed();

    accounts = await ethers.getSigners();
    provider = await ethers.provider;

    let twentyThousandEtherInHex = ethers.utils.hexStripZeros(
      ethers.utils.parseEther("20000").toHexString()
    );

    await provider.send("hardhat_setBalance", [
      accounts[1].address,
      twentyThousandEtherInHex,
    ]);
  });

  describe("balanceOf", async function () {
    it("should return a balance of 0", async function () {
      expect(
        await contractERC1155.balanceOf(accounts[0].address, 0)
      ).to.be.equal(0);
    });

    it("should mint 3 and reflect in return of balanceOf", async function () {
      contractERC1155.mint(accounts[0].address, 0, 3, []);
      expect(
        await contractERC1155.balanceOf(accounts[0].address, 0)
      ).to.be.equal(3);
    });
  });

  describe("mint", async function () {
    it("should emit the Transfer event", async function () {
      contractERC1155.mint(accounts[0].address, 0, 3, []);
      await expect(contractERC1155.mint(accounts[0].address, 0, 3, []))
        .to.emit(contractERC1155, "TransferSingle")
        .withArgs(
          accounts[0].address,
          ethers.constants.AddressZero,
          accounts[0].address,
          0,
          3
        );
    });
  });
});
