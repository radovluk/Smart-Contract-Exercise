// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "forge-std/Test.sol";
import "../src/SimpleDEX.sol";
import "../src/USDCToken.sol";

contract SimpleDEXUnitTest is Test {
    // Contracts
    SimpleDEX public dex;
    USDCToken public usdc;
    
    // Users
    address public owner;
    address public alice;
    address public bob;
    
    // Test values
    uint256 constant INITIAL_USDC_SUPPLY = 1_000_000 * 10**6; // 1M USDC
    uint256 constant INITIAL_USER_BALANCE = 10_000 * 10**6;   // 10k USDC per user
    uint256 constant INITIAL_ETH_AMOUNT = 5 ether;
    uint256 constant INITIAL_USDC_AMOUNT = 10_000 * 10**6;    // 10k USDC

    function setUp() public {
        // Setup accounts
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        
        // Give each user some ETH
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        
        // Deploy USDC token
        usdc = new USDCToken(INITIAL_USDC_SUPPLY);
        
        // Deploy DEX
        dex = new SimpleDEX(address(usdc));
        
        // Distribute USDC to users
        usdc.transfer(alice, INITIAL_USER_BALANCE);
        usdc.transfer(bob, INITIAL_USER_BALANCE);
        
        // Setup initial liquidity (as owner)
        usdc.approve(address(dex), INITIAL_USDC_AMOUNT);
        dex.addLiquidity{value: INITIAL_ETH_AMOUNT}(INITIAL_USDC_AMOUNT);
    }

    // === Liquidity provision tests ===
    
    function test_InitialLiquidity() public view {
        // Check reserves
        assertEq(dex.usdcReserve(), INITIAL_USDC_AMOUNT);
        assertEq(dex.ethReserve(), INITIAL_ETH_AMOUNT);
        
        // Check LP tokens (owner should have some)
        uint256 expectedLP = _sqrt(INITIAL_ETH_AMOUNT * INITIAL_USDC_AMOUNT) - 1000;
        assertEq(dex.balanceOf(owner), expectedLP);
        
        // Check total supply
        assertEq(dex.totalSupply(), expectedLP + 1000); // +1000 for minimum liquidity
    }
    
    function test_AddLiquidity() public {
        uint256 additionalEth = 2 ether;
        uint256 expectedUsdc = (additionalEth * dex.usdcReserve()) / dex.ethReserve();
        
        // Alice adds liquidity
        vm.startPrank(alice);
        usdc.approve(address(dex), expectedUsdc);
        uint256 lpTokens = dex.addLiquidity{value: additionalEth}(expectedUsdc);
        vm.stopPrank();
        
        // Check LP tokens received - this calculation was incorrect
        // The correct formula uses the min of both ratios according to the contract code
        uint256 totalSupplyBeforeAdd = dex.totalSupply() - lpTokens; // Calculate total supply before the add
        uint256 expectedLPFromEth = (additionalEth * totalSupplyBeforeAdd) / (dex.ethReserve() - additionalEth);
        uint256 expectedLPFromUsdc = (expectedUsdc * totalSupplyBeforeAdd) / (dex.usdcReserve() - expectedUsdc);
        uint256 expectedLP = expectedLPFromEth < expectedLPFromUsdc ? expectedLPFromEth : expectedLPFromUsdc;
        
        assertEq(lpTokens, expectedLP, "LP tokens received do not match expected amount");
        assertEq(dex.balanceOf(alice), lpTokens, "Alice's LP balance incorrect");
        
        // Check reserves updated
        assertEq(dex.usdcReserve(), INITIAL_USDC_AMOUNT + expectedUsdc, "USDC reserve not updated correctly");
        assertEq(dex.ethReserve(), INITIAL_ETH_AMOUNT + additionalEth, "ETH reserve not updated correctly");
    }
    
    // Add a receive function to accept ETH transfers
    receive() external payable {}
    
    function test_RemoveLiquidity() public {
        // Get owner's current LP tokens
        uint256 lpTokensToRemove = dex.balanceOf(owner) / 2; // Remove half
        
        // Calculate expected returns
        uint256 expectedUsdc = (lpTokensToRemove * dex.usdcReserve()) / dex.totalSupply();
        uint256 expectedEth = (lpTokensToRemove * dex.ethReserve()) / dex.totalSupply();
        
        uint256 ownerUsdcBefore = usdc.balanceOf(owner);
        uint256 ownerEthBefore = address(owner).balance;
        
        // Remove liquidity
        (uint256 usdcReceived, uint256 ethReceived) = dex.removeLiquidity(lpTokensToRemove);
        
        // Check received amounts
        assertEq(usdcReceived, expectedUsdc, "USDC received amount incorrect");
        assertEq(ethReceived, expectedEth, "ETH received amount incorrect");
        
        // Check balances
        assertEq(usdc.balanceOf(owner), ownerUsdcBefore + usdcReceived, "Owner USDC balance incorrect");
        assertEq(address(owner).balance, ownerEthBefore + ethReceived, "Owner ETH balance incorrect");
        
        // Check reserves updated
        assertEq(dex.usdcReserve(), INITIAL_USDC_AMOUNT - expectedUsdc, "USDC reserve not updated correctly");
        assertEq(dex.ethReserve(), INITIAL_ETH_AMOUNT - expectedEth, "ETH reserve not updated correctly");
    }
    
    // === Swap tests ===
    
    function test_EthToUsdc() public {
        uint256 ethToSwap = 1 ether;
        uint256 usdcReserveBefore = dex.usdcReserve();
        uint256 ethReserveBefore = dex.ethReserve();
        
        vm.startPrank(bob);
        uint256 bobUsdcBefore = usdc.balanceOf(bob);
        
        // Calculate expected output using constant product formula
        uint256 expectedUsdc = (ethToSwap * 997 * usdcReserveBefore) / ((ethReserveBefore * 1000) + (ethToSwap * 997));
        
        // Swap ETH to USDC
        uint256 usdcReceived = dex.ethToUsdc{value: ethToSwap}();
        vm.stopPrank();
        
        // Check USDC received
        assertEq(usdcReceived, expectedUsdc);
        assertEq(usdc.balanceOf(bob), bobUsdcBefore + usdcReceived);
        
        // Check reserves updated
        assertEq(dex.usdcReserve(), usdcReserveBefore - expectedUsdc);
        assertEq(dex.ethReserve(), ethReserveBefore + ethToSwap);
    }
    
    function test_UsdcToEth() public {
        uint256 usdcToSwap = 1000 * 10**6; // 1000 USDC
        uint256 usdcReserveBefore = dex.usdcReserve();
        uint256 ethReserveBefore = dex.ethReserve();
        
        vm.startPrank(alice);
        uint256 aliceEthBefore = address(alice).balance;
        
        // Approve DEX to spend USDC
        usdc.approve(address(dex), usdcToSwap);
        
        // Calculate expected output using constant product formula
        uint256 expectedEth = (usdcToSwap * 997 * ethReserveBefore) / ((usdcReserveBefore * 1000) + (usdcToSwap * 997));
        
        // Swap USDC to ETH
        uint256 ethReceived = dex.usdcToEth(usdcToSwap);
        vm.stopPrank();
        
        // Check ETH received
        assertEq(ethReceived, expectedEth);
        assertEq(address(alice).balance, aliceEthBefore + ethReceived);
        
        // Check reserves updated
        assertEq(dex.usdcReserve(), usdcReserveBefore + usdcToSwap);
        assertEq(dex.ethReserve(), ethReserveBefore - expectedEth);
    }
    
    // === Error tests ===
    
    function test_RevertWhen_InsufficientUSDCAmount() public {
        uint256 additionalEth = 2 ether;
        uint256 requiredUsdc = (additionalEth * dex.usdcReserve()) / dex.ethReserve();
        uint256 insufficientUsdc = requiredUsdc - 1; // Just under the required amount
        
        // Alice tries to add liquidity with insufficient USDC
        vm.startPrank(alice);
        usdc.approve(address(dex), insufficientUsdc);
        
        // Should revert with InsufficientUSDCAmount error
        vm.expectRevert(abi.encodeWithSelector(SimpleDEX.InsufficientUSDCAmount.selector, insufficientUsdc, requiredUsdc));
        dex.addLiquidity{value: additionalEth}(insufficientUsdc);
        vm.stopPrank();
    }
    
    function test_RevertWhen_InsufficientLiquidityTokens() public {
        // Bob tries to remove more LP tokens than he has
        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(SimpleDEX.InsufficientLiquidityTokens.selector, 1, 0));
        dex.removeLiquidity(1);
        vm.stopPrank();
    }
    
    // === Price functions tests ===
    
    function test_PriceFunctions() public view {
        // Calculate expected prices
        uint256 expectedUsdcPerEth = (dex.usdcReserve() * 1e18) / dex.ethReserve();
        uint256 expectedEthPerUsdc = (dex.ethReserve() * 1e18) / dex.usdcReserve();
        
        // Check price functions
        assertEq(dex.getCurrentUsdcToEthPrice(), expectedUsdcPerEth);
        assertEq(dex.getCurrentEthToUsdcPrice(), expectedEthPerUsdc);
    }
    
    // === Helper functions ===
    
    function _sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}