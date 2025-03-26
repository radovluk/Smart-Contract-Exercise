// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SimpleDEX
 * @notice A simplified decentralized exchange (DEX)
 *         - Allows swapping between ETH and USDC tokens
 *         - Provides liquidity pool functionality with liquidity tokens
 *         - Calculates prices based on the constant product formula (x * y = k)
 *         - Charges a 0.3% swap fee that remains in the pool
 *         - Rewards liquidity providers with LP tokens representing their share
 *           and fees collected from swaps
 */
contract SimpleDEX is ERC20, ReentrancyGuard {
    // ------------------------------------------------------------------------
    //                          Storage Variables
    // ------------------------------------------------------------------------

    // The USDC token contract interface (for our example same as ERC20 interface)
    IERC20 public immutable usdcToken;

    // Reserve amount of USDC in the pool
    uint public usdcReserve = 0;

    // Reserve amount of ETH in the pool
    uint public ethReserve = 0;

    // Minimum liquidity to prevent division by zero and lock initial liquidity forever
    uint private constant MINIMUM_LIQUIDITY = 1000;

    // ------------------------------------------------------------------------
    //                               Events
    // ------------------------------------------------------------------------

    /// Emitted when a user purchases tokens with ETH
    event TokenPurchase(
        address indexed buyer,
        uint eth_sold,
        uint tokens_bought
    );

    /// Emitted when a user purchases ETH with tokens
    event EthPurchase(address indexed buyer, uint tokens_sold, uint eth_bought);

    /// Emitted when a user adds liquidity to the pool
    event AddLiquidity(
        address indexed provider,
        uint usdc_amount,
        uint eth_amount,
        uint liquidity_minted
    );

    /// Emitted when a user removes liquidity from the pool
    event RemoveLiquidity(
        address indexed provider,
        uint usdc_amount,
        uint eth_amount,
        uint liquidity_burned
    );

    // ------------------------------------------------------------------------
    //                               Errors
    // ------------------------------------------------------------------------

    /// Insufficient USDC amount provided for liquidity addition
    error InsufficientUSDCAmount(uint provided, uint required);

    /// Zero reserves error - reserves must be non-zero for operations
    error ZeroReserves();

    /// ETH amount purchased is too small
    error InsufficientEthPurchase();

    /// ETH purchase would exceed reserves
    error ExceedsEthReserves(uint requested, uint available);

    /// ETH transfer failed
    error EthTransferFailed();

    /// USDC transfer failed
    error USDCTransferFailed();

    /// USDC amount purchased is too small
    error InsufficientUsdcPurchase();

    /// USDC purchase would exceed reserves
    error ExceedsUsdcReserves(uint requested, uint available);

    /// Insufficient liquidity burned
    error InsufficientLiquidityBurned();

    /// Insufficient liquidity minted
    error InsufficientLiquidityMinted();

    /// Insufficient liquidity tokens
    error InsufficientLiquidityTokens(uint provided, uint required);

    // ------------------------------------------------------------------------
    //                               Constructor
    // ------------------------------------------------------------------------

    /**
     * @dev Sets the USDC token contract address and initializes LP token
     * @param _usdcToken The address of the USDC token contract
     */
    constructor(address _usdcToken) ERC20("Liquidity Provider Token", "LPT") {
        usdcToken = IERC20(_usdcToken);
    }

    // ------------------------------------------------------------------------
    //                          Liquidity Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows users to add liquidity to the pool and receive LP tokens
     * @param usdcAmount The amount of USDC tokens to add
     * @return liquidity The amount of LP tokens minted for the provider
     */
    function addLiquidity(
        uint usdcAmount
    ) external payable nonReentrant returns (uint256 liquidity) {
        if (usdcReserve == 0 && ethReserve == 0) {
            // Initial liquidity provision
            uint ethAmount = msg.value;
            uint tempLiquidity = _sqrt(ethAmount * usdcAmount) -
                MINIMUM_LIQUIDITY;

            // Check if the computed liquidity is valid
            if (tempLiquidity <= 0) revert InsufficientLiquidityMinted();

            // Update reserves first
            usdcReserve = usdcAmount;
            ethReserve = ethAmount;

            // Lock the minimum liquidity forever by minting to address(1)
            _mint(address(1), MINIMUM_LIQUIDITY);

            // Give the rest of the liquidity to the provider
            _mint(msg.sender, tempLiquidity);

            // Transfer USDC after state changes
            bool success = usdcToken.transferFrom(
                msg.sender,
                address(this),
                usdcAmount
            );
            if (!success) revert USDCTransferFailed();

            emit AddLiquidity(msg.sender, usdcAmount, ethAmount, tempLiquidity);

            return tempLiquidity;
        } else {
            // Subsequent liquidity provision
            uint ethAmount = msg.value;

            // Calculate the amount of USDC needed based on the current reserves
            uint usdcNeeded;
            if (ethAmount > 0) {
                // Calculate this safely to prevent precision loss
                usdcNeeded =
                    (ethAmount * usdcReserve + ethReserve - 1) /
                    ethReserve; // Ceiling division
            } else {
                usdcNeeded = 0;
            }

            if (usdcAmount < usdcNeeded) {
                revert InsufficientUSDCAmount({
                    provided: usdcAmount,
                    required: usdcNeeded
                });
            }

            // Calculate liquidity proportionally
            uint totalLpSupply = totalSupply();
            uint ethRatio = (ethAmount * 1e18) / ethReserve;
            uint usdcRatio = (usdcNeeded * 1e18) / usdcReserve;
            uint minRatio = ethRatio < usdcRatio ? ethRatio : usdcRatio;

            // Calculate liquidity based on the smaller ratio to ensure proportionality
            uint tempLiquidity = (minRatio * totalLpSupply) / 1e18;

            // Check if provided liquidity is not zero
            if (tempLiquidity == 0) revert InsufficientLiquidityMinted();

            // Update reserves first
            usdcReserve += usdcNeeded;
            ethReserve += ethAmount;

            // Mint LP tokens to provider
            _mint(msg.sender, tempLiquidity);

            // Transfer USDC after state changes
            bool success = usdcToken.transferFrom(
                msg.sender,
                address(this),
                usdcNeeded
            );
            if (!success) revert USDCTransferFailed();

            emit AddLiquidity(msg.sender, usdcNeeded, ethAmount, tempLiquidity);

            return tempLiquidity;
        }
    }

    /**
     * @dev Allows liquidity providers to remove liquidity and reclaim assets
     * @param liquidity The amount of LP tokens to burn
     * @return usdcAmount The amount of USDC tokens returned
     * @return ethAmount The amount of ETH returned
     */
    function removeLiquidity(
        uint liquidity
    ) external nonReentrant returns (uint usdcAmount, uint ethAmount) {
        // Check user's balance of LP Tokens
        uint balance = balanceOf(msg.sender);

        // Revert if user does not have enough LP tokens
        if (balance < liquidity) {
            revert InsufficientLiquidityTokens({
                provided: liquidity,
                required: balance
            });
        }

        // Calculate amount of each asset to return
        uint totalLiquidity = totalSupply(); // All the LP tokens in circulation
        usdcAmount = (liquidity * usdcReserve) / totalLiquidity;
        ethAmount = (liquidity * ethReserve) / totalLiquidity;

        if (usdcAmount == 0 || ethAmount == 0)
            revert InsufficientLiquidityBurned();

        // Burn LP tokens first
        _burn(msg.sender, liquidity);

        // Update reserves
        usdcReserve -= usdcAmount;
        ethReserve -= ethAmount;

        // Transfer assets back to provider
        bool success = usdcToken.transfer(msg.sender, usdcAmount);
        if (!success) revert USDCTransferFailed();

        (success, ) = msg.sender.call{value: ethAmount}("");
        if (!success) revert EthTransferFailed();

        emit RemoveLiquidity(msg.sender, usdcAmount, ethAmount, liquidity);
        return (usdcAmount, ethAmount);
    }

    // ------------------------------------------------------------------------
    //                          Price Ratio Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Gets the current price of ETH in USDC
     * @return The current price of 1 ETH in USDC with 18 decimals precision
     */
    function getCurrentUsdcToEthPrice() public view returns (uint) {
        if (usdcReserve == 0 || ethReserve == 0) {
            revert ZeroReserves();
        }
        return (usdcReserve * 1e18) / ethReserve;
    }

    /**
     * @dev Gets the current price of USDC in ETH
     * @return The current price of 1 USDC in ETH with 18 decimals precision
     */
    function getCurrentEthToUsdcPrice() public view returns (uint) {
        if (usdcReserve == 0 || ethReserve == 0) {
            revert ZeroReserves();
        }
        return (ethReserve * 1e18) / usdcReserve;
    }

    // ------------------------------------------------------------------------
    //                          Swap Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows users to swap USDC for ETH with a 0.3% fee
     * @notice This function implements the constant product formula (x * y = k) with a 0.3% fee
     *         The fee is calculated by reducing the effective input amount (997/1000)
     *         Fees remain in the pool, increasing the value of LP tokens over time
     * @param usdcAmount The amount of USDC tokens to swap
     * @return ethBought The amount of ETH received after the swap and fee deduction
     */
    function usdcToEth(
        uint usdcAmount
    ) public nonReentrant returns (uint ethBought) {
        // Ensure the pool has liquidity before attempting a swap
        if (usdcReserve == 0 || ethReserve == 0) revert ZeroReserves();

        // Apply the 0.3% fee by reducing the effective input to 99.7% of the actual input
        // This approach allows the fee to remain in the pool, benefiting liquidity providers
        uint inputWithFee = usdcAmount * 997;

        // Calculate ETH output using constant product formula with fee:
        // (x + dx * 0.997) * (y - dy) = x * y
        // where: x = usdcReserve, y = ethReserve, dx = usdcAmount, dy = ethBought
        ethBought =
            (inputWithFee * ethReserve) /
            ((usdcReserve * 1000) + inputWithFee);

        // Ensure the swap produces a meaningful amount of output tokens
        if (ethBought == 0) revert InsufficientEthPurchase();

        // Store the values to be used later
        uint ethToSend = ethBought;

        // Update the reserves first
        usdcReserve += usdcAmount;
        ethReserve -= ethBought;

        // Transfer USDC from the user to the contract
        bool success = usdcToken.transferFrom(
            msg.sender,
            address(this),
            usdcAmount
        );
        if (!success) revert USDCTransferFailed();

        // Transfer ETH to the user and check for successful transfer
        (success, ) = msg.sender.call{value: ethToSend}("");
        if (!success) revert EthTransferFailed();

        emit TokenPurchase(msg.sender, ethToSend, usdcAmount);
        return ethToSend;
    }

    /**
     * @dev Allows users to swap ETH for USDC with a 0.3% fee
     * @notice This function implements the constant product formula (x * y = k) with a 0.3% fee
     *         The fee works by reducing the effective input amount by 0.3% (using 997/1000)
     *         All fees are automatically added to the liquidity pool, increasing the value of LP tokens
     * @return usdcBought The amount of USDC tokens received after the swap and fee deduction
     */
    function ethToUsdc() public payable nonReentrant returns (uint usdcBought) {
        // Ensure the pool has liquidity before attempting a swap
        if (usdcReserve == 0 || ethReserve == 0) revert ZeroReserves();

        uint ethSold = msg.value;
        uint inputWithFee = ethSold * 997;

        // Calculate USDC output using constant product formula with fee:
        // (x + dx * 0.997) * (y - dy) = x * y
        // where: x = ethReserve, y = usdcReserve, dx = ethSold, dy = usdcBought
        usdcBought =
            (inputWithFee * usdcReserve) /
            ((ethReserve * 1000) + inputWithFee);

        // Ensure the swap produces a meaningful amount of output tokens
        if (usdcBought == 0) revert InsufficientUsdcPurchase();

        // Update the reserves
        usdcReserve -= usdcBought;
        ethReserve += ethSold;

        // Transfer the USDC tokens to the user
        bool success = usdcToken.transfer(msg.sender, usdcBought);
        if (!success) revert USDCTransferFailed();

        // Emit event for off-chain tracking and transparency
        emit EthPurchase(msg.sender, usdcBought, ethSold);

        return usdcBought;
    }

    // ------------------------------------------------------------------------
    //                          Helper Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Calculate square root using the Babylonian method
     * @param y The number to find the square root of
     * @return z The square root of y
     */
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

    /**
     * @dev Returns the minimum of two values
     * @param a First value
     * @param b Second value
     * @return The minimum value
     */
    function _min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }

    /**
     * @dev Fallback function to receive ETH
     */
    receive() external payable {
        // Allow receiving ETH
    }
}
