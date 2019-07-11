pragma solidity ^0.5.0;

import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";

contract Sample is usingOraclize {
    string public authorized;
    mapping(bytes32 => bool) validIds;
    event LogContstructorInitiated(string nextStep);
    event LogAuthorizationReceived(string authorization);
    event LogNewOraclizeQuery(string description);
    
    constructor() public payable {
        emit LogContstructorInitiated("Constructor initiated. Call getAuthorization().");
    }
    
    function __callback(bytes32 myid, string result) public {
        if (!validIds[myid]) revert();
        if ( msg.sender != oraclize_cbAddress()) revert();
        authorized = result;
        emit LogAuthorizationReceived(result);
        delete validIds[myid];
    }
    
    function getAuthorization() public payable {
        if (oraclize_getPrice("URL") > this.balance){
            emit LogNewOraclizeQuery("Oraclize query not sent. Add more ETH for query fee.");
        } else {
            emit LogNewOraclizeQuery("Oraclize query not sent. Stand by for results.");
            bytes32 queryId = oraclize_query("URL", "json(https://kgabwkfdy5.execute-api.ap-southeast-1.amazonaws.com/Prod/approval).payload.data.approved");
            validIds[queryId] = true;
        }
    }
}
