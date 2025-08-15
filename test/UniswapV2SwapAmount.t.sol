// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../src/interfaces/uniswap-v2/IUniswapV2Router02.sol";
import {DAI, WETH, MKR, UNISWAP_V2_ROUTER_02} from "../src/Constants.sol";

contract UniswapV2SwapAmountTest is Test {
    // token
    IWETH private constant weth = IWETH(WETH);
    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant mkr = IERC20(MKR);
    // router
    IUniswapV2Router02 private constant router =
        IUniswapV2Router02(UNISWAP_V2_ROUTER_02);

    address private constant user = address(100);

    function test_getAmountsOut() public {
        // 将三种token存入到数组中
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;
        // 放入1 ethereum
        uint256 amountIn = 1e18;
        // 计算三种token的转换值
        uint256[] memory amounts = router.getAmountsOut(amountIn, path);
        console.log("WETH", amounts[0]);
        console.log("DAI", amounts[1]);
        console.log("MKR", amounts[2]);
    }

    function test_getAmountsIn() public {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        // 降低精度
        uint256 amountOut = 1e16;
        uint[] memory amounts = router.getAmountsIn(amountOut, path);
        console.log("WETH", amounts[0]);
        console.log("DAI", amounts[1]);
        console.log("MKR", amounts[2]);
    }
}
