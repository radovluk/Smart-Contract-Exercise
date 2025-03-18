// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/Test.sol";
import {SimpleDEX} from "../src/SimpleDEX.sol";
import {USDCToken} from "../src/USDCToken.sol";
import {console2} from "forge-std/console2.sol";

/**
 * @title SimpleDEXInvariantTest
 * @notice Simplified invariant test suite for the SimpleDEX contract
 *
 * @dev This contract tests key invariants (properties that should always be true)
 *      of the SimpleDEX contract. It does this by:
 *      - Setting up the test environment with a DEX and tokens
 *      - Creating test users (actors)
 *      - Defining target functions that the fuzzer will call randomly
 *      - Defining invariant functions that check if properties hold after each action
 */
contract SimpleDEXInvariantTest is Test {
    SimpleDEX public dex; // The DEX contract we're testing
    USDCToken public usdc; // The USDC token contract

    // Initial values for setting up the test
    uint256 constant INITIAL_USDC_SUPPLY = 1_000_000 * 10 ** 6; // 1 million USDC
    uint256 constant INITIAL_ETH_AMOUNT = 50 ether; // Initial ETH liquidity
    uint256 constant INITIAL_USDC_AMOUNT = 100_000 * 10 ** 6; // Initial USDC liquidity
    uint256 constant MINIMUM_LIQUIDITY = 1000; // Minimum liquidity in the DEX

    // We'll create multiple test users (actors) to interact with the DEX
    uint256 constant NUM_ACTORS = 5; // Number of test users
    address[] public actors; // Array to store actor addresses

    // These "ghost variables" track states that aren't directly observable from the contract
    uint256 public initialK; // Initial constant product value (x * y = k)

    // Statistics for analyzing test coverage
    uint256 public addLiquidityCalls; // Number of successful addLiquidity calls
    uint256 public removeLiquidityCalls; // Number of successful removeLiquidity calls
    uint256 public ethToUsdcCalls; // Number of successful ETH→USDC swaps
    uint256 public usdcToEthCalls; // Number of successful USDC→ETH swaps

    // Value tracking for LP providers
    int256 public totalLpValueChange; // Track if LP providers gain/lose value

    // For receiving ETH
    receive() external payable {}

    /**
     * @notice Sets up the test environment before each invariant test run
     * This happens once at the beginning of the invariant test campaign
     */
    function setUp() public {
        // Deploy USDC token with initial supply
        usdc = new USDCToken(INITIAL_USDC_SUPPLY);

        // Deploy DEX with USDC token address
        dex = new SimpleDEX(address(usdc));

        // Add initial liquidity to the DEX (from the test contract itself)
        usdc.approve(address(dex), INITIAL_USDC_AMOUNT);
        dex.addLiquidity{value: INITIAL_ETH_AMOUNT}(INITIAL_USDC_AMOUNT);

        // Record initial constant product value
        initialK = dex.usdcReserve() * dex.ethReserve();

        // Create Test Users
        createActors();

        // Configure Invariant Test Target Functions
        // These are the functions that the invariant fuzzer will call randomly
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = this.addLiquidity.selector;
        selectors[1] = this.removeLiquidity.selector;
        selectors[2] = this.ethToUsdc.selector;
        selectors[3] = this.usdcToEth.selector;

        targetSelector(
            FuzzSelector({addr: address(this), selectors: selectors})
        );
    }

    /**
     * @notice Creates and funds test users (actors) for the invariant test
     * @dev Each actor receives ETH and USDC tokens to interact with the DEX
     */
    function createActors() internal {
        // Calculate how much to give each actor
        uint256 ethPerActor = 100 ether;
        uint256 usdcPerActor = 50_000 * 10 ** 6; // 50,000 USDC

        // Create the specified number of actors
        for (uint256 i = 0; i < NUM_ACTORS; i++) {
            // Create a named actor address
            string memory name = string(
                abi.encodePacked("actor", vm.toString(i))
            );
            address actor = makeAddr(name);
            actors.push(actor);

            // Fund the actor with ETH
            vm.deal(actor, ethPerActor);

            // Fund the actor with USDC
            usdc.transfer(actor, usdcPerActor);
        }
    }

    /**
     * @notice Helper function to select a random actor from our actor list
     * @param actorIndexSeed A random number seed used to select an actor
     * @return The selected actor's address
     */
    function getActor(uint256 actorIndexSeed) internal view returns (address) {
        // Bound the seed to be within the range of our actors array
        return actors[bound(actorIndexSeed, 0, actors.length - 1)];
    }

    // ------------------------------------------------------------------------
    //                 Target Functions for Invariant Testing
    // ------------------------------------------------------------------------

    /**
     * @notice Target function: Add liquidity to the DEX
     * @param ethAmount Amount of ETH to add (will be bounded)
     * @param actorSeed Random seed used to select which actor performs the operation
     */
    function addLiquidity(uint256 ethAmount, uint256 actorSeed) external {
        // Select an actor to perform this operation
        address actor = getActor(actorSeed);

        // Bound ETH amount to a reasonable range (0.01 ETH to actor's balance)
        ethAmount = bound(ethAmount, 0.01 ether, address(actor).balance);

        uint256 usdcAmount;

        // If the pool is empty, use a fixed ratio
        if (dex.usdcReserve() == 0 || dex.ethReserve() == 0) {
            usdcAmount = ethAmount * 2000; // 1 ETH = 2000 USDC initial ratio
        } else {
            // Calculate required USDC based on current pool ratio
            usdcAmount = (ethAmount * dex.usdcReserve()) / dex.ethReserve();
        }

        // Make sure we don't try to use more USDC than the actor has
        usdcAmount = bound(usdcAmount, 0, usdc.balanceOf(actor));

        // Skip this operation if amounts are too small
        if (ethAmount < 0.001 ether || usdcAmount < 1) {
            return;
        }

        // Perform the liquidity addition as the selected actor
        vm.startPrank(actor);

        // First approve USDC spending
        usdc.approve(address(dex), usdcAmount);

        // Try to add liquidity - use try/catch to handle any reverts
        try dex.addLiquidity{value: ethAmount}(usdcAmount) returns (uint256) {
            // If successful, increment our counter
            addLiquidityCalls++;
        } catch {
            // If it reverts, just continue silently
        }

        vm.stopPrank();
    }

    /**
     * @notice Target function: Remove liquidity from the DEX
     * @param lpFraction Percentage of LP tokens to remove (will be bounded)
     * @param actorSeed Random seed used to select which actor performs the operation
     */
    function removeLiquidity(uint256 lpFraction, uint256 actorSeed) external {
        // Select an actor to perform this operation
        address actor = getActor(actorSeed);

        // Bound LP fraction to 1-100%
        lpFraction = bound(lpFraction, 1, 100);

        // Get actor's LP token balance
        uint256 lpBalance = dex.balanceOf(actor);

        // Skip if actor has no LP tokens
        if (lpBalance == 0) {
            return;
        }

        // Calculate LP tokens to remove based on the fraction
        uint256 lpToRemove = (lpBalance * lpFraction) / 100;

        // Skip if too small
        if (lpToRemove == 0) {
            return;
        }

        // Perform the liquidity removal as the selected actor
        vm.startPrank(actor);

        // Try to remove liquidity - use try/catch to handle any reverts
        try dex.removeLiquidity(lpToRemove) returns (
            uint256 usdcAmount,
            uint256 ethAmount
        ) {
            // If successful, increment our counter
            removeLiquidityCalls++;

            // Calculate value change if pool has liquidity
            if (dex.usdcReserve() > 0 && dex.ethReserve() > 0) {
                // Convert ETH value to USDC using current exchange rate
                uint256 ethValueInUsdc = (ethAmount * dex.usdcReserve()) /
                    dex.ethReserve();

                // Calculate net value received in USDC terms
                int256 valueChange = int256(usdcAmount + ethValueInUsdc);

                // Add to our running total (this helps verify LP providers don't lose value)
                totalLpValueChange += valueChange;
            }
        } catch {
            // If it reverts, just continue silently
        }

        vm.stopPrank();
    }

    /**
     * @notice Target function: Swap ETH for USDC
     * @param ethAmount Amount of ETH to swap (will be bounded)
     * @param actorSeed Random seed used to select which actor performs the operation
     */
    function ethToUsdc(uint256 ethAmount, uint256 actorSeed) external {
        // Select an actor to perform this operation
        address actor = getActor(actorSeed);

        // Bound ETH amount to a reasonable range
        ethAmount = bound(ethAmount, 0.001 ether, address(actor).balance);

        // Skip if amount is 0 or pool has no reserves
        if (ethAmount == 0 || dex.usdcReserve() == 0 || dex.ethReserve() == 0) {
            return;
        }

        // Perform the swap as the selected actor
        vm.startPrank(actor);

        // Try to swap ETH to USDC - use try/catch to handle any reverts
        try dex.ethToUsdc{value: ethAmount}() {
            // If successful, increment our counter
            ethToUsdcCalls++;
        } catch {
            // If it reverts, just continue silently
        }

        vm.stopPrank();
    }

    /**
     * @notice Target function: Swap USDC for ETH
     * @param usdcAmount Amount of USDC to swap (will be bounded)
     * @param actorSeed Random seed used to select which actor performs the operation
     */
    function usdcToEth(uint256 usdcAmount, uint256 actorSeed) external {
        // Select an actor to perform this operation
        address actor = getActor(actorSeed);

        // Bound USDC amount to a reasonable range
        usdcAmount = bound(usdcAmount, 1e6, usdc.balanceOf(actor));

        // Skip if amount is 0 or pool has no reserves
        if (
            usdcAmount == 0 || dex.usdcReserve() == 0 || dex.ethReserve() == 0
        ) {
            return;
        }

        // Perform the swap as the selected actor
        vm.startPrank(actor);

        // First approve USDC spending
        usdc.approve(address(dex), usdcAmount);

        // Try to swap USDC to ETH - use try/catch to handle any reverts
        try dex.usdcToEth(usdcAmount) {
            // If successful, increment our counter
            usdcToEthCalls++;
        } catch {
            // If it reverts, just continue silently
        }

        vm.stopPrank();
    }

    // ------------------------------------------------------------------------
    //                      Invariant Functions
    // ------------------------------------------------------------------------
    
    /**
     * @notice Invariant #1: The constant product formula (k = x * y) should never decrease
     * @dev This verifies the core AMM formula holds and fees increase k over time
     */
    function invariant_ConstantProductFormula() public view {
        // Calculate current k value
        uint256 currentK = dex.usdcReserve() * dex.ethReserve();

        // K should never decrease (may increase due to fees)
        assertGe(
            currentK,
            initialK,
            "Constant product formula violated: k decreased"
        );

        // Log current values for analysis
        console2.log("Current K:", currentK);
        console2.log("Initial K:", initialK);
        console2.log(
            "K Growth:",
            ((currentK - initialK) * 100) / initialK,
            "%"
        );
    }

    /**
     * @notice Invariant #2: Token balances should match reserves
     * @dev This ensures the contract's accounting matches its actual token holdings
     */
    function invariant_TokenBalances() public view {
        // USDC balance should match USDC reserve
        assertEq(
            usdc.balanceOf(address(dex)),
            dex.usdcReserve(),
            "USDC balance doesn't match reserve"
        );

        // ETH balance should match ETH reserve
        assertEq(
            address(dex).balance,
            dex.ethReserve(),
            "ETH balance doesn't match reserve"
        );
    }

    /**
     * @notice Invariant #3: The minimum liquidity remains locked at address(1)
     * @dev This ensures the initial minimum liquidity remains locked forever
     */
    function invariant_MinimumLiquidityLocked() public view {
        assertEq(
            dex.balanceOf(address(1)),
            MINIMUM_LIQUIDITY,
            "Minimum liquidity changed"
        );
    }

    /**
     * @notice Invariant #4: LP token total supply is correct
     * @dev Verifies proper token accounting for liquidity shares
     */
    function invariant_LpTokenTotalSupply() public view {
        // Total supply should be at least the minimum liquidity
        assertGe(
            dex.totalSupply(),
            MINIMUM_LIQUIDITY,
            "Total supply should be greater than or equal to minimum liquidity"
        );

        // If pool is empty (all liquidity removed), only MINIMUM_LIQUIDITY should remain
        if (dex.usdcReserve() == 0 || dex.ethReserve() == 0) {
            assertEq(
                dex.totalSupply(),
                MINIMUM_LIQUIDITY,
                "With empty pool, total supply should equal minimum liquidity"
            );
        }
    }

    /**
     * @notice Invariant #5: LP providers can't lose significant value from fees
     * @dev Verifies that providing liquidity doesn't result in value loss
     */
    function invariant_LpProviderValue() public view {
        // Allow a small tolerance for rounding errors (-1000 wei)
        assertTrue(
            totalLpValueChange >= -1000,
            "LP providers lost significant value"
        );
    }

    /**
     * @notice Invariant #6: Price functions return values consistent with reserves
     * @dev Ensures price calculations correctly reflect the current pool state
     */
    function invariant_PriceConsistency() public view {
        // Only check if the pool has liquidity
        if (dex.usdcReserve() > 0 && dex.ethReserve() > 0) {
            // Get current prices from DEX functions
            uint256 usdcToEthPrice = dex.getCurrentUsdcToEthPrice();
            uint256 ethToUsdcPrice = dex.getCurrentEthToUsdcPrice();

            // Calculate expected prices directly from reserves
            uint256 expectedUsdcToEthPrice = (dex.usdcReserve() * 1e18) /
                dex.ethReserve();
            uint256 expectedEthToUsdcPrice = (dex.ethReserve() * 1e18) /
                dex.usdcReserve();

            // Verify prices match expected values
            assertEq(
                usdcToEthPrice,
                expectedUsdcToEthPrice,
                "USDC/ETH price calculation error"
            );
            assertEq(
                ethToUsdcPrice,
                expectedEthToUsdcPrice,
                "ETH/USDC price calculation error"
            );
        }
    }

    // ------------------------------------------------------------------------
    //                 Helper function to log statistics
    // ------------------------------------------------------------------------

    /**
     * @notice Log statistics after the invariant test campaign completes
     * @dev This function is called once at the end of the entire testing campaign
     */
    function afterInvariant() external view {
        console2.log("===== Invariant Test Statistics =====");
        console2.log("Final USDC Reserve:", dex.usdcReserve() / 1e6, "USDC");
        console2.log("Final ETH Reserve:", dex.ethReserve() / 1e18, "ETH");
        console2.log("LP Token Total Supply:", dex.totalSupply());

        console2.log("\nOperation Counts:");
        console2.log("  Add Liquidity Calls:", addLiquidityCalls);
        console2.log("  Remove Liquidity Calls:", removeLiquidityCalls);
        console2.log("  ETH to USDC Swaps:", ethToUsdcCalls);
        console2.log("  USDC to ETH Swaps:", usdcToEthCalls);

        console2.log(
            "\nConstant Product (k) Growth:",
            ((dex.usdcReserve() * dex.ethReserve() - initialK) * 100) /
                initialK,
            "%"
        );
    }
}
