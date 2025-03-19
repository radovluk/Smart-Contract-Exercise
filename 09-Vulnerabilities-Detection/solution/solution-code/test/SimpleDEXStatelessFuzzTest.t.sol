// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { SimpleDEX } from "../src/SimpleDEX.sol";
import { USDCToken } from  "../src/USDCToken.sol";

/**
 * @title SimpleDEXStatelessFuzzTest
 * @notice Stateless fuzzing test suite for the SimpleDEX decentralized exchange contract
 * @dev This contract tests all core functionality of the SimpleDEX including:
 *      - Liquidity provision (adding and removing)
 *      - Token swaps (ETH <-> USDC)
 *      - Price calculations
 *      - Error handling
 * 
 *      The tests use a standard setup with three users:
 *      - Owner: The test contract itself, provides initial liquidity
 *      - Alice: Regular user who adds liquidity and swaps USDC to ETH
 *      - Bob: Regular user who swaps ETH to USDC
 *
 *      Initial setup:
 *      - 5 ETH and 10,000 USDC initial liquidity
 *      - Each user has 10 ETH and 10,000 USDC initially
 */
contract SimpleDEXStatelessFuzzTest is Test {
    // Contracts
    SimpleDEX public dex;
    USDCToken public usdc;

    // Users
    address public owner;
    address public alice;
    address public bob;

    // Test values
    uint256 constant INITIAL_USDC_SUPPLY = 1_000_000 * 10 ** 18; // 1M USDC
    uint256 constant INITIAL_USER_BALANCE = 10_000 * 10 ** 18; // 10k USDC per user
    uint256 constant INITIAL_ETH_AMOUNT = 5 ether;
    uint256 constant INITIAL_USDC_AMOUNT = 10_000 * 10 ** 18; // 10k USDC

    // Add receive function to allow test contract to receive ETH
    receive() external payable {}

    /**
     * @notice Sets up the test environment with users, tokens, 
     * and initial liquidity before each test
     * This function:
     *  - Creates test accounts (owner, alice, bob)
     *  - Distributes ETH to test users
     *  - Deploys the USDC token contract
     *  - Deploys the SimpleDEX contract
     *  - Distributes USDC to test users
     *  - Adds initial liquidity to the DEX (from owner)
     */
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

    // ------------------------------------------------------------------------
    //                       STATELESS FUZZING TESTS
    // ------------------------------------------------------------------------

    /**
     * @notice Tests adding liquidity with fuzzed ETH amount
     * @dev Verifies:
     *  - LP tokens calculation is correct based on the provided ETH
     *  - Alice's LP token balance is updated correctly
     *  - ETH and USDC reserves are updated with the new liquidity
     */
    function testFuzz_AddLiquidity(uint96 ethAmount) public {
        // Bound ETH amount to prevent unrealistic values
        // Minimum 0.01 ETH, maximum 5 ETH
        uint256 ethToAdd = bound(uint256(ethAmount), 0.01 ether, 5 ether);

        // Calculate USDC amount required based on current ratio
        uint256 usdcRequired = (ethToAdd * dex.usdcReserve()) /
            dex.ethReserve();

        // Ensure Alice has enough USDC and ethToAdd is reasonable
        vm.assume(usdcRequired <= usdc.balanceOf(alice));

        // Store initial reserves and total supply
        uint256 initialUsdcReserve = dex.usdcReserve();
        uint256 initialEthReserve = dex.ethReserve();
        uint256 initialTotalSupply = dex.totalSupply();

        // Calculate expected LP tokens to be minted
        uint256 expectedLpTokens = (ethToAdd * initialTotalSupply) /
            initialEthReserve;

        // Alice adds liquidity
        vm.startPrank(alice);
        usdc.approve(address(dex), usdcRequired);
        uint256 lpTokensReceived = dex.addLiquidity{value: ethToAdd}(
            usdcRequired
        );
        vm.stopPrank();

        // Assertions
        // 1. LP tokens received should match expected amount
        assertApproxEqRel(lpTokensReceived, expectedLpTokens, 1e15); // Within 0.1% due to rounding

        // 2. DEX reserves should be updated correctly
        assertEq(dex.usdcReserve(), initialUsdcReserve + usdcRequired);
        assertEq(dex.ethReserve(), initialEthReserve + ethToAdd);

        // 3. Alice should have received the LP tokens
        assertEq(dex.balanceOf(alice), lpTokensReceived);
    }

    /**
     * @notice Tests the removeLiquidity function using fuzzed LP percentage to remove
     * @dev Verifies:
     *  - Correct calculation of ETH and USDC amounts to receive based on LP tokens burned
     *  - Alice's ETH and USDC balances increase by the expected amounts
     *  - DEX reserves are reduced by the correct amounts
     */
    function testFuzz_RemoveLiquidity(uint256 lpPercentage) public {
        // First, make Alice add liquidity to have LP tokens
        uint256 ethToAdd = 1 ether;
        uint256 usdcRequired = (ethToAdd * dex.usdcReserve()) /
            dex.ethReserve();

        vm.startPrank(alice);
        usdc.approve(address(dex), usdcRequired);
        uint256 aliceLpTokens = dex.addLiquidity{value: ethToAdd}(usdcRequired);

        // Bound LP percentage to remove between 1% and 100%
        lpPercentage = bound(lpPercentage, 1, 100);
        uint256 lpToRemove = (aliceLpTokens * lpPercentage) / 100;

        // Record reserves before removing
        uint256 usdcReserveBefore = dex.usdcReserve();
        uint256 ethReserveBefore = dex.ethReserve();
        uint256 totalSupplyBefore = dex.totalSupply();

        // Calculate expected returns
        uint256 expectedUsdc = (lpToRemove * usdcReserveBefore) /
            totalSupplyBefore;
        uint256 expectedEth = (lpToRemove * ethReserveBefore) /
            totalSupplyBefore;

        // Alice removes liquidity
        (uint256 usdcReceived, uint256 ethReceived) = dex.removeLiquidity(
            lpToRemove
        );
        vm.stopPrank();

        // Assertions
        // 1. Received amounts should match expected values
        assertEq(usdcReceived, expectedUsdc);
        assertEq(ethReceived, expectedEth);

        // 2. DEX reserves should be updated correctly
        assertEq(dex.usdcReserve(), usdcReserveBefore - usdcReceived);
        assertEq(dex.ethReserve(), ethReserveBefore - ethReceived);

        // 3. Alice's LP balance should be reduced
        assertEq(dex.balanceOf(alice), aliceLpTokens - lpToRemove);
    }

    // ------------------------------------------------------------------------
    //                          Swap Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests swapping ETH for USDC with fuzzed ETH amount
     * @dev Verifies:
     *  - Bob receives the correct amount of USDC based on the constant product formula with 0.3% fee
     *  - Bob's USDC balance increases by the calculated amount
     *  - DEX reserves are updated correctly (ETH increases, USDC decreases)
     *  - Constant product invariant holds (with fee considered)
     */
    function testFuzz_EthToUsdc(uint96 ethAmount) public {
        // Bound ETH amount between 0.001 ETH and 5 ETH
        uint256 ethToSwap = bound(uint256(ethAmount), 0.001 ether, 5 ether);

        // Record state before swap
        uint256 usdcReserveBefore = dex.usdcReserve();
        uint256 ethReserveBefore = dex.ethReserve();
        uint256 bobUsdcBefore = usdc.balanceOf(bob);

        // Calculate expected USDC output using constant product formula with fee
        uint256 expectedUsdc = (ethToSwap * 997 * usdcReserveBefore) /
            ((ethReserveBefore * 1000) + (ethToSwap * 997));

        // Bob swaps ETH for USDC
        vm.startPrank(bob);
        uint256 usdcReceived = dex.ethToUsdc{value: ethToSwap}();
        vm.stopPrank();

        // Assertions
        // 1. USDC received should match expected amount
        assertEq(usdcReceived, expectedUsdc);

        // 2. Bob's USDC balance should increase by the expected amount
        assertEq(usdc.balanceOf(bob), bobUsdcBefore + usdcReceived);

        // 3. DEX reserves should be updated correctly
        assertEq(dex.usdcReserve(), usdcReserveBefore - usdcReceived);
        assertEq(dex.ethReserve(), ethReserveBefore + ethToSwap);

        // 4. Constant product invariant should hold (with 0.3% fee applied)
        // k = ethReserve * usdcReserve
        uint256 k1 = ethReserveBefore * usdcReserveBefore;
        uint256 k2 = dex.ethReserve() * dex.usdcReserve();
        // k2 should be slightly larger than k1 due to fees
        assertGe(k2, k1);
    }

    /**
     * @notice Tests swapping USDC for ETH with fuzzed USDC amount
     * @dev Verifies:
     *  - Alice receives the correct amount of ETH based on the constant product formula with 0.3% fee
     *  - Alice's ETH balance increases by the calculated amount
     *  - DEX reserves are updated correctly (USDC increases, ETH decreases)
     *  - Constant product invariant holds (with fee considered)
     */
    function testFuzz_UsdcToEth(uint96 usdcAmount) public {
        // Bound USDC amount between 1 USDC and 5,000 USDC
        uint256 usdcToSwap = bound(
            uint256(usdcAmount),
            1 * 10 ** 18,
            5_000 * 10 ** 18
        );

        // Ensure Alice has enough USDC
        vm.assume(usdcToSwap <= usdc.balanceOf(alice));

        // Record state before swap
        uint256 usdcReserveBefore = dex.usdcReserve();
        uint256 ethReserveBefore = dex.ethReserve();
        uint256 aliceEthBefore = address(alice).balance;

        // Calculate expected ETH output using constant product formula with fee
        uint256 expectedEth = (usdcToSwap * 997 * ethReserveBefore) /
            ((usdcReserveBefore * 1000) + (usdcToSwap * 997));

        // Alice swaps USDC for ETH
        vm.startPrank(alice);
        usdc.approve(address(dex), usdcToSwap);
        uint256 ethReceived = dex.usdcToEth(usdcToSwap);
        vm.stopPrank();

        // Assertions
        // 1. ETH received should match expected amount
        assertEq(ethReceived, expectedEth);

        // 2. Alice's ETH balance should increase by the expected amount
        assertEq(address(alice).balance, aliceEthBefore + ethReceived);

        // 3. DEX reserves should be updated correctly
        assertEq(dex.usdcReserve(), usdcReserveBefore + usdcToSwap);
        assertEq(dex.ethReserve(), ethReserveBefore - ethReceived);

        // 4. Constant product invariant should hold (with 0.3% fee applied)
        // k = ethReserve * usdcReserve
        uint256 k1 = ethReserveBefore * usdcReserveBefore;
        uint256 k2 = dex.ethReserve() * dex.usdcReserve();
        // k2 should be slightly larger than k1 due to fees
        assertGe(k2, k1);
    }

    // ------------------------------------------------------------------------
    //                          Price Function Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests the price calculation functions with fuzzed reserve amounts
     * @dev Verifies:
     *  - getCurrentUsdcToEthPrice returns the correct price based on the fuzzed reserves
     *  - Prices are calculated using the spot price formula (reserve ratio * scaling factor)
     */
    function testFuzz_CurrentUsdcToEthPrice(
        uint256 ethReserve,
        uint256 usdcReserve
    ) public {
        // Bounds to prevent extreme values but still covering large range
        ethReserve = uint256(bound(ethReserve, 1 ether, 1_000_000 ether));
        usdcReserve = uint256(
            bound(usdcReserve, 1 * 10 ** 18, 2_000_000_000 * 10 ** 18)
        ); // up to 2B USDC

        // Since we can't directly set reserves, we'll create a new DEX and add liquidity
        USDCToken newUsdc = new USDCToken(usdcReserve * 2);
        SimpleDEX newDex = new SimpleDEX(address(newUsdc));

        // Add initial liquidity
        newUsdc.approve(address(newDex), usdcReserve);
        vm.deal(address(this), ethReserve);
        newDex.addLiquidity{value: ethReserve}(usdcReserve);

        // Calculate expected price
        uint256 expectedPrice = (usdcReserve * 1e18) / ethReserve;

        // Get actual price
        uint256 actualPrice = newDex.getCurrentUsdcToEthPrice();

        // Assert prices match
        assertEq(actualPrice, expectedPrice);
    }

    // ------------------------------------------------------------------------
    //                          Error Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests removing liquidity with extreme values to check for rounding errors
     * @dev Verifies:
     *  - Correct calculation of ETH and USDC amounts for small percentage removals
     *  - The exact ratio is maintained within 0.1% tolerance
     *  - Rounding errors are minimal (within 1 unit)
     */
    function testFuzz_RemoveLiquidityWithExtremeValues(
        uint16 lpPercentage
    ) public {
        // Add console log to debug the input
        console.log("Bound Result", lpPercentage);

        // Bound LP percentage to remove between 1% and 99.99%
        lpPercentage = uint16(bound(lpPercentage, 100, 9999)); // Start from 1% (100 basis points) to avoid tiny amounts

        // Owner removes a percentage of their LP tokens
        uint256 ownerLp = dex.balanceOf(owner);

        // Calculate LP tokens to remove, avoiding overflow
        // Use SafeMath approach for the multiplication
        uint256 lpToRemove;
        unchecked {
            // Calculate division first to avoid overflow, then multiply
            uint256 factor = lpPercentage * 100; // This is safe as lpPercentage is bounded to 9999 max
            lpToRemove = (ownerLp * factor) / 1_000_000;
        }

        // Ensure we're removing at least 1 LP token and not too close to zero
        vm.assume(lpToRemove > 100); // Avoid extremely small amounts

        // Calculate expected returns based on current reserves
        uint256 totalSupply = dex.totalSupply();
        uint256 usdcReserve = dex.usdcReserve();
        uint256 ethReserve = dex.ethReserve();

        uint256 expectedUsdc = (lpToRemove * usdcReserve) / totalSupply;
        uint256 expectedEth = (lpToRemove * ethReserve) / totalSupply;

        // Ensure expected amounts are non-zero
        vm.assume(expectedUsdc > 0 && expectedEth > 0);

        // Remove liquidity
        (uint256 usdcReceived, uint256 ethReceived) = dex.removeLiquidity(
            lpToRemove
        );

        // Assert received amounts match expected values, allowing for 1 unit of rounding error
        assertApproxEqAbs(usdcReceived, expectedUsdc, 1);
        assertApproxEqAbs(ethReceived, expectedEth, 1);

        // Verify the exact ratio is maintained within 0.1% tolerance
        // If share of LP tokens is X%, then user should receive X% of both assets
        uint256 receivedUsdcPercentage = (usdcReceived * 1e18) / usdcReserve;
        uint256 receivedEthPercentage = (ethReceived * 1e18) / ethReserve;
        uint256 removedLpPercentage = (lpToRemove * 1e18) / totalSupply;

        assertApproxEqRel(receivedUsdcPercentage, removedLpPercentage, 1e15); // Within 0.1%
        assertApproxEqRel(receivedEthPercentage, removedLpPercentage, 1e15); // Within 0.1%
    }
}