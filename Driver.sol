// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "./Job.sol";
import "./PotentialJob";

/** 
 * @title Driver
 * @dev Represents a driver ready to take jobs
 */
contract Driver {

    address private driver;
    string public licensePlate;
    
    PotentialJobs[] private potentialJobs;

    Job[] public acceptedJobs;
    address public currentJob;

    Job[] public completedJobs;
    uint public numCompletedJobs;

    uint public avgRating;
    String[] public reviews;
    
    // Access control modifier
	modifier onlyDriver {
		require(msg.sender == driver,
		        "Only the driver can call this function");
		_;
	}
    
    // Events
    event RecievedPotentionJob(address indexed potentialJob);
    event AcceptedJob(address indexed client, uint indexed amount, string startAddress, string endAddress, uint datetime);
    
    /** 
    * @dev Creates a driver 
    * @param _licensePlate license plate of car clients should expect to be picked up in
    */
    constructor(string _licensePlate) {
        driver = msg.sender;
        licensePlate = _licensePlate;
    }
    
    /** 
    * @dev Calculates an average rating based on ratings on completed jobs.
    */
    function calculateRating() internal {

    }

    /** 
    * @dev Retuns latest review
    */
    function getLatestReview() internal returns (string latestReview){

    }
    
    /** 
    * @dev Returns all public driver information
    */
    function getInfo() view external returns (string licensePlate, uint numCompletedJobs, uint avgRating, string latestReview) {

    }
    
    /** 
    * @dev Receives potential jobs and stores them into a list of PotentialJobs
    * @param potentialJob address of PotentialJob contract which contains further details
    */
    function recievePotentialJob(address potentialJob) public {
        emit RecievedPotentionJob(potentialJob);
    }
    
    /** 
    * @dev Accepts a potential job and creates a Job contract for it
    * @param potentialJob address of PotentialJob contract which contains further details
    */
    function acceptJob(address potentialJob) public onlyDriver {

        Job newJob = Job(driver, client, amount, startAddress, endAddress, datetime, amount);
        acceptJobs.push(newJob);
        currentJob = newJob;

        emit AcceptedJob(client, amount, startAddress, endAddress, datetime, amount)
    }
    
    /** 
    * @dev Changes license plate number
    * @param newLicensePlate new license plate to change to
    */
    function changeLicensePlate(string newLicensePlate) public onlyDriver {
        licensePlate = newLicensePlate;
    }

    /** 
    * @dev Resets acceptedJobs and stores all ratings and reviews into completedJobs for all completed jobs
    */
    function syncCompletedJobs() public onlyDriver {

    }

    /** 
    * @dev Resets potentialJobs array
    */
    function clearPotentialJobs() public onlyDriver {

    }
}

