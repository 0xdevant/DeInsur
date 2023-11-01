// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../lib/Errors.sol";

interface IDeInsur {
    struct Policy {
        uint256 planId;
        uint256 price;
        uint256 insuredAmt;
        address insurer;
        bool claimable;
        uint256 activeDate;
        uint256 expiryDate;
    }

    event PolicyInsured(
        uint256 indexed planId,
        uint256 indexed policyId,
        uint256 insuredAmt,
        address insurer,
        uint256 activeDate,
        uint256 expiryDate
    );
    event PolicyClaimed(
        uint256 indexed planId,
        uint256 indexed policyId,
        uint256 claimedAmt,
        address insurer,
        uint256 activeDate,
        uint256 expiryDate
    );
    event ReserveReceived(address sender, uint256 value);

    function insure(uint256 planId, uint256 activeDate, uint256 expiryDate, uint256 insuredAmt) external payable;
    function claim(uint256 planId, uint256 policyId) external;

    function setPriceRate(uint256 planId, uint256 dailyPriceRate) external;
    function setMultiplierRateBP(uint256 newMultiplierRateBP) external;
    function setOperator(address newOperator) external;
    function setPolicyClaimable(uint256 policyId, bool isClaimable) external;

    function pause() external;
    function unpause() external;

    function getPolicyPrice(
        uint256 planId,
        uint256 activeDate,
        uint256 expiryDate,
        uint256 insuredAmt
    )
        external
        view
        returns (uint256 policyPrice);
    function getUserNumOfPolicy(address user) external view returns (uint256 userNumOfPolicy);
    function getUserPolicyIds(address user) external view returns (uint256[] memory userNumOfPolicy);
    function isUserPolicy(address user, uint256 policyId) external view returns (bool);
}
