// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.5.17;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Driver.sol";

contract TestDriver {
    Driver driver1;
    Driver driver2;
    uint256 public initialBalance = 9 ether;

    /**
     * @dev Fallback function
     */
    function() external payable {}

    /**
     * @dev Wrapper function to execute before every test
     * @dev Creates new driver
     */
    function beforeAll() public {
        driver1 = new Driver();
        driver2 = new Driver();
    }

    /**
     * @dev Tests default license plate
     */
    function testDefaultLicensePlateAfterCreation() public {
        Assert.equal(
            driver1.getLicensePlate(),
            "",
            "Default license plate is not empty string."
        );
    }

    /**
     * @dev Tests default driver status
     */
    function testDefaultDriverStatusAfterCreation() public {
        Assert.equal(
            driver1.getDriverStatus(),
            "CLOSED",
            "Default license plate is not CLOSED"
        );
    }

    /**
     * @dev Tests that changing license plate works correctly
     */
    function testChangingDriverLicensePlate() public {
        string memory licensePlate = "NYC1234";
        driver1.changeLicensePlate(licensePlate);

        Assert.equal(
            driver1.getLicensePlate(),
            licensePlate,
            "License Plate not correctly set."
        );
    }

    /**
     * @dev Tests changing driver status to OPEN
     */
    function testChangingDriverStatusToOpen() public {
        driver1.open();

        Assert.equal(
            driver1.getDriverStatus(),
            "OPEN",
            "Driver status is not set to OPEN."
        );
    }
}
