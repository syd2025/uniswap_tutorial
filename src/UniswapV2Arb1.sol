// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IUniswapV2Pair} from "../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "../src/interfaces/uniswap-v2/IUniswapV2Router02.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract UniswapV2Arb1 {
    struct SwapParams {
        // 第一次执行swap
        address router0;
        // 第二次执行swap
        address router1;
        // 第一次swap执行的token in
        address tokenIn;
        // 第一次swap执行的token out
        address tokenOut;
        // 第一次swap兑换的币数量
        uint256 amountIn;
        // 如果利润小于minProfit，则不能进行交易
        uint256 minProfit;
    }

    function _swap(
        SwapParams memory params
    ) public returns (uint256 amountOut) {
        // 授权使用tokenIn数量，来兑换tokenOut
        IERC20(params.tokenIn).approve(
            address(params.router0),
            params.amountIn
        );

        // 创建2个pair对地址
        address[] memory path = new address[](2);
        path[0] = params.tokenIn;
        path[1] = params.tokenOut;

        uint256[] memory amounts = IUniswapV2Router02(params.router0)
            .swapExactTokensForTokens({
                amountIn:params.amountIn,
                amountOutMin:0,
                path:path,
                to:address(this),
                deadline:block.timestamp
        });

        // 授权
        IERC20(params.tokenOut).approve(address(params.router1), amounts[1]);

        path[0] = params.tokenOut;
        path[1] = params.tokenIn;

        amounts = IUniswapV2Router02(params.router1).swapExactTokensForTokens({
            amountIn:amounts[1],
            amountOutMin:params.amountIn,
            path:path,
            to:address(this),
            deadline:block.timestamp
        });

        amountOut = amounts[1];
    }

    function swap(SwapParams calldata params) external {
        // 将调用者的tokenIn，转账进来
        IERC20(params.tokenIn).transferFrom(
            msg.sender,
            address(this),
            params.amountIn
        );

        // 第一次swap,计算出需要使用多少tokenIn的币数量，兑换多少tokenOut的币
        uint256 amountOut = _swap(params);
        require(
            amountOut - params.amountIn >= params.minProfit,
            "insufficient amount"
        );
        // 将tokenOut转到EOA账户
        IERC20(params.tokenIn).transfer(msg.sender, amountOut);
    }

    function flashSwap(
        address pair,
        bool isToken0,
        SwapParams calldata params
    ) external {
        bytes memory data = abi.encode(msg.sender, pair, params);
        IUniswapV2Pair(pair).swap({
            amount0Out: isToken0 ? params.amountIn : 0,
            amount1Out: !isToken0 ? params.amountIn : 0,
            to: address(this),
            data: data
        });
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external {
        (address user, address pair, SwapParams memory params) = abi.decode(
            data,
            (address, address, SwapParams)
        );

        uint256 amountOut = _swap(params);

        uint256 fee = (params.amountIn * 3) / 997 + 1;
        uint256 amountToRepay = params.amountIn + fee;

        uint256 profit = amountOut - amountToRepay;
        require(profit > params.minProfit, "No profit!");
        IERC20(params.tokenIn).transfer(address(pair), amountToRepay);
        IERC20(params.tokenIn).transfer(msg.sender, profit);
    }
}
