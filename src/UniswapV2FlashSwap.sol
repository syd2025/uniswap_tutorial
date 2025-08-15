// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IUniswapV2Pair} from "../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";

contract UniswapV2FlashSwap {
    IUniswapV2Pair private immutable pair;
    address private immutable token0;
    address private immutable token1;

    error InvalidToken();

    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);
        token0 = pair.token0();
        token1 = pair.token1();
    }

    function flashSwap(address token, uint256 amount) external {
        if (token != token0 && token != token1) {
            revert InvalidToken();
        }

        (uint256 amount0Out, uint256 amount1Out) = token == token0
            ? (amount, uint256(0))
            : (uint256(0), amount);

        // 将token和msg.sender进行编码
        bytes memory data = abi.encode(token, msg.sender);

        pair.swap({
            amount0Out: amount0Out,
            amount1Out: amount1Out,
            to: address(this),
            data: data
        });
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        // 调用者必须pair合约的地址
        require(msg.sender == address(pair), "not pair address");
        // 发送者必须是此合约，否则不能偿还借贷
        require(sender == address(this), "not sender address");

        // 解码data数据
        (address token, address caller) = abi.decode(data, (address, address));

        // 借多少
        uint256 amount = token == token0 ? amount0 : amount1;
        // 费用 fee = borrowed amount * 3 / 997 + 1
        uint256 fee = (amount * 3) / 997 + 1;
        // 需要偿还的总数
        uint256 amountToRepay = amount + fee;

        // 从从 caller 的账户中扣除 fee 数量的代币，并将其转移到当前合约的地址（ address(this) ）
        IERC20(token).transferFrom(caller, address(this), fee);

        IERC20(token).transfer(address(pair), amountToRepay);
    }
}
