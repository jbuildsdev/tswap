// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract Handler is Test {
    TSwapPool public pool;
    ERC20Mock public weth;
    ERC20Mock public token;

    //Ghost variables - do not exist in pool contract
    int256 public startingX;
    int256 public startingY;
    int256 public expectedDeltaX;
    int256 public expectedDeltaY;
    int256 public endingX;
    int256 public endingY;
    int256 public actualDeltaX;
    int256 public actualDeltaY;


    address liquidityProvider = makeAddr("lp");

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = ERC20Mock(_pool.getWeth());
        token = ERC20Mock(_pool.getPoolToken());
    }

    function deposit(uint256 _wethAmount) public {
        // sanity check deposit is reasonable amount
        uint256 wethAmount = bound(_wethAmount, 0, type(uint64).max); //18446744073709551615
        startingY = int256(weth.balanceOf(address(this)));
        startingX = int256(token.balanceOf(address(this)));

        expectedDeltaY = int256(wethAmount);
        expectedDeltaX = int256(pool.getPoolTokensToDepositBasedOnWeth(wethAmount));

        //test to see if X and Y align with the expected values

        //deposit
        vm.startPrank(liquidityProvider);
        weth.mint(liquidityProvider, wethAmount);
        token.mint(liquidityProvider, uint256(expectedDeltaX));
        weth.approve(address(pool), type(uint256).max);
        token.approve(address(pool), type(uint256).max);
        pool.deposit(
            wethAmount,
            0,
            uint256(expectedDeltaX),
            uint64(block.timestamp)
        );
        vm.stopPrank();
        uint256 endingY = weth.balanceOf(address(this));
        uint256 endingX = token.balanceOf(address(this));

        //check that the ending balances are as expected
        actualDeltaY = int256(endingY) - startingY;
        actualDeltaX = int256(endingX) - startingX;
    
        
        }
}
