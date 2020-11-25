// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/** 
 * @title Job
 * @dev Represents a driving job a driver and client agreed on
 */
contract Job {

    uint amount;
    string startAddress;
    string endAddress;
    uint datetime;
    
    address public driver;
    address public client;
    
    bool driverOk;
    bool clientOK;
    
    string review;
    uint rating;
    
    modifier onlyClient {
		require(msg.sender == client,
		        "Only the client can call this function");
		_;
	}
    
    /** 
    * @dev Creates a job
    * @param _client driver address used to recieve funds
    * @param _client client address used to pay funds
    * @param _amount cost of trip client is willing to pay
    * @param _startAddress trip starting address
    * @param _endAddress trip ending address
    * @param _datetime unix timestamp of time when client wants to be picked up at
    */
    constructor(address _driver, address _client, uint _amount, string memory _startAddress, string memory _endAddress, uint _datetime) {
        driver = _driver;
        client = _client;
        amount = _amount;
        startAddress = _startAddress;
        endAddress = _endAddress;
        datetime = _datetime;
        
        // pay first half to driver
    }

    /** 
    * @dev Used to confirm completion of a job. Upon recieving confirmations from both driver and client, releases funds to driver.
    */
    function completed() public {
        if (msg.sender == driver) {
            driverOk = true;
        } else if (msg.sender == client) {
            clientOK = true;
        }
        
        if (driverOk && clientOK) {
            // pay out second half of amount
        }
    }
    
    /** 
    * @dev Stores written review and 1-5 rating of driver based on job
    * @param _review string review of driver based on job
    * @param _rating integer 1-5 inclusive rating of driver based on job
    */
    function writeReviewAndRating(string memory _review, uint _rating) public onlyClient {
        review = _review;
        
        if (_rating >= 1 && _rating <= 5) {
            rating = _rating;
        } else {
            _rating  = 0;
        }
    }
    
    /** 
    * @dev Returns string review of driver based on job
    */
    function getReview() external view returns (string memory) {
        return review;
    }
    
    /** 
    * @dev Returns integer 1-5 inclusive rating of driver based on job
    */
    function getRating() external view returns (uint) {
        return rating;
    }
    
    
}