const { ethers } = require("ethers");

const CONTRACT_ADDRESS = "YOUR_CONTRACT_ADDRESS";
const PROVIDER_URL = "YOUR_RPC_URL_OR_ALCHEMY";
const PRIVATE_KEY = "YOUR_PRIVATE_KEY";

const ABI = [
    "event OrderCreated(uint256 indexed orderId, address indexed buyer, string productName, uint256 price)",
    "event OrderPaid(uint256 indexed orderId, address indexed buyer, uint256 paidAt)",
    "event OrderShipped(uint256 indexed orderId, address indexed buyer, uint256 shippedAt)",
    "event OrderCompleted(uint256 indexed orderId, address indexed buyer, uint256 completedAt)",
    "event OrderCancelled(uint256 indexed orderId, address indexed buyer, uint256 cancelledAt)"
];

async function main() {
    const provider = new ethers.JsonRpcProvider(PROVIDER_URL);
    const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
    const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, wallet);

    console.log("=== 订单系统事件查询 ===\n");

    // 1. 查询所有订单创建事件
    console.log("1. 查询所有订单创建事件:");
    const createdEvents = await contract.queryFilter("OrderCreated");
    console.log(`   共 ${createdEvents.length} 个订单创建事件`);
    createdEvents.forEach((event, i) => {
        const [orderId, buyer, productName, price] = event.args;
        console.log(`   订单 #${orderId}: ${productName}, 价格: ${ethers.formatEther(price)} ETH, 买家: ${buyer}`);
    });

    // 2. 查询特定用户的订单
    console.log("\n2. 查询特定用户的订单:");
    const targetUser = "0x用户地址"; // 替换为实际地址
    const userCreatedEvents = await contract.queryFilter("OrderCreated", {
        topics: [
            ethers.id("OrderCreated(uint256,address,string,uint256)"),
            null,
            ethers.zeroPadValue(targetUser, 32)
        ]
    });
    console.log(`   用户 ${targetUser} 共有 ${userCreatedEvents.length} 个订单`);

    // 3. 统计各状态的订单数量
    console.log("\n3. 统计各状态的订单数量:");
    const paidEvents = await contract.queryFilter("OrderPaid");
    const shippedEvents = await contract.queryFilter("OrderShipped");
    const completedEvents = await contract.queryFilter("OrderCompleted");
    const cancelledEvents = await contract.queryFilter("OrderCancelled");

    console.log(`   创建: ${createdEvents.length}`);
    console.log(`   已支付: ${paidEvents.length}`);
    console.log(`   已发货: ${shippedEvents.length}`);
    console.log(`   已完成: ${completedEvents.length}`);
    console.log(`   已取消: ${cancelledEvents.length}`);

    // 4. 计算平均订单金额
    console.log("\n4. 计算平均订单金额:");
    let totalAmount = BigInt(0);
    createdEvents.forEach(event => {
        totalAmount += event.args.price;
    });
    const avgAmount = createdEvents.length > 0
        ? ethers.formatEther(totalAmount / BigInt(createdEvents.length))
        : 0;
    console.log(`   总订单金额: ${ethers.formatEther(totalAmount)} ETH`);
    console.log(`   平均订单金额: ${avgAmount} ETH`);

    // 5. 获取订单完整生命周期
    console.log("\n5. 追踪特定订单的完整生命周期:");
    const orderId = 1; // 订单ID
    const orderHistory = await getOrderHistory(contract, orderId);
    console.log(`   订单 #${orderId} 状态变化:`);
    orderHistory.forEach(status => {
        console.log(`   - ${status}`);
    });
}

async function getOrderHistory(contract, orderId) {
    const history = [];
    const orderIdTopic = ethers.zeroPadValue(ethers.toBeHex(orderId), 32);

    const created = await contract.queryFilter("OrderCreated", {
        topics: [null, orderIdTopic]
    });
    if (created.length > 0) history.push("已创建");

    const paid = await contract.queryFilter("OrderPaid", {
        topics: [null, orderIdTopic]
    });
    if (paid.length > 0) history.push("已支付");

    const shipped = await contract.queryFilter("OrderShipped", {
        topics: [null, orderIdTopic]
    });
    if (shipped.length > 0) history.push("已发货");

    const completed = await contract.queryFilter("OrderCompleted", {
        topics: [null, orderIdTopic]
    });
    if (completed.length > 0) history.push("已完成");

    const cancelled = await contract.queryFilter("OrderCancelled", {
        topics: [null, orderIdTopic]
    });
    if (cancelled.length > 0) history.push("已取消");

    return history;
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
