// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OrderBookExchange {
    struct Order {
        address trader;
        uint256 amount;
        uint256 price;
        bool isBuyOrder;
    }

    mapping(address => mapping(address => uint256)) public tokenBalances;
    mapping(address => Order[]) public buyOrders;
    mapping(address => Order[]) public sellOrders;

    event OrderCreated(address indexed trader, address indexed token, uint256 amount, uint256 price, bool isBuyOrder);
    event TradeExecuted(address indexed token, uint256 amount, uint256 price);

    function createBuyOrder(address token, uint256 amount, uint256 price) external {
        require(amount > 0, "Amount must be greater than zero");
        IERC20(token).approve(msg.sender,amount);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        buyOrders[token].push(Order(msg.sender, amount, price, true));

        emit OrderCreated(msg.sender, token, amount, price, true);
    }

    function createSellOrder(address token, uint256 amount, uint256 price) external {
        require(amount > 0, "Amount must be greater than zero");
        IERC20(token).approve(msg.sender,amount);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        sellOrders[token].push(Order(msg.sender, amount, price, false));

        emit OrderCreated(msg.sender, token, amount, price, false);
    }

    function executeTrades(address token) external {
        Order[] storage buys = buyOrders[token];
        Order[] storage sells = sellOrders[token];

        for (uint256 i = 0; i < buys.length; i++) {
            for (uint256 j = 0; j < sells.length; j++) {
                if (buys[i].price >= sells[j].price && buys[i].amount > 0 && sells[j].amount > 0) {
                    uint256 tradeAmount = (buys[i].amount < sells[j].amount) ? buys[i].amount : sells[j].amount;
                    uint256 tradePrice = buys[i].price;
                    IERC20(token).approve(msg.sender,tradeAmount);
                    IERC20(token).transfer(buys[i].trader, tradeAmount);
                    IERC20(token).approve(sells[j].trader,tradeAmount);
                    IERC20(token).transferFrom(sells[j].trader, address(this), tradeAmount);

                    buys[i].amount -= tradeAmount;
                    sells[j].amount -= tradeAmount;

                    emit TradeExecuted(token, tradeAmount, tradePrice);
                }
            }
        }
    }

    function getBuyOrders(address token) external view returns (Order[] memory) {
        return buyOrders[token];
    }

    function getSellOrders(address token) external view returns (Order[] memory) {
        return sellOrders[token];
    }

    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(msg.sender);
    }
}
