// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/flash-loans/AaveFlash.sol";

contract AaveFlashLoanTest is Test {
    AaveFlash public flashTest;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setUp() public {
        address mainnetAaveLendingPoolAddressesProvider = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
        flashTest = new AaveFlash(
            ILendingPoolAddressesProvider(
                mainnetAaveLendingPoolAddressesProvider
            )
        );
    }

    function testFlashLoan() public {
        // Impersonating WETH whale
        // Helps to repay the loan+fees
        vm.startPrank(0xce0Adbb76A8Ce7224BeC6b586E18743aeB03250A);
        IERC20(WETH).transfer(address(flashTest), 0.01 ether);

        flashTest.flashloan(WETH, 1 ether);

        (
            address initiator,
            address caller,
            address asset,
            uint256 amount,
            uint256 premium
        ) = flashTest.result();

        assertTrue(initiator == address(flashTest));
        assertTrue(caller == address(flashTest.LENDING_POOL()));
        assertTrue(asset == WETH);
        assertTrue(amount == 1 ether);

        uint256 expectedPremium = (1 ether *
            ILendingPool(flashTest.LENDING_POOL()).FLASHLOAN_PREMIUM_TOTAL()) /
            10000;

        assertTrue(premium == expectedPremium);
        assertTrue(true);
    }
}
