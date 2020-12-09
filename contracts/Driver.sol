/* Assignment04 - Smart Contract
 *
 * Members:
 * - Kun Y: kun.yu25@myhunter.cuny.edu
 *
 * Repository link:
 * - https://github.com/kyu21/solidity_smart_contract
 */

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.5.17;

/**
 * @title Driver
 * @dev Represents a driver ready to take jobs as part of a ride-share model.
 */
contract Driver {
    enum Status {OPEN, BUSY, CLOSED}

    struct Request {
        address payable rider; // associated rider address for request
        Status status; // enum representing request status
        int256 fromLatitude; // latitude of start location
        int256 fromLongitude; // longtitude of start location
        int256 toLatitude; // latitude of end location
        int256 toLongtitide; // longtitude of end location
        uint256 pickupTime; // time to be picked up in unix timestamp
        uint256 amount; // amount in wei rider is willing to pay
        uint256 recieved; // amount in wei rider pre-paid as part of down payment
        bool driverOk; // boolean for driver to indicate the completion of a request
        bool riderOk; // boolean for rider to indicate the completion of a request
    }

    address payable public driver; // owner address to pay out to
    string licensePlate; // license plate number of associated driver/car
    uint256 downPaymentPercentage; // percent of request amount rider has to send with request
    Status driverStatus; // enum representing current driver status

    uint256 numRequests; // number of recieved requests
    uint256 numCompletedRequests; // number of completed requests

    mapping(uint256 => Request) requests; // mapping of requestIds to recieved Requests
    mapping(uint256 => Request) completedRequests; // mapping of requestIds to completed Requests
    mapping(uint256 => string) statusStr; // mapping of status enum to status strings

    // Access control modifier
    modifier onlyDriver {
        require(msg.sender == driver, "Only the driver can call this function");
        _;
    }

    // Events
    event ChangedLicensePlate(string oldLicensePlate, string newLicensePlate);
    event ChangedDownPaymentPercentage(
        uint256 oldPercentage,
        uint256 newPercentage
    );

    event StatusChanged(string indexed oldStatus, string indexed newStatus);

    event RequestRecieved(
        uint256 indexed requestId,
        address indexed rider,
        int256 fromLatitude,
        int256 fromLongitude,
        int256 toLatitude,
        int256 toLongtitide,
        uint256 pickupTime,
        uint256 amount
    );
    event RequestRetracted(uint256 indexed requestId, address indexed rider);
    event RequestAccepted(uint256 indexed requestId, address indexed rider);
    event RequestCancelled(uint256 indexed requestId, address indexed rider);
    event RequestFinishedDriver(
        uint256 indexed requestId,
        address indexed rider
    );
    event RequestFinishedRider(
        uint256 indexed requestId,
        address indexed rider
    );
    event RequestFinishedPaidOut(
        uint256 indexed requestId,
        address indexed rider
    );

    /**
     * @dev Creates a driver
     * @dev Defaults to empty license plate and 10% down payment
     */
    constructor() public {
        driver = msg.sender;
        licensePlate = "";
        downPaymentPercentage = 10;
        driverStatus = Status.CLOSED;

        numRequests = 0;

        statusStr[0] = "OPEN";
        statusStr[1] = "BUSY";
        statusStr[2] = "CLOSED";
    }

    /**
     * @dev Gets driver associated address
     * @return string
     */
    function getDriverAddress() public view returns (address) {
        return driver;
    }

    /**
     * @dev Gets associated license plate for driver/car
     * @return string
     */
    function getLicensePlate() public view returns (string memory) {
        return licensePlate;
    }

    /**
     * @dev Gets associated down payment percentage
     * @return uint
     */
    function getDownPaymentPercentage() public view returns (uint256) {
        return downPaymentPercentage;
    }

    /**
     * @dev Gets current driver status
     * @return string
     */
    function getDriverStatus() public view returns (string memory) {
        return statusStr[uint256(driverStatus)];
    }

    /**
     * @dev Gets number of requests by this driver
     * @return uint
     */
    function getNumRequests() public view returns (uint256) {
        return numRequests;
    }

    /**
     * @dev Gets number of completed requests by this driver
     * @return uint
     */
    function getNumCompletedRequests() public view returns (uint256) {
        return numCompletedRequests;
    }

    /**
     * @dev Changes license plate
     * @param _licensePlate new license plate of car clients should expect to be picked up in
     */
    function changeLicensePlate(string memory _licensePlate) public onlyDriver {
        string memory oldLicensePlate = licensePlate;
        licensePlate = _licensePlate;

        emit ChangedLicensePlate(oldLicensePlate, licensePlate);
    }

    /**
     * @dev Changes down payment percentage
     * @param _downPaymentPercentage new down payment percentage clients should expect to pre-pay
     */
    function changeDownPaymentPercentage(uint256 _downPaymentPercentage)
        public
        onlyDriver
    {
        require(
            (_downPaymentPercentage >= 0) && (_downPaymentPercentage <= 100),
            "downPaymentPercentage must be between 0 and 100."
        );
        uint256 oldPercentage = downPaymentPercentage;
        downPaymentPercentage = _downPaymentPercentage;

        emit ChangedDownPaymentPercentage(oldPercentage, downPaymentPercentage);
    }

    /**
     * @dev Changes driver status to OPEN (accepting new requests)
     */
    function open() public onlyDriver {
        Status oldStatus = driverStatus;
        driverStatus = Status.OPEN;

        emit StatusChanged(
            statusStr[uint256(oldStatus)],
            statusStr[uint256(driverStatus)]
        );
    }

    /**
     * @dev Changes driver status to CLOSED (stop accepting new requests)
     */
    function close() public onlyDriver {
        Status oldStatus = driverStatus;
        driverStatus = Status.CLOSED;

        emit StatusChanged(
            statusStr[uint256(oldStatus)],
            statusStr[uint256(driverStatus)]
        );
    }

    /**
     * @dev Converts uint to string
     * @dev Sourced from https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
     * @param _i uint to convert into string
     */
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
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
    function sendRequest(
        int256 _fromLatitude,
        int256 _fromLongitude,
        int256 _toLatitude,
        int256 _toLongtitide,
        uint256 _pickupTime,
        uint256 _amount
    ) public payable {
        require(
            driverStatus == Status.OPEN,
            "Driver is not accepting requests at the moment. Please try again later."
        );
        require(
            (_fromLatitude != _toLatitude) && (_fromLongitude != _toLongtitide),
            "Start location must be different from end location."
        );
        require(
            _pickupTime > block.timestamp,
            "Pickup time must be greater than now."
        );
        require(
            (msg.value >= _amount / downPaymentPercentage) &&
                (msg.value <= _amount),
            string(
                abi.encodePacked(
                    "Must send at least ",
                    uint2str(downPaymentPercentage),
                    "% of amount as down payment."
                )
            )
        );

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

        uint256 requestId = numRequests;
        numRequests = numRequests + 1;

        emit RequestRecieved(
            requestId,
            msg.sender,
            _fromLatitude,
            _fromLongitude,
            _toLatitude,
            _toLongtitide,
            _pickupTime,
            _amount
        );
    }

    /**
     * @dev Gets information about a request
     * @param requestId id of request to query
     */
    function getRequest(uint256 requestId)
        public
        view
        returns (
            int256 _fromLatitude,
            int256 _fromLongitude,
            int256 _toLatitude,
            int256 _toLongtitide,
            uint256 _pickupTime,
            uint256 _amount,
            bool _driverOk,
            bool _riderOk
        )
    {
        require(requests[requestId].rider != address(0), "Invalid requestId");

        _fromLatitude = requests[requestId].fromLatitude;
        _fromLongitude = requests[requestId].fromLongitude;
        _toLatitude = requests[requestId].toLatitude;
        _toLongtitide = requests[requestId].toLongtitide;
        _pickupTime = requests[requestId].pickupTime;
        _amount = requests[requestId].amount;
        _driverOk = requests[requestId].driverOk;
        _riderOk = requests[requestId].riderOk;
    }

    /**
     * @dev Gets status about a request
     * @param requestId id of request to query
     */
    function getRequestStatus(uint256 requestId)
        public
        view
        returns (string memory _status)
    {
        require(requests[requestId].rider != address(0), "Invalid requestId");

        _status = statusStr[uint256(requests[requestId].status)];
    }

    /**
     * @dev Retracts an open sent request by the message sender
     * @dev Sets request status to CLOSED and refunds down payment
     * @param requestId id of request to modify
     */
    function retractRequest(uint256 requestId) public {
        require(
            requests[requestId].rider == msg.sender,
            "Only owner of request can cancel request."
        );
        require(
            requests[requestId].status == Status.OPEN,
            "Can't cancel an ongoing or completed request."
        );

        requests[requestId].status = Status.CLOSED;
        msg.sender.transfer(requests[requestId].recieved);

        emit RequestRetracted(requestId, requests[requestId].rider);
    }

    /**
     * @dev Accepts an open request
     * @dev Sets request status to BUSY and driver status to BUSY
     * @param requestId id of request to modify
     */
    function acceptRequest(uint256 requestId) public onlyDriver {
        require(
            driverStatus == Status.OPEN,
            "Driver is not ready to accept requests yet. Please change status to OPEN or finish an ongoing request."
        );
        require(
            requests[requestId].status == Status.OPEN,
            "Can only accept an open request."
        );

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
    function cancelRequest(uint256 requestId) public onlyDriver {
        require(
            requests[requestId].status == Status.BUSY,
            "Can only cancel an ongoing request."
        );

        requests[requestId].status = Status.CLOSED;
        requests[requestId].rider.transfer(requests[requestId].recieved);

        emit RequestCancelled(requestId, requests[requestId].rider);

        driverStatus = Status.OPEN;

        emit StatusChanged(
            statusStr[uint256(Status.BUSY)],
            statusStr[uint256(Status.OPEN)]
        );
    }

    /**
     * @dev Completes an ongoing request
     * @dev If called by driver, sets flag in request to indicate driver acknowledgement
     * @dev If called by rider, sets flag in request to indicate rider acknowledgement only if amount - recieved is sent with transaction
     * @dev Once driver and rider have acknowledged request completion, transfers request amount to driver
     * @dev Sets request status to CLOSED driver status to OPEN
     * @param requestId id of request to modify
     */
    function finishRequest(uint256 requestId) public payable {
        require(
            requests[requestId].status == Status.BUSY,
            "Can only finish an ongoing request."
        );

        if (msg.sender == driver) {
            requests[requestId].driverOk = true;

            emit RequestFinishedDriver(requestId, requests[requestId].rider);
        } else if (msg.sender == requests[requestId].rider) {
            if (
                msg.value !=
                (requests[requestId].amount - requests[requestId].recieved)
            ) {
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
    function shutDown() public onlyDriver {
        require(
            driverStatus == Status.CLOSED,
            "Can only shut down when closed."
        );

        selfdestruct(driver);
    }

    /**
     * @dev Fallback function
     */
    function() external payable {}
}
