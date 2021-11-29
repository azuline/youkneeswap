import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { TestToken, Youkneeswap } from "../typechain-types";

describe("Youkneeswap", () => {
  let token: TestToken;
  let ykswap: Youkneeswap;

  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;

  // We:
  // 1. Deploy the TestToken and Youkneeswap contracts.
  // 2. Create three accounts: owner, addr1, and addr2.
  // 3. Mint 1000 TestToken for each account.
  beforeEach(async () => {
    const TestToken = await ethers.getContractFactory("TestToken");
    token = await TestToken.deploy();
    await token.deployed();

    const Youkneeswap = await ethers.getContractFactory("Youkneeswap");
    ykswap = await Youkneeswap.deploy(token.address);
    await ykswap.deployed();

    [owner, addr1, addr2] = await ethers.getSigners();

    await token.mint(owner.address, 1000);
    await token.mint(addr1.address, 1000);
    await token.mint(addr2.address, 1000);
  });

  it("Initial mint through addLiquidity", async () => {
    // We add 500 TestToken and 5 wei. This should give us 50 shares, because we mint
    // initial shares via the geometric mean.
    await ykswap.connect(owner).addLiquidity(500, { value: 5 });

    expect(await ykswap.shares(owner.address)).equals(50);
    expect(await ethers.provider.getBalance(ykswap.address)).equals(5);
    expect(await ykswap.otherTokenReserve()).equals(500);
  });

  it("Second mint through addLiquidity", async () => {
    // We add 500 TestToken and 5 wei.
    await ykswap.connect(addr1).addLiquidity(500, { value: 5 });

    // We add another 500 TestToken and 10 wei. This should get us:
    //
    // - Wei: 10 * 50 / 5 = 100 shares
    // - Token: 500 * 50 / 500 = 50 shares
    //
    // for a sum of 150 shares.
    await ykswap.connect(owner).addLiquidity(500, { value: 10 });

    expect(await ykswap.shares(owner.address)).equals(150);
    expect(await ethers.provider.getBalance(ykswap.address)).equals(15);
    expect(await ykswap.otherTokenReserve()).equals(1000);
  });

  it("Redeem liquidity shares after initial mint", async () => {
    // We add 1000 TestToken and 10 wei for 100 shares.
    await ykswap.connect(owner).addLiquidity(1000, { value: 10 });
    expect(await ykswap.shares(owner.address)).equals(100);

    // We now redeem the shares, which should get us back the wei in the pool.
    // TODO: This seems to be broken. lol. we need to write down our equations and make
    // sure that they are mathematically sound.
    await ykswap.connect(owner).removeLiquidityEth(50);
    expect(await ethers.provider.getBalance(ykswap.address)).equals(0);
  });
});
