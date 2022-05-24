pragma solidity ^0.8.0;

import "./Token.sol";
import "./SafeMath.sol";

contract VestingPeriod{
    using SafeMath for uint256;

    struct BuyerInfo{
        uint256 valueInput;
        uint256 valueOutput;
        uint256 countTime;
        uint256 currentTimeDeposit;
        uint256 currnetTimeClaim;
        uint256 currentTimeRefund;
        bool statusBuyer;
    }

    struct PresaleInfo {
        address payable PRESALE_OWNER;
        uint256 AMOUNT;
        uint256 TOKEN_PRICE;
        Token SALE_ADDRESS_TOKEN;
        uint256 MAX_SPEND_PER_BUYER;
        uint256 MIN_SPEND_PER_BUYER;
        uint256 FISRT_TIME_RELEASE;
        uint256 START_TIME;
        uint256 TOTAL_PERIODS;
        uint256 TIME_PER_PERIODS;
        uint256 CLIFF;
    }

    struct VestingInfo {
        uint256 VESTING_TIME;
        uint256 UNLOCKRATE;
        bool STATUS;
    }

    modifier onlyAdmin(){
        require(ADMIN == msg.sender, "ONLY ADMIN CAN ACCESS");
        _;
    }
   
    PresaleInfo private PRESALE_INFO;
    mapping(address => BuyerInfo) public BUYER;
    mapping(address => VestingInfo[]) public VESTING_INFO;
    address private ADMIN;
    uint256 public FEE_USE_APP;

    //10000000000000000
    constructor(){
        ADMIN = msg.sender;
        FEE_USE_APP = 10000000000000000;
    }

    function initialPresale(Token _sale_address_token, uint256[8] memory data)
        external
    {   
        require(block.timestamp < data[4], 
            "TIME START LESS MORE THEN TIME TO RELEASE"
        );
        require(data[4] < data[5],
            "TIME RELEASE LESS MORE THAN START TIME"
        );

        require(data[2] > data[3],
            "MAX SPEND GREAT MORE THEN MIN SPEND OF BUYERS"
        );

        require(data[0] < Token(_sale_address_token).balanceOf(msg.sender) / 10**18,
            "OVER BALANCE FOR PAYABLE"
        ); 
        PRESALE_INFO.PRESALE_OWNER = payable(msg.sender);
        PRESALE_INFO.SALE_ADDRESS_TOKEN = _sale_address_token;
        PRESALE_INFO.AMOUNT = data[0];
        PRESALE_INFO.TOKEN_PRICE = data[1];
        PRESALE_INFO.MAX_SPEND_PER_BUYER = data[2];
        PRESALE_INFO.MIN_SPEND_PER_BUYER = data[3];
        PRESALE_INFO.FISRT_TIME_RELEASE = data[4];
        PRESALE_INFO.START_TIME = data[5];
        PRESALE_INFO.TOTAL_PERIODS = data[6];
        PRESALE_INFO.TIME_PER_PERIODS = data[7];
        PRESALE_INFO.CLIFF = PRESALE_INFO.START_TIME + 100;     
    }
    //10000000000000000000
    //1000000000000000000
    //
    //10000000000000000
    // [100000, 1000, 10, 1, 1653361000, 1653361050, 10, 50]

    function prePresaleStatus() public view returns(uint256)
    {
        if(block.timestamp < PRESALE_INFO.FISRT_TIME_RELEASE) {
            return 0; //Not active
        }
        if(
            block.timestamp > PRESALE_INFO.FISRT_TIME_RELEASE && 
            block.timestamp < PRESALE_INFO.START_TIME
        ) {
            return 1; //Release
        }
        if(
            (block.timestamp >= PRESALE_INFO.START_TIME) && 
            (block.timestamp <= PRESALE_INFO.TOTAL_PERIODS * PRESALE_INFO.TIME_PER_PERIODS + PRESALE_INFO.START_TIME)
        ) {
            return 1; //Active
        }
        if(block.timestamp < PRESALE_INFO.TOTAL_PERIODS * PRESALE_INFO.TIME_PER_PERIODS) {
            return 2; // Success
        }
    }

    function whileList(uint256 _amount) internal {
        require(
            prePresaleStatus() == 0, 
            "NOT ACTIVE"
        );
        require(
            !BUYER[msg.sender].statusBuyer,
            "BUYER EXITED!"
        );
        BUYER[msg.sender].statusBuyer = true;
        VestingInfo memory vestingInfoFirst;
        vestingInfoFirst.VESTING_TIME = PRESALE_INFO.CLIFF;
        vestingInfoFirst.UNLOCKRATE = _amount.mul(20).div(100);
        vestingInfoFirst.STATUS = false;
        VESTING_INFO[msg.sender].push(vestingInfoFirst);
        uint256 valueTokenEachOtherPeriod = _amount.mul(80).div(100).div(PRESALE_INFO.TOTAL_PERIODS.sub(1));
        for(uint256 i = 1 ; i < PRESALE_INFO.TOTAL_PERIODS ; i++){
            vestingInfoFirst.VESTING_TIME = i * PRESALE_INFO.TIME_PER_PERIODS + PRESALE_INFO.CLIFF;
            vestingInfoFirst.UNLOCKRATE = valueTokenEachOtherPeriod;
            VESTING_INFO[msg.sender].push(vestingInfoFirst);
        }
    }

    function adminApproveToken() public onlyAdmin{
        uint256 totalTokenClaim;
        if(!VESTING_INFO[msg.sender][i].STATUS){
                totalTokenClaim += VESTING_INFO[msg.sender][i].UNLOCKRATE;
        }
        Token(PRESALE_INFO.SALE_ADDRESS_TOKEN).approve(msg.sender, totalTokenClaim);
    }

    function userBuyToken(uint256 amount_in) external payable {
        require(
            prePresaleStatus() == 1, 
            "NOT ACTIVE"
        );
        require(
            amount_in/ (10 ** 18) >= PRESALE_INFO.MIN_SPEND_PER_BUYER,
            "NOT ENOUGH VALUE"
        );
        require(
            amount_in/ (10 ** 18) <= PRESALE_INFO.MAX_SPEND_PER_BUYER,
            "LESS THEN MAX VALUE CAN BUY"
        );
        require(
            amount_in * PRESALE_INFO.TOKEN_PRICE / (10 ** 18) <= PRESALE_INFO.AMOUNT, 
            "TOKEN BUYER LESS MORE THEN AMONT OF PRESALE"
        );
        payable(msg.sender).transfer(msg.value - amount_in - FEE_USE_APP);
        BUYER[msg.sender].valueInput = amount_in;
        BUYER[msg.sender].valueOutput = amount_in * PRESALE_INFO.TOKEN_PRICE / (10 ** 18);
        BUYER[msg.sender].countTime++;
        BUYER[msg.sender].currentTimeDeposit = block.timestamp;
        whileList(BUYER[msg.sender].valueOutput);
    }
    
    function claimToken() external {
        require(!VESTING_INFO[msg.sender][PRESALE_INFO.TOTAL_PERIODS.sub(1)].STATUS, 
            "CLAIMED ALL"
        );
        uint256 totalTokenClaim;

        for(uint256 i = 0 ; i < PRESALE_INFO.TOTAL_PERIODS ; i++){
            if(!VESTING_INFO[msg.sender][i].STATUS){
                totalTokenClaim += VESTING_INFO[msg.sender][i].UNLOCKRATE;
                VESTING_INFO[msg.sender][i].STATUS = false;
            }
        }
        Token(PRESALE_INFO.SALE_ADDRESS_TOKEN).transferFrom(
            PRESALE_INFO.PRESALE_OWNER, 
            msg.sender,
            totalTokenClaim
        );
    }

    function getPresale() public view returns(PresaleInfo memory){
        return PRESALE_INFO;
    }

    function getBalance(address _address) public view returns(uint256){
        return _address.balance;
    }

    function getBuyerInformation(address buyerAddress) public view returns(BuyerInfo memory){
        return BUYER[buyerAddress];
    }
}