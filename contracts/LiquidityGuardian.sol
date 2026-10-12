// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LiquidityGuardian
 * @author Yohan Samuditha
 * @notice Protocol collateral health monitor and emergency debt rebalancing contract.
 * @dev Emulates FlashLoan receiver callbacks to execute emergency collateral repayment.
 */
contract LiquidityGuardian {
    address public immutable owner;

    event EmergencyRepaymentTriggered(address indexed user, address indexed asset, uint256 debtAmount);
    event FlashLoanExecuted(address indexed asset, uint256 amount, uint256 premium);

    modifier onlyOwner() {
        require(msg.sender == owner, "Guardian: Only contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Simulates an Aave V3 executeOperation callback
     * @param asset The borrowed token address
     * @param amount The borrowed principal
     * @param premium FlashLoan fee
     * @param initiator Originator of the flashloan
     * @param params Arbitrary execution payload
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        require(initiator == address(this), "Guardian: Untrusted initiator");

        // Decode target rebalancing instructions
        (address targetUser, uint256 targetDebt) = abi.decode(params, (address, uint256));

        // In production: Swap borrowed funds, repay target's unhealthy debt position, retrieve collateral
        emit EmergencyRepaymentTriggered(targetUser, asset, targetDebt);
        emit FlashLoanExecuted(asset, amount, premium);

        return true;
    }

    /**
     * @notice Emergency withdrawal of ERC20 funds sent in error
     */
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        (bool success, ) = token.call(abi.encodeWithSignature("transfer(address,uint256)", owner, amount));
        require(success, "Guardian: Rescue failed");
    }
}
