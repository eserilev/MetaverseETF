// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./MetaverseFundToken.sol";
import "./MetaverseFundWallet.sol";

contract MetaverseFund is MetaverseFundWallet, Pausable {
    using SafeMath for uint256;

    MetaverseFundToken metaverseFundToken;

    // Fee which is subtracted on any withdraw. Amount requested for withdraw * withdraw fee = Amount received by the
    // account withdrawing. This means a withdraw fee of 3% means WITHDRAW_FEE should be 97.
    uint256 constant public WITHDRAW_FEE = 97;
    // Fee which is subtracted on any purchase. Calculation works the same as for WITHDRAW_FEE
    uint256 constant public PURCHASE_FEE = 97;

    // Represents the shares of the fund
    address public token;

    // Struct which is used to save the conversion rate from tokens to wei
    // Wei * numerator / denominator = tokens
    struct Price {
        uint256 numerator;
        uint256 denominator;
    }

    // Current price at which tokens can be bought and sold.
    Price public currentPrice;

    // @dev Logs when a token was added to the fund. Can only be emitted once
    // @param token Address of the token which is added to fund as a representation of shares.
    event MetaverseFundTokenAdded(address token);

    // @dev Event which logs the purchase of tokens
    // @param from Address which purchased the tokens
    // @param to Address which received the tokens bought by "from"
    // @param tokensPurchased Amount of tokens purchased
    // @param etherReceived Amount of wei used to purchase the tokens. This wei is received by the fund.
    event Purchase(address indexed from, address indexed to, uint256 tokensPurchased, uint256 etherReceived);

    // @dev Event which logs the withdrawal/selling of tokens for Ether
    // @param from Address from which tokens are sold from
    // @param to Address to which the Ether received for the withdrawal is sent to
    // @param tokensWithdrawn Amount of tokens withdrawn/sold
    // @param etherSent Amount of wei received in exchange for the tokens sold. Amount of wei sent out by the fund.
    event Withdrawal(address indexed from, address indexed to, uint256 tokensWithdrawn, uint256 etherSent);

    // @dev Logs when a withdrawal fails because of insufficient balance of the fund
    // @param from Address from which tokens should be sold from
    // @param to Address to which the Ether received for the withdrawal should be sent to
    // @param tokensWithdrawn Amount of tokens which should have been withdrawn/sold
    // @param etherSent Amount of wei which would have been received in exchange for the tokens sold.
    // Amount of wei which would have been sent out by the fund.
    event FailedWithdrawal(address indexed from, address indexed to, uint256 tokensWithdrawn, uint256 etherSent);

    // @dev Logs the updates of the price for tokens. numerator/denominator = price
    // @param numerator The new numerator for the price
    // @param denominator The new denominator for the price
    event PriceUpdate(uint256 numerator, uint256 denominator);

    constructor() {

    }

    // @dev Function to add a token to the fund in order to represent shares of the fund
    // @param _token FundToken which will be used to represent shares
    function addToken(address _token) public onlyOwner notNull(_token) {
        require(token == address(0));
        token = _token;
        metaverseFundToken = MetaverseFundToken(token);
        emit MetaverseFundTokenAdded(token);
    }

    // @dev Simple function which updates the current price of the tokens/shares
    // @param _numerator Numerator of the currentPrice
    // @param _denominator Denominator of the currentPrice
    function updatePrice(uint256 _numerator, uint256 _denominator) public onlyOwner {
        require(_numerator != 0);
        require(_denominator != 0);
        currentPrice.numerator = _numerator;
        currentPrice.denominator = _denominator;
        emit PriceUpdate(_numerator, _denominator);
    }

    // @dev Purchase function which is used to buy shares/tokens in exchange for Ether
    // The amount of tokens received in exchange for Ether is calculated based on the current price and purchase fee
    // @param _to Address to which the purchased tokens will be credited to.
    function buyShares(address _to) public payable hasToken whenNotPaused priceSet notNull(_to) {
        require(msg.value != 0);
        uint256 convertedValue = msg.value.mul(currentPrice.numerator).div(currentPrice.denominator);
        uint256 purchaseValue = convertedValue.mul(PURCHASE_FEE).div(100);
        metaverseFundToken.mint(_to, purchaseValue);
        emit Purchase(msg.sender, _to, purchaseValue, msg.value);
    }

    // @dev Withdraw function which is used to sell your shares/tokens of the fund in exchange for Ether
    // The amount of Ether received in exchange for tokens is calculated based on the current price and withdraw fee
    // In the case of a successful withdrawal the tokens received are burned.
    // Can fail if the fund does no have enough Ether
    // Purposely no withdrawal pattern was implemented because the use case is simple enough here IMO
    // @param _to Address to which the Ether received in exchange for the tokens is sent to
    // @param _value Amount of tokens to withdrawn/sold
    function sellShares(address payable _to, uint256 _value) external hasToken whenNotPaused priceSet notNull(_to) {
        require(_value != 0);
        address requestor = msg.sender;
        uint256 convertedValue = currentPrice.denominator.mul(_value).div(currentPrice.numerator);
        uint256 withdrawValue = convertedValue.mul(WITHDRAW_FEE).div(100);
        if (address(this).balance >= withdrawValue) {
            metaverseFundToken.burn(requestor, _value);
            _to.transfer(withdrawValue);
            emit Withdrawal(requestor, _to, _value, withdrawValue);
        } else {
            emit FailedWithdrawal(requestor, _to, _value, withdrawValue);
        }
    }

    // @dev Ensures that the fund has a token already added to it
    modifier hasToken {
        require(token != address(0));
        _;
    }

    // @dev Ensures that the address given is not the zero address
    // @param _address Address checked
    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    // @dev Ensures that the price for tokens is initiated an not zero
    modifier priceSet {
        require(currentPrice.numerator != 0);
        require(currentPrice.denominator != 0);
        _;
    }
}