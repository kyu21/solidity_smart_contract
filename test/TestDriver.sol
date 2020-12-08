// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Driver.sol";

contract TestDriver {
    function test() public {
        Assert.equal(uint256(10), uint256(11), "test");
    }
}
