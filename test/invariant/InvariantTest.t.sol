// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";

contract Invariant is Test {
    //The two assets traded in the pool
    ERC20Mock public token;
    ERC20Mock public weth;

    //factory and pool contracts
    PoolFactory public factory;
    TSwapPool public pool; //token/weth pool

    int256 constant STARTING_X = 100e18; //starting amount of token
    int256 constant STARTING_Y = 50e18; //starting amount of weth

    function setUp() public {
        weth = new ERC20Mock();
        token = new ERC20Mock();
        factory = new PoolFactory((address(weth)));
        pool = TSwapPool(factory.createPool(address(token))); //create a pool for token/weth

        //mint some tokens
        token.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        //approve the pool to spend the tokens
        token.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        //add liquidity to the pool
        pool.deposit(
            uint256(STARTING_Y),
            uint256(STARTING_Y),
            uint256(STARTING_X),
            uint64(block.timestamp)
        );
    }
}
