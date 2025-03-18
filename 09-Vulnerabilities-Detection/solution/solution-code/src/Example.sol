// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

contract Example {
    uint256 public hiddenValue;
    uint256 public shouldAlwaysBeZero;

    function doStuff(uint256 data) public {
        if (data == 2) {
            shouldAlwaysBeZero = 1;
        }
        if (hiddenValue == 7) {
            shouldAlwaysBeZero = 1;
        }
        hiddenValue = data;
    }
}
