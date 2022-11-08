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
    it("should mint to contract address", async function () {
      const ContractFactoryTestReceiver = await ethers.getContractFactory(
        "TestReceiver"
      );
      const contractTestReceiver = await ContractFactoryTestReceiver.deploy();
      await contractTestReceiver.deployed();
      await expect(
        await contractERC1155.mint(contractTestReceiver.address, 0, 3, [])
      ).to.be.ok;
    });
    it("should revert", async function () {
      const ContractFactoryTestReceiver = await ethers.getContractFactory(
        "TestReceiver2"
      );
      const contractTestReceiver = await ContractFactoryTestReceiver.deploy();
      await contractTestReceiver.deployed();
      await expect(contractERC1155.mint(contractTestReceiver.address, 0, 3, []))
        .to.be.reverted;
    });
    // it("should emit the Transfer event", async function () {
    //   contractERC1155.mint(accounts[0].address, 0, 3, []);
    //   await expect(contractERC1155.mint(accounts[0].address, 0, 3, []))
    //     .to.emit(contractERC1155, "TransferSingle")
    //     .withArgs(
    //       accounts[0].address,
    //       ethers.constants.AddressZero,
    //       accounts[0].address,
    //       0,
    //       3
    //     );
    // });
  });
  describe("mintBatch", async function () {
    it("should revert when to is a zero address", async function () {
      await expect(
        contractERC1155.mintBatch(
          ethers.constants.AddressZero,
          [0, 2],
          [1, 1],
          []
        )
      ).to.be.reverted;
    });

    it("should revert when ids !==  amounts", async function () {
      await expect(
        contractERC1155.mintBatch(accounts[0].address, [0, 2], [2], [])
      ).to.be.reverted;
    });

    it("should work fine when ids ===  amounts", async function () {
      await expect(
        contractERC1155.mintBatch(accounts[0].address, [0, 2], [2, 1], [])
      ).to.be.ok;
    });

    it("should mint the appropriate amount per id", async function () {
      await contractERC1155.mintBatch(accounts[0].address, [0, 2], [2, 1], []);
      expect(
        await contractERC1155.balanceOf(accounts[0].address, 0)
      ).to.be.equal(2);

      expect(
        await contractERC1155.balanceOf(accounts[0].address, 2)
      ).to.be.equal(1);
    });
  });

  describe("uri", async function () {
    it("should return URI", async function () {
      expect(await contractERC1155.uri()).to.be.equal(
        "https://token-cdn-domain/{id}.json"
      );
    });
  });
});
