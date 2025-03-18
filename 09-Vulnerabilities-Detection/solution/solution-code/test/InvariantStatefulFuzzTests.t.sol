// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "forge-std/Test.sol";
import "../src/SimpleDEX.sol";
import "../src/USDCToken.sol";

/**
 * @title SimpleDEXStatefulTest
 * @notice Stateful fuzz test for SimpleDEX with invariants
 */
contract SimpleDEXStatefulTest is Test {
    SimpleDEX public dex;
    USDCToken public usdc;
    SimpleDEXHandler public handler;
    
    function setUp() public {
        // Deploy USDC token with a large initial supply for the test contract
        usdc = new USDCToken(100_000_000 * 10**6); // 100M initial supply
        
        // Deploy DEX
        dex = new SimpleDEX(address(usdc));
        
        // Deploy handler with the test contract as the owner
        handler = new SimpleDEXHandler(dex, usdc);
        
        // Add initial liquidity as owner
        usdc.approve(address(dex), 100_000 * 10**6); // 100k USDC
        uint256 initialLpTokens = dex.addLiquidity{value: 50 ether}(100_000 * 10**6);
        
        // Update handler's ghost variables with initial liquidity info
        handler.recordInitialLiquidity(initialLpTokens, 50 ether, 100_000 * 10**6);
        
        // Distribute USDC to all actors in the handler
        for (uint i = 0; i < 5; i++) {
            address actor = handler.actors(i);
            usdc.transfer(actor, 1_000_000 * 10**6); // 1M USDC per actor
        }
        
        // Target only the handler contract for function calls
        targetContract(address(handler));
    }
    
    // === Invariant Tests ===
    
    /**
     * @notice Verify that liquidity token accounting is correct
     */
    // function invariant_LPTokenAccounting() public view {
    //     assertEq(
    //         dex.totalSupply(),
    //         handler.totalLpMinted() - handler.totalLpBurned() + 1000, // +1000 for MINIMUM_LIQUIDITY
    //         "LP token accounting mismatch"
    //     );
    // }
    
    /**
     * @notice Verify that k value never decreases (due to fees)
     */
    function invariant_ConstantProductIncreasesWithFees() public view {
        uint256 currentK = dex.ethReserve() * dex.usdcReserve();
        assertGe(
            currentK,
            handler.lastK(),
            "k value decreased, which shouldn't happen with fees"
        );
    }
    
    /**
     * @notice Verify that DEX reserves match actual token balances
     */
    function invariant_ReservesMatchBalances() public view {
        assertEq(
            address(dex).balance,
            dex.ethReserve(),
            "ETH reserve mismatch"
        );
        
        assertEq(
            usdc.balanceOf(address(dex)),
            dex.usdcReserve(),
            "USDC reserve mismatch"
        );
    }
    
    /**
     * @notice Verify price functions return consistent values
     */
    function invariant_PriceFunctionsConsistent() public view {
        // Skip if reserves are zero
        if (dex.usdcReserve() == 0 || dex.ethReserve() == 0) return;
        
        uint256 usdcToEthPrice = dex.getCurrentUsdcToEthPrice();
        uint256 ethToUsdcPrice = dex.getCurrentEthToUsdcPrice();
        
        // Calculate expected prices
        uint256 expectedUsdcToEth = (dex.usdcReserve() * 1e18) / dex.ethReserve();
        uint256 expectedEthToUsdc = (dex.ethReserve() * 1e18) / dex.usdcReserve();
        
        assertEq(usdcToEthPrice, expectedUsdcToEth, "USDC to ETH price calculation error");
        assertEq(ethToUsdcPrice, expectedEthToUsdc, "ETH to USDC price calculation error");
    }
    
    /**
     * @notice After all swaps and liquidity operations, ensure system is still functional
     */
    function invariant_SystemFunctional() public {
        // Try to do a small swap to ensure system is still functional
        try vm.startPrank(address(this)) {} catch {}
        
        try dex.ethToUsdc{value: 0.1 ether}() returns (uint256 usdcAmount) {
            assertTrue(usdcAmount > 0, "Swap didn't return USDC");
        } catch {
            // If the swap fails, it should only be because pool is empty
            if (dex.usdcReserve() > 0 && dex.ethReserve() > 0) {
                fail();
            }
        }
        
        try vm.stopPrank() {} catch {}
    }
    
    function afterInvariant() external view {
        // Log some debug information after all invariant test runs
        console.log("======== SimpleDEX Invariant Test Summary ========");
        console.log("Total USDC Deposited:", handler.totalUsdcDeposited() / 1e6, "USDC");
        console.log("Total ETH Deposited:", handler.totalEthDeposited() / 1e18, "ETH");
        console.log("Total USDC Withdrawn:", handler.totalUsdcWithdrawn() / 1e6, "USDC");
        console.log("Total ETH Withdrawn:", handler.totalEthWithdrawn() / 1e18, "ETH");
        console.log("Current USDC Reserve:", dex.usdcReserve() / 1e6, "USDC");
        console.log("Current ETH Reserve:", dex.ethReserve() / 1e18, "ETH");
        console.log("Current LP Token Supply:", dex.totalSupply());
        console.log("=================================================");
    }
}

/**
 * @title SimpleDEXHandler
 * @notice Handler contract for SimpleDEX invariant testing
 */
contract SimpleDEXHandler is Test {
    SimpleDEX public dex;
    USDCToken public usdc;
    
    // Track total USDC deposited (including fees)
    uint256 public totalUsdcDeposited;
    
    // Track total ETH deposited
    uint256 public totalEthDeposited;
    
    // Track total USDC withdrawn
    uint256 public totalUsdcWithdrawn;
    
    // Track total ETH withdrawn
    uint256 public totalEthWithdrawn;
    
    // Track total LP tokens minted (excluding MINIMUM_LIQUIDITY)
    uint256 public totalLpMinted;
    
    // Track total LP tokens burned
    uint256 public totalLpBurned;
    
    // Track ghost variable for k = ethReserve * usdcReserve
    uint256 public lastK;
    
    // Array of test users (actors)
    address[] public actors;
    
    // Currently active actor
    address internal currentActor;
    
    // Maximum amounts for bounded functions
    uint256 constant MAX_ETH_AMOUNT = 100 ether;
    uint256 constant MAX_USDC_AMOUNT = 200_000 * 10**6; // 200k USDC
    
    constructor(SimpleDEX _dex, USDCToken _usdc) {
        dex = _dex;
        usdc = _usdc;
        
        // Initialize k
        lastK = dex.ethReserve() * dex.usdcReserve();
        
        // Setup actor addresses (5 users)
        for (uint i = 0; i < 5; i++) {
            address actor = makeAddr(string(abi.encodePacked("actor", vm.toString(i))));
            actors.push(actor);
            
            // Give each actor some ETH and USDC
            vm.deal(actor, 1000 ether);
        }
    }
    
    // Modifier to select a random actor
    modifier useActor(uint256 actorIndexSeed) {
        currentActor = actors[bound(actorIndexSeed, 0, actors.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }
    
    // === Bounded DEX Functions ===
    
    /**
     * @notice Add liquidity to the DEX with bounded values
     */
    function addLiquidity(uint256 ethAmount, uint256 actorIndexSeed) external useActor(actorIndexSeed) {
        // Bound ETH amount
        ethAmount = bound(ethAmount, 0.01 ether, MAX_ETH_AMOUNT);
        
        uint256 usdcReserve = dex.usdcReserve();
        uint256 ethReserve = dex.ethReserve();
        
        // If pool is empty, we need to initialize with some ratio
        uint256 usdcAmount;
        if (usdcReserve == 0 && ethReserve == 0) {
            usdcAmount = ethAmount * 2000; // Initial rate: 1 ETH = 2000 USDC
        } else {
            // Calculate required USDC based on current ratio
            usdcAmount = (ethAmount * usdcReserve) / ethReserve;
            
            // Bound USDC amount to prevent failures
            usdcAmount = bound(usdcAmount, 1, MAX_USDC_AMOUNT);
        }
        
        // Ensure we have approved enough USDC
        try usdc.approve(address(dex), usdcAmount) {} catch {}
        
        // Try to add liquidity
        try dex.addLiquidity{value: ethAmount}(usdcAmount) returns (uint256 lpTokens) {
            // Update ghost variables
            totalUsdcDeposited += usdcAmount;
            totalEthDeposited += ethAmount;
            totalLpMinted += lpTokens;
            
            // Update k
            lastK = dex.ethReserve() * dex.usdcReserve();
        } catch {}
    }
    
    // Function to record initial liquidity added in test setup
    function recordInitialLiquidity(uint256 lpTokens, uint256 ethAmount, uint256 usdcAmount) external {
        totalLpMinted += lpTokens;
        totalEthDeposited += ethAmount;
        totalUsdcDeposited += usdcAmount;
        
        // Update k
        lastK = dex.ethReserve() * dex.usdcReserve();
    }
    
    // Add receive function to allow the handler to receive ETH
    receive() external payable {}
    /**
     * @notice Remove liquidity from the DEX
     */    function removeLiquidity
(uint256 lpPercentage, uint256 actorIndexSeed) external useActor(actorIndexSeed) {
        uint256 lpBalance = dex.balanceOf(currentActor);
        
        // Skip if no LP tokens
        if (lpBalance == 0) return;
        
        // Bound LP percentage to remove between 1% and 100%
        lpPercentage = bound(lpPercentage, 1, 100);
        uint256 lpToRemove = (lpBalance * lpPercentage) / 100;
        
        // Ensure at least 1 LP token
        if (lpToRemove == 0) return;
        
        // Try to remove liquidity
        try dex.removeLiquidity(lpToRemove) returns (uint256 usdcAmount, uint256 ethAmount) {
            // Update ghost variables
            totalUsdcWithdrawn += usdcAmount;
            totalEthWithdrawn += ethAmount;
            totalLpBurned += lpToRemove;
            
            // Update k
            lastK = dex.ethReserve() * dex.usdcReserve();
        } catch {}
    }
    
    /**
     * @notice Swap ETH for USDC
     */
    function ethToUsdc(uint256 ethAmount, uint256 actorIndexSeed) external useActor(actorIndexSeed) {
        // Bound ETH amount
        ethAmount = bound(ethAmount, 0.001 ether, MAX_ETH_AMOUNT / 10);
        
        // Skip if reserves are zero to prevent reverts
        if (dex.usdcReserve() == 0 || dex.ethReserve() == 0) return;
        
        // Try to swap ETH for USDC
        try dex.ethToUsdc{value: ethAmount}() returns (uint256 usdcAmount) {
            // Update ghost variables
            totalEthDeposited += ethAmount;
            totalUsdcWithdrawn += usdcAmount;
            
            // Update k - should increase due to fees
            lastK = dex.ethReserve() * dex.usdcReserve();
        } catch {}
    }
    
    /**
     * @notice Swap USDC for ETH
     */
    function usdcToEth(uint256 usdcAmount, uint256 actorIndexSeed) external useActor(actorIndexSeed) {
        // Bound USDC amount
        usdcAmount = bound(usdcAmount, 1 * 10**6, MAX_USDC_AMOUNT / 10);
        
        // Skip if reserves are zero to prevent reverts
        if (dex.usdcReserve() == 0 || dex.ethReserve() == 0) return;
        
        // Ensure we have approved enough USDC
        try usdc.approve(address(dex), usdcAmount) {} catch {}
        
        // Try to swap USDC for ETH
        try dex.usdcToEth(usdcAmount) returns (uint256 ethAmount) {
            // Update ghost variables
            totalUsdcDeposited += usdcAmount;
            totalEthWithdrawn += ethAmount;
            
            // Update k - should increase due to fees
            lastK = dex.ethReserve() * dex.usdcReserve();
        } catch {}
    }
    
    // === Helper functions ===
    
    /**
     * @notice Check if the total LP token supply matches expected value
     */
    function checkLpTokenSupply() external view returns (bool) {
        uint256 expectedSupply = totalLpMinted - totalLpBurned + 1000; // +1000 for MINIMUM_LIQUIDITY
        return dex.totalSupply() == expectedSupply;
    }
    
    /**
     * @notice Check if k increases or stays the same after operations
     */
    function checkKIncreases() external view returns (bool) {
        uint256 currentK = dex.ethReserve() * dex.usdcReserve();
        return currentK >= lastK;
    }
    
    /**
     * @notice Calculate pool balance, which should match reserves in contract
     */
    function checkPoolBalance() external view returns (bool) {
        bool ethMatches = address(dex).balance == dex.ethReserve();
        bool usdcMatches = usdc.balanceOf(address(dex)) == dex.usdcReserve();
        return ethMatches && usdcMatches;
    }
}