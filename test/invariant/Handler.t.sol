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
    int256 public expectedDeltaX; //expected change in token balances
    int256 public expectedDeltaY;

    int256 public actualDeltaX; //actual change in token balances
    int256 public actualDeltaY;

    address liquidityProvider = makeAddr("lp");
    address swapper = makeAddr("swapper");

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = ERC20Mock(_pool.getWeth());
        token = ERC20Mock(_pool.getPoolToken());
    }

    function swapPoolTokenForWethBasedOnOutputWeth(uint256 _outputWeth) public {
        uint256 outputWeth = bound(_outputWeth, 0, type(uint64).max); //18446744073709551615
        if (outputWeth >= weth.balanceOf(address(pool))) {
            return;
        }

        //delta X
        uint256 tokenAmount = pool.getInputAmountBasedOnOutput(
            outputWeth,
            token.balanceOf(address(pool)),
            weth.balanceOf(address(pool))
        );

        if (tokenAmount > type(uint64).max) {
            return;
        }

        startingY = int256(weth.balanceOf(address(this)));
        startingX = int256(token.balanceOf(address(this)));

        expectedDeltaY = int256(-1) * int256(outputWeth);
        expectedDeltaX = int256(
            pool.getPoolTokensToDepositBasedOnWeth(tokenAmount)
        );

        if (token.balanceOf(swapper) < tokenAmount) {
            token.mint(swapper, tokenAmount - token.balanceOf(swapper) + 1);
        }

        // do swap
        vm.accesses(swapper);
        token.approve(address(pool), type(uint256).max);
        pool.swapExactOutput(token, weth, outputWeth, uint64(block.timestamp));
        vm.stopPrank();

        //compare deltas
        uint256 endingY = weth.balanceOf(address(this));
        uint256 endingX = token.balanceOf(address(this));

        //check that the ending balances are as expected
        actualDeltaY = int256(endingY) - startingY;
        actualDeltaX = int256(endingX) - startingX;
    }

    function deposit(uint256 _wethAmount) public {
        // sanity check deposit is reasonable amount
        uint256 wethAmount = bound(_wethAmount, 0, type(uint64).max); //18446744073709551615
        startingY = int256(weth.balanceOf(address(this)));
        startingX = int256(token.balanceOf(address(this)));

        expectedDeltaY = int256(wethAmount);
        expectedDeltaX = int256(
            pool.getPoolTokensToDepositBasedOnWeth(wethAmount)
        );

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
