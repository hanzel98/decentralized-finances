// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IUniswapV2Pair, IUniswapV2Factory} from "./interfaces/Uniswap.sol";
import {IERC20} from "./interfaces/IERC20.sol";

// Read doc here: https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/using-flash-swaps
contract UniswapFlashSwaps {
    // Uniswap V2 Router
    address private immutable WETH;
    // Uniswap V2 Factory
    IUniswapV2Factory private immutable uniswapFactory;

    constructor(address _weth, address _factory) {
        WETH = _weth;
        uniswapFactory = IUniswapV2Factory(_factory);
    }

    // needs to accept ETH from any V1 exchange and WETH
    receive() external payable {}

    function requestFlashLoan(address _tokenToBorrow, uint256 _amount) public {
        IUniswapV2Pair pair = IUniswapV2Pair(
            uniswapFactory.getPair(WETH, _tokenToBorrow)
        );
        require(address(pair) != address(0), "UFS/pair-zero");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint256 amount0Out = _tokenToBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenToBorrow == token1 ? _amount : 0;

        // Enconding information to use it later
        bytes memory data = abi.encode(_tokenToBorrow, _amount);

        // This will make a callback to the function uniswapV2Call
        pair.swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        // Uniswap caller validation
        address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch token0
        address token1 = IUniswapV2Pair(msg.sender).token1(); // fetch token1
        address pair = IUniswapV2Factory(uniswapFactory).getPair(
            token0,
            token1
        );
        require(msg.sender == pair, "UFS/invalid-sender"); // ensure that msg.sender is a V2 pair

        // =============================
        // Perform some logic here to use the borrowed funds
        // =============================

        // Retrieving the data created before
        (address tokenToBorrow, uint256 amount) = abi.decode(
            data,
            (address, uint256)
        );

        // About 0.3% on fees
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;

        // Pays loan back
        assert(IERC20(tokenToBorrow).transfer(pair, amountToRepay));
    }
}
