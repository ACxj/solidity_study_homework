// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleShop {
    // 商品结构
    struct Product {
        string name;
        uint256 price;
        uint256 stock;
        bool isActive;
    }

    // 店铺所有者
    address public owner;
    // 商品列表
    mapping(uint256 => Product) public products;
    // 购买记录：buyer => (productId => amount)
    mapping(address => mapping(uint256 => uint256)) public purchases;

    event ProductAdded(uint256 indexed productId, string name, uint256 price, uint256 stock);
    event ProductPurchased(uint256 indexed productId, address indexed buyer, uint256 quantity, uint256 totalPaid);
    event ProductStockUpdated(uint256 indexed productId, uint256 newStock);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    error NotOwner();
    error ProductNotExist();
    error ProductNotActive();
    error InsufficientStock();
    error InsufficientPayment();
    error ZeroAmount();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // 添加商品
    function addProduct(uint256 _productId, string calldata _name, uint256 _price, uint256 _stock) external onlyOwner {
        if (_price == 0) revert ZeroAmount();

        products[_productId] = Product({
            name: _name,
            price: _price,
            stock: _stock,
            isActive: true
        });

        emit ProductAdded(_productId, _name, _price, _stock);
    }

    // 购买商品
    function buyProduct(uint256 _productId, uint256 _quantity) external payable {
        if (_quantity == 0) revert ZeroAmount();

        Product storage product = products[_productId];
        if (bytes(product.name).length == 0) revert ProductNotExist();
        if (!product.isActive) revert ProductNotActive();
        if (product.stock < _quantity) revert InsufficientStock();

        uint256 totalPrice = product.price * _quantity;
        if (msg.value < totalPrice) revert InsufficientPayment();

        product.stock -= _quantity;
        purchases[msg.sender][_productId] += _quantity;

        emit ProductPurchased(_productId, msg.sender, _quantity, msg.value);

        // 退款多余的钱
        if (msg.value > totalPrice) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalPrice}("");
            require(success, "Transfer failed");
        }
    }

    // 更新库存
    function updateStock(uint256 _productId, uint256 _newStock) external onlyOwner {
        if (products[_productId].price == 0) revert ProductNotExist();

        products[_productId].stock = _newStock;
        emit ProductStockUpdated(_productId, _newStock);
    }

    // 提取收益
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert ZeroAmount();

        emit FundsWithdrawn(owner, balance);
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Transfer failed");
    }

    // 获取合约余额
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 获取用户购买数量
    function getUserPurchase(address _user, uint256 _productId) external view returns (uint256) {
        return purchases[_user][_productId];
    }
}