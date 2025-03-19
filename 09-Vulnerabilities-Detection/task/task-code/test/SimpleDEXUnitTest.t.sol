// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/Test.sol";
import {SimpleDEX} from "../src/SimpleDEX.sol";
import {USDCToken} from "../src/USDCToken.sol";

/**
 * @title SimpleDEXUnitTest
 * @notice Test suite for the SimpleDEX decentralized exchange contract
 * @dev This contract tests all core functionality of the SimpleDEX including:
 *      - Liquidity provision (adding and removing)
 *      - Token swaps (ETH <-> USDC)
 *      - Price calculations
 *      - Error handling
 *      - Fee calculation verification
 *      - Price impact
 *      - Event emission verification
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
contract SimpleDEXUnitTest is Test {
    // Contracts
    SimpleDEX public dex;
    USDCToken public usdc;

    // Users
    address public owner;
    address public alice;
    address public bob;
    address public charlie;

    // Test values
    uint256 constant INITIAL_USDC_SUPPLY = 1_000_000 * 10 ** 18; // 1M USDC
    uint256 constant INITIAL_USER_BALANCE = 10_000 * 10 ** 18; // 10k USDC per user
    uint256 constant INITIAL_ETH_AMOUNT = 50 ether;
    uint256 constant INITIAL_USDC_AMOUNT = 100_000 * 10 ** 18; // 100k USDC
    uint256 constant MINIMUM_LIQUIDITY = 1000;

    // Add receive function to allow test contract to receive ETH
    receive() external payable {}

    /**
     * @notice Sets up the test environment with users, tokens,
     * and initial liquidity before each test
     * This function:
     *  - Creates test accounts (owner, alice, bob, charlie)
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
        charlie = makeAddr("charlie");

        // Give each user some ETH
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);

        // Deploy USDC token
        usdc = new USDCToken(INITIAL_USDC_SUPPLY);

        // Deploy DEX
        dex = new SimpleDEX(address(usdc));

        // Distribute USDC to users
        usdc.transfer(alice, INITIAL_USER_BALANCE);
        usdc.transfer(bob, INITIAL_USER_BALANCE);
        usdc.transfer(charlie, INITIAL_USER_BALANCE);

        // Setup initial liquidity (as owner)
        usdc.approve(address(dex), INITIAL_USDC_AMOUNT);
        dex.addLiquidity{value: INITIAL_ETH_AMOUNT}(INITIAL_USDC_AMOUNT);
    }

    // ------------------------------------------------------------------------
    //                          Liquidity Provision Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests that initial liquidity was correctly set up in the DEX
     * @dev Verifies:
     *  - ETH and USDC reserves match the initial deposits
     *  - LP tokens were correctly issued to the owner
     *  - Total supply of LP tokens is correctly calculated including the minimum liquidity (1000)
     */
    function test_InitialLiquidity() public view {
        // TODO: Implement this test
        // ============================================================
        // EXERCISE: Initial Liquidity Check
        //
        // Verify that the initial liquidity setup in the DEX was correct.
        // This includes checking reserve values, LP token issuance to the
        // owner, and total supply calculations.
        // ============================================================
        assertTrue(false, "Test not implemented yet");
    }

    /**
     * @notice Tests the minimum liquidity lock mechanism
     * @dev Verifies:
     *  - MINIMUM_LIQUIDITY tokens are correctly locked at address(1)
     */
    function test_MinimumLiquidityLock() public view {
        // Verify minimum liquidity is locked at address(1)
        assertEq(dex.balanceOf(address(1)), MINIMUM_LIQUIDITY);
    }

    /**
     * @notice Tests the addLiquidity function when Alice adds more liquidity to the pool
     * @dev Verifies:
     *  - LP tokens calculation is correct based on the ratio of assets provided
     *  - Alice's LP token balance is updated correctly
     *  - ETH and USDC reserves are updated with the new liquidity
     *  - Correct event is emitted with correct parameters
     */
    function test_AddLiquidity() public {
        uint256 additionalEth = 2 ether;
        uint256 expectedUsdc = (additionalEth * dex.usdcReserve()) /
            dex.ethReserve();

        // Expected LP tokens calculation
        uint256 totalSupplyBefore = dex.totalSupply();
        uint256 expectedLPFromEth = (additionalEth * totalSupplyBefore) /
            dex.ethReserve();
        uint256 expectedLPFromUsdc = (expectedUsdc * totalSupplyBefore) /
            dex.usdcReserve();
        uint256 expectedLP = expectedLPFromEth < expectedLPFromUsdc
            ? expectedLPFromEth
            : expectedLPFromUsdc;

        // Test event emission
        vm.startPrank(alice);
        usdc.approve(address(dex), expectedUsdc);

        // Expect AddLiquidity event with correct parameters
        vm.expectEmit(true, false, false, true);
        emit SimpleDEX.AddLiquidity(
            alice,
            expectedUsdc,
            additionalEth,
            expectedLP
        );

        uint256 lpTokens = dex.addLiquidity{value: additionalEth}(expectedUsdc);
        vm.stopPrank();

        // Check LP tokens received
        assertEq(
            lpTokens,
            expectedLP,
            "LP tokens received do not match expected amount"
        );
        assertEq(
            dex.balanceOf(alice),
            lpTokens,
            "Alice's LP balance incorrect"
        );

        // Check reserves updated
        assertEq(
            dex.usdcReserve(),
            INITIAL_USDC_AMOUNT + expectedUsdc,
            "USDC reserve not updated correctly"
        );
        assertEq(
            dex.ethReserve(),
            INITIAL_ETH_AMOUNT + additionalEth,
            "ETH reserve not updated correctly"
        );
    }

    /**
     * @notice Tests the removeLiquidity function when owner withdraws half of their LP tokens
     * @dev Verifies:
     *  - Correct calculation of ETH and USDC amounts to receive based on LP tokens burned
     *  - Owner's ETH and USDC balances increase by the expected amounts
     *  - DEX reserves are reduced by the correct amounts
     *  - Correct event is emitted with correct parameters
     */
    function test_RemoveLiquidity() public {
        // TODO: Implement this test
        // ============================================================
        // EXERCISE: Test Liquidity Removal
        //
        // Implement a test that verifies removing liquidity works correctly.
        // You should test with the owner removing some portion of their LP tokens.
        // Verify expected return amounts, balance changes, reserve updates,
        // and proper event emission.
        // ============================================================
        assertTrue(false, "Test not implemented yet");
    }

    // ------------------------------------------------------------------------
    //                          Swap Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests swapping ETH for USDC
     * @dev Verifies:
     *  - Bob receives the correct amount of USDC based on the constant product formula with 0.3% fee
     *  - Bob's USDC balance increases by the calculated amount
     *  - DEX reserves are updated correctly (ETH increases, USDC decreases)
     *  - Correct event is emitted with correct parameters
     */
    function test_EthToUsdc() public {
        uint256 ethToSwap = 1 ether;
        uint256 usdcReserveBefore = dex.usdcReserve();
        uint256 ethReserveBefore = dex.ethReserve();

        vm.startPrank(bob);
        uint256 bobUsdcBefore = usdc.balanceOf(bob);

        // Calculate expected output using constant product formula
        uint256 expectedUsdc = (ethToSwap * 997 * usdcReserveBefore) /
            ((ethReserveBefore * 1000) + (ethToSwap * 997));

        // Expect EthPurchase event
        vm.expectEmit(true, false, false, true);
        emit SimpleDEX.EthPurchase(bob, expectedUsdc, ethToSwap);

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

    /**
     * @notice Tests swapping USDC for ETH
     * @dev Verifies:
     *  - Alice receives the correct amount of ETH based on the constant product formula with 0.3% fee
     *  - Alice's ETH balance increases by the calculated amount
     *  - DEX reserves are updated correctly (USDC increases, ETH decreases)
     *  - Correct event is emitted with correct parameters
     */
    function test_UsdcToEth() public {
        // TODO: Implement this test
        // ============================================================
        // EXERCISE: Test USDC to ETH Swap
        //
        // Create a test for swapping USDC to ETH. Make sure to verify
        // the swap uses the correct constant product formula with the
        // 0.3% fee applied. Check that Alice receives the correct ETH amount,
        // her balance increases appropriately, and the reserves update
        // correctly. Don't forget to test event emission.
        // ============================================================
        assertTrue(false, "Test not implemented yet");
    }

    /**
     * @notice Tests the accumulation of swap fees in the pool
     * @dev Verifies:
     *  - After swaps, the constant product (k) increases due to fees
     *  - LP providers benefit from accumulated fees when removing liquidity
     */
    function test_FeesAccumulation() public {
        // Record initial state
        uint256 initialK = dex.usdcReserve() * dex.ethReserve();

        // Have Bob perform a swap
        vm.startPrank(bob);
        dex.ethToUsdc{value: 1 ether}();
        vm.stopPrank();

        // Have Alice perform a swap
        vm.startPrank(alice);
        usdc.approve(address(dex), 1000 * 10 ** 18);
        dex.usdcToEth(1000 * 10 ** 18);
        vm.stopPrank();

        // Calculate new constant product
        uint256 newK = dex.usdcReserve() * dex.ethReserve();

        // Verify fees have increased the constant product
        assertGt(
            newK,
            initialK,
            "Constant product should increase due to fees"
        );

        // Now verify LP providers benefit from these fees
        // Add LP position for Charlie
        vm.startPrank(charlie);
        uint256 charlieEthBefore = address(charlie).balance;
        uint256 charlieUsdcBefore = usdc.balanceOf(charlie);

        // Add liquidity
        uint256 ethToAdd = 1 ether;
        uint256 usdcToAdd = (ethToAdd * dex.usdcReserve()) / dex.ethReserve();
        usdc.approve(address(dex), usdcToAdd);
        uint256 lpTokens = dex.addLiquidity{value: ethToAdd}(usdcToAdd);

        // Remove liquidity immediately
        (uint256 usdcReceived, uint256 ethReceived) = dex.removeLiquidity(
            lpTokens
        );
        vm.stopPrank();

        // Due to the tiny precision loss in solidity calculations and rounding,
        // we allow for a very small loss (0.1% or less) when removing liquidity
        assertApproxEqRel(
            address(charlie).balance,
            charlieEthBefore - ethToAdd + ethReceived,
            0.001e18, // 0.1% tolerance
            "Charlie's ETH should not significantly decrease"
        );

        assertApproxEqRel(
            usdc.balanceOf(charlie),
            charlieUsdcBefore - usdcToAdd + usdcReceived,
            0.001e18, // 0.1% tolerance
            "Charlie's USDC should not significantly decrease"
        );
    }

    /**
     * @notice Tests the impact of large trades on exchange rates
     * @dev Verifies price changes correctly according to the constant product formula
     */
    function test_PriceImpact() public {
        // TODO: Implement this test
        // ============================================================
        // EXERCISE: Test Large Trade Price Impact
        //
        // Implement a test that demonstrates how large trades impact
        // the exchange rate in the pool. You should examine how
        // the price changes after a significant swap.
        // ============================================================
        assertTrue(false, "Test not implemented yet");
    }

    // ------------------------------------------------------------------------
    //                          Error Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests that addLiquidity properly reverts when insufficient USDC is provided
     * @dev Verifies:
     *  - The transaction reverts with the expected InsufficientUSDCAmount error
     *  - The error contains the correct parameters (actual amount vs required amount)
     */
    function test_RevertWhen_InsufficientUSDCAmount() public {
        uint256 additionalEth = 2 ether;
        uint256 requiredUsdc = (additionalEth * dex.usdcReserve()) /
            dex.ethReserve();
        uint256 insufficientUsdc = requiredUsdc - 1; // Just under the required amount

        // Alice tries to add liquidity with insufficient USDC
        vm.startPrank(alice);
        usdc.approve(address(dex), insufficientUsdc);

        // Should revert with InsufficientUSDCAmount error
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleDEX.InsufficientUSDCAmount.selector,
                insufficientUsdc,
                requiredUsdc
            )
        );
        dex.addLiquidity{value: additionalEth}(insufficientUsdc);
        vm.stopPrank();
    }

    /**
     * @notice Tests that removeLiquidity properly reverts when insufficient LP tokens are available
     * @dev Verifies:
     *  - The transaction reverts with the expected InsufficientLiquidityTokens error
     *  - The error contains the correct parameters (requested amount vs actual balance)
     */
    function test_RevertWhen_InsufficientLiquidityTokens() public {
        // TODO: Implement this test
        // ============================================================
        // EXERCISE: Test Error on Insufficient LP Tokens
        //
        // Create a test that verifies the DEX correctly reverts when
        // a user tries to remove more LP tokens than they have.
        // ============================================================
        assertTrue(false, "Test not implemented yet");
    }

    /**
     * @notice Tests usdcToEth with insufficient allowance
     * @dev Verifies swap fails when DEX doesn't have enough allowance
     */
    function test_RevertWhen_InsufficientAllowance() public {
        vm.startPrank(alice);

        // Alice does NOT approve the DEX to spend her USDC
        uint256 usdcToSwap = 1000 * 10 ** 18;

        // Attempt to swap without approval should revert
        vm.expectRevert();
        dex.usdcToEth(usdcToSwap);

        vm.stopPrank();
    }

    /**
     * @notice Tests swaps with zero input amount
     * @dev Verifies swaps with zero input amount properly revert
     */
    function test_RevertWhen_ZeroSwapAmount() public {
        // Try to swap zero ETH
        vm.expectRevert();
        dex.ethToUsdc{value: 0}();

        // Try to swap zero USDC
        vm.startPrank(alice);
        usdc.approve(address(dex), 0);
        vm.expectRevert();
        dex.usdcToEth(0);
        vm.stopPrank();
    }

    /**
     * @notice Tests initializing a pool with zero amounts
     * @dev Verifies zero-amount liquidity provision properly reverts
     */
    function test_RevertWhen_ZeroLiquidityProvided() public {
        // TODO: Implement this test
        // ============================================================
        // EXERCISE: Test Error on Zero Liquidity Provision
        //
        // Verify that the DEX correctly handles (rejects) attempts
        // to provide zero liquidity.
        // ============================================================
        assertTrue(false, "Test not implemented yet");
    }

    // ------------------------------------------------------------------------
    //                          Price Function Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests the price calculation functions in the DEX
     * @dev Verifies:
     *  - getCurrentUsdcToEthPrice returns the correct price based on the current reserves
     *  - getCurrentEthToUsdcPrice returns the correct price based on the current reserves
     *  - Prices are calculated using the spot price formula (reserve ratio * scaling factor)
     */
    function test_PriceFunctions() public view {
        // Calculate expected prices
        uint256 expectedUsdcPerEth = (dex.usdcReserve() * 1e18) /
            dex.ethReserve();
        uint256 expectedEthPerUsdc = (dex.ethReserve() * 1e18) /
            dex.usdcReserve();

        // Check price functions
        assertEq(dex.getCurrentUsdcToEthPrice(), expectedUsdcPerEth);
        assertEq(dex.getCurrentEthToUsdcPrice(), expectedEthPerUsdc);
    }

    // ------------------------------------------------------------------------
    //                          Helper Functions
    // ------------------------------------------------------------------------

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
