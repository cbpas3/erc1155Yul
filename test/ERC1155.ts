const { ethers } = require("hardhat");
const { expect } = require("chai");
const fs = require("fs");
const path = require("path");
const { BigNumber } = ethers;

const getAbi = () => {
  try {
    const dir = path.resolve(
      __dirname,
      "../artifacts/contracts/IERC1155.sol/IERC1155.json"
    );
    const file = fs.readFileSync(dir, "utf8");
    const json = JSON.parse(file);
    const abi = json.abi;
    return abi;
  } catch (e) {
    console.log(`e: `, e);
  }
};

const getBytecode = () => {
  try {
    const dir = path.resolve(
      __dirname,
      "../artifacts/contracts/ERC1155.yul/ERC1155.json"
    );
    const file = fs.readFileSync(dir, "utf8");
    const json = JSON.parse(file);
    const bytecode = json.bytecode;
    return bytecode;
  } catch (e) {
    console.log(`e: `, e);
  }
};

describe("ERC1155", () => {
  let contractERC1155: any = null;
  let accounts: any = null;
  let provider = null;

  beforeEach(async function () {
    const ContractFactoryERC1155 = await ethers.getContractFactory(
      "Yul_Caller"
    );

    const ERC1155 = await ethers.getContractFactory(
      await getAbi(),
      await getBytecode()
    );
    contractERC1155 = await ERC1155.deploy();
    await contractERC1155.deployed();
    // console.log("ERC1155 deployed to:", contractERC1155.address);

    // contractERC1155 = await ContractFactoryERC1155.deploy();

    // await contractERC1155.deployed();
    // const yulContractAddress = await contractERC1155.getYulContractAddress();
    // yulContract = ethers.getContractAt("IERC1155", yulContractAddress);

    accounts = await ethers.getSigners();
    provider = await ethers.provider;
    // console.log(await contractERC1155.balanceOf(accounts[0].address, 0));

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

    it("should mint batch to contract address", async function () {
      const ContractFactoryTestReceiver = await ethers.getContractFactory(
        "TestReceiver"
      );
      const contractTestReceiver = await ContractFactoryTestReceiver.deploy();
      await contractTestReceiver.deployed();
      await expect(
        await contractERC1155.mintBatch(
          contractTestReceiver.address,
          [1, 2],
          [2, 2],
          []
        )
      ).to.be.ok;
    });
    it("should revert", async function () {
      const ContractFactoryTestReceiver = await ethers.getContractFactory(
        "TestReceiver2"
      );
      const contractTestReceiver = await ContractFactoryTestReceiver.deploy();
      await contractTestReceiver.deployed();
      await expect(
        contractERC1155.mintBatch(
          contractTestReceiver.address,
          [1, 2],
          [2, 2],
          []
        )
      ).to.be.reverted;
    });
  });

  describe("uri", async function () {
    it("should return URI", async function () {
      expect(await contractERC1155.uri(0)).to.be.equal(
        "https://token-cdn-domain/{id}.json"
      );
    });
  });

  describe("transfer", async function () {
    it("should transfer balance from address 1 to address 2", async function () {
      contractERC1155.mint(accounts[0].address, 0, 3, []);
      contractERC1155.safeTransferFrom(
        accounts[0].address,
        accounts[1].address,
        0,
        1,
        []
      );
      expect(
        await contractERC1155.balanceOf(accounts[0].address, 0)
      ).to.be.equal(2);
      expect(
        await contractERC1155.balanceOf(accounts[1].address, 0)
      ).to.be.equal(1);
    });

    it("should revert because from address needs to match caller address", async function () {
      contractERC1155.mint(accounts[1].address, 0, 3, []);
      await expect(
        contractERC1155.safeTransferFrom(
          accounts[1].address,
          accounts[0].address,
          0,
          1,
          []
        )
      ).to.be.reverted;
    });
  });

  describe("safeBatchTransfer", async function () {
    it("should revert when the ids length is not equal the amounts length", async function () {
      await expect(
        contractERC1155.safeBatchTransferFrom(
          accounts[0].address,
          accounts[1].address,
          [1, 2],
          [1],
          []
        )
      ).to.be.reverted;
    });

    it("should add and subtract to several balances at once", async function () {
      await contractERC1155.mintBatch(accounts[0].address, [1, 2], [2, 2], []);
      await contractERC1155.safeBatchTransferFrom(
        accounts[0].address,
        accounts[1].address,
        [1, 2],
        [1, 2],
        []
      );
      // TODO: Update once batch balance is implemented
      expect(
        await contractERC1155.balanceOfBatch(
          [accounts[1].address, accounts[1].address],
          [1, 2]
        )
      ).to.deep.equal([BigNumber.from(1), BigNumber.from(2)]);

      expect(
        await contractERC1155.balanceOfBatch(
          [accounts[0].address, accounts[0].address],
          [1, 2]
        )
      ).to.deep.equal([BigNumber.from(1), BigNumber.from(0)]);
    });

    it("should transfer batch to contract address", async function () {
      const ContractFactoryTestReceiver = await ethers.getContractFactory(
        "TestReceiver"
      );
      const contractTestReceiver = await ContractFactoryTestReceiver.deploy();
      await contractTestReceiver.deployed();

      await contractERC1155.mintBatch(accounts[0].address, [1, 2], [2, 2], []);

      await expect(
        contractERC1155.safeBatchTransferFrom(
          accounts[0].address,
          contractTestReceiver.address,
          [1, 2],
          [1, 2],
          []
        )
      ).to.be.ok;
    });

    it("should revert", async function () {
      const ContractFactoryTestReceiver = await ethers.getContractFactory(
        "TestReceiver2"
      );
      const contractTestReceiver = await ContractFactoryTestReceiver.deploy();
      await contractTestReceiver.deployed();

      await contractERC1155.mintBatch(accounts[0].address, [1, 2], [2, 2], []);

      await expect(
        contractERC1155.safeBatchTransferFrom(
          accounts[0].address,
          contractTestReceiver.address,
          [1, 2],
          [1, 2],
          []
        )
      ).to.be.reverted;
    });
  });

  describe("balanceOfBatch", async function () {
    it("should return updated balances", async function () {
      await contractERC1155.mint(accounts[0].address, 0, 3, []);
      await contractERC1155.mint(accounts[1].address, 1, 4, []);
      expect(
        await contractERC1155.balanceOfBatch(
          [accounts[0].address, accounts[1].address],
          [0, 1]
        )
      ).to.deep.equal([BigNumber.from(3), BigNumber.from(4)]);
    });
  });

  describe("burn", async function () {
    it("should return updated balance", async function () {
      await contractERC1155.mint(accounts[0].address, 0, 3, []);
      await contractERC1155.burn(accounts[0].address, 0, 2);
      expect(
        await contractERC1155.balanceOf(accounts[0].address, 0)
      ).to.be.equal(1);
    });
  });
});
