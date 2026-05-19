// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrderSystem {
    enum OrderStatus { Created, Paid, Shipped, Completed, Cancelled }

    struct Order {
        address buyer;
        string productName;
        uint256 price;
        OrderStatus status;
        uint256 createdAt;
        uint256 paidAt;
        uint256 shippedAt;
        uint256 completedAt;
    }

    mapping(uint256 => Order) public orders;
    uint256 public orderCount;

    event OrderCreated(
        uint256 indexed orderId,
        address indexed buyer,
        string productName,
        uint256 price
    );
    event OrderPaid(uint256 indexed orderId, address indexed buyer, uint256 paidAt);
    event OrderShipped(uint256 indexed orderId, address indexed buyer, uint256 shippedAt);
    event OrderCompleted(uint256 indexed orderId, address indexed buyer, uint256 completedAt);
    event OrderCancelled(uint256 indexed orderId, address indexed buyer, uint256 cancelledAt);

    error InvalidOrderId();
    error InvalidStatusTransition(OrderStatus current, OrderStatus target);
    error OnlyBuyer();
    error OrderNotPaid();
    error OrderAlreadyClosed();

    modifier onlyBuyer(uint256 orderId) {
        if (orders[orderId].buyer != msg.sender) revert OnlyBuyer();
        _;
    }

    function createOrder(string calldata productName, uint256 price) external returns (uint256) {
        if (price == 0) revert InvalidOrderId();

        orderCount++;
        Order storage order = orders[orderCount];
        order.buyer = msg.sender;
        order.productName = productName;
        order.price = price;
        order.status = OrderStatus.Created;
        order.createdAt = block.timestamp;

        emit OrderCreated(orderCount, msg.sender, productName, price);
        return orderCount;
    }

    function payOrder(uint256 orderId) external onlyBuyer(orderId) {
        Order storage order = orders[orderId];
        if (order.status != OrderStatus.Created) revert InvalidStatusTransition(order.status, OrderStatus.Paid);

        order.status = OrderStatus.Paid;
        order.paidAt = block.timestamp;

        emit OrderPaid(orderId, msg.sender, block.timestamp);
    }

    function shipOrder(uint256 orderId) external {
        Order storage order = orders[orderId];
        if (order.status != OrderStatus.Paid) revert InvalidStatusTransition(order.status, OrderStatus.Shipped);

        order.status = OrderStatus.Shipped;
        order.shippedAt = block.timestamp;

        emit OrderShipped(orderId, order.buyer, block.timestamp);
    }

    function completeOrder(uint256 orderId) external {
        Order storage order = orders[orderId];
        if (order.status != OrderStatus.Shipped) revert InvalidStatusTransition(order.status, OrderStatus.Completed);

        order.status = OrderStatus.Completed;
        order.completedAt = block.timestamp;

        emit OrderCompleted(orderId, order.buyer, block.timestamp);
    }

    function cancelOrder(uint256 orderId) external onlyBuyer(orderId) {
        Order storage order = orders[orderId];
        if (order.status == OrderStatus.Completed || order.status == OrderStatus.Cancelled) {
            revert OrderAlreadyClosed();
        }
        if (order.status == OrderStatus.Shipped) {
            revert InvalidStatusTransition(order.status, OrderStatus.Cancelled);
        }

        order.status = OrderStatus.Cancelled;

        emit OrderCancelled(orderId, msg.sender, block.timestamp);
    }

    function getOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }
}