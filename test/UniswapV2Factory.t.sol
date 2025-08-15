// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {ERC20} from "../src/ERC20.sol";
import {IUniswapV2Pair} from "../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "../src/interfaces/uniswap-v2/IUniswapV2Factory.sol";
import {DAI, WETH, MKR, UNISWAP_V2_FACTORY} from "../src/Constants.sol";

contract UniswapV2FactoryTest is Test {
    IWETH private constant weth = IWETH(WETH);

    IUniswapV2Factory private constant factory =
        IUniswapV2Factory(UNISWAP_V2_FACTORY);

    function test_createPair() public {
        // 部署ERC20合约
        ERC20 token = new ERC20("test", "TEST", 18);

        // 创建代币对
        address pair = factory.createPair(address(token), WETH);

        // 通过 IUniswapV2Pair 查看 pair 中 token0、token1 的地址
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        if (address(token) < WETH) {
            assertEq(token0, address(token), "token 0");
            assertEq(token1, WETH, "token 1");
        } else {
            assertEq(token0, WETH, "token 0");
            assertEq(token1, address(token), "token 1");
        }
    }
}
