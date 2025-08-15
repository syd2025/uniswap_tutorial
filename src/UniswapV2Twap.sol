// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IUniswapV2Pair} from "../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import {FixedPoint} from "../src/FixedPoint.sol";

contract UniswapV2Twap {
    using FixedPoint for *;

    uint256 private constant MIN_WAIT = 300;
    IUniswapV2Pair public immutable pair;
    address public immutable token0;
    address public immutable token1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    uint32 public updateAt;

    FixedPoint.uq112x112 public price0Avg;
    FixedPoint.uq112x112 public price1Avg;

    constructor(address _pair) {
        pair = IUniswapV2Pair(address(0));
        token0 = pair.token0();
        token1 = pair.token1();

        price0CumulativeLast = pair.price0CumulativeLast();
        price1CumulativeLast = pair.price1CumulativeLast();

        (, , updateAt) = pair.getReserves();
    }

    function _getCurrentCumulativePrices()
        internal
        view
        returns (uint256 price0Cumulative, uint256 price1Cumulative)
    {
        price0Cumulative = pair.price0CumulativeLast();
        price1Cumulative = pair.price1CumulativeLast();

        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair
            .getReserves();

        uint32 blockTimestamp = uint32(block.timestamp);
        if (blockTimestampLast != blockTimestamp) {
            uint32 dt = blockTimestamp - blockTimestampLast;

            unchecked {
                price0Cumulative +=
                    uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
                    dt;
                price1Cumulative +=
                    uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
                    dt;
            }
        }
    }

    function update() external {
        uint32 blockTimestamp = uint32(block.timestamp);

        uint32 dt = blockTimestamp - updateAt;
        require(dt >= MIN_WAIT, "not enough wait time");

        (
            uint256 price0Cumulative,
            uint256 price1Cumulative
        ) = _getCurrentCumulativePrices();

        unchecked {
            price0Avg = FixedPoint.uq112x112(
                uint224((price0Cumulative - price0CumulativeLast) / dt)
            );
            price1Avg = FixedPoint.uq112x112(
                uint224((price1Cumulative - price1CumulativeLast) / dt)
            );
        }

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        updateAt = blockTimestamp;
    }

    function consult(
        address tokenIn,
        uint256 amountIn
    ) external view returns (uint256 amountOut) {
        require(
            tokenIn == token0 || tokenIn == token1,
            "consult: invalid token"
        );

        if (tokenIn == token0) {
            amountOut = FixedPoint.mul(price0Avg, amountIn).decode144();
        } else {
            amountOut = FixedPoint.mul(price1Avg, amountIn).decode144();
        }
    }
}
