// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/Test.sol";
import {SimpleDEX} from "../src/SimpleDEX.sol";
import {USDCToken} from "../src/USDCToken.sol";
import {console2} from "forge-std/console2.sol";

/**
 * @title SimpleDEXInvariantTest
 * @notice Invariant test suite for the SimpleDEX contract following Foundry best practices
 */
contract SimpleDEXInvariantTest is Test {
    SimpleDEX public dex;
    USDCToken public usdc;
    SimpleDEXHandler public handler;

    // Constants for test setup
    uint256 constant INITIAL_USDC_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion USDC
    uint256 constant INITIAL_ETH_AMOUNT = 50 ether;
    uint256 constant INITIAL_USDC_AMOUNT = 100_000 * 10 ** 18;
    uint256 constant MINIMUM_LIQUIDITY = 1000;

    // Events for logging
    event InvariantResult(string name, uint256 value);

    // For receiving ETH
    receive() external payable {}

    /**
     * @notice Sets up the test environment before each invariant test run
     */
    function setUp() public {
        // Deploy tokens
        usdc = new USDCToken(INITIAL_USDC_SUPPLY);

        // Deploy DEX
        dex = new SimpleDEX(address(usdc));

        // Add initial liquidity
        usdc.approve(address(dex), INITIAL_USDC_AMOUNT);
        dex.addLiquidity{value: INITIAL_ETH_AMOUNT}(INITIAL_USDC_AMOUNT);

        // Reserve USDC for the handler
        uint256 usdcForHandler = 1_000_000 * 10 ** 18;

        // Deploy handler
        handler = new SimpleDEXHandler(dex, usdc);

        // Transfer funds to handler
        usdc.transfer(address(handler), usdcForHandler);
        handler.fundActors();

        // Explicitly define target selectors from handler
        // This ensures only these functions are called during testing
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = handler.addLiquidity.selector;
        selectors[1] = handler.removeLiquidity.selector;
        selectors[2] = handler.ethToUsdc.selector;
        selectors[3] = handler.usdcToEth.selector;

        // Target only the handler contract with specific selectors
        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );

        // Exclude the token from being targeted
        excludeContract(address(usdc));

        // Exclude the DEX from being directly targeted
        // All interactions should go through the handler
        excludeContract(address(dex));
    }

    /**
     * @notice Called after each invariant test campaign completes
     */
    function afterInvariant() external view {
        // Log statistics about the campaign
        console2.log("=== Invariant Test Campaign Summary ===");
        console2.log("Final K value:", dex.usdcReserve() * dex.ethReserve());
        console2.log("Initial K value:", handler.initialK());
        console2.log(
            "K Growth (%):",
            ((dex.usdcReserve() * dex.ethReserve() - handler.initialK()) *
                100) / handler.initialK()
        );
        console2.log("Total LP value change:", handler.totalLpValueChange());
        console2.log("Total swap count:", handler.swapCount());
        console2.log(
            "Total liquidity actions:",
            handler.liquidityActionCount()
        );
    }

    /**
     * @notice Invariant #1: The constant product formula (k = x * y) should never decrease
     */
    function invariant_ConstantProductFormula() public view {
        // Calculate current k value
        uint256 currentK = dex.usdcReserve() * dex.ethReserve();

        // K should never decrease (may increase due to fees)
        assertGe(
            currentK,
            handler.initialK(),
            "Constant product formula violated: k decreased"
        );
    }

    /**
     * @notice Invariant #2: Additional Custom Invariant Test
     * @dev ============================================================
     * EXERCISE:
     * Implement a custom invariant for the SimpleDEX contract.
     * Replace the assertTrue(false, ...) with your own invariant check.
     * ============================================================
     */
    function invariant_CustomTest1() public view {
        // TODO: Implement this test
        assertTrue(false, "Custom Invariant Test 1 not implemented");
    }

    /**
     * @notice Invariant #3: Additional Custom Invariant Test
     * @dev ============================================================
     * EXERCISE:
     * Implement a custom invariant for the SimpleDEX contract.
     * Replace the assertTrue(false, ...) with your own invariant check.
     * ============================================================
     */
    function invariant_CustomTest2() public view {
        // TODO: Implement this test
        assertTrue(false, "Custom Invariant Test 2 not implemented");
    }

    /**
     * @notice Invariant #4: Additional Custom Invariant Test
     * @dev ============================================================
     * EXERCISE:
     * Implement a custom invariant for the SimpleDEX contract.
     * Replace the assertTrue(false, ...) with your own invariant check.
     * ============================================================
     */
    function invariant_CustomTest3() public view {
        // TODO: Implement this test
        assertTrue(false, "Custom Invariant Test 3 not implemented");
    }
}

/**
 * @title SimpleDEXHandler
 * @notice Handler contract for invariant testing of the SimpleDEX following Foundry best practices
 */
contract SimpleDEXHandler is Test {
    SimpleDEX public immutable dex;
    USDCToken public immutable usdc;

    // Actor management
    uint256 constant NUM_ACTORS = 5;
    address[] public actors;

    // Ghost variables for tracking state
    uint256 public initialK;
    int256 public totalLpValueChange;
    uint256 public swapCount;
    uint256 public liquidityActionCount;

    // Per-actor tracking
    mapping(address => uint256) public actorLpTokens;
    mapping(address => uint256) public actorEthDeposited;
    mapping(address => uint256) public actorUsdcDeposited;

    // For receiving ETH
    receive() external payable {}

    constructor(SimpleDEX _dex, USDCToken _usdc) {
        dex = _dex;
        usdc = _usdc;

        // Record initial constant product value
        initialK = dex.usdcReserve() * dex.ethReserve();

        // Create actors (without funding)
        createActors();
    }

    /**
     * @notice Creates test users (actors) for the invariant test
     */
    function createActors() internal {
        for (uint256 i = 0; i < NUM_ACTORS; i++) {
            string memory name = string(
                abi.encodePacked("actor", vm.toString(i))
            );
            address actor = makeAddr(name);
            actors.push(actor);
        }
    }

    /**
     * @notice Funds all created actors with ETH and USDC
     */
    function fundActors() public {
        // Calculate how much to give each actor
        uint256 ethPerActor = 100 ether;
        uint256 usdcPerActor = 50_000 * 10 ** 18; // 50,000 USDC

        for (uint256 i = 0; i < NUM_ACTORS; i++) {
            address actor = actors[i];

            // Fund with ETH
            vm.deal(actor, ethPerActor);

            // Fund with USDC
            usdc.transfer(actor, usdcPerActor);
        }
    }

    /**
     * @notice Helper to select a random actor from our actor list
     */
    function getActor(uint256 actorIndexSeed) internal view returns (address) {
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
        address actor = getActor(actorSeed);

        // Skip if actor has insufficient ETH
        if (address(actor).balance < 0.01 ether) return;

        // Now we can safely bound the ETH amount
        ethAmount = bound(ethAmount, 0.01 ether, address(actor).balance);

        // Calculate equivalent USDC based on current price
        uint256 usdcAmount = 0;
        if (dex.usdcReserve() > 0 && dex.ethReserve() > 0) {
            usdcAmount = (ethAmount * dex.usdcReserve()) / dex.ethReserve();
        } else {
            usdcAmount = ethAmount * 1000; // Initial ratio
        }

        // Skip if not enough USDC
        if (usdcAmount > usdc.balanceOf(actor)) return;

        vm.startPrank(actor);
        usdc.approve(address(dex), usdcAmount);

        try dex.addLiquidity{value: ethAmount}(usdcAmount) {
            // Track actor's contribution
            actorEthDeposited[actor] += ethAmount;
            actorUsdcDeposited[actor] += usdcAmount;

            // Increment counter
            liquidityActionCount++;
        } catch {
            // Operation failed - no state change
        }

        vm.stopPrank();
    }

    /**
     * @notice Target function: Remove liquidity from the DEX
     * @param lpFraction Percentage of LP tokens to remove (1-100)
     * @param actorSeed Random seed used to select which actor performs the operation
     */
    function removeLiquidity(uint256 lpFraction, uint256 actorSeed) external {
        address actor = getActor(actorSeed);

        // Bound LP fraction to 1-100%
        lpFraction = bound(lpFraction, 1, 100);

        // Get actor's LP token balance
        uint256 lpBalance = dex.balanceOf(actor);

        // Skip if actor has no LP tokens
        if (lpBalance == 0) return;

        // Calculate LP tokens to remove based on the fraction
        uint256 lpToRemove = (lpBalance * lpFraction) / 100;

        // Skip if too small
        if (lpToRemove == 0) return;

        vm.startPrank(actor);

        try dex.removeLiquidity(lpToRemove) {
            // Increment counter
            liquidityActionCount++;
        } catch {
            // Operation failed - no state change
        }

        vm.stopPrank();
    }

    /**
     * @notice Target function: Swap ETH for USDC
     * @param ethAmount Amount of ETH to swap
     * @param actorSeed Random seed used to select which actor performs the operation
     */
    function ethToUsdc(uint256 ethAmount, uint256 actorSeed) external {
        address actor = getActor(actorSeed);

        // Skip if actor has insufficient balance or if pool has no reserves
        if (
            address(actor).balance < 0.001 ether ||
            dex.usdcReserve() == 0 ||
            dex.ethReserve() == 0
        ) return;

        // Now we can safely bound the ETH amount
        ethAmount = bound(ethAmount, 0.001 ether, address(actor).balance);

        vm.startPrank(actor);

        try dex.ethToUsdc{value: ethAmount}() {
            // Increment swap counter
            swapCount++;
        } catch {
            // Swap failed
        }

        vm.stopPrank();
    }

    /**
     * @notice Target function: Swap USDC for ETH
     * @param usdcAmount Amount of USDC to swap
     * @param actorSeed Random seed used to select which actor performs the operation
     */
    function usdcToEth(uint256 usdcAmount, uint256 actorSeed) external {
        address actor = getActor(actorSeed);

        // Skip if actor has no USDC or if pool has no reserves
        if (
            usdc.balanceOf(actor) < 1 ||
            dex.usdcReserve() == 0 ||
            dex.ethReserve() == 0
        ) return;

        // Now we can safely bound the USDC amount
        usdcAmount = bound(usdcAmount, 1, usdc.balanceOf(actor));

        vm.startPrank(actor);
        usdc.approve(address(dex), usdcAmount);

        try dex.usdcToEth(usdcAmount) {
            // Increment swap counter
            swapCount++;
        } catch {
            // Swap failed
        }

        vm.stopPrank();
    }
}
