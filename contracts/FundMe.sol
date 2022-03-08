// SPDX-License-Identifier: MIT

// Smart contract that lets anyone deposit ETH into the contract
// Only the owner of the contract can withdraw the ETH
pragma solidity >=0.6.0 <0.9.0;

// Get the latest ETH/USD price from chainlink price feed
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./SafeMath.sol";

contract FundMe {
    // safe math library check uint256 for integer overflows
    using SafeMath for uint256;

    //mapping to store which address depositeded how much ETH
    mapping(address => uint256) public addressToAmountFunded;

    // array of addresses who deposited
    address[] public funders;

    //address of the owner (who deployed the contract)
    address public owner;
    AggregatorV3Interface public priceFeed;

    // AggregatorV3Interface public priceFeed;

    // the first person to deploy the contract is
    // the owner
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        // 18 digit number to be compared with donated amount
        uint256 minimumUSD = 50 * 10**15;

        //is the donated amount less than 5USD?
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH !"
        );

        //if not, add to mapping and funders array
        addressToAmountFunded[msg.sender] += msg.value; // msg.sender: address of sender and msg.value is how much they sent
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        return priceFeed.version();
    }

    //function to get the version of the chainlink pricefeed
    function getPrice() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getConversionRate(uint256 _ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * _ethAmount);
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 5 * 10**15;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**16;
        // return (minimumUSD * precision) / price;
        // We fixed a rounding error found in the video by adding one!
        return ((minimumUSD * precision) / price) + 1;
    }

    //modifier: https://medium.com/coinmonks/solidity-tutorial-all-about-modifiers-a86cf81c14cb
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        // only want the contract admin/owner
        // require (msg.sender == owner, "You are not the sender");
        payable(msg.sender).transfer(address(this).balance); //this-> the contract that you are currently in

        //iterate through all the mappings and make them 0
        //since all the deposited amount has been withdrawn
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        //funders array will be initialized to 0
        funders = new address[](0);
    }
}
