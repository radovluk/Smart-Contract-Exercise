// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract Organisation {
    // Mapping to store members by their index
    mapping(uint => address) members;
    // Counter to keep track of the total number of members
    uint public membersCount;
    // Variable to measure the gas used by the join operation
    uint public gasNeeded;

    /**
     * @dev Checks if an address is a member of the organization
     * @param addr The address to check
     * @return true if the address is a member, false otherwise
     * @notice This function has O(n) complexity which can lead to DoS with growing membership
     */
    function isMember(address addr) public view returns (bool) {
        for(uint i = 0; i < membersCount; i++) {
            if(members[i] == addr) return true;
        }
        return false;
    }

    /**
     * @dev Allows an address to join the organization if not already a member
     * @notice Records the gas used for the operation
     */
    function join() public {
        uint gas = gasleft();
        if(!isMember(msg.sender)) {
            members[membersCount++] = msg.sender;
        }
        gasNeeded = gas - gasleft();
    }
}