// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/** 
 * @title PotentialJob
 * @dev Represents a potential job ready for a driver to take
 */
contract PotentialJob {

    uint amount;
    string startAddress;
    string endAddress;
    uint datetime;
    
    address public client;
    
    /** 
    * @dev Creates a driver 
    * @param _client client address used to pay funds
    * @param _amount cost of trip client is willing to pay
    * @param _startAddress trip starting address
    * @param _endAddress trip ending address
    * @param _datetime unix timestamp of time when client wants to be picked up at
    */
    constructor(address _client, uint _amount, string _startAddress, string _endAddress, uint _datetime) {
        client = _client;
        amount = _amount;
        startAddress = _startAddress;
        endAddress = _endAddress;
        datetime = _datetime;
    }
    
    /** 
    * @dev Returns address of this PotentialJob contract
    */
    function getAddress() view external returns (address thisAddress) {
        address(this);
    }

    /** 
    * @dev Returns client address used to pay funds
    */
    function getClient() view external returns (address client) {
        return client
    }

    /** 
    * @dev Returns cost of trip client is willing to pay
    */
    function getAmount() view external returns (uint amount) {
        return amount
    }

    /** 
    * @dev Returns trip starting address
    */
    function getStartAddress() view external returns (string startAddress) {
        return startAddress
    }

    /** 
    * @dev Returns trip ending address
    */
    function getEndAddress() view external returns (string endAddress) {
        return endAddress
    }

    /** 
    * @dev Returns unix timestamp of time when client wants to be picked up at
    */
    function getDatetime() view external returns (uint datetime) {
        return datetime
    }
    
}