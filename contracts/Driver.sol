/* Assignment04 - Smart Contract
 * 
 * Members:
 * - Kun Y: kun.yu25@myhunter.cuny.edu
 * 
 * Repository link:
 * - https://github.com/kyu21/solidity_smart_contract
 */

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/** 
 * @title Driver
 * @dev Represents a driver ready to take jobs as part of a ride-share model.
 */
contract Driver {
    
    enum Status{ OPEN, BUSY, CLOSED }

    struct Request {
        address rider; // associated rider address for request 
        Status status; // enum representing request status
        int fromLatitude; // latitude of start location
        int fromLongitude; // longtitude of start location
        int toLatitude; // latitude of end location
        int toLongtitide; // longtitude of end location
        uint pickupTime; // time to be picked up in unix timestamp
        uint amount; // amount in wei rider is willing to pay
        uint recieved; // amount in wei rider pre-paid as part of down payment
        bool driverOk; // boolean for driver to indicate the completion of a request
        bool riderOk; // boolean for rider to indicate the completion of a request
    }
    
    address payable private driver; // owner address to pay out to
    string licensePlate; // license plate number of associated driver/car
    uint downPaymentPercentage; // percent of request amount rider has to send with request
    Status driverStatus; // enum representing current driver status
    
    uint numRequests; // number of recieved requests
    uint numCompletedRequests; // number of completed requests
    
    mapping(uint => Request) requests; // mapping of requestIds to recieved Requests
    mapping(uint => Request) completedRequests; // mapping of requestIds to completed Requests
    mapping(uint => string) statusStr; // mapping of status enum to status strings

    // Access control modifier
	modifier onlyDriver {
		require(msg.sender == driver,
		        "Only the driver can call this function");
		_;
	}
    
    // Events
    event ChangedLicensePlate(string oldLicensePlate, string newLicensePlate);
    
    event StatusChanged(string indexed oldStatus, string indexed newStatus);
    
    event RequestRecieved(uint indexed requestId, address indexed rider, int fromLatitude, int fromLongitude, int toLatitude, int toLongtitide, uint pickupTime, uint amount);
    event RequestRetracted(uint indexed requestId, address indexed rider);
    event RequestAccepted(uint indexed requestId, address indexed rider);
    event RequestCancelled(uint indexed requestId, address indexed rider);
    event RequestFinishedDriver(uint indexed requestId, address indexed rider);
    event RequestFinishedRider(uint indexed requestId, address indexed rider);
    event RequestFinishedPaidOut(uint indexed requestId, address indexed rider);
    
    
    /** 
    * @dev Creates a driver 
    * @param _licensePlate license plate of car clients should expect to be picked up in
    */
    constructor(string memory _licensePlate, uint _downPaymentPercentage) {
        require((_downPaymentPercentage >= 0) && (_downPaymentPercentage <= 100), "downPaymentPercentage must be between 0 and 100.");
        
        driver = msg.sender;
        licensePlate = _licensePlate;
        downPaymentPercentage = _downPaymentPercentage;
        driverStatus = Status.OPEN;
        
        numRequests = 0;
        
        statusStr[0] = "OPEN";
        statusStr[1] = "BUSY";
        statusStr[2] = "CLOSED";
    }

    /** 
    * @dev Gets associated license plate for driver/car
    * @return string
    */
    function getLicensePlate() public view returns(string memory) {
        return licensePlate;
    }
    
    /** 
    * @dev Gets current driver status
    * @return string
    */
    function getDriverStatus() public view returns(string memory) {
        return statusStr[uint(driverStatus)];
    }
    
    /** 
    * @dev Gets number of completed jobs by this driver
    * @return uint
    */
    function getNumCompletedRequests() public view returns (uint) {
        return numCompletedRequests;
    }
    
    /** 
    * @dev Creates a driver 
    * @param _licensePlate new license plate of car clients should expect to be picked up in
    */
    function changeLicensePlate(string memory _licensePlate) public onlyDriver {
        string memory oldLicensePlate = licensePlate;
        licensePlate = _licensePlate;
        
        emit ChangedLicensePlate(oldLicensePlate, licensePlate);
    }
    
    /** 
    * @dev Changes driver status to OPEN (accepting new requests)
    * @dev Can't change driver status when driver is BUSY
    */
    function open() public onlyDriver {
        require(driverStatus != Status.BUSY, "Can't change status when there is an ongoing request.");
        
        Status oldStatus = driverStatus;
        driverStatus = Status.OPEN;
        
        emit StatusChanged(statusStr[uint(oldStatus)], statusStr[uint(driverStatus)]);
    }
    
    /** 
    * @dev Changes driver status to CLOSED (stop accepting new requests)
    * @dev Can't change driver status when driver is BUSY
    */
    function close() public onlyDriver {
        require(driverStatus != Status.BUSY, "Can't change status when there is an ongoing request.");
        
        Status oldStatus = driverStatus;
        driverStatus = Status.CLOSED;
        
        emit StatusChanged(statusStr[uint(oldStatus)], statusStr[uint(driverStatus)]);
    }
    
    /** 
    * @dev Converts uint to string
    * @dev Sourced from https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    * @param _i uint to convert into string
    */
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    /** 
    * @dev Sends a request to the driver to look at and potentially accept.
    * @dev Will only accept new requests when driver is OPEN.
    * @dev Start location must be different from end location (latitude, longtitude)
    * @dev pickupTime must be greater than the current block timestamp
    * @dev sender must send "downPaymentPercentage" of indicated amount as downpayment (calculated using integer division)
    * @param _fromLatitude latitude of start location
    * @param _fromLongitude longtitude of start location
    * @param _toLatitude  latitude of end location
    * @param _toLongtitide longtitude of end location
    * @param _pickupTime time to be picked up in unix timestamp
    * @param _amount amount in wei rider is willing to pay
    */
    function sendRequest(int _fromLatitude, int _fromLongitude, int _toLatitude, int _toLongtitide, uint _pickupTime, uint _amount) public payable{
        require(driverStatus == Status.OPEN, "Driver is not accepting requests at the moment. Please try again later.");
        require((_fromLatitude != _toLatitude) && (_fromLongitude != _toLongtitide), "Start location must be different from end location.");
        require(_pickupTime > block.timestamp, "Pickup time must be greater than now.");
        require( (msg.value >= _amount / downPaymentPercentage) && (msg.value <= _amount), string(abi.encodePacked("Must send at least ", uint2str(downPaymentPercentage), "% of amount as down payment.")));
        
        
        requests[numRequests] = Request({
            rider: msg.sender,
            status: Status.OPEN,
            fromLatitude: _fromLatitude,
            fromLongitude: _fromLongitude,
            toLatitude: _toLatitude,
            toLongtitide: _toLongtitide,
            pickupTime: _pickupTime,
            amount: _amount,
            recieved: msg.value,
            driverOk: false,
            riderOk: false
        });
        
        uint requestId = numRequests;
        numRequests = numRequests + 1;
        
        emit RequestRecieved(requestId, msg.sender, _fromLatitude, _fromLongitude, _toLatitude, _toLongtitide, _pickupTime, _amount);
    }
    
    /**
     * @dev Retracts an open sent request by the message sender
     * @dev Sets request status to CLOSED and refunds down payment
     * @param requestId id of request to modify
     */
    function retractRequest(uint requestId) public{
        require(requests[requestId].rider == msg.sender, "Only owner of request can cancel request.");
        require(requests[requestId].status != Status.OPEN, "Can't cancel an ongoing or completed request.");
        
        requests[requestId].status = Status.CLOSED;
        msg.sender.transfer(requests[requestId].recieved);
        
        emit RequestRetracted(requestId, requests[requestId].rider);
    }
    
    /**
     * @dev Accepts an open request
     * @dev Sets request status to BUSY and driver status to BUSY
     * @param requestId id of request to modify
     */
    function acceptRequest(uint requestId) public onlyDriver{
        require(driverStatus == Status.OPEN, "Driver is not ready to accept requests yet. Please change status to OPEN or finish an ongoing request.");
        require(requests[requestId].status == Status.OPEN, "Can only accept an open request.");
        
        requests[requestId].status = Status.BUSY;
        driverStatus = Status.BUSY;
        
        emit RequestAccepted(requestId, requests[requestId].rider);
    }
    
    /**
     * @dev Cancels an ongoing request
     * @dev Sets request status to closed and refunds down payment
     * @dev Sets driver status to OPEN
     * @param requestId id of request to modify
     */
    function cancelRequest(uint requestId) public onlyDriver{
        require(requests[requestId].status == Status.BUSY, "Can only cancel an ongoing request.");
        
        requests[requestId].status = Status.CLOSED;
        msg.sender.transfer(requests[requestId].recieved);
        
        emit RequestCancelled(requestId, requests[requestId].rider);
        
        driverStatus = Status.OPEN;
        
        emit StatusChanged(statusStr[uint(Status.BUSY)], statusStr[uint(Status.OPEN)]);
    }
    
    /**
     * @dev Completes an ongoing request
     * @dev If called by driver, sets flag in request to indicate driver acknowledgement
     * @dev If called by rider, sets flag in request to indicate rider acknowledgement only if amount - recieved is sent with transaction
     * @dev Once driver and rider have acknowledged request completion, transfers request amount to driver
     * @dev Sets request status to CLOSED driver status to OPEN
     * @param requestId id of request to modify
     */
    function finishRequest(uint requestId) public payable{
        require(requests[requestId].status == Status.BUSY, "Can only finish an ongoing request.");
        
        if (msg.sender == driver) {
            requests[requestId].driverOk = true;
            
             emit RequestFinishedDriver(requestId, requests[requestId].rider);
        } else if (msg.sender == requests[requestId].rider) {
            if (msg.value != (requests[requestId].amount - requests[requestId].recieved)) {
                revert("Missing rest of amount");
            } else {
                requests[requestId].riderOk = true;
                
                emit RequestFinishedRider(requestId, requests[requestId].rider);
            }
        }
        
        if (requests[requestId].driverOk && requests[requestId].riderOk) {
            driver.transfer(requests[requestId].amount);
            
            requests[requestId].status = Status.CLOSED;
            driverStatus = Status.OPEN;
            
            completedRequests[numCompletedRequests] = requests[requestId];
            numCompletedRequests = numCompletedRequests + 1;
            
            emit RequestFinishedPaidOut(requestId, requests[requestId].rider);
        }
    }
    
    /**
     * @dev Shuts down driver contract
     * @dev Can only shut down when driver status is CLOSED.
     */
    function shutDown() public onlyDriver{
        require(driverStatus == Status.CLOSED, "Can only shut down when closed.");
        
        selfdestruct(driver);
    }

    /**
     * @dev Fallback function
     */
    fallback () external payable {}
}