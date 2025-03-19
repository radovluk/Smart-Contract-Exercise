// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {SimpleDEX} from "../src/SimpleDEX.sol";
import {USDCToken} from "../src/USDCToken.sol";

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
        // TODO: Implement this test
        // ============================================================
        // EXERCISE: Fuzz Test for Adding Liquidity
        //
        // Create a test that verifies adding liquidity with random ETH amounts.
        // Use bound() to limit the ETH to a reasonable range.
        // Consider how the USDC amount needs to be calculated based on the current
        // reserve ratio.
        // ============================================================
        assertTrue(false, "Test not implemented yet");
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
        // TODO: Implement this test
        // ============================================================
        // EXERCISE: Fuzz Test for ETH to USDC Swaps
        //
        // Create a test that verifies ETH to USDC swaps with random ETH amounts.
        // Make sure to bound the input to reasonable values and calculate the
        // expected USDC output using the constant product formula with the 0.3% fee.
        // ============================================================
        assertTrue(false, "Test not implemented yet");
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
        // TODO: Implement this test
        // ============================================================
        // EXERCISE: Fuzz Test for Price Calculation
        //
        // Create a test that verifies the price calculation functions with
        // randomized reserve amounts. Because you can't directly manipulate
        // reserves in the original DEX, you'll need to create a new DEX instance
        // with the fuzzed reserve values.
        // ============================================================
        assertTrue(false, "Test not implemented yet");
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
        // TODO: Implement this test
        // ============================================================
        // EXERCISE: Fuzz Test for Edge Case Liquidity Removal
        //
        // Create a test that checks removing liquidity with extreme values,
        // focusing on potential rounding errors. Pay special attention to handling
        // small percentage removals and verifying that asset ratios are maintained.
        // Use assertApproxEqAbs and assertApproxEqRel for comparing values that
        // might have minimal rounding errors.
        // ============================================================
        assertTrue(false, "Test not implemented yet");
    }
}
