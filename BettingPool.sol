pragma solidity ^0.5.0;


import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";

contract BettingPool is usingOraclize {
    using SafeMath for uint256;
    
    struct wagerData {
        uint256 stake;
        uint8 selectionID;
        bool exists;
        bool winningsCollected;
    }
    
    //Variables & Events for Oraclize
    mapping(bytes32 => bool) validIds;
    event LogConstructorInitiated(string nextStep);
    event LogResultReceived(string result, uint8 id);
    event LogNewOraclizeQuery(string description);
    
    address owner;
    string[2] private _selections;
    int256[2] private _odds;
    uint256 private _minimumStake;
    uint8 constant private MAX_UINT8 = 255;
    uint8 public winningSelectionID;
    bool winnerSelected;
    bool cutOff;
    
    
    mapping (address => wagerData) public wagers;
    
    constructor(
        string memory firstSelection,
        string memory secondSelection,
        int256 firstOdds,
        int256 secondOdds,
        uint256 minimumStakes
    ) public payable {
        // require(bettingOdds.length == s2, "BettingPool: array of odds do not match.");
        owner = msg.sender;
        _selections[0] = firstSelection;
        _selections[1] = secondSelection;
        _odds[0] = firstOdds;
        _odds[1] = secondOdds;
        _minimumStake = minimumStakes;
        winningSelectionID = 255;
        winnerSelected = false;
        cutOff = false;
        emit LogConstructorInitiated("Constructor Initiated. Call randomNumber().");
    }
    
    function() external payable {
        
    }
    /**
     * @notice makes the bet and passes money to contract. Bets are recorded in the wagers mapping.
     * @param selectionID must be 0 or 1, representing the selection they wish to bet on.
     * @param stake the amount of money at stake in the bet.
     *
    */
    function makeWager(uint8 selectionID, uint256 stake) external payable {
        require(msg.value == stake, "BettingPool: Passed ETH and stated stake do not match.");
        require(msg.sender != owner, "BettingPool: owner not allowed to makeWager");
        require(cutOff == false, "BettingPool: Betting period is over.");
        require(selectionID <= 1, "BettingPool: selectionID must be valid. ");
        require(stake >= _minimumStake, "BettingPool: Stake is not enough");
        require(wagers[msg.sender].exists == false, "BettingPool: sender has already made a wager.");
        
        wagers[msg.sender].stake = stake;
        wagers[msg.sender].selectionID = selectionID;
        wagers[msg.sender].exists = true;
        
    }
    
    /**
     * @notice queries for a trivia to be used to determine a random winning Seleciton.
     * @dev would be better if it queries from actual sports API.
    */
    function setWinningSelection() external {
        require(msg.sender == owner, "BettingPool: must be authorized to set Winning Selection.");
        require(winnerSelected == false, "BettingPool: must only declare winning selection once.");
        require(cutOff == true, "BettingPool: Betters must be cut off from making more wagers.");
        winnerSelected = true;
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit LogNewOraclizeQuery("Oraclize query not sent. Add more ETH for query fee.");
        } else {
            emit LogNewOraclizeQuery("Oraclize query sent. Stand by for results.");
            bytes32 queryId = oraclize_query("URL", "json(http://numbersapi.com/random/trivia?json).text");
            validIds[queryId] = true;
        }
    }
    
    /**
     * @notice turns the cutOff as true.
     * @dev could use oraclize to incorporate a clock, making it less decentralized. Possible alternative is Ethereum Alarm Clock.
    */
    function triggerCutOff() external returns(bool) {
        require (msg.sender == owner, "BettingPool: Not authorized to trigger cutOff.");
        cutOff = true;
        return true;
    }
    
    /**
     * @notice withdraws a party's winnings as dictated by the moneyline and their stake.
    */
    function getWinnings() external returns(bool) {
        require(winningSelectionID != MAX_UINT8, "Betting Pool: results not available");
        require(wagers[msg.sender].winningsCollected == false, "Betting Pool: party already collected winnings.");
        require(wagers[msg.sender].selectionID == winningSelectionID, "BettingPool: Must have won to collect winnings.");
        wagers[msg.sender].winningsCollected = true;
        uint256 payout = calculatePayout(msg.sender);
        (msg.sender).transfer(payout);
        return true;
    }
    
    /**
     * @notice fetches the result of oraclize query
     * @dev hashes the result, converts it to uint8 and gets the modulo to get either a random 0 or a random 1.]
    */
    function __callback(bytes32 _myid, string memory _result) public {
        if (!validIds[_myid]) revert("BettingPool: callback must have a valid id.");
        if ( msg.sender != oraclize_cbAddress()) revert("BettingPool: sender must be oraclize cbAddress.");
        
        winningSelectionID = uint8(uint(keccak256(abi.encodePacked(_result))) % 2);
        winnerSelected = true;
        emit LogResultReceived(_result, winningSelectionID);
        delete validIds[_myid];
        
    }
    /**
     * @notice calculates payout according to typical moneyline formula.
    */
    function calculatePayout(address party) public view returns(uint256) {
        uint256 stake = wagers[party].stake;
        int256 Odds = _odds[winningSelectionID];
        
        if ( Odds < 0 ){
            return (stake + (stake.mul(100)).div(uint256(Odds*-1)));
        } else {
            return (stake + (stake.mul(uint256(Odds))).div(100));
        }
    }
    

    function selections() public view returns(string memory, string memory) {return (_selections[0], _selections[1]);}
    function odds() public view returns(int256[2] memory) {return _odds;}
    function minimumStake() public view returns(uint256) {return _minimumStake;}
    function isCutOff() public view returns(bool) {return cutOff;}
    function contractAddress() public view returns(address) {return address(this);}
    function getOwner() public view returns(address) {return owner;}
    function contractBalance() public view returns(uint256) {return address(this).balance;}
    function getBalance(address party) public view returns (uint256) {return party.balance;}
    
}
