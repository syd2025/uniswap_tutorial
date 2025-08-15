// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IUniswapV2Pair} from "../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "../src/interfaces/uniswap-v2/IUniswapV2Router02.sol";
import {DAI, WETH, UNISWAP_V2_ROUTER_02, SUSHISWAP_V2_ROUTER_02, UNISWAP_V2_PAIR_DAI_WETH, UNISWAP_V2_PAIR_DAI_MKR} from "../src/Constants.sol";
import {UniswapV2Arb1} from "../src/UniswapV2Arb1.sol";

contract UniswapV2Arb1Test is Test {
    IUniswapV2Router02 private constant uni_router =
        IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IUniswapV2Router02 private constant sushi_router =
        IUniswapV2Router02(SUSHISWAP_V2_ROUTER_02);
    IERC20 private constant dai = IERC20(DAI);
    IWETH private constant weth = IWETH(WETH);
    address constant user = address(11);

    UniswapV2Arb1 private arb;

    function setUp() public {
        arb = new UniswapV2Arb1();

        deal(address(this), 100 * 1e18);  // 给本合约地址充入资金

        weth.deposit{value: 100 * 1e18}();  // 将100 weth转入WETH合约
        weth.approve(address(uni_router), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;

        uni_router.swapExactTokensForTokens({
            amountIn: 100 * 1e18,
            amountOutMin: 1,
            path: path,
            to: user,
            deadline: block.timestamp
        });

        deal(DAI, user, 10000 * 1e18);
        vm.prank(user);
        dai.approve(address(arb), type(uint256).max);
    }

    function test_swap() public {
        uint256 bal0 = dai.balanceOf(user);
        vm.prank(user);
        arb._swap(
            UniswapV2Arb1.SwapParams({
                router0: UNISWAP_V2_ROUTER_02,
                router1: SUSHISWAP_V2_ROUTER_02,
                tokenIn: DAI,
                tokenOut: WETH,
                amountIn: 10000 * 1e18,
                minProfit: 1
            })
        );

        uint256 bal1 = dai.balanceOf(user);

        assertGe(bal1, bal0, "no profit");
        assertEq(
            dai.balanceOf(address(arb)),
            0,
            "Dai balance of arb is not zero"
        );
        console.log("profit", bal1 - bal0);
    }

    function test_flash() public {
        uint256 bal0 = dai.balanceOf(user);
        vm.prank(user);

        arb.flashSwap(
            UNISWAP_V2_PAIR_DAI_MKR,
            true,
            UniswapV2Arb1.SwapParams({
                router0: UNISWAP_V2_ROUTER_02,
                router1: SUSHISWAP_V2_ROUTER_02,
                tokenIn: DAI,
                tokenOut: WETH,
                amountIn: 1000000 * 1e18,
                minProfit: 1
            })
        );
        uint256 bal1 = dai.balanceOf(user);

        assertGe(bal1, bal0, "no profit");
        assertEq(
            dai.balanceOf(address(arb)),
            0,
            "Dai balance of arb is not zero"
        );
    }
}
